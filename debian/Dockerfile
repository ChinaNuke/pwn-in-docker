# Usage:
#
#   $ podman build -t pwn-image .
#
#   To use proxy, add these arguments:
#     --build-arg http_proxy=http://host.containers.internal:7891 \
#     --build-arg https_proxy=http://host.containers.internal:7891
#
#   $ podman run \
#       --privileged --security-opt seccomp=unconfined \
#       --network host \
#       -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK \
#       -v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK \
#       -v /home/$USER/MyWorkspace:/root/work \
#       -v /home/$USER/mytmp:/root/mytmp \
#       -v /home/$USER/Projects:/root/projects \
#       --name pwn-bookworm \
#       --hostname pwn --add-host pwn:127.0.0.1 \
#       -it pwn-image
#
#   $ podman start -ai pwn-bookworm
#
# Note:
#   - Add `--cap-add=SYS_PTRACE --security-opt seccomp=unconfined` for gdb to
#     debug running process.
#   - `-e SSH_AUTH_SOCK=$SSH_AUTH_SOCK -v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK` for
#     ssh forwarding.
#   - `--network host` to share the host's network.
#   - `--cap-add=SYS_ADMIN --cap-add=MKNOD` and `--device=/dev/nbd0` for qemu-nbd.
#   - In rootless podman, container root maps to host user, so files created
#     as root inside will be owned by your user on the host.

# ----------------------------------------------------------
# Metadata
# ----------------------------------------------------------
FROM debian:bookworm
LABEL maintainer="ChinaNuke <chinanuke@nuke666.cn>"

# ----------------------------------------------------------
# Environment setup
# ----------------------------------------------------------
ENV LANG=en_US.UTF-8 \
    TZ=Asia/Shanghai

# ----------------------------------------------------------
# Change the apt source to speed up the download process
# ----------------------------------------------------------
RUN sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list.d/debian.sources

# ----------------------------------------------------------
# Install necessary packages (with cache mount for faster rebuilds)
# ----------------------------------------------------------
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && \
    # Install some basic tools
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        # for missing commands
        sudo man-db locales file iputils-ping iproute2 netcat-openbsd \
        # for `killall` and `strace` command
        psmisc strace ltrace \
        # useful tools
        neovim tmux git gdb gdb-multiarch wget curl python3 python3-pip \
        ranger ripgrep fd-find htop nmap dnsutils \
        # required if you want to compile or run 32-bit programs
        gcc-multilib g++-multilib \
        # glibc debugging symbols
        libc6-dbg \
        # OpenSSL (required for compiling python from source)
        libssl-dev

# ----------------------------------------------------------
# Tools to analyse non-x86 binaries
# ----------------------------------------------------------
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        qemu-user-static binutils-mips-linux-gnu binutils-arm-linux-gnueabi

# ----------------------------------------------------------
# Install fish shell from openSUSE Build Service
# ----------------------------------------------------------
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y curl gnupg && \
    echo 'deb http://download.opensuse.org/repositories/shells:/fish/Debian_12/ /' \
        > /etc/apt/sources.list.d/shells:fish.list && \
    curl -fsSL https://download.opensuse.org/repositories/shells:fish/Debian_12/Release.key \
        | gpg --dearmor > /etc/apt/trusted.gpg.d/shells_fish.gpg && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y fish

# ----------------------------------------------------------
# Basic settings
# ----------------------------------------------------------
RUN \
    # Set the locale
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen && \
    # Set root's shell to fish
    chsh -s $(which fish) && \
    # Create a symlink for fd-find
    ln -s $(which fdfind) /usr/local/bin/fd && \
    # Hostname setup
    echo '127.0.0.1 pwn' >> /etc/hosts

# ----------------------------------------------------------
# Make all following operations as root
# ----------------------------------------------------------
USER root
WORKDIR /root

# ----------------------------------------------------------
# Set up uv and pip mirror
# ----------------------------------------------------------
ENV UV_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple \
    PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple

# ----------------------------------------------------------
# Python environment setup
# ----------------------------------------------------------
RUN \
    # Install uv (fast Python package manager)
    curl -LsSf https://astral.sh/uv/install.sh | sh && \
    ~/.local/bin/uv venv ~/.venv && \
    # Install ipython as a tool
    ~/.local/bin/uv tool install --no-cache ipython

# ----------------------------------------------------------
# Rust environment setup
# ----------------------------------------------------------
RUN \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# ----------------------------------------------------------
# In the following part we will install commonly used tools,
# feel free to comment out any of the tools you don't need.
# ----------------------------------------------------------

# ------------------------------------------
# Pwntools
# ------------------------------------------
RUN ~/.local/bin/uv pip install --no-cache pwntools -p ~/.venv/bin/python

# ------------------------------------------
# semgrep (CLI tool)
# ------------------------------------------
RUN ~/.local/bin/uv tool install --no-cache semgrep

# ------------------------------------------
# unblob
# ------------------------------------------
RUN ~/.local/bin/uv tool install --no-cache unblob
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        android-sdk-libsparse-utils e2fsprogs p7zip-full unar \
        zlib1g-dev liblzo2-dev lzop lziprecover libhyperscan-dev zstd lz4

# ------------------------------------------
# pwninit
# ------------------------------------------
RUN wget https://github.com/io12/pwninit/releases/download/3.3.0/pwninit -O ~/.local/bin/pwninit && \
    chmod +x ~/.local/bin/pwninit

