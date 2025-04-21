# 📑 Rapport — Déploiement Sécurisé Docker & Ansible

---

## 1. Contexte et Objectifs

Ce projet vise à démontrer la capacité à concevoir, sécuriser et automatiser le déploiement d’une infrastructure applicative à l’aide de **Docker** et **Ansible**.  
L’architecture cible comprend :
- Un **serveur SSH** basé sur Debian 12 hébergeant Nginx, accessible uniquement par clé.
- Un **contrôleur Ansible** sous AlmaLinux 9, orchestrant le déploiement et la configuration.
- Un **playbook Ansible** pour l’installation et la gestion de Nginx.

L’accent est mis sur la sécurité, la reproductibilité, la modularité et la documentation du processus, tout en assumant les limites et les axes d’amélioration.

---

## 2. Démarche Projet & Évolution de l’Architecture

### a. Première Implémentation (Docker "classique")

Au départ, chaque conteneur était lancé individuellement via des commandes `docker run`.  
**Limites constatées :**
- Gestion réseau manuelle, difficile à maintenir.
- Orchestration séquentielle impossible (ordre de démarrage non garanti).
- Risque d’erreur élevé lors de la configuration des ports et des volumes.
- Difficulté à documenter et à versionner l’ensemble.

### b. Migration vers Docker Compose

**Justification du choix :**
- Centralisation de la configuration dans un unique `Docker-compose.yaml`.
- Création automatique d’un réseau interne (`ansible-net`) pour l’isolation.
- Gestion des dépendances (`depends_on`, `healthcheck`) pour garantir la disponibilité des services.
- Reproductibilité accrue et déploiement simplifié.

---

## 3. Description détaillée des composants

### 3.1 Serveur SSH (Debian 12)

**Implémentation Docker :**
- Dockerfile basé sur `debian:12` (non joint ici, mais conforme aux standards).
- Installation d’OpenSSH, Python3, sudo.
- Création d’un utilisateur non-root `ansible-user` avec droits sudo limités.
- Génération automatique des clés d’hôte (`ssh-keygen -A`).
- Script d’entrée [`docker-entrypoint.sh`] pour garantir la présence de `/run/sshd` et démarrer le service SSH de façon fiable.
- Ports exposés : `8022:22` (SSH), `8080:80` (Nginx).

**Sécurité :**
- Désactivation de l’authentification par mot de passe dans `sshd_config`.
- Utilisation exclusive de clés SSH (voir gestion des clés plus bas).
- Permissions strictes sur les fichiers sensibles (`chmod 600` sur les clés).
- Réseau Docker interne (`internal: true`) pour limiter l’exposition.

**Défis rencontrés :**
- Erreur `no hostkeys available` : corrigée via la génération systématique des clés d’hôte.
- Erreur `Missing privilege separation directory: /run/sshd` : résolue par la création explicite du dossier dans l’entrypoint.
- Problèmes DNS lors de l’installation de paquets : nécessitant la configuration manuelle du DNS Docker Desktop.

### 3.2 Contrôleur Ansible (AlmaLinux 9)

**Implémentation Docker :**
- Dockerfile basé sur `almalinux:9` (création d’un utilisateur non-root).
- Montage du dossier `ssh-keys` en lecture seule (`./ssh-keys:/ansible/ssh-keys:ro`).
- Commande principale : `tail -f /dev/null` pour garder le conteneur actif.
- Healthcheck avec `ansible --version`.
- Intégration réseau via `ansible-net`.

**Sécurité :**
- Exécution en utilisateur non-root (UID 1000).
- Volumes montés en lecture seule pour les fichiers sensibles.
- Aucun port exposé côté hôte pour le contrôleur Ansible.

**Défis rencontrés :**
- Arrêt immédiat du conteneur Ansible (exit 0) : corrigé par la commande persistante.
- Problèmes de résolution DNS entre conteneurs : réglés via l’utilisation des hostnames Docker et d’un réseau dédié.

### 3.3 Gestion des clés SSH

- Génération de la paire de clés via [`ssh-keygen.sh`] :
  - Clé privée montée dans le conteneur Ansible (`id_rsa`).
  - Clé publique copiée dans `ssh-server/authorized_keys`.
