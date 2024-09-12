#! /usr/bin/bash
echo -n "Enter Harvester VIP IP: "
read harvestervip
echo -n "Paste in Bearer Token That Was Built: "
read bearertoken

curl --location --insecure --request POST "https://$harvestervip/apis/harvesterhci.io/v1beta1/namespaces/default/virtualmachineimages" \
--header "Authorization: Bearer $bearertoken" \
--header 'Content-Type: application/json' \
--data-raw '{
    "apiVersion": "harvesterhci.io/v1beta1",
    "kind": "VirtualMachineImage",
    "metadata": {
        "annotations": {
            "harvesterhci.io/storageClassName": "harvester-longhorn",
            "field.cattle.io/description": "demo cirros image"
        },
        "name": "cirros-test",
        "namespace": "default"
    },
    "spec": {
        "description": "cirros test img",
        "displayName": "cirros-img-test",
        "sourceType": "download",
        "url": "https://github.com/cirros-dev/cirros/releases/download/0.4.0/cirros-0.4.0-x86_64-disk.img"
    }
}'


# token-c6wsj:7dwqnx969bhpbg9n9vpwwms6vhwlmdsw5mpmjrm5trpwpptbxfnjzp