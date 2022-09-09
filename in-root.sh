
HOSTNAME="CoolhavenPC"

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

echo >install.log


run "set timezone"                "ln -sf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime"
run "set hwclock to UTC"          "hwclock --systohc"
run "generate locals"             "locale-gen"
echo "config locals"
echo "LANG=en_GB.UTF-8" >/etc/locale.conf
run "set hostname"
echo "$HOSTNAME" >/etc/hostname
echo "create hosts file"
echo "127.0.0.1     localhost"  >/etc/hosts
echo "::1           localhost" >>/etc/hosts
echo "127.0.1.1     $HOSTNAME" >>/etc/hosts

run "generate initramfs"          "mkinitcpio -P" "return"

run "add .ssh dir to skel"        "mkdir /etc/skel/.ssh"
run "create user"                 "useradd --home-dir /home/mreenen --create-home --skel /etc/skel mreenen"
run "touch authoized keys"        "touch /home/mreenen/.ssh/authorized_keys"
run "add sshkeys for new user"    "curl -o /home/mreenen/.ssh/authorized_keys https://github.com/MReenen.keys"

run "install CRUB"                "pacman -S grub efibootmgr"
run "create efi directory"        "mkdir /boot/efi"
run "run grub-install"            "grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi"
run "make grub config"            "grub-mkconfig -o /boot/grub/grub.cfg"
