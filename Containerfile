# This is mostly based on the official kas image except based upon Ubuntu 22.04
# https://github.com/siemens/kas/blob/master/Dockerfile

FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.utf8

RUN apt-get update && \
    apt-get install -y locales && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
    apt-get install --no-install-recommends -y \
        python3-pip python3-setuptools python3-wheel python3-yaml python3-distro python3-jsonschema \
        python3-dev python3-newt python3-colorlog python3-kconfiglib python3-websockets \
        gosu lsb-release file vim less procps tree tar bzip2 zstd pigz lz4 unzip tmux libncurses-dev \
        git-lfs mercurial iproute2 ssh-client telnet curl rsync gnupg awscli sudo \
        socat python3-git python3-gnupg python3-cairo gawk wget git diffstat unzip texinfo \
        gcc build-essential chrpath cpio python3-pexpect libelf-dev \
        xz-utils debianutils iputils-ping python3-jinja2 libegl1-mesa libsdl1.2-dev \
        pylint xterm python3-subunit mesa-common-dev liblz4-tool && \
    rm -rf /var/log/* /tmp/* /var/tmp/* /var/cache/ldconfig/aux-cache /var/cache/apt && \
    rm -f /etc/gitconfig && \
    git config --system filter.lfs.clean 'git-lfs clean -- %f' && \
    git config --system filter.lfs.smudge 'git-lfs smudge -- %f' && \
    git config --system filter.lfs.process 'git-lfs filter-process' && \
    git config --system filter.lfs.required true

# FIXME: bash-complete
RUN cd /tmp && \
    pip3 install --no-build-isolation kas && \
    rm -rf $(pip3 cache dir) && \
    git clone --depth=1 https://github.com/siemens/kas.git && \
    install -m 0755 ./kas/contrib/oe-git-proxy /usr/bin/ && \
    install -m 0755 ./kas/container-entrypoint /usr/bin/ && \
    rm -rf kas

ENV GIT_PROXY_COMMAND="oe-git-proxy" \
    NO_PROXY="*"

RUN echo "builder ALL=NOPASSWD: ALL" > /etc/sudoers.d/builder-nopasswd && \
    chmod 660 /etc/sudoers.d/builder-nopasswd && \
    echo "Defaults env_keep += \"ftp_proxy http_proxy https_proxy no_proxy\"" > /etc/sudoers.d/env_keep && chmod 660 /etc/sudoers.d/env_keep && \
    groupadd builder -g 30000 && \
    useradd builder -u 30000 -g 30000 --create-home --home-dir /builder

USER builder
ENTRYPOINT [ "container-entrypoint" ]
