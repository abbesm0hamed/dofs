FROM fedora:latest

# Install base dependencies needed for bootstrap
RUN dnf install -y \
    sudo \
    git \
    util-linux \
    passwd \
    findutils \
    which \
    ansible \
    chezmoi \
    && dnf clean all

ARG UID=1000
ARG GID=1000

# Create test user (matching host UID/GID for bind-mount write access)
RUN (getent group "$GID" >/dev/null || groupadd -g "$GID" dofs) \
    && useradd -m -u "$UID" -g "$GID" -G wheel dofs \
    && echo "dofs:dofs" | chpasswd \
    && echo "dofs ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/dofs \
    && chmod 0440 /etc/sudoers.d/dofs

USER dofs
WORKDIR /home/dofs/dofs

# Set some basic environment variables
ENV USER=dofs
ENV HOME=/home/dofs
ENV SHELL=/bin/bash

# Default command is just to check if repo is mounted
CMD ["bash"]
