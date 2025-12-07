FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    USE_CCACHE=1 CCACHE_DIR=/ccache AOSP_HOME=/aosp

# Everything you need + SSH
RUN apt update -y && apt install --no-install-recommends -y \
    sudo vim curl wget git ccache openjdk-11-jdk build-essential \
    zip rsync bc bison flex lib32z1-dev lib32ncurses5-dev gcc-multilib \
    libssl-dev git-lfs openssh-server \
    && rm -rf /var/lib/apt/lists/*

# Fix SSH privilege separation directory (this was the last error)
RUN mkdir -p /run/sshd

# Create elite user with sudo and known password
RUN useradd -m -s /bin/bash elite && \
    echo 'elite:elite123' | chpasswd && \
    echo 'elite ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# ccache 150 GB + AOSP folder
RUN ccache -M 150G && mkdir -p /aosp && chown elite:elite /aosp /ccache

# Expose only SSH
EXPOSE 22

# Start SSH forever
CMD ["/usr/sbin/sshd", "-D"]