# ------------------------------------------
# pwndbg
# ------------------------------------------
RUN git clone --depth=1 https://github.com/pwndbg/pwndbg.git ~/.pwndbg && \
    cd ~/.pwndbg && ./setup.sh

# ------------------------------------------
# GEP (GDB Enhanced Prompt)
# 有 bug，远程调试时不能 attach 到子进程。
# ------------------------------------------
# RUN git clone --depth 1 https://github.com/lebr0nli/GEP.git ~/.local/share/GEP && \
#     ~/.local/share/GEP/install.sh

# ------------------------------------------
# gef (stable version)
# ------------------------------------------
# RUN wget -O ~/.gdbinit-gef.py -q https://gef.blah.cat/py && \
#     echo source ~/.gdbinit-gef.py >> ~/.gdbinit && \
#     # Optional gef-extras
#     git clone --depth=1 --branch main https://github.com/hugsy/gef-extras.git ~/.config/gef-extras && \
#     pip3 install --no-cache-dir -r ~/.config/gef-extras/requirements.txt && \
#     gdb -q -ex "gef config gef.extra_plugins_dir '~/.config/gef-extras/scripts'" \
#         -ex "gef config pcustom.struct_path '~/.config/gef-extras/structs'" \
#         -ex "gef config syscall-args.path '~/.config/gef-extras/syscall-tables'" \
#         -ex "gef config context.libc_args True" \
#         -ex "gef config context.libc_args_path '~/.config/gef-extras/glibc-function-args'" \
#         -ex 'gef save' \
#         -ex quit

# ------------------------------------------
# gef (dev version)
# ------------------------------------------
# RUN wget -O ~/.gdbinit-gef.py -q https://gef.blah.cat/dev && \
#     # Optional dependencies
#     pip3 install --no-cache-dir --no-warn-script-location capstone unicorn keystone-engine ropper && \
#     echo 'source ~/.gdbinit-gef.py' >> ~/.gdbinit && \
#     # Optional gef-extras
#     git clone --depth=1 --branch dev https://github.com/hugsy/gef-extras.git ~/.config/gef-extras && \
#     gdb -q -ex "gef config gef.extra_plugins_dir '~/.config/gef-extras/scripts'" \
#         -ex "gef config pcustom.struct_path '~/.config/gef-extras/structs'" \
#         -ex "gef config syscall-args.path '~/.config/gef-extras/syscall-tables'" \
#         -ex "gef config context.libc_args True" \
#         -ex "gef config context.libc_args_path '~/.config/gef-extras/glibc-function-args'" \
#         -ex 'gef save' \
#         -ex quit

# ------------------------------------------
# patchelf
# ------------------------------------------
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && \
    apt-get install -y autoconf && \
    git clone --depth=1 https://github.com/NixOS/patchelf.git && \
    cd patchelf && \
    ./bootstrap.sh && ./configure && \
    make -j `nproc` && \
    make install && \
    cd .. && rm -rf patchelf

# ------------------------------------------
# one_gadget and seccomp-tools
# ------------------------------------------
# RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
#     --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
#     sudo apt-get update && \
#     sudo apt-get install -y --no-install-recommends ruby-full && \
#     sudo gem sources --add https://mirrors.tuna.tsinghua.edu.cn/rubygems/ --remove https://rubygems.org/ && \
#     # FIXME: it's not secure to install with `sudo`
#     sudo gem install one_gadget seccomp-tools

# ------------------------------------------
# Binwalk maintained by community
# ------------------------------------------
# RUN git clone --depth=1 https://github.com/OSPG/binwalk.git ~/.binwalk && \
#     cd ~/.binwalk && \
#     sed -i '/REQUIRED_UTILS="wget tar python"/cREQUIRED_UTILS="wget tar python3"' deps.sh && \
#     ./deps.sh --yes && \
#     sudo python3 ./setup.py install && \
#     cd .. && sudo rm -rf .binwalk

# ------------------------------------------
# Binwalk v3
# ------------------------------------------

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    git clone --depth=1 https://github.com/ReFirmLabs/binwalk.git /tmp/binwalk && \
    cd /tmp/binwalk && \
    apt-get update && \
    # Build dependencies for cargo
    apt-get install -y unzip libbz2-dev pkg-config && \
    # Patch ubuntu.sh for Debian compatibility
    sed -i 's/unrar/unrar-free/g' dependencies/ubuntu.sh && \
    sed -i 's/7zip-standalone/p7zip-full/g' dependencies/ubuntu.sh && \
    ./dependencies/ubuntu.sh && \
    rm -rf /tmp/binwalk

RUN . "$HOME/.cargo/env" && cargo install binwalk

# Install wabt
# RUN sudo apt-get update && sudo apt-get install -y cmake && \
#     git clone --recursive https://github.com/WebAssembly/wabt ~/.wabt && \
#     cd ~/.wabt && git submodule update --init && \
#     mkdir build && cd build && \
#     cmake .. && cmake --build . && sudo cmake --install . && \
#     cd .. && rm -rf .wabt

# Install pycdc (python bytecode disassembler)
# RUN git clone --depth=1 https://github.com/zrax/pycdc.git && cd pycdc && \
#     mkdir build && cd build && cmake .. && \
#     make && make check && sudo make install && \
#     cd ../.. && rm -rf pycdc


# ------------------------------------------
# radare2
# ------------------------------------------
# RUN git clone --depth=1 https://github.com/radareorg/radare2 && \
    # radare2/sys/install.sh

# ------------------------------------------
# Copy config files to home directory
# ------------------------------------------
COPY files/home_config /root
COPY files/config /root/.config

CMD ["tmux"]
