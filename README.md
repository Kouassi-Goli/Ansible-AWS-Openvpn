# AWS VPN
Create a secure self-hosted OpenVPN server on AWS with Terraform and Ansible using
OpenVPN roadwarrior script from [openvpn-install](https://github.com/angristan/openvpn-install)

## Prerequisite

* Terraform and Ansible installed on host machine.
* AWS credentials in `~/.aws/credentials`

## Start 

Generate SSH key, create Ubuntu 20.04 (64-bit x86) EC2 virtual machine, install OpenVPN, create a user and dowload .ovpn profile in local directory.

`./run_all.sh`
