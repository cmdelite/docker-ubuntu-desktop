FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update -y && apt install --no-install-recommends -y xfce4 xfce4-goodies tigervnc-standalone-server novnc websockify sudo xterm init systemd snapd vim net-tools curl wget git tzdata dbus-x11 x11-utils x11-xserver-utils x11-apps software-properties-common python2
RUN add-apt-repository ppa:mozillateam/ppa -y
RUN echo 'Package: *' >> /etc/apt/preferences.d/mozilla-firefox
RUN echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox
RUN echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox
RUN echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:jammy";' | tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox
RUN apt update -y && apt install -y firefox
RUN apt update -y && apt install -y xubuntu-icon-theme
RUN touch /root/.Xauthority

# Install systemctl replacement for service management
RUN curl -o /usr/bin/systemctl https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl.py && \
    chmod +x /usr/bin/systemctl && \
    mkdir -p /run/systemd/system/ && \
    service dbus stop || true  # Stop dbus if running, ignore if not

# Create and enable a service to run the original VNC/noVNC startup
RUN echo '[Unit]\nDescription=Start VNC and noVNC\n\n[Service]\nExecStart=/bin/bash -c "vncserver -localhost no -SecurityTypes None -geometry 1024x768 --I-KNOW-THIS-IS-INSECURE && openssl req -new -subj \"/C=JP\" -x509 -days 365 -nodes -out self.pem -keyout self.pem && websockify -D --web=/usr/share/novnc/ --cert=self.pem 6080 localhost:5901 && tail -f /dev/null"\nRestart=always\n\n[Install]\nWantedBy=multi-user.target' > /etc/systemd/system/vnc-novnc.service && \
    /usr/bin/systemctl enable vnc-novnc.service

EXPOSE 5901
EXPOSE 6080
CMD ["/usr/bin/systemctl"]
