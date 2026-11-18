<?php
// Mimics the approval of the DAC portal, which this demonstrator does not have.
//
// What the real DAC portal does when it accepts a submission (see ResourceEditService::handleDacPatch in the API):
//  - the policy chosen for a dataset becomes active and approved,
//  - the dataset is approved (status APR), and so are the parts it holds,
//  - once every dataset of a study is approved, the study is approved too.
// The administrator of FHDportal then reviews the approved datasets ("Dataset Publication Review") and publishes them: this script
// never publishes. It runs every minute (init/sdacron) and approves what is submitted (SUB) or re-submitted (RES), whatever its
// release date.
require __DIR__ . '/include.php';
use Ramsey\Uuid\Uuid;

const APPROVED = 'APR';

function logAction(string $resourceId, string $actionType): void
{
    DB::insert('resource_log', [
        'id'             => Uuid::uuid4()->toString(),
        'resource_id'    => $resourceId,
        'user_id'        => null, // the DAC portal is not a user of the portal
        'action_type_id' => $actionType,
        'properties'     => DB::queryFirstField("SELECT properties FROM resource WHERE id = %s", $resourceId),
    ]);
}

// Sets the status, and that of the parts of the resource (isPartOf), like ResourceEditService::setResourceStatusById. A deleted
// resource is left alone: deleting only sets its status, it must not come back.
function approve(string $resourceId, array &$done): void
{
    if (isset($done[$resourceId])) {
        return;
    }
    $done[$resourceId] = true;
    $status = DB::queryFirstField("SELECT status_type_id FROM resource WHERE id = %s", $resourceId);
    if ($status === 'DEL') {
        return;
    }
    if ($status !== APPROVED) {
        DB::update('resource', ['status_type_id' => APPROVED], 'id = %s', $resourceId);
    }
    $parts = DB::queryFirstColumn(
        "SELECT domain_resource_id FROM relationship_view
         WHERE range_resource_id = %s AND predicate_name = 'isPartOf' AND domain_type <> 'SdaFile'",
        $resourceId
    );
    foreach ($parts as $part) {
        approve($part, $done);
    }
}

$datasets = DB::queryFirstColumn(
    "SELECT resource.id
     FROM resource
     INNER JOIN resource_type ON resource.resource_type_id = resource_type.id
     WHERE resource_type.name IN ('Dataset', 'ImageDataset') AND resource.status_type_id IN ('SUB', 'RES')"
);

foreach ($datasets as $datasetId) {
    $publicId = DB::queryFirstField("SELECT properties ->> 'public_id' FROM resource WHERE id = %s", $datasetId);

    // the policy the submitter chose is accepted: active, and approved
    $policyLinks = DB::queryFirstColumn(
        "SELECT relationship.id
         FROM relationship
         INNER JOIN resource policy ON policy.id = relationship.range_resource_id
         INNER JOIN resource_type ON policy.resource_type_id = resource_type.id
         WHERE relationship.domain_resource_id = %s AND resource_type.name = 'Policy'",
        $datasetId
    );
    foreach ($policyLinks as $linkId) {
        DB::update('relationship', ['is_active' => true, 'status_type_id' => APPROVED], 'id = %s', $linkId);
        DB::insert('relationship_log', [
            'id'              => Uuid::uuid4()->toString(),
            'relationship_id' => $linkId,
            'user_id'         => null,
            'action_type_id'  => 'MOD',
        ]);
    }

    $done = [];
    approve($datasetId, $done);
    logAction($datasetId, APPROVED);
    echo "dataset $publicId approved\n";

    // the study is approved once all its datasets are (a deleted dataset does not count)
    $studyId = DB::queryFirstField(
        "SELECT range_resource_id FROM relationship_view WHERE domain_resource_id = %s AND range_type = 'Study'",
        $datasetId
    );
    if (!$studyId) {
        continue;
    }
    $siblings = DB::queryFirstColumn(
        "SELECT dataset.status_type_id
         FROM relationship_view
         INNER JOIN resource dataset ON dataset.id = relationship_view.domain_resource_id
         WHERE relationship_view.range_resource_id = %s
           AND relationship_view.domain_type IN ('Dataset', 'ImageDataset')
           AND dataset.status_type_id <> 'DEL'",
        $studyId
    );
    if ($siblings && count(array_unique($siblings)) === 1 && $siblings[0] === APPROVED) {
        approve($studyId, $done);
        logAction($studyId, APPROVED);
        echo "study " . DB::queryFirstField("SELECT properties ->> 'public_id' FROM resource WHERE id = %s", $studyId) . " approved\n";
    }
}
