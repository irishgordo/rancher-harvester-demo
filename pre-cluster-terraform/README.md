## General
Since Harvester currently doesn't provide any Software Defined Networking we really are dependent on a deep understanding of what is available for the bare-metal machines at the switch/router level.
This just serves as a small concept-example of how one might "prior" to setting up Harvester with an iPXE install create via IaC (Infrastructure as Code) some VLANS if the user had a UniFi / Ubiquiti system -> note that no concrete examples could be provided due to Version 8 Controller support in limbo.

But this can just be extended in thought to other ecosystems where PFSense, Juniper, Cisco, etc. based networking infrastructure may provide some sort of Terraform hooks.
Building out the network & assigning static addresses is critical for solid Harvester deployments -> and Harvester IS not meant to be virtualized -> virtualizing Harvester creates several un-intended side-effects generally and is definitely not recommended or supported...it's usually a "not so great" time when really trying to work with the product.


### Concept Within

- Concept based IaaC approach

Currently waiting on Version 8 Controller Support github.com/paultyng/terraform-provider-unifi

# Pre Cluster Creation Concepts

## Getting Close To The Bare-Metal

The age old question of:
> How does one deploy Harvester?

There are some different approaches:
- manual via usb / iodd st400 (tool), interactive iso installation
- pxe based:
  - via [harvester/seeder](https://github.com/harvester/seeder)
  - something like [netbootxyz](https://technotim.live/posts/netbootxyz-tutorial/):
    - you can additionally check out my [netboot.xyz-custom ipxe menu I built for a fileserver based install of harvester interactively](https://github.com/irishgordo/netboot.xyz-custom/tree/master)
    - `netboot.xyz` out of the box does like the Harvester project and has provided some layer of support for it: https://github.com/netbootxyz/netboot.xyz/blob/development/roles/netbootxyz/templates/menu/harvester.ipxe.j2

- additionally, if someone is leveraging a metal-as-a-service provider like Equinix there is some phenomenal tooling available to help provision & work with that cloud provider:
  - https://github.com/rancherlabs/terraform-harvester-equinix

## Pre-Deploy Considerations
- since Harvester currently doesn't have SDN a deep understanding of your underlying networks is critical and in fact potentially one of the most important things about running anything on Harvester:
  - additionally you may want to create a static address for the Harvester nodes, new VLANs, etc -> some of which might be accomplished through Terraform depending on the underling network infrastructure, just a few like (many more also exist depending):
    - [Terraform Provider Unifi](https://github.com/paultyng/terraform-provider-unifi)
    - [Terraform Provider Cisco Systems](https://registry.terraform.io/namespaces/terraform-cisco-modules)
    - [Terraform Provider (MicroTik's) RouterOS](https://github.com/terraform-routeros/terraform-provider-routeros)
  - The networking aspect does change in contrast to if someone is leveraging "on prem"/"MSP" kinda approach VS "I'm going to use a bare-metal cloud provider (Equinix for instance)"
- additionally collecting information about all nodes in the cluster, gaining access to mac addresses thru iLO/iDRAC (some sort of mgmt-interface on the node) or just directly thru the node's BIOS etc, pre-deploy
- also important to consider is whether or not the desire is to have Harvester + Rancher entirely airgapped, important considerations need to be made on the fronts of:
  - whatever iPXE provisioning exists should be airgapped, eg: as an example earlier, and in the media of harvester-creation, there is the pxe provisioning through netbootxyz, the netbootxyz is running on a separate thinkcentre mini-pc/node, it is rigged into the unifi/ubiquiti networks but the vlan the Nodes use by default for their management iLO are airgapped -> additionally a separate vlan was built that is airgapped, that can be flipped on either programatically or manually to target certain ports on the switch, once we know that the chatter between the HP/Dell machine booting is airgapped from itself to the file-server hosting the ipxe-custom then that path is safe-guarded
  - additionally for all things Rancher, sometimes an "easy-ish" approach would be to have two vlans (one airgap, one not airgap), both created with terraform on Harvester, the VM that is going to be running any flavor of K8s distros (K3s, RKE2, etc.) will just be "originally" provisioned on the "non-airgap" vlan, but then once provisioning is finished, the terraform can be modified to have that VM be on the "airgap vlan" -> important things to note is that it may be easier to configure k3s for instance like the `registries.yaml` and making sure `resolv.conf` stuff is set to a "private dns-server", post cutover to the airgap network
  - an NTP server is absolutely also needed, so anything that can be provisioned non-airgap, then cutover to airgap
  - the dns-server, could be a variety, for simplicity, a solid tool might be to stick with the "time-old-tradition" of leveraging a *.sslip.io , stylized a-record, but the beauty, just never ever ever having to edit `/etc/hosts`, running https://github.com/cunnie/sslip.io , as something like a docker-compose piece can be phenomenal, and again, just ensuring that it is indeed setup as a VM (non-airgap), then cutover to (airgap) vm network
  - one of the most important tools is Rancher Federal's Hauler: https://rancherfederal.github.io/hauler-docs/docs/airgap-workflow :
    - it has single-handedly been able to reduce headaches by the sheer amount of customization, which can with some solid Ansible be setup to dynamically generate image templates so that spec.images [n] could then just reference what is needed, as well as metadata.annotations.hauler.dev/registry & metadata.annoatations.hauler.dev/platform can be utilized to reference only what arch is needed and the registry additionally something like a `systemd` based service can be set up to serve the registry once network cutover on the VM (ex: just utterly replacing the VM network):
```bash
[Unit]
Description=Hauler Serve Registry Service

[Service]
Environment="HOME=/home/ubuntu/"
ExecStart=/usr/local/bin/hauler store serve registry --config /home/ubuntu/hauler_config.yaml
WorkingDirectory=/home/ubuntu

[Install]
WantedBy=multi-user.target

### With the config looking like
version: 0.1
http:
  addr: {{ hauler_server_ip }}:5000
  tls:
    certificate: /home/ubuntu/public.crt
    key: /home/ubuntu/private.key
storage:
  filesystem:
    rootdirectory: /home/ubuntu/registry
    maxthreads: 100
```
  - Once all "airgap-integrations" (provisioned potentially in "mostly-parralel") are created with non-airgapped networking, then cutover to airgap networking -> then the Harvester cluster can be provisioned and at it's inception, have in it's configuration all the needed information to connect out to those services ex: S3-API for backup-target, DNS private server, NTP servers, etc.


# Important!
- Terraform provider for Harvester "should" **soon** support the ability to bootstrap things, thus eliminating the need to "have to acquire the kubeconfig from Harvester", github.com/harvester/harvester/issues/1797
  - allowing for more "fluid" automation w/ Harvester