FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    USE_CCACHE=1 \
    CCACHE_DIR=/ccache \
    CCACHE_EXEC=/usr/bin/ccache \
    AOSP_HOME=/aosp \
    JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Install everything in one layer
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-goodies tigervnc-standalone-server novnc websockify \
    sudo xterm vim net-tools curl wget git tzdata \
    dbus-x11 x11-utils x11-xserver-utils x11-apps \
    firefox xubuntu-icon-theme \
    python3-minimal ca-certificates \
    git-core gnupg flex bison build-essential zip zlib1g-dev \
    gcc-multilib g++-multilib libc6-dev-i386 libncurses5 lib32ncurses5-dev \
    x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils \
    xsltproc unzip fontconfig rsync ccache python3-pip openjdk-11-jdk \
    git-lfs gperf imagemagick protobuf-compiler libsdl1.2-dev libssl-dev \
    lz4 lzop squashfs-tools bc libdw-dev libelf-dev pngcrush schedtool \
    liblz4-tool m4 maven lib32stdc++6 android-tools-adb android-tools-fastboot \
    openssh-server \
    && rm -rf /var/lib/apt/lists/*

# SSH configuration (fixed syntax!)
RUN mkdir -p /var/run/sshd && \
    echo 'root:admin123' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

# Create elite user + sudo without password
RUN useradd -m -s /bin/bash elite && \
    echo 'elite:elite123' | chpasswd && \
    echo 'elite ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Fix systemctl replacement for Python 3
RUN curl -fsSL https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl.py \
    -o /usr/local/bin/systemctl && \
    sed -i '1s|.*|#!/usr/bin/python3|' /usr/local/bin/systemctl && \
    chmod +x /usr/local/bin/systemctl

# Repo tool + 150 GB ccache
RUN mkdir -p /root/bin && \
    curl https://storage.googleapis.com/git-repo-downloads/repo > /root/bin/repo && \
    chmod a+x /root/bin/repo && \
    mkdir -p /ccache && ccache -M 150G

# AOSP workspace owned by elite
RUN mkdir -p /aosp && chown elite:elite /aosp /ccache

# Expose everything you need
EXPOSE 22 5901 6080

# Final startup – everything starts reliably
CMD /usr/sbin/sshd && \
    su - elite -c "vncserver -geometry 1280x720 -depth 24 -SecurityTypes None :1" && \
    openssl req -new -x509 -days 365 -nodes -subj "/C=US/ST=Cloud/L=Railway/O=Elite/CN=localhost" \
        -keyout /self.pem -out /self.pem >/dev/null 2>&1 && \
    websockify --web=/usr/share/novnc/ --cert=/self.pem 6080 localhost:5901 && \
    tail -f /dev/null
