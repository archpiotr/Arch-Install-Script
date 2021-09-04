fdisk -l

printf "Wybierz dysk: "
read disk

uefi_check=/sys/firmware/efi

if [ -d "$uefi_check" ]; then

#uefi
fdisk $disk <<EOF
g
n


+512M
t
1

n



w
EOF

partition=$disk
partition+="2"

mkfs.ext4 $partition
mount $partition /mnt

mkdir /mnt/boot

efi=$disk
efi+="1"

mkfs.vfat -F32 $efi
mount $efi /mnt/boot

else

#legacy

fdisk $disk <<EOF
o
n



w
EOF

partition=$disk
$partition+="1"

mkfs.ext4 $partition
mount $partition /mnt

fi

pacstrap /mnt base linux linux-firmware

genfstab -U /mnt >> /mnt/etc/fstab

cat << EOF > /mnt/root/install.sh 
	# Installtion required packages

	echo -e "\n" | pacman -Syu
	echo -e "\n\n\n" | pacman -S grub efibootmgr vim networkmanager git base-devel xf86-video-fbdev xorg-server xorg-xinit xorg-fonts ttf-hack libxft libxinerama

	# Editing configuration files

	ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
	hwclock --systohc
	echo pl_PL.UTF-8 UTF-8 > /etc/locale.gen
	locale-gen
	echo LANG=pl_PL.UTF-8 > /etc/locale.conf
	echo archpiotr >> /etc/hostname

	echo 127.0.0.1		localhost > /etc/hosts
	echo ::1 		localhost >> /etc/hosts
	echo 127.0.1.1		archpiotr.localdomain archpiotr >> /etc/hosts

	# Installing GRUB bootloader

	if [ -d "/sys/firmware/efi" ]; then

	grub-install --target=x86_64-efi --efi-directory=/boot --force --bootloader-id=GRUB

	else

	grub-install --target=i386-pc --force $disk

	fi

	grub-mkconfig -o /boot/grub/grub.cfg

	# Enabling NetworkManager

	systemctl enable NetworkManager

	# Adding user

	useradd -m -g users -G wheel piotr

	# Installing suckless stuff

	mkdir /home/piotr/Documents
	mkdir /home/piotr/Documents/suckless

	cd /home/piotr/Documents/suckless

	git clone git://git.suckless.org/dwm

	cd dwm

	make clean install

	cd ..
	
	git clone git://git.suckless.org/st

	cd st

	make clean install

	echo exec dwm > /home/piotr/.xinitrc

	chown -R piotr:users /home/piotr/

	# Changing passwords

	echo -e "admin\nadmin" | passwd
	echo -e "admin\nadmin" | passwd piotr
EOF

chmod +x /mnt/root/install.sh

arch-chroot /mnt /root/install.sh
reboot
