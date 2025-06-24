FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
  apt install -y openssh-server sudo && \
  useradd -m -s /bin/bash ansible && \
  echo 'ansible:ansible123' | chpasswd && \
  echo 'ansible ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
  mkdir -p /var/run/sshd 

# Configura SSH
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config 
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config

EXPOSE 22

CMD [ "/usr/sbin/sshd", "-D" ]

# docker build -t control-node .
# docker run -dit --name control-node -p 2222:22 control-node
# ssh ansible@localhost -p 2222
