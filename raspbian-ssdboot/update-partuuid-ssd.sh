DISK=$(lsblk -lo path,label |grep ssdroot | awk '{print $1}' |sed -e 's/2$//')
SSDROOTPART=$(lsblk -lo path,label |grep ssdroot | awk '{print $1}')
sudo umount $SSDROOTPART 2>/dev/null

if [[ -z $DISK ]]; then
  echo "disk not detected. exiting"
  exit 1
fi

echo "PARTUUIDs before update:"
lsblk -lo path,label,partuuid | grep $DISK

# The following is adapted from Milliways script at 
# https://www.raspberrypi.org/forums/viewtopic.php?f=29&t=253562#p1547598
PTUUID=$(uuid | cut -c-8)
PTUUID="$(tr [A-Z] [a-z] <<< "${PTUUID}")"
if [[ ! "${PTUUID}" =~ ^[[:xdigit:]]{8}$ ]]; then
  echo "Invalid PARTUUID generated: ${PTUUID}"
fi

echo "Writing new PARTUUID:$PTUUID, to device:$DISK..."
sync && sleep 2
sudo fdisk $DISK <<EOF > /dev/null
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
lsblk -lo path,label,partuuid | grep $DISK
