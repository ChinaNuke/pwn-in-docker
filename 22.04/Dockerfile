# Usage:
# 
#   $ sudo docker build -t pwn-image .
#
#   To use proxy, add these arguments:
#     --build-arg http_proxy=http://172.17.0.1:7891 --build-arg https_proxy=http://172.17.0.1:7891
#
#   $ sudo docker run --privileged --security-opt seccomp=unconfined \
#       --network host \
#       -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK \
#       -v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK \
#       -v /home/$USER/MyWorkspace:/home/nuke/work \
#       -v /home/$USER/mytmp:/home/nuke/mytmp \
#       -v /home/$USER/Projects:/home/nuke/projects \
#       --name pwn22 \
#       --hostname docker --add-host docker:127.0.0.1 \
#       -it pwn-image
# 
#   $ sudo docker start -ai pwn22
# 
# Note:
#   - Add `--cap-add=SYS_PTRACE --security-opt seccomp=unconfined` for gdb to 
#     debug running process.
#   - `-e SSH_AUTH_SOCK=$SSH_AUTH_SOCK -v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK` for 
#     ssh forwarding.
#   - `--network host` to share the host's network.
#   - `--cap-add=SYS_ADMIN --cap-add=MKNOD` and `--device=/dev/nbd0` for qemu-nbd.

FROM ubuntu:22.04
MAINTAINER ChinaNuke <chinanuke@nuke666.cn>

ENV LANG=en_US.UTF-8 \
    TZ=Asia/Shanghai

