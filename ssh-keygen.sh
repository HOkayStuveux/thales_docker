#!/bin/bash
ssh-keygen -t ed25519 -a 100 -f ssh-keys/ansible-key -N "" -C "ansible-$(date +%Y-%m)"
cp ssh-keys/ansible-key.pub ssh-server/authorized_keys