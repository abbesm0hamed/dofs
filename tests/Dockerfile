FROM fedora:latest

# Install base dependencies needed for bootstrap
RUN dnf install -y \
    sudo \
    git \
    util-linux \
    passwd \
    findutils \
    which \
    && dnf clean all

# Create test user (matching user environment but non-root)
RUN useradd -m -G wheel abbes \
    && echo "abbes:abbes" | chpasswd \
    && echo "abbes ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/abbes

USER abbes
WORKDIR /home/abbes/dofs

# Set some basic environment variables
ENV USER=abbes
ENV HOME=/home/abbes
ENV SHELL=/bin/bash

# Default command is just to check if repo is mounted
CMD ["bash"]
