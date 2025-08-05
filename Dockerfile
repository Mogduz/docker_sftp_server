FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Grundinstallation
RUN apt-get update && \
    apt-get install -y openssh-server passwd && \
    mkdir /var/run/sshd

# SFTP-Gruppe anlegen
RUN groupadd sftpusers

# SSHD-Konfiguration: internal-sftp mit Chroot für Gruppe sftpusers
RUN sed -i '/^Subsystem sftp/ s@.*@Subsystem sftp internal-sftp@' /etc/ssh/sshd_config

RUN cat <<'EOF' >> /etc/ssh/sshd_config

Match Group sftpusers
    ChrootDirectory /srv/cloud
    ForceCommand internal-sftp
    X11Forwarding no
    AllowTcpForwarding no
    PermitTunnel no
    PasswordAuthentication yes
EOF

# Verzeichnis für Chroot vorbereiten
RUN mkdir -p /srv/cloud && chown root:root /srv/cloud && chmod 755 /srv/cloud

# Minimal: keine Passwortabfrage beim Start
RUN echo "PermitRootLogin no" >> /etc/ssh/sshd_config

# Entrypoint-Script kopieren
COPY ./src/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/usr/sbin/sshd","-D"]