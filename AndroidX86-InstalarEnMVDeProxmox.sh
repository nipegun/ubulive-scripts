#!/bin/bash

# Pongo a disposición pública este script bajo el término de "software de dominio público".
# Puedes hacer lo que quieras con él porque es libre de verdad; no libre con condiciones como las licencias GNU y otras patrañas similares.
# Si se te llena la boca hablando de libertad entonces hazlo realmente libre.
# No tienes que aceptar ningún tipo de términos de uso o licencia para utilizarlo o modificarlo porque va sin CopyLeft.

#----------------------------------------------------------------------------------------------------------------------
#  Script de NiPeGun para instalar AndroidX86 en una máquina virtual de ProxmoxVE inciando desde Ubuntu Live 
#
# Ejecución remota:
# curl -s https://raw.githubusercontent.com/nipegun/ubulive-scripts/main/AndroidX86-InstalarEnMVDeProxmox.sh | bash
#----------------------------------------------------------------------------------------------------------------------

ColorVerde="\033[1;32m"
FinColor="\033[0m"

PrimerDisco="/dev/sda"
VersAndX86="9.0"

echo ""
echo -e "${ColorVerde}  Iniciando el script de instalación de AndroidX86 para máquinas virtuales de Proxmox...${FinColor}"
echo ""

sudo sed -i -e 's|main restricted|main universe restricted|g' /etc/apt/sources.list

## Comprobar si el paquete dialog está instalado. Si no lo está, instalarlo.
   if [[ $(dpkg-query -s dialog 2>/dev/null | grep installed) == "" ]]; then
     echo ""
     echo "  dialog no está instalado. Iniciando su instalación..."
     echo ""
     sudo apt-get -y update
     sudo apt-get -y install dialog
     echo ""
   fi

