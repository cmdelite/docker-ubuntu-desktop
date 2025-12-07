FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    USE_CCACHE=1 \
    CCACHE_DIR=/ccache \
    AOSP_HOME=/aosp

# Install only what we really need
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-goodies tigervnc-standalone-server sudo xterm vim curl wget git \
    firefox openssh-server python3-minimal ca-certificates ccache openjdk-11-jdk \
    build-essential zip rsync bc bison flex lib32z1-dev lib32ncurses5-dev \
    gcc-multilib g++-multilib libssl-dev git-lfs \
    && rm -rf /var/lib/apt/lists/*

# SSH + elite user
RUN echo 'root:admin123' | chpasswd
RUN useradd -m -s /bin/bash elite && \
    echo 'elite:elite123' | chpasswd && \
    echo 'elite ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# ccache 150 GB + AOSP folder
RUN ccache -M 150G && mkdir -p /aosp && chown elite:elite /aosp /ccache

# Allow insecure VNC (this is the fix for the "REFUSING" error)
RUN mkdir -p /home/elite/.vnc && \
    echo "I-KNOW-THIS-IS-INSECURE" > /home/elite/.vnc/allow_insecure

# Expose only what you need
EXPOSE 22 5901

# Start SSH + VNC as elite on display :1 (port 5901) — NO websockify, NO 6080
CMD /usr/sbin/sshd && \
    su - elite -c "vncserver :1 -geometry 1280x720 -depth 24 --I-KNOW-THIS-IS-INSECURE" && \
    tail -f /dev/null
