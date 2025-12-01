FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install all required packages + python3 (needed for systemctl.py)
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-goodies tigervnc-standalone-server novnc websockify \
    sudo xterm systemd vim net-tools curl wget git tzdata \
    dbus-x11 x11-utils x11-xserver-utils x11-apps \
    python3-minimal ca-certificates \
    firefox xubuntu-icon-theme \
    && rm -rf /var/lib/apt/lists/*

# Create Xauthority
RUN touch /root/.Xauthority

# Install the docker-systemctl-replacement script (safe location)
RUN curl -fsSL https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl.py \
    -o /usr/local/bin/systemctl \
    && chmod +x /usr/local/bin/systemctl \
    && mkdir -p /run/systemd/system

# Expose ports for VNC and noVNC
EXPOSE 5901 6080

# This command starts the desktop and keeps the container alive
CMD bash -c "\
    vncserver -localhost no -SecurityTypes None -geometry 1024x768 --I-KNOW-THIS-IS-INSECURE && \
    openssl req -new -subj \"/C=JP\" -x509 -days 365 -nodes -out /self.pem -keyout /self.pem && \
    websockify -D --web=/usr/share/novnc/ --cert=/self.pem 6080 localhost:5901 && \
    tail -f /dev/null"