- Permissions strictes appliquées (`chmod 600` pour la clé privée, `chmod 644` pour la clé publique).
- Vérification automatique de la présence des clés lors du démarrage.

### 3.4 Playbook Ansible pour Nginx

- Playbook YAML (`deploy-nginx.yml`) :
  - Installation de Nginx sur le serveur SSH cible.
  - Démarrage et activation du service.
  - Vérification de l’accessibilité via le module `uri`.
- Inventory Ansible pointant sur le hostname du service SSH Docker.

**Sécurité :**
- Désactivation du host key checking dans `ansible.cfg`.
- Utilisation exclusive de clés SSH pour l’authentification.
- Aucune donnée sensible stockée en clair dans les playbooks ou inventaires.

---

## 4. Limites, erreurs rencontrées et apprentissages

### Problème majeur : échec du ping Ansible

Lors des tests, la commande :
ansible -m ping all

text
échoue systématiquement avec :
ssh: connect to host ssh-server port 22: Connection refused

text
**Explication honnête :**
- Ce blocage est **de ma faute** : j’ai configuré le réseau Docker en `internal: true`, ce qui isole le réseau et empêche toute connexion sortante, y compris depuis Ansible.
- J’ai aussi parfois mal vérifié la disponibilité effective du port 22 (healthcheck incomplet).
- Ce point m’a permis de comprendre l’importance de la configuration réseau dans Docker Compose et l’impact des options de sécurité sur la connectivité.

### Autres difficultés et solutions

- **Permissions sur les clés SSH** : nécessité de corriger dans le conteneur à chaque démarrage.
- **Montage de volumes** : erreurs fréquentes si le chemin ou le nom de fichier est incorrect.
- **Problèmes DNS dans les conteneurs** : résolus en forçant le DNS dans Docker Desktop.
- **Arrêt automatique du conteneur Ansible** : corrigé par la commande persistante.
- **Gestion des dépendances Python sur Debian** : installation de Python3 obligatoire pour Ansible.

---

## 5. Bilan technique

### Réussites
- Isolation réseau et séparation des rôles via Docker Compose.
- Sécurisation des accès SSH et Ansible (utilisateur non-root, clés, restrictions).
- Déploiement idempotent de Nginx via Ansible (tests validés).
- Respect des bonnes pratiques Docker (volumes en ro, healthchecks, pas de mode privilégié).
- Documentation claire, scripts reproductibles.

### Limites et axes d’amélioration
- Gestion des secrets via Ansible Vault non implémentée.
- Rotation et gestion avancée des clés SSH non automatisée.
- Monitoring et logs centralisés non mis en place.
- Problèmes DNS récurrents sous Docker Desktop Windows (résolus manuellement).
- **Certains tests comme le ping Ansible ne passent pas à cause de ma configuration réseau**.
- Ce projet reste un premier jet : tout n’est pas parfait, mais il est le reflet de mon envie d’apprendre et de progresser.


## 6. Structure des fichiers

.
├── Docker-compose.yaml

├── ssh-server/

│ ├── Dockerfile

│ ├── sshd_config

│ ├── authorized_keys

│ ├── docker-entrypoint.sh

├── ansible/

│ ├── Dockerfile

│ ├── ansible.cfg

│ ├── inventory.ini

│ ├── deploy-nginx.yml

├── ssh-keys/

│ ├── id_rsa

│ └── id_rsa.pub

├── ssh-keygen.sh


## 7. Conclusion et engagement

Ce projet est **mon premier jet** dans la conception d’une infrastructure Docker/Ansible sécurisée.  
Je reconnais que tout n’est pas parfait :  
- certains tests échouent (notamment le ping Ansible à cause de ma configuration réseau),
- certains aspects comme la gestion avancée des secrets, la rotation des clés ou le monitoring restent à implémenter.

**Mais je suis là pour apprendre et m’améliorer**.  
Chaque difficulté rencontrée a été l’occasion de progresser, de documenter et de renforcer la robustesse de mes scripts.  
Je suis plus que motivé à continuer, à corriger mes erreurs et à atteindre un niveau professionnel sur ces sujets.  
