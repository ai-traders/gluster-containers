#!/bin/bash

set -e

mkdir -p /run/
mount -o rw,relatime -t tmpfs tmpfs /run/
mount --make-rshared /run
echo "Mounted /run on shared tmpfs"

export GLUSTERFS_CONF_DIR="/etc/glusterfs"
export GLUSTERFS_LOG_DIR="/var/log/glusterfs"
export GLUSTERFS_META_DIR="/var/lib/glusterd"
export GLUSTERFS_LOG_CONT_DIR="/var/log/glusterfs/container"
export GLUSTERFS_CUSTOM_FSTAB="/etc/glusterfs/fstab"

mount_gluster_bricks () {

  mkdir -p $GLUSTERFS_LOG_CONT_DIR

  echo "" > $GLUSTERFS_LOG_CONT_DIR/brickattr
  echo "" > $GLUSTERFS_LOG_CONT_DIR/failed_bricks
  echo "" > $GLUSTERFS_LOG_CONT_DIR/lvscan
  echo "" > $GLUSTERFS_LOG_CONT_DIR/mountfstab

  if [ -f $GLUSTERFS_CUSTOM_FSTAB ]
  then
        cut -f 2 -d " " $GLUSTERFS_CUSTOM_FSTAB | while read -r dest_dir
        do
            mkdir -p $dest_dir
        done
        pvscan > $GLUSTERFS_LOG_CONT_DIR/pvscan
        vgscan > $GLUSTERFS_LOG_CONT_DIR/vgscan
        lvscan > $GLUSTERFS_LOG_CONT_DIR/lvscan
        mount -a --fstab $GLUSTERFS_CUSTOM_FSTAB > $GLUSTERFS_LOG_CONT_DIR/mountfstab
        if [ $? -eq 1 ]
        then
              echo "mount -a failed" >> $GLUSTERFS_LOG_CONT_DIR/mountfstab
              exit 1
        fi
        echo "Mount command Successful" >> $GLUSTERFS_LOG_CONT_DIR/mountfstab
        cut -f 2 -d " " $GLUSTERFS_CUSTOM_FSTAB | while read -r line
        do
              if grep -qs "$line" /proc/mounts; then
                   echo "$line mounted." >> $GLUSTERFS_LOG_CONT_DIR/mountfstab
                   if test "ls $line/brick"
                   then
                         echo "$line/brick is present" >> $GLUSTERFS_LOG_CONT_DIR/mountfstab
                         getfattr -d -m . -e hex "$line"/brick >> $GLUSTERFS_LOG_CONT_DIR/brickattr
                   else
                         echo "$line/brick is not present" >> $GLUSTERFS_LOG_CONT_DIR/mountfstab
                   fi
              else
		   grep "$line" $GLUSTERFS_CUSTOM_FSTAB >> $GLUSTERFS_LOG_CONT_DIR/failed_bricks
                   echo "$line not mounted." >> $GLUSTERFS_LOG_CONT_DIR/mountfstab
                   sleep 0.5
             fi
        done
        if [ $(wc -l $GLUSTERFS_LOG_CONT_DIR/failed_bricks | cut -f 1 -d " ") -gt 1 ]
        then
              vgscan --mknodes > $GLUSTERFS_LOG_CONT_DIR/vgscan_mknodes
              sleep 10
              mount -a --fstab $GLUSTERFS_LOG_CONT_DIR/failed_bricks
        fi
  else
        echo "gluster fstab not found"
  fi

  echo "Mount gluster bricks ran successfully"
}
mount_gluster_bricks

exec /init $@
