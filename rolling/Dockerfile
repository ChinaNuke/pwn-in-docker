# Usage:
#   $ sudo docker build -t ctf-image --build-arg http_proxy=http://172.17.0.1:8080 --build-arg https_proxy=http://172.17.0.1:8080 .
#   $ sudo docker run -it --name ctf --hostname ctf -v "$PWD/work":/home/ctf/work ctf-image
#   $ sudo docker start -ai ctf

FROM ubuntu:rolling
MAINTAINER ChinaNuke <chinanuke@nuke666.cn>

# Changing the apt source to speed up the download process
RUN sed -i -E "s/http:\/\/(archive|security).ubuntu.com/http:\/\/mirrors.tuna.tsinghua.edu.cn/g" /etc/apt/sources.list && \
    apt update && \
    # Avoid user interaction
    export DEBIAN_FRONTEND=noninteractive && \
    # Unminimize the ubuntu installation
    yes | unminimize && \
    apt install -y sudo man-db locales \
                   file iputils-ping \
                   vim tmux git gdb wget curl python3 python3-pip \
                   zsh zsh-autosuggestions zsh-syntax-highlighting \
                   # required if you want to compile or run 32-bit programs
                   gcc-multilib g++-multilib

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
RUN pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple && \
    sudo pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# Copy all config files to home directory
COPY --chown=ctf files/ /home/ctf

# Install ipython
RUN pip3 install --no-cache-dir ipython

# Install pwntools
RUN pip3 install --no-cache-dir --upgrade pwntools==4.8.0b0

# Install pwndbg
# RUN git clone --depth=1 https://github.com/pwndbg/pwndbg.git ~/.pwndbg && \
#     cd ~/.pwndbg && ./setup.sh

# Install gef
RUN wget -O ~/.gdbinit-gef.py -q https://gef.blah.cat/py && \
    # Optional dependencies
    pip3 install --no-cache-dir capstone unicorn keystone-engine ropper && \
    echo source ~/.gdbinit-gef.py >> ~/.gdbinit

# Install patchelf from source
RUN sudo apt install -y autoconf && \
    git clone --depth=1 https://github.com/NixOS/patchelf.git && \
    cd patchelf && \
    ./bootstrap.sh && ./configure && \
    make -j `nproc` && make check && \
    sudo make install && \
    cd .. && rm -rf patchelf

# Install one_gadget and seccomp-tools
RUN sudo apt install -y ruby-full && \
    sudo gem install one_gadget seccomp-tools

# Install binwalk
# FIXME: Cannot compile on 21.10 due to ‘if’ clause does not guard
# RUN git clone --depth=1 https://github.com/devttys0/binwalk.git ~/.binwalk && \
#     cd ~/.binwalk && \
#     sed -i '/REQUIRED_UTILS="wget tar python"/c\REQUIRED_UTILS="wget tar python3"' deps.sh && \
#     sudo ./deps.sh --yes && \
#     sudo python3 ./setup.py install

# Clear the cache and we do not need `NOPASSWD` anymore
RUN sudo apt clean && sudo apt autoremove && \
    sudo sed -i "/^ctf/s/NOPASSWD://" /etc/sudoers

CMD ["tmux"]