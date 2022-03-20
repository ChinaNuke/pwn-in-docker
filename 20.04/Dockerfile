# Usage:
#   $ sudo docker build -t ctf20-image --build-arg http_proxy=http://172.17.0.1:8080 --build-arg https_proxy=http://172.17.0.1:8080 .
#   $ sudo docker run -d --name ctf20 -v "$PWD/work":/home/ctf/work ctf20-image

FROM ubuntu:20.04
MAINTAINER ChinaNuke <chinanuke@nuke666.cn>

# Avoid user interaction with tzdata when using `apt install`
ENV DEBIAN_FRONTEND noninteractive

# Changing the apt source to speed up the download process
RUN sed -i "s/http:\/\/archive.ubuntu.com/http:\/\/mirrors.tuna.tsinghua.edu.cn/g" /etc/apt/sources.list && \
    apt update && \
    apt install -y sudo locales vim tmux git gdb wget curl python3 python3-pip \
                   zsh zsh-autosuggestions zsh-syntax-highlighting

# Set the locale, required by some programs
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8

# Add an unprivilaged user, and all subsequent operations are performed as this
# unprivileged user.
RUN useradd -m ctf -s $(which zsh) && echo "ctf:ctf" | chpasswd && \
    # Temporarily allow use of `sudo` without password
    echo "\nctf ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    # Keep proxy settings when using `sudo`
    sed -i '1s/^/Defaults env_keep="http_proxy https_proxy no_proxy"\n/' /etc/sudoers && \
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
COPY files/ /home/ctf

# Install pwntools
RUN pip3 install --upgrade pwntools

# Install pwndbg
RUN git clone --depth=1 https://github.com/pwndbg/pwndbg.git && \
    cd pwndbg && ./setup.sh

# Install binwalk
RUN git clone --depth=1 https://github.com/devttys0/binwalk.git && \
    cd binwalk && \
    sed -i '/REQUIRED_UTILS="wget tar python"/c\REQUIRED_UTILS="wget tar python3"' deps.sh && \
    sudo ./deps.sh --yes && sudo python3 ./setup.py install

# Clear the cache and restore using `sudo` with password
RUN sudo apt clean && sudo apt autoremove && \
    sudo sed -i "s/ctf ALL=(ALL) NOPASSWD:ALL/ctf ALL=(ALL) ALL/g" /etc/sudoers

CMD ["tmux"]