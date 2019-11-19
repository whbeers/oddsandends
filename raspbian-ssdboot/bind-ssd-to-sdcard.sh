if [[ ! -d /media/$USERNAME/boot/ ]]; then
  echo "SD Card boot device not mounted. Exiting."
  exit 1
fi

if [[ ! -d /media/$USERNAME/rootfs/ ]]; then
  echo "SD Card rootfs device not mounted. Exiting."
  exit 1
fi

if [[ ! -d /media/$USERNAME/ssdroot/ ]]; then
  echo "SSD rootfs device not mounted. Exiting."
  exit 1
fi

echo "Enabling ssh..."
touch /media/$USERNAME/boot/ssh


# the following ensure that my USB3 SATA adapter uses usb-storage ainstead of
# UAS. Update this (and cmdline below) with your vendorid:productid pair if
# you run into performance issues. Adapted from YtvwlD's solution at
# https://unix.stackexchange.com/questions/239782/connection-problem-with-usb3-external-storage-on-linux-uas-driver-problem
sudo --preserve-env=USERNAME sh -c 'echo "usb-storage quirks=152d:0578:u" > /media/$USERNAME/rootfs/etc/modprobe.d/blacklist_uas.conf'
sudo --preserve-env=USERNAME sh -c 'echo "usb-storage quirks=152d:0578:u" > /media/$USERNAME/ssdroot/etc/modprobe.d/blacklist_uas.conf'


echo "Enabling boot from SSD..."
PARTUUID=$(sudo lsblk -lo name,label,partuuid|grep ssdroot | awk '{print $3}')
echo "console=serial0,115200 console=tty1 root=PARTUUID=$PARTUUID rootfstype=ext4 elevator=deadline usb-storage.quirks=152d:0578:u fsck.repair=yes rootwait" > /media/$USERNAME/boot/cmdline.txt
sudo sed -i 's/PARTUUID=6c586e13-01/LABEL=boot/' /media/$USERNAME/rootfs/etc/fstab
sudo sed -i 's/PARTUUID=6c586e13-02/LABEL=ssdroot/' /media/$USERNAME/rootfs/etc/fstab
sudo sed -i 's/PARTUUID=6c586e13-01/LABEL=boot/' /media/$USERNAME/ssdroot/etc/fstab
sudo sed -i 's/PARTUUID=6c586e13-02/LABEL=ssdroot/' /media/$USERNAME/ssdroot/etc/fstab


echo "Unmounting..."
sync
sudo umount /media/$USERNAME/boot
sudo umount /media/$USERNAME/rootfs
sudo umount /media/$USERNAME/ssdroot

echo "Safe to remove SSD and SD card."
