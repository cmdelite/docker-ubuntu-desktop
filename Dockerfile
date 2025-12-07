FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    USE_CCACHE=1 \
    CCACHE_DIR=/ccache \
    CCACHE_EXEC=/usr/bin/ccache \
    AOSP_HOME=/aosp \
    JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Install all components and dependencies in one layer for optimization
RUN apt update -y && apt install --no-install-recommends -y \
    # Desktop components (original: XFCE, VNC, noVNC, Firefox)
    xfce4 xfce4-goodies tigervnc-standalone-server novnc websockify \
    sudo xterm systemd vim net-tools curl wget git tzdata \
    dbus-x11 x11-utils x11-xserver-utils x11-apps \
    firefox xubuntu-icon-theme \
    python3-minimal ca-certificates \
    # AOSP/LineageOS build dependencies (consolidated and optimized)
    git-core gnupg flex bison build-essential zip zlib1g-dev \
    gcc-multilib g++-multilib libc6-dev-i386 libncurses5 lib32ncurses5-dev \
    x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils \
    xsltproc unzip fontconfig rsync ccache python3-pip openjdk-11-jdk \
    git-lfs gperf imagemagick protobuf-compiler libsdl1.2-dev libssl-dev \
    lz4 lzop squashfs-tools bc libdw-dev libelf-dev pngcrush schedtool \
    liblz4-tool m4 maven byobu lib32stdc++6 android-tools-adb android-tools-fastboot \
    # SSH server integration
    openssh-server \
    && update-alternatives --install /usr/bin/java java $JAVA_HOME/bin/java 1 \
    && update-alternatives --install /usr/bin/javac javac $JAVA_HOME/bin/javac 1 \
    && rm -rf /var/lib/apt/lists/*

# Configure SSH: Enable root login, set a default root password (change in production!)
RUN mkdir /var/run/sshd && \
    echo 'root:change_me' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Create Xauthority for VNC (original)
RUN touch /root/.Xauthority

# Install and fix systemctl replacement (original with Python3 fix)
RUN curl -fsSL https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl.py \
    -o /usr/local/bin/systemctl \
    && sed -i '1s|.*|#!/usr/bin/python3|' /usr/local/bin/systemctl \
    && chmod +x /usr/local/bin/systemctl \
    && mkdir -p /run/systemd/system

# Setup repo tool, ccache, and symlinks (optimized from sources)
RUN mkdir -p ~/bin && \
    curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo && \
    chmod a+x ~/bin/repo && \
    echo 'export PATH=~/bin:$PATH' >> ~/.bashrc && \
    mkdir -p $CCACHE_DIR && \
    ccache -M 150G && \
    mkdir -p /usr/local/bin && \
    for compiler in cc gcc c++ g++; do ln -vsf /usr/bin/ccache /usr/local/bin/$compiler; done

# Create AOSP/Lineage workspace and non-root users for builds
RUN mkdir -p $AOSP_HOME && \
    useradd -m -s /bin/bash aosp && \
    chown -R aosp:aosp $AOSP_HOME $CCACHE_DIR && \
    echo "aosp ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    useradd -m -s /bin/bash elite && \
    echo "elite ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "elite:change_me" | chpasswd  # Set default password for elite (change in production!)

# Setup for elite user in noVNC: Copy Xauthority and set permissions
RUN mkdir -p /home/elite/.vnc && \
    cp /root/.Xauthority /home/elite/ && \
    chown -R elite:elite /home/elite

# Expose ports for VNC/noVNC (original) and SSH
EXPOSE 5901 6080 22

# Start SSH, VNC/noVNC as elite, and keep alive (original CMD with SSH integration)
CMD bash -c "\
    /usr/sbin/sshd -D & \
    su - elite -c 'vncserver -localhost no -SecurityTypes None -geometry 1280x720 --I-KNOW-THIS-IS-INSECURE' && \
    openssl req -new -subj \"/C=JP\" -x509 -days 365 -nodes -out /self.pem -keyout /self.pem && \
    websockify -D --web=/usr/share/novnc/ --cert=/self.pem 6080 localhost:5901 && \
    tail -f /dev/null"
