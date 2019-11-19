DISK=$(lsblk -lo name,label,partuuid|grep rootfs | awk '{print $1}' |sed -e 's/2$//')
ROOTFS=$(lsblk -lo name,label,partuuid|grep rootfs | awk '{print "/dev/"$1}')
BOOTFS=$(lsblk -lo name,label,partuuid|grep boot | awk '{print "/dev/"$1}')
sudo umount $ROOTFS 2>/dev/null
sudo umount $BOOTFS 2>/dev/null

if [[ -z $DISK ]]; then
  echo "disk not detected. exiting"
  exit 1
fi

echo "PARTUUIDs before update:"
lsblk -lo name,label,partuuid | grep $DISK


# The following is lifted from a comment on stackoverflow that I can't find anymore.
PTUUID=$(uuid | cut -c-8)
PTUUID="$(tr [A-Z] [a-z] <<< "${PTUUID}")"
if [[ ! "${PTUUID}" =~ ^[[:xdigit:]]{8}$ ]]; then
  echo "Invalid PARTUUID generated: ${PTUUID}"
fi

echo "Writing new PARTUUID:$PTUUID to device:$DISK..."
sync && sleep 2
sudo fdisk "/dev/"$DISK <<EOF > /dev/null
p
x
i
0x${PTUUID}
r
p
w
EOF
sync && sleep 2

echo "PARTUUIDs after update:"
lsblk -lo name,label,partuuid | grep $DISK

