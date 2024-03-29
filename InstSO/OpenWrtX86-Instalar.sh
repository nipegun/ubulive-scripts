#!/bin/bash

# Pongo a disposición pública este script bajo el término de "software de dominio público".
# Puedes hacer lo que quieras con él porque es libre de verdad; no libre con condiciones como las licencias GNU y otras patrañas similares.
# Si se te llena la boca hablando de libertad entonces hazlo realmente libre.
# No tienes que aceptar ningún tipo de términos de uso o licencia para utilizarlo o modificarlo porque va sin CopyLeft.

# ----------
# Script de NiPeGun para instalar OpenWrt en una máquina virtual de ProxmoxVE inciando desde Ubuntu Live 
#
# Ejecución remota:
#   Para sistema con discos sata:
#     curl -sL https://raw.githubusercontent.com/nipegun/ubulive-scripts/main/InstSO/OpenWrtX86-Instalar.sh | bash
#  Para sistemas con discos virtio:
#     curl -sL https://raw.githubusercontent.com/nipegun/ubulive-scripts/main/InstSO/OpenWrtX86-Instalar.sh | sed 's-/dev/sda-/dev/vda-g' | bash
# ----------

vNumUltVer=$(curl -sL openwrt.org | grep urrent | grep "stable" | grep ":" | cut -d":" -f2 | cut -d"." -f1 | sed 's- --g' | cut -d"t" -f2)
#vNumUltVer="22"

vFechaDeEjec=$(date +A%Y-M%m-D%d@%T)
vPrimerDisco="/dev/sda"

# Declaración de las variables de color
  vColorAzul="\033[0;34m"
  vColorAzulClaro="\033[1;34m"
  vColorVerde='\033[1;32m'
  vColorRojo='\033[1;31m'
  vFinColor='\033[0m'

echo ""
echo -e "${vColorAzulClaro}  Iniciando el script de instalación de OpenWrt X86 para máquinas virtuales de Proxmox...${vFinColor}"
echo ""

# Desactivar toda la swap
  sudo swapoff -a

# Comprobar si el paquete dialog está instalado. Si no lo está, instalarlo.
  if [[ $(dpkg-query -s dialog 2>/dev/null | grep installed) == "" ]]; then
    echo ""
    echo -e "${vColorRojo}    El paquete dialog no está instalado. Iniciando su instalación...${vFinColor}"
    echo ""
    sudo sed -i -e 's|main restricted|main universe restricted|g' /etc/apt/sources.list
    sudo apt-get -y update
    sudo apt-get -y install dialog
    echo ""
  fi

  # Cambiar resolución de la pantalla
    vNombreDisplay=$(xrandr | grep " connected" | cut -d" " -f1)
    xrandr --output $vNombreDisplay --mode 1024x768

