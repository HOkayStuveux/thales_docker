FROM almalinux:9

RUN dnf install -y python3 python3-pip openssh-clients && \
    pip3 install ansible && \
    useradd -u 1001 -m -s /bin/bash ansible-runner && \
    ssh-keygen -A

COPY roles/ /ansible/roles/
COPY playbooks/ /ansible/playbooks/

USER ansible-runner
WORKDIR /ansible