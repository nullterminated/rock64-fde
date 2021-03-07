NAME=$1
mkimage -A arm -O linux -T script -C none -n "U-Boot boot script" -d $NAME.txt $NAME.scr
mount /dev/sda1 /mnt
cp $NAME.scr /mnt/boot.scr
umount -l /mnt/
