FROM centos:7

MAINTAINER Tomasz Setkowski <tom@ai-traders.com>

ENV container docker
ENV package_version=3.12.4-1.el7
LABEL architecture="x86_64" \
      name="gluster/gluster-centos" \
      version="3.12" \
      vendor="Red Hat, Inc" \
      summary="This image has a running glusterfs service ( CentOS 7 + Gluster 3.12)" \
      io.k8s.display-name="Gluster 3.12 based on CentOS 7"

# The Storage SIG provides centos-release-<project> packages in the CentOS Extras repository.
# This makes it easy for users to install projects from the Storage SIG
RUN yum --setopt=tsflags=nodocs -y update && yum install -y wget centos-release-gluster && yum clean all &&\
  rm -fr /lib/systemd/ &&\
  rm -fr /etc/systemd/

RUN wget -O /tmp/s6-overlay-amd64.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v1.21.2.2/s6-overlay-amd64.tar.gz &&\
  tar xzf /tmp/s6-overlay-amd64.tar.gz -C / --exclude="./bin" --exclude="./sbin" && \
  tar xzf /tmp/s6-overlay-amd64.tar.gz -C /usr ./bin

RUN yum --setopt=tsflags=nodocs -y install nano nfs-utils attr iputils iproute openssh-server openssh-clients ntp rsync tar cronie sudo xfsprogs glusterfs-${package_version} glusterfs-server-${package_version} && yum clean all &&\
  sed -i '/Defaults    requiretty/c\#Defaults    requiretty' /etc/sudoers &&\
  sed -i '/Port 22/c\Port 2222' /etc/ssh/sshd_config &&\
  sed -i.save -e "s#udev_sync = 1#udev_sync = 0#" -e "s#udev_rules = 1#udev_rules = 0#" -e "s#use_lvmetad = 1#use_lvmetad = 0#" /etc/lvm/lvm.conf;

VOLUME [ "/sys/fs/cgroup" ]

EXPOSE 2222 111 245 443 24007 2049 8080 6010 6011 6012 38465 38466 38468 38469 49152 49153 49154 49156 49157 49158 49159 49160 49161 49162

# Add all the services
COPY ./services.d /etc/services.d
#COPY ./cont-init.d/* /etc/cont-init.d
COPY mount_run_init.sh /mount_run_init.sh

ENTRYPOINT ["/mount_run_init.sh"]
