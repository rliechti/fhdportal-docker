<?php
require __DIR__ . '/include.php';
require __DIR__ . '/keycloak.php';
use Ramsey\Uuid\Uuid;

if (!defined("SDA_INBOX")) define("SDA_INBOX","/var/www/fhd-portal/sda/");

function updateResourceStatus($user_id, $filepath, $status, $comment = "")
{
    echo $filepath." => ".$status.PHP_EOL;
    $dbresources = DB::query("SELECT
        resource.id,
        resource.properties,
        resource.properties ->> 'public_id' as public_id
    FROM
        resource
        INNER JOIN resource_type ON resource.resource_type_id = resource_type.id
        AND resource_type.\"name\" = 'SdaFile'
        inner join resource_acl on resource.id = resource_acl.resource_id and resource_acl.user_id = %i
    where coalesce(resource.properties->>'filepath'::text,'') = %s
    ", $user_id, $filepath);
    if (!$dbresources) {
        fwrite(STDERR, "Error: file ".$filepath." is unknown".PHP_EOL);
    }
    foreach ($dbresources as $dbresource) {
        DB::update("resource", array("status_type_id" => $status), "id = %s", $dbresource['id']);
        $uuid = Uuid::uuid4();
        $log_id = $uuid->toString();
        $log = array(
            "id" => $log_id,
            "resource_id" => $dbresource['id'],
            "user_id" => $user_id,
            "action_type_id" => $status,
            "properties" => json_encode($dbresource['properties'])
        );
        if ($comment) {
            $log['comment'] = $comment;
        }
        DB::insert("resource_log", $log);
    }
}

$messages = array();
$dirs = glob(SDA_INBOX."*@*",GLOB_ONLYDIR);
foreach($dirs as $dir){
    $user_id = basename($dir);
	$filelist = array();
	if (file_exists($dir."/.filelist")){
        $filelist = file($dir."/.filelist",FILE_IGNORE_NEW_LINES);
	}
	$previous_files = array();
	foreach($filelist as $f){
		list($filename,$sha) = explode(":",$f);
		$previous_files[$sha] = $filename;
	}


	$list = array_filter(scandir($dir),function($f){return substr($f,0,1)!= '.';});
	$current_files = array();
	foreach($list as $f){
		$sha =  hash_file('sha256', $dir."/".$f);
		$current_files[$sha] = $f;
		if (isset($previous_files[$sha]) && $previous_files[$sha] != $f){
			$messages[] = array(
				"operation" => "rename",
				"user"      => $user_id,
				"filepath"  => ltrim($dir."/".$f,'/'),
				"oldpath"   => ltrim($dir."/".basename($previous_files[$sha]),"/")
			);
			unset($previous_files[$sha]);
		}
		else if (!isset($previous_files[$sha])){
			$messages[] = array(
				"operation"           => "upload",
				"user"                => $user_id,
				"filepath"            => ltrim($dir."/".$f,'/'),
				"file_last_modified"  => filemtime($dir."/".$f),
				"filesize"            => filesize($dir."/".$f),
				"encrypted_checksums" => array(
					array("type" => "sha256", "value" => $sha)
				)
			);
		}
	}
	$content = array();
	foreach($current_files as $sha => $f){
		$content[] = $f.":".$sha;
	}

	file_put_contents($dir."/.filelist",implode(PHP_EOL,$content));
	$removed_files = array_diff(array_values($previous_files),$list);
	foreach($removed_files as $f){
		$messages[] = array(
			"operation" => "remove",
			"user" => $user_id,
			"filepath" => ltrim($dir."/".$f,'/'),
		);
	}
}

foreach($messages as $msg){
    $users = getKeyCloakUsers('', 'email='.$msg['user']);
    $user = array_shift($users);
    $user_id = DB::queryFirstField("SELECT id from \"user\" where email = %s", $user['email']);
    if (!$user_id) {
        DB::insert("user", array("external_id" => $msg['user'],"email" => $msg['user']));
        $user_id = DB::insertId();
    }
    $role_id = DB::queryFirstField("SELECT id from \"role\" where name = 'owner'");
    if ($msg['operation'] == 'upload') {
        $resourceProperties = array(
            "filesize" => isset($msg['filesize']) ? +$msg['filesize'] : -1,
            "title" => basename($msg['filepath']),
            "filepath" => $msg['filepath'],
            "file_last_modified" => +$msg['file_last_modified'],
            "encrypted_checksums" => $msg['encrypted_checksums']
        );
        $validator = new JsonSchema\Validator();
        $schema_json = DB::queryFirstField("SELECT properties from resource_type where name = 'SdaFile'");
        $schema = json_decode($schema_json);
        $properties = json_decode(json_encode($resourceProperties));
        $validator->validate($properties, $schema->data_schema);
        if ($validator->isValid()) {
            $ret = array('action_type_id' => null,'public_id' => null);
            $resource = array(
                "id" => null,
                "properties" => json_encode($properties),
                "resource_type_id" => DB::queryFirstField("SELECT id from resource_type where name = 'SdaFile'"),
                "status_type_id" => DB::queryFirstField("SELECT id from status_type where name = 'draft'")
            );
            $action_type_id = 'CRE';
            $checksums = array();
            foreach ($msg['encrypted_checksums'] as $chs) {
                if ($chs['value']) {
                    $checksums[] = $chs['value'];
                }
            }
            $dbresource = null;
            if ($checksums !== []) {
                $dbresource = DB::queryFirstRow("SELECT
                    resource.id,
                    coalesce(resource.properties->>'filepath'::text,'') as filepath,
                    resource.properties ->> 'public_id' as public_id
                FROM
                    resource
                    INNER JOIN resource_type ON resource.resource_type_id = resource_type.id
                    AND resource_type.\"name\" = 'SdaFile'
                    inner join resource_acl on resource.id = resource_acl.resource_id and resource_acl.user_id = %i
                where coalesce(resource.properties->'encrypted_checksums'->>'value'::text,'') in %ls
                ", $user_id, $checksums);
            }
            if ($dbresource && $dbresource['filepath'] == $msg['filepath']) {
                fwrite(STDERR, "Already exists".PHP_EOL);
                return;
            } elseif ($dbresource) { //UPDATE (RENAME)
                // TODO RENAME
                $resource['id'] = $dbresource['id'];
                $properties->public_id = $dbresource['public_id'];
                $resource['properties'] = json_encode($properties);
                $action_type_id = 'MOD';
            }
            if (!$resource['id']) {
                $uuid = Uuid::uuid4();
                $resource['id'] = $uuid->toString();
                DB::insert('resource', $resource);
                if ($role_id) {
                    $acl = array( "resource_id" => $resource['id'], "user_id" => $user_id, "role_id" => $role_id );
                    DB::insert('resource_acl', $acl);
                }
            } else {
                DB::update('resource', $resource, "id = %s", $resource['id']);
            }
            $uuid = Uuid::uuid4();
            $log_id = $uuid->toString();
            $log = array(
                "id" => $log_id,
                "resource_id" => $resource['id'],
                "user_id" => $user_id,
                "action_type_id" => $action_type_id,
                "properties" => $resource['properties']
            );
            DB::insert("resource_log", $log);
                        
        } else {
            $content = '';
            print "\tJSON does not validate. Violations:\t";
            foreach ($validator->getErrors() as $error) {
                $content .= "[".$error['property']."]:". $error['message']."; ";
                print("\t". $error['property']."\t". $error['message']);
            }
            fwrite(STDERR, substr($content, 0, -2).PHP_EOL);
        }
    } elseif ($msg['operation'] == 'rename') {
        if (!isset($msg['oldpath']) || !$msg['oldpath']) {
            // throw new Exception("Error. Cannot rename file with no name (oldpath)", 1);
            fwrite(STDERR, "Cannot rename file with no name (oldpath)".PHP_EOL);
        } elseif (!isset($msg['filepath']) || !$msg['filepath']) {
            fwrite(STDERR, "Cannot rename file: no new filepath provided".PHP_EOL);
        } else {
            $dbresource = DB::queryFirstRow("SELECT
                resource.id,
                resource.properties,
                resource.properties ->> 'public_id' as public_id
            FROM
                resource
                INNER JOIN resource_type ON resource.resource_type_id = resource_type.id
                AND resource_type.\"name\" = 'SdaFile'
                inner join resource_acl on resource.id = resource_acl.resource_id and resource_acl.user_id = %i
            where coalesce(resource.properties->>'filepath'::text,'') = %s
            ", $user_id, $msg['oldpath']);
            if (!$dbresource) {
                fwrite(STDERR, "Error: resource is unknown".PHP_EOL);
            } else {
                $properties = json_decode($dbresource['properties'], true);
                $properties['filepath'] = $msg['filepath'];
                DB::query("UPDATE resource set properties = properties::jsonb || '{\"filepath\":\"".$msg['filepath']."\"}' where id = %s", $dbresource['id']);
                $uuid = Uuid::uuid4();
                $log_id = $uuid->toString();
                $log = array(
                    "id" => $log_id,
                    "resource_id" => $dbresource['id'],
                    "user_id" => $user_id,
                    "action_type_id" => "MOD",
                    "properties" => json_encode($properties)
                );
                DB::insert("resource_log", $log);
            }
        }
    } elseif ($msg['operation'] == 'remove') {
        if (!isset($msg['filepath']) || !$msg['filepath']) {
            fwrite(STDERR, "Cannot remove file: no new filepath provided".PHP_EOL);
        } else {
            echo "REMOVE ".$msg['filepath'].PHP_EOL;
            updateResourceStatus($user_id, $msg['filepath'], "DEL", "deleted by user");
        }
    }
}
