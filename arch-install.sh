
function run(){
    echo "[    ] $1"
    echo "# $1" >>install.log
    echo "> $2" >>install.log
    $2 &>>install.log \
        && echo -e "\e[1A\e[K[ \e[32mOK\e[0m ] $1" \
        || { 
            echo -e "\e[1A\e[K[\e[31mFAIL\e[0m] $1"
            $3
            exit
        }
     echo >>install.log
}

echo "" >install.log


# === setup networking

# ENDEV=enp1s1
# IP=1.2.3.4/24
# GATEWAY=1.2.3.1
HOSTNAME="CoolhavenPC"

# ip addr add $IP dev $ENDEV
# ip route add default via $GATEWAY dev $ENDEV
# echo "nameserver $GATEWAY" >>/dev/resolve.conf

echo
echo === setup localisation
echo

run "enable ntp"                  "timedatectl set-ntp true"
run "set timezone"                "timedatectl set-timezone Europe/Amsterdam"

echo
echo === install git and get this gist
echo

# pacman -Sy
# pacman -S git
# git clone https://gist.github.com/038178626dd006a62e1ff4734d88694b.git
# cd 038178626dd006a62e1ff4734d88694b

echo === setup partitions

DISK="/dev/sda"

# fdisk $DISK
#   g
#   n # boot partition
#     1
#     [default]
#     +512M
#   n # SWAP partition
#     2
#     [default]
#     +4G
#   n # recovery partition
#     3
#     [default]
#     +4G
#   n # system partition
#     10
#     [default]
#     [default]
#   w

echo
echo === format partitions
echo

echo -n "disk encryption password: "
read -s PASS
echo
echo -n "retype password: "
read -s PASSRE
echo

if [ "$PASS" != "$PASSRE" ]; then
  echo "password do not match"
  exit
fi
echo

run "format boot partition"       "mkfs.fat ${DISK}1"
run "format swap partition"       "mkswap ${DISK}2"
echo -n "$PASS" >keyfile.luks
run "encrypt root partition"      "cryptsetup luksFormat --batch-mode --key-file keyfile.luks ${DISK}10"     "rm keyfile.luks"
run "map root partitaion"         "cryptsetup open --batch-mode --key-file keyfile.luks ${DISK}10 cryptroot" "rm keyfile.luks"
rm keyfile.luks
run "format root partition"       "mkfs.btrfs /dev/mapper/cryptroot"

echo
echo === mount all partitions
echo

run "mount root partition"        "mount /dev/mapper/cryptroot /mnt"
run "create root btrfs subvolume" "btrfs subvolume create /mnt/@"
run "create home btrfs subvolume" "btrfs subvolume create /mnt/@home"
run "unmount btrfs"               "umount /mnt"
run "mount root subvolume"        "mount -o subvol=@ /dev/mapper/cryptroot /mnt"
run "make root directorys"        "mkdir -p /mnt/root /mnt/home"
run "mount boot partition"        "mount ${DISK}1 /mnt/root"
run "mount home subvolume"        "mount -o subvol=@home /dev/mapper/cryptroot /mnt/home"
run "enable swap"                 "swapon ${DISK}2"

echo
echo === install arch
echo

run "install base of arch"        "pacstrap /mnt base linux linux-firmware"

echo "generate fstab"
genfstab -U /mnt >>/mnt/etc/fstab
run "copy in-root script"         "cp in-root.sh /mnt/root"

echo
echo === chroot config
echo

arch-chroot /mnt bash /root/in-root.sh
