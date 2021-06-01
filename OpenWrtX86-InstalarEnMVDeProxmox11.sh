#!/bin/bash

# Pongo a disposición pública este script bajo el término de "software de dominio público".
# Puedes hacer lo que quieras con él porque es libre de verdad; no libre con condiciones como las licencias GNU y otras patrañas similares.
# Si se te llena la boca hablando de libertad entonces hazlo realmente libre.
# No tienes que aceptar ningún tipo de términos de uso o licencia para utilizarlo o modificarlo porque va sin CopyLeft.

#----------------------------------------------------------------------------------------------------------
#  Script de NiPeGun para instalar OpenWrt en una máquina virtual de ProxmoxVE inciando desde Ubuntu Live 
#----------------------------------------------------------------------------------------------------------

ColorVerde="\033[1;32m"
FinColor="\033[0m"

PrimerDisco="/dev/sda"

echo ""
echo -e "${ColorVerde}Iniciando el script de instalación de OpenWrt X86 para máquinas virtuales de Proxmox...${FinColor}"
echo ""

## Comprobar si el paquete dialog está instalado. Si no lo está, instalarlo.
   if [[ $(dpkg-query -s dialog 2>/dev/null | grep installed) == "" ]]; then
     echo ""
     echo "  dialog no está instalado. Iniciando su instalación..."
     echo ""
     sudo sed -i -e 's|main restricted|main universe restricted|g' /etc/apt/sources.list
     sudo apt-get -y update
     sudo apt-get -y install dialog
     echo ""
   fi

