#! /usr/bin/bash
echo -n "Enter Harvester VIP IP: "
read harvestervip
echo -n "Paste in Bearer Token That Was Built: "
read bearertoken

curl --location --insecure --request POST "https://$harvestervip/apis/network.harvesterhci.io/v1beta1/clusternetworks" \
--header "Authorization: Bearer $bearertoken" \
--header 'Content-Type: application/json' \
--data-raw '{
    "apiVersion": "network.harvesterhci.io/v1beta1",
    "kind": "ClusterNetwork",
    "metadata": {
        "name": "test",
        "namespace": "default"
    }
}'