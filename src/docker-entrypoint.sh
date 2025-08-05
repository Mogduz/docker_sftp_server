#!/bin/bash
set -e

# Erwartet: SFTP_USERS in Form: user1:password1 user2:password2 oder user:keyfile_path
# Beispiel: SFTP_USERS="alice:secret bob:secret2"
# Optional: SSH_KEY_dir unter /keys

# Benutzer anlegen
if [ -n "$SFTP_USERS" ]; then
  for entry in $SFTP_USERS; do
    IFS=':' read -r user secret <<< "$entry"

    # Benutzer ohne Shell
    useradd -m -g sftpusers -d "/$user" -s /usr/sbin/nologin "$user" || true

    # Passwort setzen (falls nicht als Key-only)
    if [ -n "$secret" ]; then
      echo "$user:$secret" | chpasswd
    fi

    # Persönliches Verzeichnis unter Chroot
    mkdir -p /srv/cloud/"$user"
    chown "$user":sftpusers /srv/cloud/"$user"
    chmod 700 /srv/cloud/"$user"

    # SSH-Key-Handling: wenn im Mounted /keys/<user>.pub vorhanden
    if [ -f "/keys/${user}.pub" ]; then
      mkdir -p /srv/cloud/"$user"/.ssh
      chown root:root /srv/cloud/"$user"/.ssh
      chmod 700 /srv/cloud/"$user"/.ssh
      cat "/keys/${user}.pub" > /srv/cloud/"$user"/.ssh/authorized_keys
      chown "$user":sftpusers /srv/cloud/"$user"/.ssh/authorized_keys
      chmod 600 /srv/cloud/"$user"/.ssh/authorized_keys
    fi
  done
fi

# Sicherstellen, dass Chroot-Root korrekt ist
chown root:root /srv/cloud
chmod 755 /srv/cloud

# Starte SSHD (über CMD)
exec "$@"
