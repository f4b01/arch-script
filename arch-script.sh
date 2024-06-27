#!/bin/bash 

#!/bin/bash
# Disco su cui creare le partizioni
disk="/dev/sda"

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
mount -o defaults,noatime,compress=zstd,commit=120,subvol=@ /dev/vda3 /mnt

mkdir -p /mnt/{root,srv,var/log,var/cache,tmp}

mount -o defaults,noatime,compress=zstd,commit=120,subvol=@root /dev/vda3 /mnt/root


mount -o defaults,noatime,compress=zstd,commit=120,subvol=@home /dev/vda3 /mnt/home

mount -o defaults,noatime,compress=zstd,commit=120,subvol=@srv /dev/vda3 /mnt/srv

mount -o defaults,noatime,compress=zstd,commit=120,subvol=@log /dev/vda3 /mnt/var/log

mount -o defaults,noatime,compress=zstd,commit=120,subvol=@cache /dev/vda3 /mnt/var/cache

mount -o defaults,noatime,compress=zstd,commit=120,subvol=@tmp /dev/vda3 /mnt/tmp


