<?php
require __DIR__ . '/include.php';
$status_id = 'PUB';
$resources = DB::query("SELECT id, status_type_id from resource where resource.properties->>'released_date' is not null and to_date(resource.properties->>'released_date','YYYY-MM-DD') <= CURRENT_DATE and status_type_id = 'SUB';");
foreach($resources as $resource){
    if ($resource['status_type_id'] != $status_id) {
        DB::update("resource", array("status_type_id" => $status_id), "id = %s", $resource['id']);
    }    
    // update children resources //
    $children_resource_ids = DB::queryFirstColumn("SELECT
        resource.id
        FROM
            relationship
            inner join resource on relationship.domain_resource_id = resource.id
        WHERE
            relationship.range_resource_id = %s
            and resource.status_type_id <> 'DEL';",
    $resource['id']);
    if ($children_resource_ids){
        DB::update("resource", array("status_type_id" => $status_id), "id in %ls", $children_resource_ids);    
    }
    // update parent resource (study) //
    $parent_resource_ids = DB::queryFirstColumn("SELECT
        resource.id,
        resource.properties
        FROM
        	relationship
        	inner join resource on relationship.range_resource_id = resource.id
        	inner join resource_type on resource.resource_type_id = resource_type.id
        WHERE
        	relationship.domain_resource_id = %s
        	and resource.status_type_id <> 'DEL'
        	and resource_type.\"name\" = 'Study';",
    $resource['id']);
    if ($parent_resource_ids){
        DB::update("resource", array("status_type_id" => $status_id), "id in %ls", $parent_resource_ids);    
    }
    
}