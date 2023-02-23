# Usage:
#   $ sudo docker build -t ctf22-image --build-arg http_proxy=http://172.17.0.1:8080 --build-arg https_proxy=http://172.17.0.1:8080 .
#   $ sudo docker run --cap-add=SYS_PTRACE --security-opt seccomp=unconfined -it --name ctf22 --hostname ctf -v "$PWD/work":/home/ctf/work ctf22-image
#   $ sudo docker start -ai ctf22
# 
# Note:
#   - Add `--cap-add=SYS_PTRACE --security-opt seccomp=unconfined` for gdb to 
#     debug running process.

FROM ubuntu:22.04
MAINTAINER ChinaNuke <chinanuke@nuke666.cn>

# Changing the apt source to speed up the download process
RUN sed -i -E "s/http:\/\/(archive|security).ubuntu.com/http:\/\/mirrors.tuna.tsinghua.edu.cn/g" /etc/apt/sources.list && \
    apt update && \
    # Avoid user interaction
    export DEBIAN_FRONTEND=noninteractive && \
    # Unminimize the ubuntu installation
    yes | unminimize && \
    apt install -y sudo man-db locales \
                   # for `file` command
                   file \
                   # for `ping`, `ip` and `nc` command
                   iputils-ping iproute2 netcat \
                   # for `killall` and `strace` command
                   psmisc strace \
                   vim tmux git gdb gdb-multiarch wget curl python3 python3-pip \
                   zsh zsh-autosuggestions zsh-syntax-highlighting \
                   # required if you want to compile or run 32-bit programs
                   gcc-multilib g++-multilib \
                   # for debug symbols
                   libc6-dbg && \
    rm -rf /var/lib/apt/lists/*

# Set the locale, which is required by some programs
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8

# Set timezone to display the right time.
ENV TZ Asia/Shanghai

# Add an unprivilaged user, and all subsequent operations are performed as this
# unprivileged user.
RUN useradd -m ctf -s $(which zsh) && echo "ctf:ctf" | chpasswd && \
    # Temporarily allow use of `sudo` without password
    sed -i "/^root/a ctf\tALL=(ALL) NOPASSWD:ALL" /etc/sudoers && \
    # Keep proxy settings when using `sudo`
    sed -i '/^Defaults.*env_reset/i Defaults\tenv_keep="http_proxy https_proxy no_proxy"' /etc/sudoers && \
    # Create the directory for mapping
    mkdir /home/ctf/work && chown ctf:ctf /home/ctf/work
WORKDIR /home/ctf
USER ctf

# Install zsh theme and plugins
RUN mkdir ~/.zsh-theme-and-plugins && \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.zsh-theme-and-plugins/powerlevel10k && \
    git clone --depth=1 https://github.com/zsh-users/zsh-history-substring-search.git ~/.zsh-theme-and-plugins/zsh-history-substring-search

# Set pypi mirror
RUN sudo pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple --upgrade pip && \
    pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple && \
    sudo pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# Copy all config files to home directory
COPY --chown=ctf files/ /home/ctf

# Do not generate gdb_history file
RUN echo 'set history save off' >> ~/.gdbinit

# ----------------------------------------------------------
# In the following part we will install commonly used tools,
# feel free to comment out any of the tools you don't need.
# ----------------------------------------------------------

# Install ipython
RUN pip3 install --no-cache-dir --no-warn-script-location ipython

# Install pwntools
RUN pip3 install --no-cache-dir --no-warn-script-location --upgrade pwntools

# Install pwndbg
RUN git clone --depth=1 https://github.com/pwndbg/pwndbg.git ~/.pwndbg && \
    cd ~/.pwndbg && ./setup.sh --user && \
    # Disable pwndbg by default
    sed -i "/pwndbg\/gdbinit.py/s/^/# /" ~/.gdbinit

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
RUN wget -O ~/.gdbinit-gef.py -q https://gef.blah.cat/dev && \
    # Optional dependencies
    pip3 install --no-cache-dir --no-warn-script-location capstone unicorn keystone-engine ropper && \
    echo 'source ~/.gdbinit-gef.py' >> ~/.gdbinit && \
    # Optional gef-extras
    git clone --depth=1 --branch dev https://github.com/hugsy/gef-extras.git ~/.config/gef-extras && \
    gdb -q -ex "gef config gef.extra_plugins_dir '~/.config/gef-extras/scripts'" \
        -ex "gef config pcustom.struct_path '~/.config/gef-extras/structs'" \
        -ex "gef config syscall-args.path '~/.config/gef-extras/syscall-tables'" \
        -ex "gef config context.libc_args True" \
        -ex "gef config context.libc_args_path '~/.config/gef-extras/glibc-function-args'" \
        -ex 'gef save' \
        -ex quit

# Install patchelf from source
RUN sudo apt install -y autoconf && \
    git clone --depth=1 https://github.com/NixOS/patchelf.git && \
    cd patchelf && \
    ./bootstrap.sh && ./configure && \
    make -j `nproc` && \
    sudo make install && \
    cd .. && rm -rf patchelf

# Install one_gadget and seccomp-tools
RUN sudo apt install -y ruby-full && \
    sudo gem sources --add https://mirrors.tuna.tsinghua.edu.cn/rubygems/ --remove https://rubygems.org/ && \
    # FIXME: it's not secure to install with `sudo`
    sudo gem install one_gadget seccomp-tools

# Install binwalk
RUN git clone --depth=1 https://github.com/devttys0/binwalk.git ~/.binwalk && \
    cd ~/.binwalk && \
    # Fix the python not found error.
    sed -i '/REQUIRED_UTILS="wget tar python"/cREQUIRED_UTILS="wget tar python3"' deps.sh && \
    # Fix the "'if' clause does not guard" error.
    # https://github.com/devttys0/sasquatch/pull/47
    # https://github.com/ffontaine/binwalk/commit/ba8f5e3eaf3d701be8b2d9a49fd0b616d63c5f85
    sed -i 's?(cd sasquatch \&\& \$SUDO ./build.sh)?(cd sasquatch \&\& wget https://github.com/devttys0/sasquatch/pull/47.patch -O - | patch -p1 \&\& \$SUDO ./build.sh)?' deps.sh && \
    ./deps.sh --yes && \
    sudo python3 ./setup.py install && \
    cd .. && sudo rm -rf .binwalk

# Clear the cache and we do not need `NOPASSWD` anymore
RUN sudo apt clean && sudo apt autoremove && \
    sudo sed -i "/^ctf/s/NOPASSWD://" /etc/sudoers

CMD ["tmux"]