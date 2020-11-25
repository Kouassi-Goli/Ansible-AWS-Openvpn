echo "=== KEY GENERATION ==="
if [ ! -f ./aws_vpn_key ]
then
    ssh-keygen -b 4096 -f ./aws_vpn_key -C "AWS VPN" -q -N ""
fi

echo "=== TERRAFORM ==="

terraform init
terraform apply -auto-approve

# Wait for elastic ip allocation
sleep 20

echo "=== ANSIBLE ==="
ansible-playbook -i hosts openvpn.yml