menu=(dialog --timeout 5 --checklist "Instalación de OpenWrt X86:" 22 90 16)
  opciones=(1 "Hacer copia de seguridad de la instalación anterior" off
            2 "Crear las particiones" on
            3 "Formatear las particiones" on
            4 "Marcar la partición OVMF como esp" on
            5 "Determinar la última versión de OpenWrt" on
            6 "Montar las particiones" on
            7 "Descargar Grub para EFI" on
            8 "Crear el archivo de configuración para Grub" on
            9 "Crear la estructura de carpetas y archivos en ext4" on
           10 "Configurar la MV para que pille IP por DHCP" on
           11 "Copiar el script de instalación de paquetes" on
           12 "Copiar el script de instalación de los o-scripts" off
           13 "Copiar el script de preparación de OpenWrt para funcionar como una MV de Proxmox" off
           14 "Mover copia de seguridad de la instalación anterior a la nueva instalción" off)
  choices=$("${menu[@]}" "${opciones[@]}" 2>&1 >/dev/tty)
  clear

  for choice in $choices
    do
      case $choice in

        1)

          echo ""
          echo "  Haciendo copia de seguridad de la instalación anterior..."
          echo ""

          sudo mkdir -p /OpenWrt/PartOVMF/
          sudo mount -t auto /dev/sda1 /OpenWrt/PartOVMF/
          sudo mkdir -p /OpenWrt/PartExt4/
          sudo mount -t auto /dev/sda2 /OpenWrt/PartExt4/
        ;;

        2)

          echo ""
          echo "  Creando las particiones..."
          echo ""
          sudo ummount /OpenWrt/PartOVMF/
          sudo ummount /OpenWrt/PartExt4/
          ## Crear tabla de particiones GPT
             sudo parted -s $PrimerDisco mklabel gpt
          ## Crear la partición OVMF
             sudo parted -s $PrimerDisco mkpart OVMF ext4 1MiB 201MiB
          ## Crear la partición ext4
             sudo parted -s $PrimerDisco mkpart OpenWrt ext4 201MiB 24580MiB
          ## Crear la partición de intercambio
             sudo parted -s $PrimerDisco mkpart Intercambio ext4 24580MiB 100%

        ;;

        3)

          echo ""
          echo "  Formateando las particiones..."
          echo ""
          ## Formatear la partición para EFI como fat32
             sudo mkfs -t vfat -F 32 -n OVMF $PrimerDisco"1"
          ## Formatear la partición para OpenWrt como ext4
             sudo mkfs -t ext4 -L OpenWrt $PrimerDisco"2"
          ## Formatear la partición para Intercambio como swap
             sudo mkswap -L Intercambio $PrimerDisco"3"

        ;;

        4)

          echo ""
          echo "  Marcando la partición EFI como esp..."
          echo ""
          sudo parted -s $PrimerDisco set 1 esp on

        ;;

        5)

          echo ""
          echo "  Determinando la última versión de OpenWrt"
          echo ""

          ## Comprobar si el paquete curl está instalado. Si no lo está, instalarlo.
             if [[ $(dpkg-query -s curl 2>/dev/null | grep installed) == "" ]]; then
               echo ""
               echo "  curl no está instalado. Iniciando su instalación..."
               echo ""
               sudo apt-get -y update
               sudo apt-get -y install curl
               echo ""
             fi
  
          VersOpenWrt=$(curl --silent https://downloads.openwrt.org | grep rchive | grep eleases | grep OpenWrt | head -n 1 | cut -d'/' -f 5)

          echo ""
          echo "La última versión estable de OpenWrt es la $VersOpenWrt"
          echo ""

        ;;

        6)

          echo ""
          echo "Montando las particiones..."
          echo ""
          sudo mkdir -p /OpenWrt/PartOVMF/
          sudo mount -t auto /dev/sda1 /OpenWrt/PartOVMF/
          sudo mkdir -p /OpenWrt/PartExt4/
          sudo mount -t auto /dev/sda2 /OpenWrt/PartExt4/

        ;;

        7)

          echo ""
          echo "  Descargando grub para efi..."
          echo ""
          sudo mkdir -p /OpenWrt/PartOVMF/EFI/Boot/ 2> /dev/null
          sudo wget http:///hacks4geeks.com/_/premium/descargas/OpenWrtX86/PartEFI/EFI/Boot/bootx64.efi -O /OpenWrt/PartOVMF/EFI/Boot/bootx64.efi

        ;;

        8)

          echo ""
          echo "  Creando el archivo de configuración para Grub (grub.cfg)..."
          echo ""
          sudo mkdir -p /OpenWrt/PartOVMF/EFI/OpenWrt/ 2> /dev/null
          sudo su -c "echo 'serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1 --rtscts=off'                                                 > /OpenWrt/PartOVMF/EFI/OpenWrt/grub.cfg"
          sudo su -c "echo 'terminal_input console serial; terminal_output console serial'                                                            >> /OpenWrt/PartOVMF/EFI/OpenWrt/grub.cfg"
          sudo su -c "echo ''                                                                                                                         >> /OpenWrt/PartOVMF/EFI/OpenWrt/grub.cfg"
          sudo su -c "echo 'set default="'"0"'"'                                                                                                      >> /OpenWrt/PartOVMF/EFI/OpenWrt/grub.cfg"
          sudo su -c "echo 'set timeout="'"1"'"'                                                                                                      >> /OpenWrt/PartOVMF/EFI/OpenWrt/grub.cfg"
          sudo su -c 'echo "set root='"'(hd0,2)'"'"                                                                                                     >> /OpenWrt/PartOVMF/EFI/OpenWrt/grub.cfg'
          sudo su -c "echo ''                                                                                                                         >> /OpenWrt/PartOVMF/EFI/OpenWrt/grub.cfg"
          sudo su -c "echo 'menuentry "'"OpenWrt"'" {'                                                                                                >> /OpenWrt/PartOVMF/EFI/OpenWrt/grub.cfg"
          sudo su -c "echo '  linux /boot/vmlinuz root=/dev/sda2 rootfstype=ext4 rootwait console=tty0 console=ttyS0,115200n8 noinitrd'               >> /OpenWrt/PartOVMF/EFI/OpenWrt/grub.cfg"
          sudo su -c "echo '}'                                                                                                                        >> /OpenWrt/PartOVMF/EFI/OpenWrt/grub.cfg"
          sudo su -c "echo 'menuentry "'"OpenWrt (failsafe)"'" {'                                                                                     >> /OpenWrt/PartOVMF/EFI/OpenWrt/grub.cfg"
          sudo su -c "echo '  linux /boot/vmlinuz failsafe=true root=/dev/sda2 rootfstype=ext4 rootwait console=tty0 console=ttyS0,115200n8 noinitrd' >> /OpenWrt/PartOVMF/EFI/OpenWrt/grub.cfg"
          sudo su -c "echo '}'                                                                                                                        >> /OpenWrt/PartOVMF/EFI/OpenWrt/grub.cfg"

        ;;

        9)

          echo ""
          echo " Creando la estructura de carpetas y archivos en la partición ext4 con OpenWrt $VersOpenWrt"
          echo ""
          echo ""
          echo "  Borrando el contenido de la partición ext4..."
          echo ""
          sudo rm -rf /OpenWrt/PartExt4/*

          echo ""
          echo "  Bajando y posicionando el Kernel..."
          echo ""
          sudo mkdir -p /OpenWrt/PartExt4/boot

          sudo wget --no-check-certificate https://downloads.openwrt.org/releases/$VersOpenWrt/targets/x86/64/openwrt-$VersOpenWrt-x86-64-vmlinuz -O /OpenWrt/PartExt4/boot/vmlinuz

          echo ""
          echo "Bajando el archivo con el sistema root..."
          echo ""
          rm -rf /OpenWrt/PartOVMF/rootfs.tar.gz
          sudo wget --no-check-certificate https://downloads.openwrt.org/releases/$VersOpenWrt/targets/x86/64/openwrt-$VersOpenWrt-x86-64-generic-rootfs.tar.gz -O /OpenWrt/PartOVMF/rootfs.tar.gz

          echo ""
          echo "Descomprimiendo el sistema de archivos root en la partición ext4..."
          echo ""

          ## Comprobar si el paquete tar está instalado. Si no lo está, instalarlo.
             if [[ $(dpkg-query -s tar 2>/dev/null | grep installed) == "" ]]; then
               echo ""
               echo "  tar no está instalado. Iniciando su instalación..."
               echo ""
               sudo apt-get -y update
               sudo apt-get -y install tar
               echo ""
             fi
          sudo tar -xf /OpenWrt/PartOVMF/rootfs.tar.gz -C /OpenWrt/PartExt4/

        ;;

        10)

          echo ""
          echo "  Configurando la MV de OpenWrt para que pille IP por DHCP"
          echo ""
          sudo mkdir /OpenWrt/PartOVMF/scripts/ 2> /dev/null
          sudo su -c 'echo "config interface loopback"       > /OpenWrt/PartOVMF/scripts/network'
          sudo su -c 'echo "  option ifname '"'lo'"'"         >> /OpenWrt/PartOVMF/scripts/network'
          sudo su -c 'echo "  option proto '"'static'"'"      >> /OpenWrt/PartOVMF/scripts/network'
          sudo su -c 'echo "  option ipaddr '"'127.0.0.1'"'"  >> /OpenWrt/PartOVMF/scripts/network'
          sudo su -c 'echo "  option netmask '"'255.0.0.0'"'" >> /OpenWrt/PartOVMF/scripts/network'
          sudo su -c 'echo ""                               >> /OpenWrt/PartOVMF/scripts/network'
          sudo su -c 'echo "config interface '"'WAN'"'"       >> /OpenWrt/PartOVMF/scripts/network'
          sudo su -c 'echo "  option ifname '"'eth0'"'"       >> /OpenWrt/PartOVMF/scripts/network'
          sudo su -c 'echo "  option proto '"'dhcp'"'"        >> /OpenWrt/PartOVMF/scripts/network'
          sudo rm -rf                               /OpenWrt/PartExt4/etc/config/network
          sudo cp /OpenWrt/PartOVMF/scripts/network /OpenWrt/PartExt4/etc/config/

        ;;

        11)

          echo ""
          echo "  Copiando el script de instalación de paquetes..."
          echo ""
          sudo mkdir -p /OpenWrt/PartOVMF/scripts/ 2> /dev/null
          sudo su -c "echo '#!/bin/sh'                                    > /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh"
          sudo su -c 'echo ""                                            >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "opkg update"                                 >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "opkg install nano"                           >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "opkg install mc"                             >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "opkg install pciutils"                       >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "opkg install wget"                           >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "opkg install git-http"                       >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "opkg install tcpdump"                        >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "opkg install msmtp"                          >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "opkg install ca-bundle"                      >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "opkg install ca-certificates"                >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "opkg install libustream-openssl"             >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "opkg install hostapd-openssl"                >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "opkg install kmod-mac80211"                  >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "opkg install kmod-ath"                       >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "opkg install kmod-ath9k"                     >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "opkg install kmod-ath10k-ct"                 >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "opkg install ath10k-firmware-qca9984-ct-htt" >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "opkg install luci-i18n-base-es"              >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "opkg install luci-i18n-firewall-es"          >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "opkg install luci-i18n-adblock-es"           >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "opkg install luci-i18n-qos-es"               >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "opkg install luci-i18n-wifischedule-es"      >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "opkg install luci-i18n-wireguard-es"         >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "opkg install luci-i18n-wol-es"               >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo ""                                            >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "rm -rf /root/scripts/1-InstalarPaquetes.sh"  >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo su -c 'echo "reboot"                                      >> /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh'
          sudo mkdir -p                                           /OpenWrt/PartExt4/root/scripts/
          sudo cp /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh /OpenWrt/PartExt4/root/scripts/1-InstalarPaquetes.sh
          sudo chmod +x                                           /OpenWrt/PartExt4/root/scripts/1-InstalarPaquetes.sh

        ;;

        12)

          echo ""
          echo "  Copiando el script de instalación de los o-scripts..."
          echo ""
          sudo mkdir -p                                                                                   /OpenWrt/PartOVMF/scripts/ 2> /dev/null
          sudo echo '#!/bin/sh'                                                                         > /OpenWrt/PartOVMF/scripts/2-InstalarOScripts.sh
          sudo echo ""                                                                                 >> /OpenWrt/PartOVMF/scripts/2-InstalarOScripts.sh
          sudo echo "rm /root/scripts/o-scripts -R 2> /dev/null"                                       >> /OpenWrt/PartOVMF/scripts/2-InstalarOScripts.sh
          sudo echo "mkdir /root/scripts 2> /dev/null"                                                 >> /OpenWrt/PartOVMF/scripts/2-InstalarOScripts.sh
          sudo echo "cd /root/scripts"                                                                 >> /OpenWrt/PartOVMF/scripts/2-InstalarOScripts.sh
          sudo echo "git clone --depth=1 https://github.com/nipegun/o-scripts"                         >> /OpenWrt/PartOVMF/scripts/2-InstalarOScripts.sh
          sudo echo "mkdir -p /root/scripts/o-scripts/Alias/"                                          >> /OpenWrt/PartOVMF/scripts/2-InstalarOScripts.sh
          sudo echo "rm /root/scripts/o-scripts/.git -R 2> /dev/null"                                  >> /OpenWrt/PartOVMF/scripts/2-InstalarOScripts.sh
          sudo echo 'find /root/scripts/o-scripts/ -type f -iname "*.sh" -exec chmod +x {} \;'         >> /OpenWrt/PartOVMF/scripts/2-InstalarOScripts.sh
          sudo echo "/root/scripts/o-scripts/OScripts-CrearAlias.sh"                                   >> /OpenWrt/PartOVMF/scripts/2-InstalarOScripts.sh
          sudo echo "find /root/scripts/o-scripts/Alias/ -type f -exec chmod +x {} \;"                 >> /OpenWrt/PartOVMF/scripts/2-InstalarOScripts.sh
          sudo echo ""                                                                                 >> /OpenWrt/PartOVMF/scripts/2-InstalarOScripts.sh
          sudo echo 'sh -c "echo 'export PATH=$PATH:/root/scripts/o-scripts/Alias/' >> /root/.bashrc"' >> /OpenWrt/PartOVMF/scripts/2-InstalarOScripts.sh
          sudo echo ""                                                                                 >> /OpenWrt/PartOVMF/scripts/2-InstalarOScripts.sh
          sudo echo "rm -rf /root/scripts/2-InstalarOScripts.sh"                                       >> /OpenWrt/PartOVMF/scripts/2-InstalarOScripts.sh
          sudo cp /OpenWrt/PartOVMF/scripts/2-InstalarOScripts.sh /OpenWrt/PartExt4/root/scripts/2-InstalarOScripts.sh
          sudo chmod +x                                           /OpenWrt/PartExt4/root/scripts/2-InstalarOScripts.sh

        ;;

        13)

          echo ""
          echo "  Copiando el script de preparación de OpenWrt para funcionar como una MV de Proxmox..."
          echo ""
          sudo mkdir -p                                                                            /OpenWrt/PartOVMF/scripts/ 2> /dev/null
          sudo echo '#!/bin/sh'                                                                  > /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo ""                                                                          >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "# Configurar red e interfaces"                                             >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "config interface 'loopback'"            > /etc/config/network"       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option ifname 'lo'"                  >> /etc/config/network"       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option proto 'static'"               >> /etc/config/network"       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option ipaddr '127.0.0.1'"           >> /etc/config/network"       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option netmask '255.0.0.0'"          >> /etc/config/network"       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo ""                                      >> /etc/config/network"       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "config interface 'WAN'"                >> /etc/config/network"       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option ifname 'eth0'"                >> /etc/config/network"       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option proto 'static'"               >> /etc/config/network"       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option gateway '192.168.0.1'"        >> /etc/config/network"       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option ipaddr '192.168.0.201'"       >> /etc/config/network"       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option netmask '255.255.255.0'"      >> /etc/config/network"       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  list dns '1.1.1.1'"                  >> /etc/config/network"       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo ""                                      >> /etc/config/network"       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "config interface 'LAN'"                >> /etc/config/network"       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option type 'bridge'"                >> /etc/config/network"       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option ifname 'eth1 eth2 eth3 eth4'" >> /etc/config/network"       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option proto 'static'"               >> /etc/config/network"       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option ipaddr '192.168.1.1'"         >> /etc/config/network"       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option netmask '255.255.255.0'"      >> /etc/config/network"       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  list dns '1.1.1.1'"                  >> /etc/config/network"       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option delegate '0'"                 >> /etc/config/network"       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option force_link '0'"               >> /etc/config/network"       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo ""                                                                          >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "# Permitir SSH desde WAN"                                                  >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "config rule"                    >> /etc/config/firewall"             >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option name 'Allow-SSH-WAN'"  >> /etc/config/firewall"             >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option target 'ACCEPT'"       >> /etc/config/firewall"             >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  list proto 'tcp'"             >> /etc/config/firewall"             >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option dest_port '22'"        >> /etc/config/firewall"             >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option src 'wan'"             >> /etc/config/firewall"             >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo ""                                                                          >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "# Permitir LUCI desde WAN"                                                 >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "config rule"                    >> /etc/config/firewall"             >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option name 'Allow-LUCI-WAN'" >> /etc/config/firewall"             >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option target 'ACCEPT'"       >> /etc/config/firewall"             >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  list proto 'tcp'"             >> /etc/config/firewall"             >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option dest_port '80'"        >> /etc/config/firewall"             >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option src 'wan'"             >> /etc/config/firewall"             >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo ""                                                                          >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "# Adblock"                                                                 >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "mkdir -p /root/logs/dns/"                                                  >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "config adblock 'global'"                      > /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option adb_dnsfilereset '0'"               >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option adb_backup '1'"                     >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option adb_maxqueue '4'"                   >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option adb_dns 'dnsmasq'"                  >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option adb_fetchutil 'uclient-fetch'"      >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option adb_report '1'"                     >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option adb_mail '1'"                       >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option adb_mailreceiver 'mail@gmail.com'"  >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option adb_dnsflush '1'"                   >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option adb_mailtopic 'AdBlock de OpenWrt'" >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option adb_debug '1'"                      >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option adb_forcedns '1'"                   >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  list adb_sources 'adaway'"                 >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  list adb_sources 'adguard'"                >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  list adb_sources 'android_tracking'"       >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  list adb_sources 'anti_ad'"                >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  list adb_sources 'disconnect'"             >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  list adb_sources 'firetv_tracking'"        >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  list adb_sources 'malwaredomains'"         >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  list adb_sources 'malwarelist'"            >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  list adb_sources 'notracking'"             >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  list adb_sources 'openphish'"              >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  list adb_sources 'phishing_army'"          >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  list adb_sources 'spam404'"                >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  list adb_sources 'stopforumspam'"          >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  list adb_sources 'whocares'"               >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  list adb_safesearch '0'"                   >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  list adb_reportdir '/root/logs/dns'"       >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  list adb_repiface 'br-LAN'"                >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  list adb_enabled '1'"                      >> /etc/config/adblock" >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo ""                                                                          >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "# DHCP en LAN"                                                             >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "config dhcp 'LAN'"        >> /etc/config/dhcp"                       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option start '100'"     >> /etc/config/dhcp"                       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option leasetime '12h'" >> /etc/config/dhcp"                       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option interface 'LAN'" >> /etc/config/dhcp"                       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "echo "  option limit '199'"     >> /etc/config/dhcp"                       >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo ""                                                                          >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "rm -rf /root/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh"                  >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo ""                                                                          >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo echo "poweroff"                                                                  >> /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo cp /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh /OpenWrt/PartExt4/root/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
          sudo chmod +x                                                         /OpenWrt/PartExt4/root/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh

        ;;

        14)

          echo ""
          echo "  Moviendo copia de seguridad de la instalación anterior a la instalación nueva..."
          echo ""

        ;;

      esac

done

echo ""
echo "Ejecución del script, finalizada."
echo ""
echo "Reinicia el sistema con:"
echo "sudo shutdown -r now"
echo ""
echo "Recuerda quitar el DVD de la unidad antes de que vuelve a arrancar la máquina virtual."
echo ""

