################
FROM ubuntu:16.04 AS horde_base
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt install -y openssh-server iproute2 openmpi-bin openmpi-common iputils-ping \
    && mkdir /var/run/sshd \
    && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
    && setcap CAP_NET_BIND_SERVICE=+eip /usr/sbin/sshd \
    && useradd -ms /bin/bash horde \
    && chown -R horde /etc/ssh/ \
    && su - horde -c \
        'ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -N "" \
        && cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys \
        && cp /etc/ssh/sshd_config ~/.ssh/sshd_config \
        && sed -i "s/UsePrivilegeSeparation yes/UsePrivilegeSeparation no/g" ~/.ssh/sshd_config \
        && printf "Host *\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config'
WORKDIR /home/horde
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
EXPOSE 22
################
FROM ubuntu:16.04 AS builder
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt install -y cmake build-essential zlib1g-dev libopenmpi-dev git wget unzip build-essential zlib1g-dev iproute2 cmake python python-pip build-essential gfortran wget curl
#ADD hordesat hordesat
RUN git clone https://github.com/biotomas/hordesat
RUN cd hordesat && ./makehordesat.sh
################
FROM horde_base AS horde_liaison
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt install -y awscli
COPY --from=builder /hordesat/hordesat /hordesat/hordesat
ADD mpi-run.sh supervised-scripts/mpi-run.sh
USER horde
CMD ["/usr/sbin/sshd", "-D", "-f", "/home/horde/.ssh/sshd_config"]
CMD supervised-scripts/mpi-run.sh