menu=(dialog --timeout 5 --checklist "Instalación de AndroidX86:" 22 94 16)
  opciones=(
     1 "Hacer copia de seguridad de la instalación anterior" off
     2 "Crear las particiones" on
     3 "Formatear las particiones" on
     4 "Marcar la partición OVMF como esp" on
     5 "Montar las particiones" on
     6 "Determinar la última versión de AndroidX86" on
     7 "Descargar la última versión de AndroidX86" on
     8 "Preparar los archivos de la particion ext4" on
     9 "Preparando los archivos de la particion EFI (Grub y otros)" on
    10 "Borrando archivos sobrantes" on
    11 "" off
  )
  choices=$("${menu[@]}" "${opciones[@]}" 2>&1 >/dev/tty)
  clear

  for choice in $choices
    do
      case $choice in

        1)

          echo ""
          echo "  Haciendo copia de seguridad de la instalación anterior..."
          echo ""
          sudo apt-get -y update
          sudo apt-get -y install mc
          sudo mkdir -p /AndroidX86/PartOVMF/
          sudo mount -t auto $PrimerDisco"1" /AndroidX86/PartOVMF/
          sudo mkdir -p /AndroidX86/PartExt4/
          sudo mount -t auto $PrimerDisco"2" /AndroidX86/PartExt4/
          
        ;;

        2)

          echo ""
          echo "  Creando las particiones..."
          echo ""
          sudo rm -rf /AndroidX86/PartOVMF/* 2> /dev/null
          sudo rm -rf /AndroidX86/PartExt4/* 2> /dev/null
          sudo umount $PrimerDisco"1" 2> /dev/null
          sudo umount $PrimerDisco"2" 2> /dev/null
          sudo umount $PrimerDisco"3" 2> /dev/null
          sudo swapoff -a
          ## Crear tabla de particiones GPT
             sudo parted -s $PrimerDisco mklabel gpt
          ## Crear la partición OVMF
             sudo parted -s $PrimerDisco mkpart OVMF ext4 1MiB 201MiB
          ## Crear la partición ext4
             sudo parted -s $PrimerDisco mkpart AndroidX86 ext4 201MiB 24580MiB
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
             sudo mkfs -t ext4 -L AndroidX86 $PrimerDisco"2"
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
          echo "  Montando las particiones..."
          echo ""
          sudo mkdir -p /AndroidX86/PartOVMF/ 2> /dev/null
          sudo mount -t auto /dev/sda1 /AndroidX86/PartOVMF/
          sudo mkdir -p /AndroidX86/PartExt4/ 2> /dev/null
          sudo mount -t auto /dev/sda2 /AndroidX86/PartExt4/

          sudo chmod 777 /AndroidX86/PartOVMF/
          sudo chmod 777 /AndroidX86/PartExt4/
          sudo mkdir -p /AndroidX86/PartExt4/Temp/
          sudo chmod 777 /AndroidX86/PartExt4/Temp/
          
          sudo mkdir -p /AndroidX86/PartExt4/Temp/ISO/
          sudo chmod 777 /AndroidX86/PartExt4/Temp/ISO/

          sudo mkdir -p /AndroidX86/PartExt4/Temp/SFS/
          sudo chmod 777 /AndroidX86/PartExt4/Temp/SFS/

          sudo mkdir -p /AndroidX86/PartExt4/Temp/IMG/
          sudo chmod 777 /AndroidX86/PartExt4/Temp/IMG/
        ;;

        6)

          echo ""
          echo "  Determinando la última versión de AndroidX86..."
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
          touch /tmp/ISOsAndroidX86.txt
          curl --silent curl -s https://www.fosshub.com/Android-x86.html | grep href | grep -v rc | grep .iso | sed 's-href="-\n-g' | cut -d'"' -f1 | grep http > /tmp/ISOsAndroidX86.txt
          VersAndroidX86=$(cat /tmp/ISOsAndroidX86.txt | grep -v k49 | head -n1 | sed 's|-x86_64-|\n|g' | grep iso | sed 's-.iso--g')
          echo $VersAndroidX86
          echo ""
          echo "  La última versión estable de AndroidX86 es la $VersAndroidX86"
          echo ""

        ;;

        7)

          echo ""
          echo "  Descargando la última versión de AndroidX86..."
          echo ""
          vUltReleaseOSDN=$(curl -s https://osdn.net/projects/android-x86/releases | grep href | grep "/releases/" | grep -v class | grep -v li | cut -d '"' -f2 | grep -v "s/p" | sort | tail -n1 | sed 's|/projects/android-x86/releases/||g')
          cd /tmp/
          # Comprobar si el paquete wget está instalado. Si no lo está, instalarlo.
            if [[ $(dpkg-query -s wget 2>/dev/null | grep installed) == "" ]]; then
              echo ""
              echo "  wget no está instalado. Iniciando su instalación..."
              echo ""
              sudo apt-get -y update
              sudo apt-get -y install wget
              echo ""
            fi
          rm -rf /AndroidX86/PartExt4/Temp/android-x86_64-$VersAndroidX86-k49.iso 2> /dev/null
          wget "https://osdn.net/frs/redir.php?m=rwthaachen&f=android-x86%2F$vUltReleaseOSDN%2Fandroid-x86_64-$VersAndroidX86-k49.iso" -O /AndroidX86/PartExt4/Temp/android-x86_64-$VersAndroidX86-k49.iso

        ;;

        8)

          echo ""
          echo "  Preparando los archivos de la particion ext4..."
          echo ""
          sudo mount /AndroidX86/PartExt4/Temp/android-x86_64-$VersAndroidX86-k49.iso /AndroidX86/PartExt4/Temp/ISO/
          sudo cp /AndroidX86/PartExt4/Temp/ISO/initrd.img  /AndroidX86/PartExt4/
          sudo cp /AndroidX86/PartExt4/Temp/ISO/kernel      /AndroidX86/PartExt4/
          sudo cp /AndroidX86/PartExt4/Temp/ISO/ramdisk.img /AndroidX86/PartExt4/
          sudo unsquashfs -f -d /AndroidX86/PartExt4/Temp/SFS/ /AndroidX86/PartExt4/Temp/ISO/system.sfs
          sudo cp /AndroidX86/PartExt4/Temp/SFS/system.img  /AndroidX86/PartExt4/
          #sudo mount -o loop /AndroidX86/PartExt4/Temp/SFS/system.img /AndroidX86/PartExt4/Temp/IMG/

        ;;

        9)

          echo ""
          echo "  Preparando los archivos de la particion EFI (Grub y otros)..."
          echo ""
          sudo mkdir -p /AndroidX86/PartOVMF/EFI/Boot/ 2> /dev/null
          rm -rf /AndroidX86/PartOVMF/EFI/Boot/*
          # sudo wget http://hacks4geeks.com/_/premium/descargas/OpenWrtX86/PartEFI/EFI/Boot/bootx64.efi -O /AndroidX86/PartOVMF/EFI/Boot/bootx64.efi
          sudo wget https://raw.githubusercontent.com/nipegun/ubulive-scripts/main/Recursos/bootx64androidx86.efi -O /AndroidX86/PartOVMF/EFI/Boot/bootx64.efi
          sudo mkdir -p /AndroidX86/PartOVMF/EFI/AndroidX86/ 2> /dev/null
          sudo cp /AndroidX86/PartExt4/Temp/ISO/efi/boot/android.cfg /AndroidX86/PartOVMF/EFI/AndroidX86/grub.cfg
          sudo su -c "echo 'serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1 --rtscts=off'                    > /AndroidX86/PartOVMF/EFI/AndroidX86/grub.cfg"
          sudo su -c "echo 'terminal_input console serial; terminal_output console serial'                               >> /AndroidX86/PartOVMF/EFI/AndroidX86/grub.cfg"
          sudo su -c "echo ''                                                                                            >> /AndroidX86/PartOVMF/EFI/AndroidX86/grub.cfg"
          sudo su -c "echo 'set default="'"0"'"'                                                                         >> /AndroidX86/PartOVMF/EFI/AndroidX86/grub.cfg"
          sudo su -c "echo 'set timeout="'"1"'"'                                                                         >> /AndroidX86/PartOVMF/EFI/AndroidX86/grub.cfg"
          sudo su -c 'echo "set root='"'(hd0,2)'"'"                                                                      >> /AndroidX86/PartOVMF/EFI/AndroidX86/grub.cfg'
          sudo su -c "echo ''                                                                                            >> /AndroidX86/PartOVMF/EFI/AndroidX86/grub.cfg"
          sudo su -c "echo 'menuentry "'"AndroidX86"'" {'                                                                >> /AndroidX86/PartOVMF/EFI/AndroidX86/grub.cfg"
          sudo su -c "echo '  linux /kernel root=/dev/ram0 rootfstype=ext4 rootwait console=tty0 console=ttyS0,115200n8' >> /AndroidX86/PartOVMF/EFI/AndroidX86/grub.cfg"
          sudo su -c "echo '  initrd /initrd.img'                                                                        >> /AndroidX86/PartOVMF/EFI/AndroidX86/grub.cfg"
          sudo su -c "echo '}'                                                                                           >> /AndroidX86/PartOVMF/EFI/AndroidX86/grub.cfg"

        ;;

        10)

 
          echo ""
          echo "  Borrando archivos sobrantes..."
          echo ""
          sudo umount /AndroidX86/PartExt4/Temp/ISO/
          sudo rm -rf /AndroidX86/PartExt4/Temp/
          sudo apt-get -y install mc

        ;;

        11)

        ;;

      esac

done

echo ""
echo "Ejecución del script, finalizada."
echo ""
echo "Reinicia el sistema con:"
echo "sudo shutdown -r now"
echo ""
echo "Recuerda quitar el DVD de la unidad antes de que vuelva a arrancar la máquina virtual."
echo ""

    
