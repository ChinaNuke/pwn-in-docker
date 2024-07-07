# Usage:
#   $ sudo docker build -t pwn-image --build-arg http_proxy=http://172.17.0.1:7891 --build-arg https_proxy=http://172.17.0.1:7891 .
#
#   # SSH forwarding, and share the host's network.
#   $ sudo docker run --cap-add=SYS_PTRACE --security-opt seccomp=unconfined --network host -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK -v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK -it --name pwn22 -v $HOME/MyWorkspace:/home/nuke/work pwn-image
#   $ sudo docker start -ai pwn22
# 
# Note:
#   - Add `--cap-add=SYS_PTRACE --security-opt seccomp=unconfined` for gdb to 
#     debug running process.
#   - `-e SSH_AUTH_SOCK=$SSH_AUTH_SOCK -v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK` for 
#     ssh forwarding.
#   - `--network host` to share the host's network.

FROM ubuntu:22.04
MAINTAINER ChinaNuke <chinanuke@nuke666.cn>

ENV LANG=en_US.UTF-8 \
    TZ=Asia/Shanghai

# Install necessary packages
# Change the apt source to speed up the download process
# (time: about 4min)
RUN sed -i -E "s/http:\/\/(archive|security).ubuntu.com/http:\/\/mirrors.tuna.tsinghua.edu.cn/g" /etc/apt/sources.list && \
    apt-get update && \
    # Unminimize the ubuntu installation
    yes | unminimize && \
    # Install some basic tools
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        # for missing commands
        sudo man-db locales file iputils-ping iproute2 netcat \
        # for `killall` and `strace` command
        psmisc strace \
        # useful tools
        vim tmux git gdb gdb-multiarch wget curl python3 python3-pip \
        zsh zsh-autosuggestions zsh-syntax-highlighting \
        ranger ripgrep \
        # required if you want to compile or run 32-bit programs
        gcc-multilib g++-multilib \
        # glibc debugging symbols
        libc6-dbg \
        # OpenSSL (required for compiling python from source)
        libssl-dev && \
    # Clean up apt cache
    rm -rf /var/lib/apt/lists/*

# Basic settings
RUN \
    # Set the locale
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen && \
    # Add an unpriviladged user.
    useradd -m nuke -s $(which zsh) && echo "nuke:nuke" | chpasswd && \
    echo "nuke ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/nuke && \
    sed -i '/^Defaults.*env_reset/i Defaults\tenv_keep="http_proxy https_proxy no_proxy"' /etc/sudoers
    # mkdir /home/nuke/work && chown nuke:nuke /home/nuke/work 

# Copy all config files to home directory
COPY --chown=nuke files/ /home/nuke

USER nuke
WORKDIR /home/nuke

RUN \
    # Install zsh theme and plugins
    mkdir ~/.zsh-theme-and-plugins && \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.zsh-theme-and-plugins/powerlevel10k && \
    git clone --depth=1 https://github.com/zsh-users/zsh-history-substring-search.git ~/.zsh-theme-and-plugins/zsh-history-substring-search && \
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

# Install unblob
RUN pip3 install --no-cache-dir --no-warn-script-location unblob && \
    # install the extractors
    sudo apt-get update && \
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y android-sdk-libsparse-utils e2fsprogs p7zip-full unar zlib1g-dev liblzo2-dev lzop lziprecover libhyperscan-dev zstd lz4 && \
    # squashfs support
    curl -L -o /tmp/sasquatch_1.0.deb "https://github.com/onekey-sec/sasquatch/releases/download/sasquatch-v4.5.1-4/sasquatch_1.0_$(dpkg --print-architecture).deb" && \
    sudo dpkg -i /tmp/sasquatch_1.0.deb || sudo apt-get -f install -y && \
    rm /tmp/sasquatch_1.0.deb && \
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

# Install binwalk
# NOTE: binwalk is now deprecated. Use `unblob` instead.
# RUN git clone --depth=1 https://github.com/devttys0/binwalk.git ~/.binwalk && \
#     cd ~/.binwalk && \
#     # Fix the python not found error.
#     sed -i '/REQUIRED_UTILS="wget tar python"/cREQUIRED_UTILS="wget tar python3"' deps.sh && \
#     # Fix the "'if' clause does not guard" error.
#     # https://github.com/devttys0/sasquatch/pull/47
#     # https://github.com/ffontaine/binwalk/commit/ba8f5e3eaf3d701be8b2d9a49fd0b616d63c5f85
#     sed -i 's?(cd sasquatch \&\& \$SUDO ./build.sh)?(cd sasquatch \&\& wget https://github.com/devttys0/sasquatch/pull/47.patch -O - | patch -p1 \&\& \$SUDO ./build.sh)?' deps.sh && \
#     ./deps.sh --yes && \
#     sudo python3 ./setup.py install && \
#     cd .. && sudo rm -rf .binwalk

# Install wabt
# Install semgrep
RUN pip3 install semgrep

# Clear the cache and we do not need `NOPASSWD` anymore
RUN sudo apt-get clean && sudo apt-get autoremove -y && \
    sudo rm -rf /var/lib/apt/lists/* && \
    sudo sed -i "/^nuke/s/NOPASSWD://" /etc/sudoers.d/nuke

CMD ["tmux"]
