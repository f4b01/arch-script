#!/bin/bash 

# Disco su cui creare le partizioni
echo "Nome del disco in cui creare le partizioni"
read disk

echo "inserisci il nome del computer"
read pc

echo "inserisci il nome dell'utente"
read USERNAME

echo "inserisci la password"
read PASSWORD
# Creazione della tabella delle partizioni
parted -s $disk mklabel gpt

# Creazione della partizione EFI
parted -s $disk mkpart primary fat32 1MiB 513MiB
parted -s $disk set 1 esp on

# Creazione della partizione Btrfs per il root
parted -s $disk mkpart primary 513MiB 4610MiB

# Creazione della partizione di swap
parted -s $disk mkpart primary linux-swap 4611MiB 100%

# Formattazione delle partizioni
mkfs.fat -F32 ${disk}1
mkswap ${disk}2
mkfs.btrfs -f ${disk}3


echo "Partizioni create con successo."

mount ${disk}3 /mnt 
btrfs subv cr /mnt/@
btrfs subv cr /mnt/@root
btrfs subv cr /mnt/@home
btrfs subv cr /mnt/@srv
btrfs subv cr /mnt/@log
btrfs subv cr /mnt/@cache
btrfs subv cr /mnt/@tmp

umount /mnt
mount -o defaults,noatime,compress=zstd,commit=120,subvol=@ ${disk}3 /mnt

mkdir -p /mnt/{home,root,srv,var/log,var/cache,tmp}

mount -o defaults,noatime,compress=zstd,commit=120,subvol=@root ${disk}3 /mnt/root

mount -o defaults,noatime,compress=zstd,commit=120,subvol=@home ${disk}3 /mnt/home

mount -o defaults,noatime,compress=zstd,commit=120,subvol=@srv ${disk}3 /mnt/srv

mount -o defaults,noatime,compress=zstd,commit=120,subvol=@log ${disk}3 /mnt/var/log

mount -o defaults,noatime,compress=zstd,commit=120,subvol=@cache ${disk}3 /mnt/var/cache

mount -o defaults,noatime,compress=zstd,commit=120,subvol=@tmp ${disk}3 /mnt/tmp

mkdir -p /mnt/boot/efi
mount ${disk}1 /mnt/boot/efi

swapon ${disk}2

pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware neovim git btrfs-progs intel-ucode grub efibootmgr networkmanager --noconfirm --needed

genfstab -U /mnt > /mnt/etc/fstab


cat <<REALEND > /mnt/next.sh 

echo "---------------------------------------"
echo "impostiamo la lingua su IT, il tipo di tastiera e i locale"
echo "---------------------------------------\n"

ln -sf /usr/share/zoneinfo/Europe/Rome /etc/localtime

hwclock --systohc

echo "LANG=it.IT.UTF-8" > /etc/locale.conf

echo "KEYMAP=it2" > /etc/vconsole.conf

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen

locale-gen


echo "------------------------------------------------"
echo "Creiamo l'utente e configuriamo i sudoers file"
echo "------------------------------------------------\n"


echo $pc > /etc/hostname

useradd -m -G wheel,storage,power,audio -s /bin/bash $USERNAME

echo "$USERNAME:$PASSWORD" | chpasswd

sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers



echo "-----------------"
echo "Installiamo Grub"
echo "-----------------"


grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi

grub-mkconfig -o /boot/grub/grub.cfg



echo "-----------------------"
echo "Installiamo KDE Plasma"
echo "-----------------------"

sudo pacman -S plasma sddm kde-applications --noconfirm --needed



echo "---------------------"
echo "Abilitiamo i servizi"
echo "---------------------"

systemctl enable Networkmanager sddm

REALEND

arch-chroot /mnt sh next.sh    
