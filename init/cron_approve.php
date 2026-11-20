<?php
// Plays the DAC portal, which this demonstrator does not have, by making the call a real DAC portal makes when it accepts a
// submission: PATCH /api/submissions/{study}/datasets/{dataset} with a token of the dac-cli client and
// {"policy_id": ..., "policy_status": "valid"} (see docs/integration-dac-portal.md, section 5.2).
//
// The API does the rest, exactly as it does for a real DAC: the policy link becomes active and approved, the dataset (and the parts
// it holds) become APR, and once every dataset of a study is APR the study is approved too and the help desk is notified by mail.
// The administrator of FHDportal then reviews the approved datasets ("Dataset Publication Review") and publishes them: this script
// never publishes.
//
// It runs every minute (init/sdacron) and approves what is submitted (SUB) or re-submitted (RES), whatever its release date. The
// only thing it reads from the database is that list: a real DAC portal keeps it itself, from POST /submissions.
//
// Configuration, all from .env: KEYCLOAK_DAC_CLIENT_ID and KEYCLOAK_DAC_SECRET (the dac-cli client), KEYCLOAK_ISSUER_URL and
// KEYCLOAK_REALM (the token must carry the issuer that the API expects), KEYCLOAK_URL (where Keycloak is reached from this container).
// FHDPORTAL_API_INTERNAL_URL (default http://webserver/api) is the API as seen from this container.
require __DIR__ . '/include.php';

const APPROVED = 'APR';

function env(string $name, ?string $default = null): ?string
{
    $value = $_ENV[$name] ?? $_SERVER[$name] ?? getenv($name);
    return ($value === false || $value === null || $value === '') ? $default : $value;
}

function fail(string $message): never
{
    fwrite(STDERR, "cron_approve: $message\n");
    exit(1);
}

// Token of the dac-cli client (client credentials). The issuer of the token is the host that the request names, and the API only
// accepts KEYCLOAK_ISSUER_URL: the request is sent to that URL, and curl is told where it really is (connect-to). The certificate of
// the demonstrator is self-signed and issued for another name, so it is not verified here.
function dacToken(): string
{
    $issuer = rtrim(env('KEYCLOAK_ISSUER_URL') ?? fail('KEYCLOAK_ISSUER_URL is not set'), '/');
    $realm = env('KEYCLOAK_REALM') ?? fail('KEYCLOAK_REALM is not set');
    $parts = parse_url($issuer);
    $port = $parts['port'] ?? (($parts['scheme'] ?? 'https') === 'https' ? 443 : 80);
    $internal = preg_replace('~^https?://~', '', rtrim(env('KEYCLOAK_URL', 'keycloak:8080'), '/'));
    $internalHost = explode(':', $internal)[0];

    $ch = curl_init("$issuer/realms/$realm/protocol/openid-connect/token");
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT        => 15,
        CURLOPT_POSTFIELDS     => http_build_query([
            'grant_type'    => 'client_credentials',
            'client_id'     => env('KEYCLOAK_DAC_CLIENT_ID', 'dac-cli'),
            'client_secret' => env('KEYCLOAK_DAC_SECRET') ?? fail('KEYCLOAK_DAC_SECRET is not set'),
        ]),
        CURLOPT_CONNECT_TO     => ["{$parts['host']}:$port:$internalHost:$port"],
        CURLOPT_SSL_VERIFYPEER => false,
        CURLOPT_SSL_VERIFYHOST => 0,
    ]);
    $body = curl_exec($ch);
    $status = curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
    if ($body === false || $status !== 200) {
        fail("no token from Keycloak (HTTP $status" . ($body === false ? ', ' . curl_error($ch) : ': ' . substr((string) $body, 0, 200)) . ')');
    }
    return json_decode($body, true)['access_token'] ?? fail('the answer of Keycloak has no access_token');
}

// The decision of the DAC on one dataset. Returns the HTTP status of the API.
function decide(string $token, string $studyId, string $datasetId, string $policyId): array
{
    $api = rtrim(env('FHDPORTAL_API_INTERNAL_URL', 'http://webserver/api'), '/');
    $ch = curl_init("$api/submissions/" . rawurlencode($studyId) . '/datasets/' . rawurlencode($datasetId));
    curl_setopt_array($ch, [
        CURLOPT_CUSTOMREQUEST  => 'PATCH',
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT        => 60,
        CURLOPT_HTTPHEADER     => ["Authorization: Bearer $token", 'Content-Type: application/json'],
        CURLOPT_POSTFIELDS     => json_encode(['policy_id' => $policyId, 'policy_status' => 'valid']),
    ]);
    $body = curl_exec($ch);
    return [curl_getinfo($ch, CURLINFO_RESPONSE_CODE), $body === false ? curl_error($ch) : (string) $body];
}

$datasets = DB::query(
    "SELECT resource.id,
            resource.properties ->> 'public_id' AS public_id,
            resource.properties ->> 'policy_id' AS policy_id,
            (SELECT range_resource_id FROM relationship_view
              WHERE domain_resource_id = resource.id AND range_type = 'Study' LIMIT 1) AS study_id
     FROM resource
     INNER JOIN resource_type ON resource.resource_type_id = resource_type.id
     WHERE resource_type.name IN ('Dataset', 'ImageDataset') AND resource.status_type_id IN ('SUB', 'RES')
     ORDER BY resource.id"
);
if (!$datasets) {
    exit(0); // nothing to decide: do not even ask for a token
}

$token = dacToken();
$failed = 0;
foreach ($datasets as $dataset) {
    $name = $dataset['public_id'] ?: $dataset['id'];
    if (!$dataset['study_id'] || !$dataset['policy_id']) {
        fwrite(STDERR, "dataset $name: skipped, it has " . (!$dataset['study_id'] ? 'no study' : 'no policy') . "\n");
        $failed++;
        continue;
    }
    [$status, $body] = decide($token, $dataset['study_id'], $dataset['id'], $dataset['policy_id']);
    $now = DB::queryFirstField("SELECT status_type_id FROM resource WHERE id = %s", $dataset['id']);
    if ($status === 204 && $now === APPROVED) {
        echo "dataset $name approved\n";
        $studyStatus = DB::queryFirstRow(
            "SELECT properties ->> 'public_id' AS public_id, status_type_id FROM resource WHERE id = %s",
            $dataset['study_id']
        );
        if ($studyStatus['status_type_id'] === APPROVED) {
            echo "study {$studyStatus['public_id']} approved\n";
        }
    } else {
        fwrite(STDERR, "dataset $name: the API answered HTTP $status, the status is now $now" . ($body !== '' ? ': ' . substr($body, 0, 200) : '') . "\n");
        $failed++;
    }
}
exit($failed ? 1 : 0);
