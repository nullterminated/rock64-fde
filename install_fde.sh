#!/bin/bash
set -eoux pipefail
## Set the disk to the appropriate device before running the script
DISK="/dev/sda"
## Set a password directly, or randomly generate one
PASS="password"
#PASS=$(< /dev/random tr -d -c 0-9A-Za-z | head -c 8)
## Partition the disk
## 512M boot partition 1
## remaining free space partition 2
dd if=/dev/zero of=$DISK bs=1M count=32
fdisk $DISK <<EOF
o
p
n
p
1
32768
1081344
n
p
2
1081345

w
EOF
## Format boot partition
mkfs.ext4 ${DISK}1
## Set up LVM on LUKS for partition 2
echo -n $PASS | cryptsetup luksFormat ${DISK}2 -d -
echo -n $PASS | cryptsetup open ${DISK}2 cryptlvm -d -
pvcreate /dev/mapper/cryptlvm
vgcreate vg0 /dev/mapper/cryptlvm
lvcreate -L 8G vg0 -n swap
lvcreate -l 100%FREE vg0 -n root
mkswap /dev/vg0/swap
mkfs.ext4 /dev/vg0/root
## Mount partitions and swap
mount /dev/vg0/root /mnt
mkdir /mnt/boot
mount ${DISK}1 /mnt/boot
swapon /dev/mapper/vg0-swap
## Copy file system into mounted partitions
bsdtar -xpf ArchLinuxARM-aarch64-latest.tar.gz -C /mnt/
genfstab -U /mnt >> /mnt/etc/fstab
sed -i -e 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)/g' /mnt/etc/mkinitcpio.conf;
sed -i -e 's/MODULES=()/MODULES=(rockchipdrm)/g' /mnt/etc/mkinitcpio.conf;
## Setup install script for arch-chroot
## The lvm2 install is required for FDE
## it triggers mkinitcpio regeneration
cat <<EOF > /mnt/install.sh
# stuff here to do inside the chroot
pacman-key --init
pacman-key --populate archlinuxarm
pacman -Sy --noconfirm lvm2 iwd
## TODO more stuff here, install grub, run mkinitcpio, etc
exit # to leave the chroot
EOF
chmod +x /mnt/install.sh
## Now run the install.sh in chroot
arch-chroot /mnt/ ./install.sh
## Copy the u-boot boot script to the boot partition
cp boot.scr /mnt/boot/
## Copy iwd conf so it can connect to the network
mkdir /mnt/etc/iwd
cp etc-iwd-main.conf /mnt/etc/iwd/main.conf
## clean up
umount -l /mnt/boot
umount -l /mnt
swapoff /dev/vg0/swap
vgchange -a n vg0
cryptsetup close cryptlvm
rm -rf /mnt/boot
## Copy u-boot into remaining 32M free space at beginning of disk
dd if=idbloader.img of=$DISK seek=64 conv=notrunc
dd if=u-boot.itb of=$DISK seek=16384 conv=notrunc
## Echo success and password
echo "Full disk encryption installation is complete!"
echo "Your initial password is:"
echo $PASS

