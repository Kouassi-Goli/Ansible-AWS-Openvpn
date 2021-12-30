#!/bin/bash
export TF_VAR_ip_address=$(curl --no-progress-meter -4 ifconfig.co)/32
terraform destroy -auto-approve