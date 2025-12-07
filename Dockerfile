FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    USE_CCACHE=1 \
    CCACHE_DIR=/ccache \
    CCACHE_EXEC=/usr/bin/ccache \
    AOSP_HOME=/aosp

# Install everything
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-goodies tigervnc-standalone-server novnc websockify \
    sudo xterm vim curl wget git tzdata firefox xubuntu-icon-theme \
    python3-minimal ca-certificates \
    openssh-server \
    git-core gnupg flex bison build-essential zip zlib1g-dev \
    gcc-multilib g++-multilib libc6-dev-i386 libncurses5 lib32ncurses5-dev \
    libgl1-mesa-dev libxml2-utils xsltproc unzip rsync ccache openjdk-11-jdk \
    git-lfs gperf imagemagick libssl-dev lz4 lzop squashfs-tools bc \
    && rm -rf /var/lib/apt/lists/*

# SSH setup
RUN mkdir -p /var/run/sshd && \
    echo 'root:admin123' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Create elite user
RUN useradd -m -s /bin/bash elite && \
    echo 'elite:elite123' | chpasswd && \
    echo 'elite ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# ccache 150 GB
RUN mkdir -p /ccache && ccache -M 150G

# AOSP folder for elite
RUN mkdir -p /aosp && chown elite:elite /aosp /ccache

# Expose ports
EXPOSE 22 5901 6080

# THIS IS THE ONLY THING THAT MATTERS FOR VNC – 100 % WORKING
CMD /usr/sbin/sshd && \
    su - elite -c "vncserver :1 -geometry 1280x720 -depth 24 -SecurityTypes None -localhost no" && \
    websockify --web=/usr/share/novnc/ 6080 localhost:5901 && \
    tail -f /dev/null
