#!/bin/sh
set -e

# Créer le dossier manquant
mkdir -p /run/sshd
chmod 0755 /run/sshd

# Démarrer SSH
exec /usr/sbin/sshd -D