# docker build -t util:latest util
# docker run -itd -p 2222:22 -v /opt/docker_volume:/opt/docker_volume -v /var/run/docker.sock:/var/run/docker.sock --privileged --name util util:latest

FROM centos:centos7
WORKDIR /opt
USER root

# lang jp
RUN yum -y reinstall glibc-common
RUN localedef -v -c -i ja_JP -f UTF-8 ja_JP.UTF-8; echo "";

ENV LANG=ja_JP.UTF-8
RUN rm -f /etc/localtime
RUN ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# install repo
RUN set -x && \
  yum -y install deltarpm && \
  yum -y install yum-utils device-mapper-persistent-data lvm2 && \
  yum -y install epel-release && \
  yum -y install http://rpms.famillecollet.com/enterprise/remi-release-7.rpm && \
  yum -y install https://centos7.iuscommunity.org/ius-release.rpm && \
  yum -y remove docker docker-common docker-selinux docker-engine && \
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# required
RUN set -x && \
  yum -y install git

# docker
RUN set -x && \
  yum -y install docker-ce

# php
RUN set -x && \
  yum -y install --enablerepo=remi,remi-php70 --disablerepo=ius php php-devel php-mbstring php-pdo php-gd php-intl php-mysqlnd php-xml php-zip php-pecl-xdebug

# composer
RUN set -x && \
  cd /tmp/ && \
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
  php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
  php -r "unlink('composer-setup.php');"

# tmux
# https://github.com/tmux/tmux/releases
RUN set -x && \
  cd /tmp && \
  yum -y install gcc libevent-devel ncurses-devel make && \
  curl -kLO https://github.com/tmux/tmux/releases/download/2.6/tmux-2.6.tar.gz && \
  tar -zxvf tmux-2.6.tar.gz && \
  cd tmux-2.6 && \
  ./configure --prefix=/usr/local && \
  make && \
  make install

# tmux(config)
RUN set -x && \
  mkdir -p /root/work/git/ && \
  cd /root/work/git && \
  git clone https://github.com/suzunoneseven/tmuxConfig.git

# java
RUN set -x && \
  yum -y install java

# python
RUN set -x && \
  yum -y install python-pip && \
  pip install pip --upgrade

# util and update
RUN set -x && \
  yum -y install gcc unzip wget expect sendmail sendmail-cf tcpdump net-tools install openssh openssh-server vim whois && \
  yum -y update

# vim
RUN set -x && \
  echo -e "set number\n \
syntax off\n \
set expandtab\n \
set softtabstop=4" > /root/.vimrc

# user
RUN set -x && \
  expect -c " \
    spawn passwd root \
    expect \"New password:\" \
    send \"root123\n\" \
    expect \"Retype new password:\" \
    send \"root123\n\" \
    expect \"passwd: all authentication tokens updated successfully.\" \
    send \"exit\n\" \
    "

# entrypoint
ADD entrypoint.sh /root/entrypoint.sh
RUN set -x && \
  mkdir -p /opt/docker_volume && \
  chmod +x /root/entrypoint.sh

# script
ADD script/easy_docker /root/easy_docker
ADD script/easy_ssh /root/easy_ssh
ADD script/start_zalenium /root/start_zalenium

ENTRYPOINT /root/entrypoint.sh
