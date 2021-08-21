fdisk -l

printf "Wybierz dysk: "
read disk

uefi_check=/sys/firmware/efi

if [ -d "$file" ]; then

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
	echo -e "\n" | pacman -Syu
	echo -e "\n\n\n" | pacman -S grub efibootmgr vim networkmanager git base-devel xf86-video-fbdev xorg-server xorg-xinit xorg-fonts libxft libxinerama

	ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
	hwclock --systohc
	echo pl_PL.UTF-8 UTF-8 > /etc/locale.gen
	locale-gen
	echo LANG=pl_PL.UTF-8 > /etc/locale.conf
	echo archpiotr >> /etc/hostname

	echo 127.0.0.1		localhost > /etc/hosts
	echo ::1 		localhost >> /etc/hosts
	echo 127.0.1.1		archpiotr.localdomain archpiotr >> /etc/hosts

	echo -e "admin\nadmin" | passwd

	uefi_check=/sys/firmware/efi

	if [ -d "$file" ]; then

	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

	else

	grub-install --target=i386-pc $disk

	fi

	grub-mkconfig -o /boot/grub/grub.cfg

	systemctl enable NetworkManager

	useradd -m -g users -G wheel piotr

	git clone git://git.suckless.org/dwm

	cd dwm

	make clean install

	cd ..
	
	git clone git://git.suckless.org/st

	cd st

	make clean install

	echo exec dwm > /home/piotr/.xinitrc

	su piotr
	
EOF

chmod +x /mnt/root/install.sh

arch-chroot /mnt /root/install.sh
arch-chroot /mnt
