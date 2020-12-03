#!/bin/sh

SSH_KEY=$HOME/.ssh/id_unifi

# make sure we have a key
[ -f $SSH_KEY ] || ssh-keygen -t rsa -f $SSH_KEY -C 'unifi' -N ''
[ -L `basename $SSH_KEY.pub` ] || ln -s $SSH_KEY.pub

# create AWS resources
[ -d .terraform ] || terraform init
terraform apply
UNIFI_HOST=`terraform output public_dns`

ANSIBLE_HOSTS='ansible-hosts.ini'
cat << EOF > $ANSIBLE_HOSTS
$UNIFI_HOST ansible_connection=ssh ansible_user=ubuntu ansible_ssh_private_key_file=$SSH_KEY
EOF
ansible-playbook install-unifi.yml -i $ANSIBLE_HOSTS
