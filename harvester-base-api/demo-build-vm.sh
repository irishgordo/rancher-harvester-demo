#! /usr/bin/bash
echo -n "Enter Harvester VIP IP: "
read harvestervip
echo -n "Paste in Bearer Token That Was Built: "
read bearertoken


curl --location --insecure --request POST "https://$harvestervip/apis/kubevirt.io/v1/namespaces/default/virtualmachines" \
--header "Authorization: Bearer $bearertoken" \
--header 'Content-Type: application/json' \
--data-raw '{
  "apiVersion": "kubevirt.io/v1",
  "kind": "VirtualMachine",
  "metadata": {
    "name": "testvmi-nocloud"
  },
  "spec": {
    "runStrategy": "RerunOnFailure",
    "architecture": "amd64",
    "template": {
      "spec": {
        "domain": {
          "machine": {
            "type": "q35"
          },
          "cpu": {
            "cores": 1,
            "sockets": 1,
            "threads": 1
          },
          "resources": {
            "requests": {
              "memory": "1024M"
            }
          },
          "features": {
            "acpi": {
              "enabled": true
            }
          },
          "networks": [],
          "devices": {
            "disks": [
              {
                "name": "containerdisk",
                "disk": {
                  "bus": "virtio"
                }
              },
              {
                "name": "emptydisk",
                "disk": {
                  "bus": "virtio"
                }
              },
              {
                "disk": {
                  "bus": "virtio"
                },
                "name": "cloudinitdisk"
              }
            ],
            "inputs": [
              {
                "bus": "usb",
                "name": "tablet",
                "type": "tablet"
              }
            ],
            "interfaces": []
          }
        },
        "volumes": [
          {
            "name": "containerdisk",
            "containerDisk": {
              "image": "kubevirt/fedora-cloud-container-disk-demo:latest"
            }
          },
          {
            "name": "emptydisk",
            "emptyDisk": {
              "capacity": "2Gi"
            }
          },
          {
            "name": "cloudinitdisk",
            "cloudInitNoCloud": {
              "userData": "#cloud-config\npassword: fedora\nchpasswd: { expire: False }"
            }
          }
        ]
      }
    }
  }
}'
