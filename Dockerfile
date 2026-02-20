# Dockerfile.jenkins
FROM jenkins/jenkins:lts

USER root

# Podman 및 필요 패키지 설치
RUN apt-get update && \
    apt-get install -y \
        podman \
        uidmap \
        slirp4netns \
        fuse-overlayfs \
        iptables && \
    rm -rf /var/lib/apt/lists/* && \
    echo 'jenkins:100000:65536' > /etc/subuid && \
    echo 'jenkins:100000:65536' > /etc/subgid

# rootless podman 설정
RUN mkdir -p /var/lib/jenkins/.config/containers && \
    echo '[storage]\ndriver = "vfs"' > /var/lib/jenkins/.config/containers/storage.conf && \
    chown -R jenkins:jenkins /var/lib/jenkins/.config

USER jenkins