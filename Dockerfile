FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install everything the original image needs
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-goodies tigervnc-standalone-server novnc websockify \
    sudo xterm init systemd snapd vim net-tools curl wget git tzdata \
    dbus-x11 x11-utils x11-xserver-utils x11-apps \
    software-properties-common \
    && apt install -y firefox xubuntu-icon-theme \
    && rm -rf /var/lib/apt/lists/*

# Firefox PPA (kept from your original file)
RUN add-apt-repository ppa:mozillateam/ppa -y && \
    echo 'Package: *' > /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:jammy";' \
        > /etc/apt/apt.conf.d/51unattended-upgrades-firefox

RUN touch /root/.Xauthority

# ──────────────────────
# Install systemctl replacement (this is the important part)
# ──────────────────────
RUN curl -fsSL https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl.py \
        -o /usr/local/bin/systemctl && \
    chmod +x /usr/local/bin/systemctl && \
    mkdir -p /run/systemd/system && \
    # Stop real dbus if it tries to start (prevents conflicts)
    systemctl mask dbus.service dbus.socket 2>/dev/null || true

EXPOSE 5901 6080

# Keep the exact same startup command you had before
# → this is what starts VNC + noVNC web interface and keeps the container alive
CMD bash -c "\
    vncserver -localhost no -SecurityTypes None -geometry 1024x768 --I-KNOW-THIS-IS-INSECURE && \
    openssl req -new -subj \"/C=JP\" -x509 -days 365 -nodes -out /self.pem -keyout /self.pem && \
    websockify -D --web=/usr/share/novnc/ --cert=/self.pem 6080 localhost:5901 && \
    tail -f /dev/null"