menu=(dialog --checklist "Instalación de OpenWrt X86:" 30 100 20)
  opciones=(
     1 "Hacer copia de seguridad de la instalación anterior" on
     2 "Crear las particiones" on
     3 "Formatear las particiones" on
     4 "Marcar la partición EFI como esp" on
     5 "Determinar la última versión de OpenWrt" on
     6 "Montar las particiones" on
     7 "Descargar Grub para EFI" on
     8 "Crear el archivo de configuración para Grub" on
     9 "Crear la estructura de carpetas y archivos en ext4" on
    10 "Configurar OpenWrt para que pille IP WAN mediante DHCP" on
    11 "Copiar el script de instalación de paquetes" on
    12 "Copiar el script de instalación de los o-scripts" on
    13 "Copiar el script de preparación de OpenWrt para funcionar como una MV de Proxmox" on
    14 "Copiar el script de preparación de OpenWrt para funcionar como router Baremetal" on
    15 "Mover copia de seguridad de la instalación anterior a la nueva instalación" on
    16 "Descargar paquetes ipk esenciales a la partición EFI" on
    17 "Instalar GPartEd y Midnight Commander para poder visualizar los cambios realizados" on
    18 "Apagar la máquina virtual" off
  )
  choices=$("${menu[@]}" "${opciones[@]}" 2>&1 >/dev/tty)

  for choice in $choices
    do
      case $choice in

        1)

          echo ""
          echo "  Haciendo copia de seguridad de la instalación anterior..."
          echo ""
          # Desmontar discos, si es que están montados
            sudo umount $vPrimerDisco"1" 2> /dev/null
            sudo umount $vPrimerDisco"2" 2> /dev/null
            sudo umount $vPrimerDisco"3" 2> /dev/null
          # Crear particiones para montar
            sudo mkdir -p /OpenWrt/PartEFI/
            sudo mount -t auto $vPrimerDisco"1" /OpenWrt/PartEFI/
            sudo mkdir -p /OpenWrt/PartExt4/
            sudo mount -t auto $vPrimerDisco"2" /OpenWrt/PartExt4/
          # Crear carpeta donde guardar los archivos
            sudo mkdir -p /CopSegOpenWrt/$vFechaDeEjec/PartEFI/
            sudo mkdir -p /CopSegOpenWrt/$vFechaDeEjec/PartExt4/
          # Copiar archivos
            sudo cp -r /OpenWrt/PartEFI/* /CopSegOpenWrt/$vFechaDeEjec/PartEFI/
            sudo cp -r /OpenWrt/PartExt4/* /CopSegOpenWrt/$vFechaDeEjec/PartExt4/
          # Desmontar partición 
            sudo umount /OpenWrt/PartEFI/
            sudo rm -rf  /OpenWrt/PartEFI/
            sudo umount /OpenWrt/PartExt4/
            sudo rm -rf  /OpenWrt/PartEFI/

        ;;

        2)

          echo ""
          echo "  Creando las particiones..."
          echo ""
          sudo rm -rf /OpenWrt/PartEFI/*
          sudo rm -rf /OpenWrt/PartExt4/*
          sudo umount $vPrimerDisco"1" 2> /dev/null
          sudo umount $vPrimerDisco"2" 2> /dev/null
          sudo umount $vPrimerDisco"3" 2> /dev/null
          sudo swapoff -a
          # Crear tabla de particiones GPT
            sudo parted -s $vPrimerDisco mklabel gpt
          # Crear la partición EFI
            sudo parted -s $vPrimerDisco mkpart EFI ext4 1MiB 1024MiB
          # Crear la partición ext4
            sudo parted -s $vPrimerDisco mkpart OpenWrt ext4 1025MiB 28000MiB
          # Crear la partición de intercambio
            sudo parted -s $vPrimerDisco mkpart Intercambio ext4 28001MiB 100%

        ;;

        3)

          echo ""
          echo "  Formateando las particiones..."
          echo ""
          # Formatear la partición para EFI como fat32
            sudo mkfs -t vfat -F 32 -n EFI $vPrimerDisco"1"
          # Formatear la partición para OpenWrt como ext4
            sudo mkfs -t ext4 -L OpenWrt $vPrimerDisco"2"
          # Formatear la partición para Intercambio como swap
            sudo mkswap -L Intercambio $vPrimerDisco"3"

        ;;

        4)

          echo ""
          echo "  Marcando la partición EFI como esp..."
          echo ""
          sudo parted -s $vPrimerDisco set 1 esp on

        ;;

        5)

          echo ""
          echo "  Determinando la última versión de OpenWrt..."
          echo ""

          # Comprobar si el paquete curl está instalado. Si no lo está, instalarlo.
            if [[ $(dpkg-query -s curl 2>/dev/null | grep installed) == "" ]]; then
              echo ""
              echo "    El paquete curl no está instalado. Iniciando su instalación..."
              echo ""
              sudo apt-get -y update
              sudo apt-get -y install curl
              echo ""
            fi
  
          vUltVersOpenWrtX86Estable=$(curl -sL https://downloads.openwrt.org | grep eleases | grep -v rchive | grep -v rc | head -n1 | cut -d'"' -f2 | cut -d'/' -f2)

          echo ""
          echo "    La última versión estable de OpenWrt es la $vUltVersOpenWrtX86Estable."
          echo ""

        ;;

        6)

          echo ""
          echo "  Montando las particiones..."
          echo ""
          sudo mkdir -p /OpenWrt/PartEFI/ 2> /dev/null
          sudo mount -t auto /dev/sda1 /OpenWrt/PartEFI/
          sudo mkdir -p /OpenWrt/PartExt4/ 2> /dev/null
          sudo mount -t auto /dev/sda2 /OpenWrt/PartExt4/

        ;;

        7)

          echo ""
          echo "  Descargando grub para efi..."
          echo ""
          sudo mkdir -p /OpenWrt/PartEFI/EFI/Boot/ 2> /dev/null
          rm -rf /OpenWrt/PartEFI/EFI/Boot/*
          # Comprobar si el paquete wget está instalado. Si no lo está, instalarlo.
            if [[ $(dpkg-query -s wget 2>/dev/null | grep installed) == "" ]]; then
              echo ""
              echo "    El paquete wget no está instalado. Iniciando su instalación..."
              echo ""
              sudo apt-get -y update
              sudo apt-get -y install wget
              echo ""
            fi
          # sudo wget http://hacks4geeks.com/_/premium/descargas/OpenWrtX86/PartEFI/EFI/Boot/bootx64.efi -O /OpenWrt/PartEFI/EFI/Boot/bootx64.efi
          sudo wget https://github.com/nipegun/o-scripts/raw/master/Recursos/PartEFI/efi/boot/bootx64.efi -O /OpenWrt/PartEFI/EFI/Boot/bootx64.efi
                    
        ;;

        8)

          echo ""
          echo "  Creando el archivo de configuración para Grub (grub.cfg)..."
          echo ""
          sudo mkdir -p /OpenWrt/PartEFI/EFI/OpenWrt/ 2> /dev/null
          sudo su -c "echo 'serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1 --rtscts=off'                                                            > /OpenWrt/PartEFI/EFI/OpenWrt/grub.cfg"
          sudo su -c "echo 'terminal_input console serial; terminal_output console serial'                                                                       >> /OpenWrt/PartEFI/EFI/OpenWrt/grub.cfg"
          sudo su -c "echo ''                                                                                                                                    >> /OpenWrt/PartEFI/EFI/OpenWrt/grub.cfg"
          sudo su -c "echo 'set default="'"0"'"'                                                                                                                 >> /OpenWrt/PartEFI/EFI/OpenWrt/grub.cfg"
          sudo su -c "echo 'set timeout="'"1"'"'                                                                                                                 >> /OpenWrt/PartEFI/EFI/OpenWrt/grub.cfg"
          sudo su -c "echo ''                                                                                                                                    >> /OpenWrt/PartEFI/EFI/OpenWrt/grub.cfg"
          sudo su -c "echo 'menuentry "'"OpenWrt"'" {'                                                                                                           >> /OpenWrt/PartEFI/EFI/OpenWrt/grub.cfg"
          sudo su -c 'echo "  set root='"'(hd0,2)'"'"                                                                                                            >> /OpenWrt/PartEFI/EFI/OpenWrt/grub.cfg'
          sudo su -c "echo '  linux /boot/generic-kernel.bin root=/dev/sda2 rootfstype=ext4 rootwait console=tty0 console=ttyS0,115200n8 noinitrd'               >> /OpenWrt/PartEFI/EFI/OpenWrt/grub.cfg"
          sudo su -c "echo '}'                                                                                                                                   >> /OpenWrt/PartEFI/EFI/OpenWrt/grub.cfg"
          sudo su -c "echo 'menuentry "'"OpenWrt (failsafe)"'" {'                                                                                                >> /OpenWrt/PartEFI/EFI/OpenWrt/grub.cfg"
          sudo su -c 'echo "  set root='"'(hd0,2)'"'"                                                                                                            >> /OpenWrt/PartEFI/EFI/OpenWrt/grub.cfg'
          sudo su -c "echo '  linux /boot/generic-kernel.bin failsafe=true root=/dev/sda2 rootfstype=ext4 rootwait console=tty0 console=ttyS0,115200n8 noinitrd' >> /OpenWrt/PartEFI/EFI/OpenWrt/grub.cfg"
          sudo su -c "echo '}'                                                                                                                                   >> /OpenWrt/PartEFI/EFI/OpenWrt/grub.cfg"

        ;;

        9)

          echo ""
          echo "  Creando la estructura de carpetas y archivos en la partición ext4 con OpenWrt $vUltVersOpenWrtX86Estable..."
          echo ""
          echo ""
          echo "    Borrando el contenido de la partición ext4..."
          echo ""
          sudo rm -rf /OpenWrt/PartExt4/*

          echo ""
          echo "    Bajando y posicionando el Kernel..."
          echo ""
          sudo mkdir -p /OpenWrt/PartExt4/boot 2> /dev/null
          # Comprobar si el paquete wget está instalado. Si no lo está, instalarlo.
            if [[ $(dpkg-query -s wget 2>/dev/null | grep installed) == "" ]]; then
              echo ""
              echo "      El paquete wget no está instalado. Iniciando su instalación..."
              echo ""
              sudo apt-get -y update
              sudo apt-get -y install wget
              echo ""
            fi
          sudo wget --no-check-certificate https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/targets/x86/64/openwrt-$vUltVersOpenWrtX86Estable-x86-64-generic-kernel.bin -O /OpenWrt/PartExt4/boot/generic-kernel.bin

          echo ""
          echo "    Bajando el archivo con el sistema root..."
          echo ""
          sudo rm -rf /OpenWrt/PartEFI/rootfs.tar.gz
          sudo wget --no-check-certificate https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/targets/x86/64/openwrt-$vUltVersOpenWrtX86Estable-x86-64-rootfs.tar.gz -O /OpenWrt/PartEFI/rootfs.tar.gz

          echo ""
          echo "    Descomprimiendo el sistema de archivos root en la partición ext4..."
          echo ""

          # Comprobar si el paquete tar está instalado. Si no lo está, instalarlo.
            if [[ $(dpkg-query -s tar 2>/dev/null | grep installed) == "" ]]; then
              echo ""
              echo "      El paquete tar no está instalado. Iniciando su instalación..."
              echo ""
              sudo apt-get -y update
              sudo apt-get -y install tar
              echo ""
            fi
          sudo tar -xf /OpenWrt/PartEFI/rootfs.tar.gz -C /OpenWrt/PartExt4/

        ;;

        10)

          echo ""
          echo "  Configurando OpenWrt para que pille IP WAN mediante DHCP..."
          echo ""
          sudo mkdir /OpenWrt/PartEFI/scripts/ 2> /dev/null
          sudo su -c 'echo "config interface '"'loopback'"'"   > /OpenWrt/PartEFI/scripts/network'
          sudo su -c 'echo "  option device '"'lo'"'"         >> /OpenWrt/PartEFI/scripts/network'
          sudo su -c 'echo "  option proto '"'static'"'"      >> /OpenWrt/PartEFI/scripts/network'
          sudo su -c 'echo "  option ipaddr '"'127.0.0.1'"'"  >> /OpenWrt/PartEFI/scripts/network'
          sudo su -c 'echo "  option netmask '"'255.0.0.0'"'" >> /OpenWrt/PartEFI/scripts/network'
          sudo su -c 'echo ""                                 >> /OpenWrt/PartEFI/scripts/network'
          sudo su -c 'echo "config device"                    >> /OpenWrt/PartEFI/scripts/network'
          sudo su -c 'echo "  option name '"'br-wan'"'"       >> /OpenWrt/PartEFI/scripts/network'
          sudo su -c 'echo "  option type '"'bridge'"'"       >> /OpenWrt/PartEFI/scripts/network'
          sudo su -c 'echo "  list ports '"'eth0'"'"          >> /OpenWrt/PartEFI/scripts/network'
          sudo su -c 'echo ""                                 >> /OpenWrt/PartEFI/scripts/network'
          sudo su -c 'echo "config interface '"'wan'"'"       >> /OpenWrt/PartEFI/scripts/network'
          sudo su -c 'echo "  option device '"'br-wan'"'"     >> /OpenWrt/PartEFI/scripts/network'
	  sudo su -c 'echo "  option proto '"'dhcp'"'"        >> /OpenWrt/PartEFI/scripts/network'
          sudo su -c 'echo "  option hostname '"'*'"'"        >> /OpenWrt/PartEFI/scripts/network'
          sudo su -c 'echo "  option delegate '"'0'"'"        >> /OpenWrt/PartEFI/scripts/network'
          sudo su -c 'echo "  option peerdns '"'0'"'"         >> /OpenWrt/PartEFI/scripts/network'
          sudo su -c 'echo "  list dns '"'9.9.9.9'"'"         >> /OpenWrt/PartEFI/scripts/network'
          sudo su -c 'echo "  list dns '"'149.112.112.112'"'" >> /OpenWrt/PartEFI/scripts/network'
          sudo rm -f                               /OpenWrt/PartExt4/etc/config/network
          sudo cp /OpenWrt/PartEFI/scripts/network /OpenWrt/PartExt4/etc/config/
          sudo rm -rf /OpenWrt/PartEFI/scripts/

        ;;

        11)

          echo ""
          echo "  Copiando el script de instalación de paquetes..."
          echo ""
          sudo mkdir -p /OpenWrt/PartExt4/root/scripts/ 2> /dev/null
          # Comprobar si el paquete wget está instalado. Si no lo está, instalarlo.
            if [[ $(dpkg-query -s wget 2>/dev/null | grep installed) == "" ]]; then
              echo ""
              echo "  wget no está instalado. Iniciando su instalación..."
              echo ""
              sudo apt-get -y update
              sudo apt-get -y install wget
              echo ""
            fi
          sudo su -c "wget https://raw.githubusercontent.com/nipegun/o-scripts/master/PostInst/MVdeProxmox-InstalarPaquetes.sh -O /OpenWrt/PartExt4/root/scripts/1-InstalarPaquetes.sh"
          echo "rm -rf /root/scripts/1-InstalarPaquetes.sh"                                                                    >> /OpenWrt/PartExt4/root/scripts/1-InstalarPaquetes.sh
          echo "reboot"                                                                                                        >> /OpenWrt/PartExt4/root/scripts/1-InstalarPaquetes.sh
          sudo chmod +x                                                                                                           /OpenWrt/PartExt4/root/scripts/1-InstalarPaquetes.sh

        ;;

        12)

          echo ""
          echo "  Copiando el script de instalación de los o-scripts..."
          echo ""
          sudo su -c "echo '#!/bin/sh'                                                                                       > /OpenWrt/PartExt4/root/scripts/2-InstalarOScripts.sh"
          sudo su -c 'echo ""                                                                                               >> /OpenWrt/PartExt4/root/scripts/2-InstalarOScripts.sh'
          sudo su -c 'echo "wget -O - https://raw.githubusercontent.com/nipegun/o-scripts/master/OScripts-Instalar.sh | sh" >> /OpenWrt/PartExt4/root/scripts/2-InstalarOScripts.sh'
          sudo su -c 'echo "rm -rf /root/scripts/2-InstalarOScripts.sh"                                                     >> /OpenWrt/PartExt4/root/scripts/2-InstalarOScripts.sh'
          sudo chmod +x                                                                                                        /OpenWrt/PartExt4/root/scripts/2-InstalarOScripts.sh

        ;;

        13)

          echo ""
          echo "  Copiando el script de preparación de OpenWrt para funcionar como una MV de Proxmox..."
          echo ""
          # Comprobar si el paquete wget está instalado. Si no lo está, instalarlo.
            if [[ $(dpkg-query -s wget 2>/dev/null | grep installed) == "" ]]; then
              echo ""
              echo "  wget no está instalado. Iniciando su instalación..."
              echo ""
              sudo apt-get -y update
              sudo apt-get -y install wget
              echo ""
            fi
          sudo wget https://raw.githubusercontent.com/nipegun/o-scripts/master/PostInst/ConfigurarComo-MVdeProxmox.sh -O /OpenWrt/PartExt4/root/scripts/3-ConfigurarComo-MVdeProxmox.sh
          sudo chmod +x                                                                                                  /OpenWrt/PartExt4/root/scripts/3-ConfigurarComo-MVdeProxmox.sh

        ;;

        14)

          echo ""
          echo "  Copiando el script de preparación de OpenWrt para funcionar como router baremetal..."
          echo ""
          # Comprobar si el paquete wget está instalado. Si no lo está, instalarlo.
            if [[ $(dpkg-query -s wget 2>/dev/null | grep installed) == "" ]]; then
              echo ""
              echo "  wget no está instalado. Iniciando su instalación..."
              echo ""
              sudo apt-get -y update
              sudo apt-get -y install wget
              echo ""
            fi
          sudo wget https://raw.githubusercontent.com/nipegun/o-scripts/master/PostInst/ConfigurarComo-RouterBaremetal.sh -O /OpenWrt/PartExt4/root/scripts/3-ConfigurarComo-RouterBaremetal.sh
          sudo chmod +x                                                                                                      /OpenWrt/PartExt4/root/scripts/3-ConfigurarComo-RouterBaremetal.sh

        ;;

        15)

          echo ""
          echo "  Moviendo copia de seguridad de la instalación anterior a la instalación nueva..."
          echo ""
          # Crear carpeta en la nueva partición
          sudo mkdir -p /OpenWrt/PartExt4/CopSeg/
          # Mover archivos
            sudo mv /CopSegOpenWrt/$vFechaDeEjec/ /OpenWrt/PartExt4/CopSeg/
          # Borrar carpeta de copia de seguridad de la partición de Debian Live
            sudo rm -rf  /CopSegOpenWrt/
        ;;

        16)

          echo ""
          echo "  Descargando paquetes ipk esenciales a la partición EFI..."
          echo ""
          # Crear carpeta en la nueva partición
            sudo mkdir -p /OpenWrt/PartEFI/Paquetes/
          # Descargar paquetes
	    # lspci (Por orden de dependencias)
              sudo mkdir -p /OpenWrt/PartEFI/Paquetes/lspci/
              cd /OpenWrt/PartEFI/Paquetes/lspci/
	      # libc
                vNomArchivo=$(curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/base/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep libc)
                wget --no-check-certificate https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/base/$vNomArchivo
              # zlib
                vNomArchivo=$(curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/base/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep zlib | grep -v dev)
                wget --no-check-certificate https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/base/$vNomArchivo
	      # libkmod
                vNomArchivo=$(curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep libkmod)
                wget --no-check-certificate https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/packages/$vNomArchivo
	      # libgcc1
                vNomArchivo=$(curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/targets/x86/64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep libgcc1)
                wget --no-check-certificate https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/targets/x86/64/packages/$vNomArchivo
	      # libpthread
                vNomArchivo=$(curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/targets/x86/64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep libpthread)
	        wget --no-check-certificate https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/targets/x86/64/packages/$vNomArchivo
              # librt
	        vNomArchivo=$(curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/targets/x86/64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep librt)
	        wget --no-check-certificate https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/targets/x86/64/packages/$vNomArchivo
              # libpci
	        vNomArchivo=$(curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep libpci | grep -v acc)
	        wget --no-check-certificate https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/packages/$vNomArchivo
	      # pciids
                vNomArchivo=$(curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep pciids)
		wget --no-check-certificate https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/packages/$vNomArchivo
	      # pciutils
                vNomArchivo=$(curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep pciutils)
                wget --no-check-certificate https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/packages/$vNomArchivo

	    # Ethernet

              # Intel I219-V (Por orden de dependencias)
                sudo mkdir -p /OpenWrt/PartEFI/Paquetes/Ethernet-Intel-I219-V/
                cd /OpenWrt/PartEFI/Paquetes/Ethernet-Intel-I219-V/
		# kmod-pps
                  vNomArchivo=$(curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/targets/x86/64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep kmod-pps | grep -v gpio | grep -v disc)
	          wget --no-check-certificate https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/targets/x86/64/packages/$vNomArchivo
		# kmod-ptp
                  vNomArchivo=$(curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/targets/x86/64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep kmod-ptp | grep -v gpio | grep -v disc)
	          wget --no-check-certificate https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/targets/x86/64/packages/$vNomArchivo
	        # kmod-e1000e
	          vNomArchivo=$(curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/targets/x86/64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep kmod-e1000e)
	          wget --no-check-certificate https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/targets/x86/64/packages/$vNomArchivo
              # Intel I225-V (Por orden de dependencias)
                sudo mkdir -p /OpenWrt/PartEFI/Paquetes/Ethernet-Intel-I225-V/
                cd /OpenWrt/PartEFI/Paquetes/Ethernet-Intel-I225-V/
		# kmod-igc
                  vNomArchivo=$(curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/targets/x86/64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep kmod-igc)
	          wget --no-check-certificate https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/targets/x86/64/packages/$vNomArchivo
	      # Realtek RTL8125 (Por orden de dependencias)
                sudo mkdir -p /OpenWrt/PartEFI/Paquetes/Ethernet-Realtek-RTL8125/
                cd /OpenWrt/PartEFI/Paquetes/Ethernet-Realtek-RTL8125/
		# kmod-r8169
                  vNomArchivo=$(curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/targets/x86/64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep kmod-r8169)
	          wget --no-check-certificate https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/targets/x86/64/packages/$vNomArchivo

	    # Wireless

              # Mediatek MT7915E (Por orden de dependencias)
                sudo mkdir -p /OpenWrt/PartEFI/Paquetes/Wireless-Mediatek-MT7915E/
                cd /OpenWrt/PartEFI/Paquetes/Wireless-Mediatek-MT7915E/
		# kmod-mt7915-firmware
                  vNomArchivo=$(curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/targets/x86/64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep kmod-mt7915-firmware)
	          wget --no-check-certificate https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/targets/x86/64/packages/$vNomArchivo
		# kmod-mt7915e
                  vNomArchivo=$(curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/targets/x86/64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep kmod-mt7915e)
	          wget --no-check-certificate https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/targets/x86/64/packages/$vNomArchivo
    
	      vKMOD-IGB=$()
                   curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/base/     | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep hostapd-openssl

              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/base/     | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep hostapd-openssl
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/base/     | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep hostapd-common
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep kmod-cfg80211
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep kmod-mac80211
            # Driver WiFi
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep kmod-ath9k
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep kmod-ath10k-ct
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/base/     | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep ath10k-firmware-qca9984-ct-htt
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep kmod-ath
            # SFP
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep kmod-sfp
            # USB 2
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep kmod-usb2
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep kmod-usb-core
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep kmod-usb-ehci
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep kmod-usb-ohci
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep usbutils
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep usbids
            # USB 3
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep kmod-usb3
            # NVMe
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep kmod-nvme
	    # PCI
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep pciutils
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep pciids
            # Software
              # Herramientas para terminal (mandatorias para el funcionamiento del sistema)
                curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/      | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep base-files
                curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/base/   | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep uci
                curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/base/   | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep opkg
                curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/      | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep dropbear
            # Herramientas para terminal (extra)
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep mc
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep nano
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep curl
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep git
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/base/     | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep hwclock
            # Web
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/luci/     | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/luci/     | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-i18n-base-es
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep adblock
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/luci/     | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-app-adblock
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/luci/     | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-i18n-adblock-es
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/base/     | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep tcpdump-mini
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep msmtp
            # DDNS
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep ddns-scripts
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep ddns-scripts-services
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/luci/     | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-app-ddns
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/luci/     | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-i18n-ddns-es
            # Cortafuegos
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/base/     | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep firewall4
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/luci/     | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-app-firewall
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/luci/     | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-i18n-firewall-es
	    # OPKG
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/base/     | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep opkg
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/luci/     | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-app-opkg
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/luci/     | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-i18n-opkg-es
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/luci/     | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-app-upnp
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/luci/     | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-i18n-upnp-es
            # Programación Wifi
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep wifischedule
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/luci/     | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-app-wifischedule
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/luci/     | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-i18n-wifischedule-es
            # Wake on LAN
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/luci/     | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-app-wol
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/packages/ | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep etherwake
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/luci/     | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-i18n-wol-es
            # VPN
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep kmod-wireguard
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep wireguard-tools
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-proto-wireguard
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-app-wireguard
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-i18n-wireguard-es
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep qrencode
            # Acceso a volúmenes
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep e2fsprogs
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep f2fsck
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep fstools
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep blkid
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep dosfstools
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep fdisk
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep kmod-fs-vfat
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep kmod-usb-storage
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep parted
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep nand-utils
            # Otros
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-i18n-adblock-es
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-i18n-base-es
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-i18n-firewall-es
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-i18n-opkg-es
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-i18n-upnp-es
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-i18n-wifischedule-es
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-i18n-wol-es

              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep parted
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep pciids
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep pciutils
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep wifischedule

              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep fdisk
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep fstools

              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep hwclock
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep kmod-fs-vfat
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep kmod-usb-storage
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-app-adblock
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-app-firewall
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-app-opkg
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-app-upnp
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-app-wifischedule
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-app-wol
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-i18n-adblock-es
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-i18n-base-es
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-i18n-firewall-es
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-i18n-opkg-es
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-i18n-upnp-es
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-i18n-wifischedule-es
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/x/        | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep luci-i18n-wol-es
              curl -sL https://downloads.openwrt.org/releases/$vUltVersOpenWrtX86Estable/packages/x86_64/luci/     | sed 's|>|>\n|g' | grep href | cut -d'"' -f2 | grep curl

           # https://downloads.openwrt.org/releases/22.03.5/packages/x86_64/

        ;;

        17)

          echo ""
          echo "  Instalando Midnight Commander para poder visualizar los cambios realizados..."
          echo ""
          sudo apt-get -y install mc
          sudo apt-get -y install gparted

        ;;

        18)

          echo ""
          echo "  Apagando la máquina virtual..."
          echo ""
          #eject
          sudo shutdown -h now

        ;;

      esac

done

echo ""
echo " ----------"
echo "  Ejecución del script, finalizada."
echo ""
echo "  Reinicia el sistema con:"
echo "  sudo shutdown -r now"
echo ""
echo "  Recuerda quitar el DVD de la unidad antes de que vuelva a arrancar la máquina virtual."
echo " ----------"
echo ""