# Install necessary packages
# (build time: about 4min)
# Change the apt source to speed up the download process
RUN sed -i -E "s/http:\/\/(archive|security).ubuntu.com/http:\/\/mirrors.tuna.tsinghua.edu.cn/g" /etc/apt/sources.list && \
    apt-get update && \
    # Unminimize the ubuntu installation
    yes | unminimize && \
    # Install some basic tools
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        # for missing commands
        sudo man-db locales file iputils-ping iproute2 netcat \
        # for `killall` and `strace` command
        psmisc strace ltrace \
        # useful tools
        vim tmux git gdb gdb-multiarch wget curl python3 python3-pip \
        ranger ripgrep fd-find htop nmap dnsutils \
        # required if you want to compile or run 32-bit programs
        gcc-multilib g++-multilib \
        # glibc debugging symbols
        libc6-dbg \
        # OpenSSL (required for compiling python from source)
        libssl-dev && \
    # Clean up apt cache
    rm -rf /var/lib/apt/lists/*

# Tools to analyse non-x86 binaries
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        qemu-user-static binutils-mips-linux-gnu binutils-arm-linux-gnueabi && \
    rm -rf /var/lib/apt/lists/*

# Install fish shell
RUN apt-get update && \ 
    DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common && \
    apt-add-repository ppa:fish-shell/release-3 && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y fish && \
    rm -rf /var/lib/apt/lists/*

# Create a symlink `fd` to `fdfind`
RUN ln -s $(which fdfind) /usr/local/bin/fd

# Basic settings
RUN \
    # Set the locale
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen && \
    # Add an unpriviladged user.
    useradd -m nuke -s $(which fish) && echo "nuke:nuke" | chpasswd && \
    echo "nuke ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/nuke && \
    sed -i '/^Defaults.*env_reset/i Defaults\tenv_keep="http_proxy https_proxy no_proxy"' /etc/sudoers
    # mkdir /home/nuke/work && chown nuke:nuke /home/nuke/work 

# Copy all config files to home directory
COPY --chown=nuke files/ /home/nuke

RUN echo '127.0.0.1 docker' >> /etc/hosts

# Make all following operations as unprivileged user
USER nuke
WORKDIR /home/nuke

RUN \
    # Set pypi mirror
    sudo pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple --upgrade pip && \
    pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple && \
    sudo pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple && \
    # Install ipython
    pip3 install --no-cache-dir --no-warn-script-location ipython && \
    # Install pyenv
    curl https://pyenv.run | bash && \
    # Do not generate gdb_history file
    echo 'set history save off' >> ~/.gdbinit

# ----------------------------------------------------------
# In the following part we will install commonly used tools,
# feel free to comment out any of the tools you don't need.
# ----------------------------------------------------------

# Install pwntools
RUN pip3 install --no-cache-dir --no-warn-script-location --upgrade pwntools

# Install pwninit
RUN wget https://github.com/io12/pwninit/releases/download/3.3.0/pwninit -O ~/.local/bin/pwninit && \
    chmod +x ~/.local/bin/pwninit

# Install pwndbg
RUN git clone --depth=1 https://github.com/pwndbg/pwndbg.git ~/.pwndbg && \
    cd ~/.pwndbg && ./setup.sh && \
    sudo rm -rf /var/lib/apt/lists/*

# Install GEP (GDB Enhanced Prompt)
# 有 bug，远程调试时不能 attach 到子进程。
# RUN git clone --depth 1 https://github.com/lebr0nli/GEP.git ~/.local/share/GEP && \
#     ~/.local/share/GEP/install.sh

# Install unblob
RUN pip3 install --no-cache-dir --no-warn-script-location unblob && \
    # install the extractors
    sudo apt-get update && \
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y android-sdk-libsparse-utils e2fsprogs p7zip-full unar zlib1g-dev liblzo2-dev lzop lziprecover libhyperscan-dev zstd lz4 && \
    # squashfs support (binwalk v3 will install this)
    # curl -L -o /tmp/sasquatch_1.0.deb "https://github.com/onekey-sec/sasquatch/releases/download/sasquatch-v4.5.1-4/sasquatch_1.0_$(dpkg --print-architecture).deb" && \
    # sudo dpkg -i /tmp/sasquatch_1.0.deb || sudo apt-get -f install -y && \
    # rm /tmp/sasquatch_1.0.deb && \
    # clean up
    sudo rm -rf /var/lib/apt/lists/*

# Install gef (stable version)
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

# Install gef (dev version)
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

# Install patchelf from source
RUN sudo apt-get update && \
    sudo apt-get install -y autoconf && \
    git clone --depth=1 https://github.com/NixOS/patchelf.git && \
    cd patchelf && \
    ./bootstrap.sh && ./configure && \
    make -j `nproc` && \
    sudo make install && \
    cd .. && rm -rf patchelf && \
    sudo rm -rf /var/lib/apt/lists/*

# Install one_gadget and seccomp-tools
RUN sudo apt-get update && \
    sudo apt-get install -y --no-install-recommends ruby-full && \
    sudo gem sources --add https://mirrors.tuna.tsinghua.edu.cn/rubygems/ --remove https://rubygems.org/ && \
    # FIXME: it's not secure to install with `sudo`
    sudo gem install one_gadget seccomp-tools && \
    sudo rm -rf /var/lib/apt/lists/*

# Binwalk maintained by community
# RUN git clone --depth=1 https://github.com/OSPG/binwalk.git ~/.binwalk && \
#     cd ~/.binwalk && \
#     sed -i '/REQUIRED_UTILS="wget tar python"/cREQUIRED_UTILS="wget tar python3"' deps.sh && \
#     ./deps.sh --yes && \
#     sudo python3 ./setup.py install && \
#     cd .. && sudo rm -rf .binwalk

# Binwalk v3
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    . "$HOME/.cargo/env" && \
    git clone --depth=1 https://github.com/ReFirmLabs/binwalk.git /tmp/binwalk && \
    cd /tmp/binwalk && \
    sudo apt-get update && \
    # required by ubuntu.sh
    sudo apt-get install -y unzip libbz2-dev && \
    # fix permissions
    sed -i 's/apt-get/sudo apt-get/g' dependencies/ubuntu.sh && \
    sed -i 's/dpkg/sudo dpkg/g' dependencies/ubuntu.sh && \
    sed -i 's/cp/sudo cp/g' dependencies/src.sh && \
    sed -i 's/make install/sudo make install/g' dependencies/src.sh && \
    ./dependencies/ubuntu.sh && \
    cargo build --release && \
    cp target/release/binwalk ~/.local/bin/binwalk && \
    cd .. && rm -rf /tmp/binwalk && \
    sudo rm -rf /var/lib/apt/lists/*

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

# Install semgrep
RUN pip3 install semgrep

# Clear the cache and we do not need `NOPASSWD` anymore
RUN sudo apt-get clean && sudo apt-get autoremove -y && \
    sudo rm -rf /var/lib/apt/lists/* && \
    sudo sed -i "/^nuke/s/NOPASSWD://" /etc/sudoers.d/nuke

CMD ["tmux"]
