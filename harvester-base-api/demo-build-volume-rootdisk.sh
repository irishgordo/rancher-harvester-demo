#! /usr/bin/bash
echo -n "Enter Harvester VIP IP: "
read harvestervip
echo -n "Paste in Bearer Token That Was Built: "
read bearertoken


curl --location --insecure --request POST "https://$harvestervip/api/v1/namespaces/default/persistentvolumeclaims" \
--header "Authorization: Bearer $bearertoken" \
--header 'Content-Type: application/json' \
--data-raw '{
  "type": "persistentvolumeclaim",
  "kind": "PersistentVolumeClaim",
  "metadata": {
    "name": "testvolrootdisk",
    "namespace": "default",
    "annotations": {
      "harvesterhci.io/imageId": "default/cirros-test"
    }
  },
  "spec": {
    "accessModes": ["ReadWriteMany"],
    "volumeMode": "Block",
    "resources": {
      "requests": {
        "storage": "10Gi"
      }
    },
    "storageClassName": "longhorn-cirros-test"
  }
}'
