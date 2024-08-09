[![Build](https://img.shields.io/github/actions/workflow/status/badrmoh/ssh-utils/build_and_publish.yml?branch=main&label=ci&logo=github&style=flat-square)](https://github.com/badrmoh/ssh-utils/actions?workflow=build_and_publish)

---

# About 

SSH Utils is a Alpine based image, that contains ssh tools:
- openssh-server
- openssh-client
- ssh-agent
- ssh-add

# Available Configurations
| **Environment Variable** |                                                  **Description**                                                 |             **Default**            |
|:------------------------:|:----------------------------------------------------------------------------------------------------------------:|:----------------------------------:|
|           DUSER          |                                              Run as docker username                                              |              ssh-user              |
|          DGROUP          |                                              Run as docker groupname                                             |              ssh-user              |
|           DPID           |                                                 Run as docker uid                                                |                1001                |
|           DGID           |                                                 Run as docker gid                                                |                1001                |
|         SSH_PORT         |                                            OpenSSH Server listen port                                            |                2222                |
|     SSH_HOST_KEY_DIR     |                                            SSH host key directory path                                           |  /home/ssh-user/.ssh/ssh_host_keys |
|       SSH_AUTH_SOCK      |                                           SSH Agent listen socket path                                           | /home/ssh-user/.ssh/ssh-agent.sock |
|  SSH_PRIVATE_KEYS_DIR    |           When private keys are mounted in this directory, it will be automatically imported by ssh-add          |    /home/ssh-user/.ssh/private     |
|     SSH_AGENT_ENABLED    |                                If set (with any value), ssh-agent will be started                                |                false               |
|  SSH_ADD_WATCHER_ENABLED | If set (with any value), ssh-add will watch $SSH_KEYS_DIR, and adds private keys automatically when copied there |                false               |
|       SSHD_ENABLED       |                              If set (with any value), OpenSSH Server will be started                             |                true                |
|      SSH_PUBLIC_KEY*     |    Environment Variables starting with SSH_PUBLIC_KEY will be evaluated and added to authorized_keys of $DUSER   |                 ""                 |

# Basic Usage

## Use openssh-server with multiple ssh public keys
```
export SSH_PORT=2224
export SSH_PUBLIC_KEY1=$(cat path-to-1stuser's-public-key)
export SSH_PUBLIC_KEY2=$(cat path-to-2snduser's-public-key)
docker run -p $SSH_PORT \
    -e SSH_PORT=$SSH_PORT \
    -e SSH_PUBLIC_KEY1=$SSH_PUBLIC_KEY1 \
    -e SSH_PUBLIC_KEY1=$SSH_PUBLIC_KEY1 \
    ghcr.io/badrmoh/ssh-utils:v1.0 
```

Once Docker Container is healthy:

`ssh -p $SSH_PORT ssh-user@127.0.0.1`


## Use ssh-agent with openssh client and server
ssh-agent starts automatically, and looks for keys in $SSH_PRIVATE_KEYS_DIR to load them using `ssh-add`.
```
export SSH_PORT=2224
export SSH_PUBLIC_KEY=$(cat path-to-user's-public-key)
export SSH_PRIVATE_KEYS_DIR=/home/ssh-user/.ssh/private   # default value
docker run -p $SSH_PORT \
    -e SSH_PORT=$SSH_PORT \
    -e SSH_PUBLIC_KEY=$SSH_PUBLIC_KEY \
    -e SSH_AGENT_ENABLED=1 \
    -e SSH_PRIVATE_KEYS_DIR=$SSH_PRIVATE_KEYS_DIR \
    -v path-to-keys-on-host:$SSH_PRIVATE_KEYS_DIR \
    ghcr.io/badrmoh/ssh-utils:latest
```

## Use ssh-add watcher service with ssh-agent, openssh client and server
in case ssh keys are to be loaded after first initialization of the container, ssh-add watcher can be used to monitor $SSH_PRIVATE_KEYS_DIR and adds newly added keys automatically.
Make sure that keys added have empty passphrases (keys with passphrases are not supported for now)
```
export SSH_PORT=2224
export SSH_PUBLIC_KEY=$(cat path-to-user's-public-key)
export SSH_PRIVATE_KEYS_DIR=/home/ssh-user/.ssh/private   # default value
docker run -p $SSH_PORT \
    -e SSH_PORT=$SSH_PORT \
    -e SSH_PUBLIC_KEY=$SSH_PUBLIC_KEY \
    -e SSH_AGENT_ENABLED=1 \
    -e SSH_ADD_WATCHER_ENABLED=1 \
    -e SSH_PRIVATE_KEYS_DIR=$SSH_PRIVATE_KEYS_DIR \
    -v path-to-keys-on-host:$SSH_PRIVATE_KEYS_DIR \
    ghcr.io/badrmoh/ssh-utils:latest 
```

## Use host's ssh-agent with openssh client and disabled openssh server.
sometimes, it is better use host's ssh-agent. Just mount the socket without enabling any other services. In this example the container is used as openssh client with host's ssh-agent.
```
export DOCKER_SSH_AUTH_SOCK=/home/ssh-user/.ssh/ssh-agent.socket
docker run -p $SSH_PORT \
    -e SSHD_ENABLED=false \
    -e SSH_AUTH_SOCK=$DOCKER_SSH_AUTH_SOCK \
    -v path-to-ssh-agents-sock-file:$DOCKER_SSH_AUTH_SOCK \
    ghcr.io/badrmoh/ssh-utils:latest
```


# Advanced Usage

# Use as jump host
it is possible to use this pattern in situations where jump host is required.


```
                    ___________________________          ___________________
                   |jump host|                 |        |                   |
                   |---------                  |        |                   |
  0                |        _____________      |        |                   |
 ___               |       |             |     |        |                   |
|___| ------->  [$SSH_PORT]   ssh-utils  |============> |   target server   |
                   |       |  container  |     |        |                   |
                   |       |_____________|     |        |                   |
                   |___________________________|        |___________________|


```

1. On the jump host, install docker
2. Run the image on the jump host as shown in the [section](#Use ssh-agent / ssh-add) above.
3. Configure the jump host's firewall's setting to allow incoming TCP traffic on $SSH_PORT.
4. Use `ssh -J ssh-user@<jump-host-addr> <target-host-user>@<target-host-addr>`



# Credits
This image is inspired by:
- linuxserver.io's openssh-server [image](https://github.com/linuxserver/docker-openssh-server)
- serversideup's docker-ssh [image](https://github.com/serversideup/docker-ssh)
