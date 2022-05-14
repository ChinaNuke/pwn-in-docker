# pwn-in-docker

Dockerfiles to build ctf pwn environments. The dockerfiles are wrote for personal use, but you can use them as you like.

## Usage

You can pull the latest version of the image from aliyun: 

```shell
docker pull registry.cn-beijing.aliyuncs.com/chinanuke/pwn-in-docker:latest
```

Or you can build the docker image with a simple command.:

```shell
docker build -t ctf-image .
```

If you need a proxy to speed up the build process, you can provide it with `--build-arg`: 

```shell
docker build -t ctf-image --build-arg http_proxy=http://172.17.0.1:8080 --build-arg https_proxy=http://172.17.0.1:8080 .
```

Run the container with the following command, you will get a tmux shell. (You will be asked to configure powerlevel10k before you get the shell, after that you can run `p10k configure` if you want to change the configurations)

```shell
docker run -it --name ctf --hostname ctf -v "$PWD/work":/home/ctf/work ctf-image
```

And you don't have to execute the `docker run` command every time you want to use it, just use `docker start` .

```shell
docker start -ai ctf
```

