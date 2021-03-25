FROM ubuntu:16.04 AS horde_base
ENV DEBIAN_FRONTEND "noninteractive"
RUN apt-get update



FROM horde_base AS builder
RUN DEBIAN_FRONTEND=noninteractive apt install -y cmake build-essential zlib1g-dev \
    libopenmpi-dev git wget unzip build-essential zlib1g-dev iproute2 cmake python3-pip build-essential gfortran wget curl
RUN git clone https://github.com/biotomas/hordesat
RUN cd hordesat && ./makehordesat.sh



FROM horde_base AS horde_node
RUN apt install -y openssh-server iproute2 openmpi-bin openmpi-common iputils-ping awscli python3 mpi
# Setup SSHD
RUN mkdir /var/run/sshd \
    && echo "export VISIBLE=now" >> /etc/profile \
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
ENV NOTVISIBLE "in users profile"
WORKDIR /home/horde
COPY --from=builder /hordesat/hordesat /hordesat/hordesat
ADD mpi-run.sh supervised-scripts/mpi-run.sh
ADD make_combined_hostfile.py supervised-scripts/make_combined_hostfile.py
RUN chmod a+x supervised-scripts/make_combined_hostfile.py supervised-scripts/mpi-run.sh
USER horde
EXPOSE 22
CMD supervised-scripts/mpi-run.sh

# CMD ["/usr/sbin/sshd", "-D", "-f", "/home/horde/.ssh/sshd_config"]
