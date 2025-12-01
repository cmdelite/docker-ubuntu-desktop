FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-goodies tigervnc-standalone-server novnc websockify \
    sudo xterm systemd vim net-tools curl wget git tzdata \
    dbus-x11 x11-utils x11-xserver-utils x11-apps \
    python3-minimal ca-certificates \
    firefox xubuntu-icon-theme \
    && rm -rf /var/lib/apt/lists/*

RUN touch /root/.Xauthority

# Install systemctl replacement + fix the shebang to python3 (this is the fix!)
RUN curl -fsSL https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl.py \
    -o /usr/local/bin/systemctl \
    && sed -i '1s|.*|#!/usr/bin/python3|' /usr/local/bin/systemctl \
    && chmod +x /usr/local/bin/systemctl \
    && mkdir -p /run/systemd/system

EXPOSE 5901 6080

CMD bash -c "\
    vncserver -localhost no -SecurityTypes None -geometry 1024x768 --I-KNOW-THIS-IS-INSECURE && \
    openssl req -new -subj \"/C=JP\" -x509 -days 365 -nodes -out /self.pem -keyout /self.pem && \
    websockify -D --web=/usr/share/novnc/ --cert=/self.pem 6080 localhost:5901 && \
    tail -f /dev/null"
