fdisk -l

printf "Wybierz dysk: "
read disk

fdisk $disk <<EOF
g
n


+512M
t
1

n



w
EOF

mkdir /mnt/boot

efi=$disk
efi+="1"

mkfs.vfat -F32 $efi
mount $efi /mnt/boot

partition=$disk
partition+="2"

mkfs.ext4 $partition
mount $partition /mnt

pacstrap /mnt base linux linux-firmware

genfstab -U /mnt >> /mnt/etc/fstab

cat << EOF > /mnt/root/install.sh 
	echo -e "\n" | pacman -Syu
	echo -e "\n" | pacman -S grub efibootmgr vim networkmanager

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

	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
	grub-mkconfig -o /boot/grub/grub.cfg
EOF

chmod +x /mnt/root/install.sh

arch-chroot /mnt /root/install.sh
arch-chroot /mnt
