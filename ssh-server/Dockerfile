FROM debian:12

RUN apt-get update && \
    apt-get install -y openssh-server python3 sudo && \
    mkdir -p /run/sshd && chmod 0755 /run/sshd && \
    useradd -u 1002 -m -s /bin/bash ansible-user && \
    ssh-keygen -A

COPY sshd_config /etc/ssh/sshd_config
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh && \
    chmod 440 /etc/ssh/sshd_config

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D", "-e"]