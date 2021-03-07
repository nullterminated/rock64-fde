This is a script to generate a bootable SD card for a rock64 with full disk encryption. It uses LVM on LUKS, encrypted root and a 512MB unencrypted boot partitions. The root partition is divided into 8GB swap volume and the remaining free space is the root volume.

To use, you need to download the latest archlinuxarm filesystem tarball into this directory like,

wget http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz
wget http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz.sig
(Optional step, not necessary if you already have this on your gpg keyring)
gpg --recv-keys 68B3537F39A313B3E574D06777193F152BDBE6A6
gpg --verify ArchLinuxARM-aarch64-latest.tar.gz.sig

Once you have the tarball, open the install_fde.sh script in a text editor and make sure the DISK path matches where you want to write your new microsd card data. You also need to set your PASSWORD directly, or you can use the provided random password generator.

After those two values are set to your liking, it is just

sudo ./install_fde.sh

And in a few minutes you will have a bootable sd card with full disk encryption for your rock64 SBC. If you choose to use the random password generator, it will echo the password at the end of the script. Write that down, because it will not be saved anywhere else.

A brief explanation of the files included:

etc-iwd-main.conf: configuration for the internet wireless daemon needed to connect to the internet with something like a ThinkPenguin wireless dongle

idbloader.img, u-boot.itb: u-boot bootloader files build from blob free source 

boot.txt: u-boot boot script, modified from the original archlinuxarm script for use in full disk encrypted setup

boot.scr: the generated boot.scr file from boot.txt

mksrc: handy script to put in your /boot/ dir along with boot.txt for regenerating a boot.scr after making changes

loadboot.sh: handy script to regenerate the boot.scr for any given <name>.txt file, mount /boot from the sd card, copy said <name>.scr into /boot/boot.scr, and then unmount
