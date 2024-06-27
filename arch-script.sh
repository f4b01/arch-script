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


