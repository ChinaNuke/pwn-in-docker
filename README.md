# pwn-in-docker

Dockerfiles to build ctf pwn environments. The dockerfiles are wrote for personal use, but you can use them as you like. Not all pull requests will be accepted.

## Usage

You can build the docker image with a simple command:

```shell
sudo docker build -t ctf20-image .
```

If you need a proxy to speed up the build process, you can provide it with `--build-arg`: 

```shell
sudo docker build -t ctf20-image --build-arg http_proxy=http://172.17.0.1:8080 --build-arg https_proxy=http://172.17.0.1:8080 .
```

Run the container with the following command, you will get a tmux shell.

```shell
sudo docker run -it --name ctf20 -v "$PWD/work":/home/ctf/work ctf20-image
```

And you don't have to execute the `docker run` command every time you want to use it, just use `docker start` .

```shell
sudo docker start -ai ctf20
```

