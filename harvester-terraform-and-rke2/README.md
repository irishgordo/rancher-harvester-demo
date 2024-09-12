# Wait...What is this?
Here we see a more holistic approach to leveraging Harvester + Rancher in unison.

The pre-requisites are mentioned below.

Some of these elements will change, as:
- https://github.com/harvester/harvester/issues/1797
Should be merged in soon (which would reduce the need for Kubeconfig), but still manual step of importing Harvester into Rancher would probably need to take place, TBD.

**What this provides?**

We use a hybrid approach to achieve provisioning:
- a VM image for a MinIO VM
- a VM Network (on mgmt network), vlan1, for MinIO
- a MinIO VM, that is provisioned using the image + network, and is configured and set up with Ansible & Cloud-Init, to provide us a bucket, key, secretkey, region, etc. , that then in turn will be used in the RKE2 cluster reference
- a VM image for the RKE2 cluster
- a VM Network (on mgmt network), vlan1 for the RKE2 cluster
- the RKE2 machine config
- the RKE2 cluster config, that leverages S3 config to reference the MinIO instance we created

**With the setup/pre-req steps of:**
- harvester main node `/etc/rancher/rke2/rke2.yaml` with loopback/localhost address on server replaced with harvester vip needs to be the `integration-cluster-kubeconfig` file at the root of this project
- making sure to either download a "more recent" generate_addon.sh from [Harvester's cloud-provider-harvester deploy/generate_addon.sh](https://github.com/harvester/cloud-provider-harvester/blob/master/deploy/generate_addon.sh) or just trying your luck with the bundled one here
- ensuring KUBECONFIG points to wherever the Harvester cluster rke2.yaml is that's been modified for server address to point to Harvester VIP
- importing Harvester into Rancher (however rancher is setup, be that vCluster or some other VM or other endpoint/ha spot somewhere)
- updating the `variables.tf` or rolling your own `./env/local.tfvars` to utilize in something like `-var-file="local.tfvars"` from the `apply` command
- running the generate addon to fill out the cloud-provider config portion, please see: `Please Pay Attention To:` heading for more info
- ensuring you have all the dependencies needed for this portion check dependencies section
- (potentially another step? :sweat_smile_emoji: ?) - just audit everything

All just run in the flow of:
- `TF_LOG=TRACE terraform init -reconfigure -upgrade`
- `TF_LOG=TRACE TF_LOG_PROVIDER=DEBUG terraform apply -auto-approve` , (re-running to overcome bug)

Noting the bug (of running apply twice to handle the drift/change/accounting for the cred/machine_config dependency on knowing the harvester vm ipv4), you'll ultimately see the output like:

```bash
Outputs:

general_info = <<EOT
Hello!

This is the information output!

This is MinIO Output Content :) !

IP Address: 192.168.104.142
Username For VM: ubuntu
Password For VM: ubuntupw
Web Console Port: 9001
API Port: 9000
HTTPS Enabled: true
Region: sample-test-1
Disk Mount Point: /mnt/minio-data
MinIO Web User Name: minioadmin
MinIO Web Password: minioadmin
MinIO Bucket: generic-bucket
MinIO Access Key: myuserserviceaccount
MinIO Secret Key: myuserserviceaccountsecret

This is the rancher2_cluster_v2 Output Content :) !

Cluster ID: fleet-default/test-rke2-default-default
Cluster Name: test-rke2-default-default
Verson OF RKE2 Installed: v1.29.8+rke2r1
Each Node In The Cluster Username For SSH: ubuntu
Each Node In The Cluster Password For SSH: password

```


# Demo Videos Found in ./media!
- `hybrid-demo-speed-increased-by-ffmpeg.mp4` demonstrates the whole flow with the **exception to**:
  - creating an api key in rancher
    - modifying the variables.tf to account for the rancher api key & url
  - importing harvester into rancher
  - getting the `/etc/rancher/rke2/rke2.yaml` from a main harvester node and modifying the server from loopback/localhost address to the harvester-vip address
  - running the `./generate_addon.sh` script to build the rke2 cluster v2's needed machine_config.cloud-provider info that will create Cloud Output when utilizing harvester's `/etc/rancher/rke2/rke2.yaml` info (see "please pay attention to section for more detail")
- `hybrid-demo-backup.mp4` demonstrates just actually then exercising the MinIO VM we built in Harvester and linked to Rancher RKE2 as an S3-Compatible Backup solution for snapshots, showing nginx captured, it's all wired in and snapshots & audit traces come across in the demo


## Ansible Dependencies
- `ansible-galaxy collection install community.general`
- `ansible-galaxy collection install ansible.posix`
- ansible binary must be in the path!

## Other Dependencies
- sshpass installed
- of course, terraform should be installed, tested with:

## Additional Links:
- https://www.suse.com/c/rancher_blog/managing-harvester-with-terraform/

## Please Pay Attention To:

In `main.tf`:

```terraform

    # !NOTE!: VERY IMPORTANT ABOUT MACHINE_SELECTOR_CONFIG WITH HARVESTER
    # in order to get the value for "cloud-provider-config" you must do the following
    # 1. on a main node of Harvester (not worker), get `/etc/rancher/rke2/rke2.yaml` (REMEMBER TO REPLACE LOCALHOST/LOOPBACK WITH YOUR HARVESTER VIP IPV4) and stash somewhere
    # 2. take wherever you've stashed it and point your KUBECONFIG var to it like, `export KUBECONFIG=~/.kube/myharvester.yaml`
    # 3. grab the "raw" of this: https://github.com/harvester/cloud-provider-harvester/blob/master/deploy/generate_addon.sh
    # 4. once you've grabbed the raw, make it executable somewhere like `chmod +x generate_addon.sh`
    # 5. then using the KUBECONFIG execute the script with something like `./generate_addon.sh <the name of the rancher2_cluster_v2.name, whatever you're going to be naming it> <default or another namespace>`
    # 6. Then inside the `EOF` flags put the entire "cloud config" that is output, don't worry abou the cloud-init stuff
    # 7. Make sure that the rancher2_cluster_v2.name does MATCH EXACTLY to what is output from the Cloud Config Output dump's `context[0].name` very important
    # 8. Then if all that is in place you should be good to go, this is a needed effort to get Harvester Cloud Provider working correctly with RKE2 otherwise it's just going to fall flat on it's face and you'll see nothing but taints on the node in RKE2 from Harvester Cloud Provider if this is setup incorrectly
    machine_selector_config {
      config = yamlencode({
        cloud-provider-config = <<EOF
```

In `provider.tf`:

```terraform
# !NOTE!: Please use the `/etc/rancher/rke2/rke2.yaml` (REMEMBER TO REPLACE LOCALHOST/LOOPBACK WITH YOUR HARVESTER VIP IPV4) from the main Harvester node for the provider.kubeconfig for Harvester
# using the Support -> Downloaded Kubeconfig "can" cause issues
provider "harvester" {
  # Configuration options
  kubeconfig = abspath("${local.codebase_root_path}/integration-cluster-kubeconfig.yaml")
}
```

## Noticed Bug!:
- `terraform apply` needs to be run twice to overcome (tracking: [1413 on rancher/terraform-provider-rancher2](https://github.com/rancher/terraform-provider-rancher2/issues/1413) ):
```
╷
│ Error: Provider produced inconsistent final plan
│
│ When expanding the plan for rancher2_cluster_v2.rke2-terraform to include new values learned so far during apply, provider "registry.terraform.io/rancher/rancher2" produced an invalid new value for
│ .rke_config[0].etcd[0].s3_config[0].endpoint: was cty.StringVal(""), but now cty.StringVal("https://192.168.104.251:9000").
│
│ This is a bug in the provider, which should be reported in the provider's own issue tracker.
╵
```
