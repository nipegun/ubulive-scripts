#!/bin/bash

# Pongo a disposición pública este script bajo el término de "software de dominio público".
# Puedes hacer lo que quieras con él porque es libre de verdad; no libre con condiciones como las licencias GNU y otras patrañas similares.
# Si se te llena la boca hablando de libertad entonces hazlo realmente libre.
# No tienes que aceptar ningún tipo de términos de uso o licencia para utilizarlo o modificarlo porque va sin CopyLeft.

# ----------
# Script de NiPeGun para instalar UnraidOS en una máquina virtual de ProxmoxVE inciando desde Ubuntu Live 
#
# Ejecución remota:
#   Para sistema con discos sata:
#     curl -sL https://raw.githubusercontent.com/nipegun/ubulive-scripts/main/InstSO/UnraidOS-Instalar.sh | bash
#  Para sistemas con discos virtio:
#     curl -sL https://raw.githubusercontent.com/nipegun/ubulive-scripts/main/InstSO/UnraidOS-Instalar.sh | sed 's-/dev/sda-/dev/vda-g' | bash
# ----------

vNumUltVer=$(curl -sL UnraidOS.org | grep urrent | grep "stable" | grep ":" | cut -d":" -f2 | cut -d"." -f1 | sed 's- --g' | cut -d"t" -f2)
#vNumUltVer="22"

vURLDescargaUltVersEstable="https://unraid-dl.sfo2.cdn.digitaloceanspaces.com/stable/unRAIDServer-6.11.5-x86_64.zip"

vFechaDeEjec=$(date +A%Y-M%m-D%d@%T)
vPrimerDisco="/dev/sda"

# Declaración de las variables de color
  vColorAzul="\033[0;34m"
  vColorAzulClaro="\033[1;34m"
  vColorVerde='\033[1;32m'
  vColorRojo='\033[1;31m'
  vFinColor='\033[0m'

echo ""
echo -e "${vColorAzulClaro}  Iniciando el script de instalación de UnraidOS X86 para máquinas virtuales de Proxmox...${vFinColor}"
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

menu=(dialog --checklist "Instalación de UnraidOS X86:" 30 100 20)
  opciones=(
     1 "Hacer copia de seguridad de la instalación anterior" on
     2 "Crear las particiones" on
     3 "Formatear las particiones" on
     4 "Marcar la partición EFI como esp" on
     5 "Determinar la última versión de UnraidOS" on
     6 "Montar las particiones" on
     7 "Descargar el archivo zip con UnraidOS" on
     8 "Descomprimir el archivo zip con UnraidOS" on
     9 "Crear la estructura de carpetas y archivos en ext4" on
    10 "Configurar UnraidOS para que pille IP WAN mediante DHCP" on
    11 "Copiar el script de instalación de paquetes" on
    12 "Copiar el script de instalación de los o-scripts" on
    13 "Copiar el script de preparación de UnraidOS para funcionar como una MV de Proxmox" on
    14 "Copiar el script de preparación de UnraidOS para funcionar como router Baremetal" on
    15 "Mover copia de seguridad de la instalación anterior a la nueva instalación" on
    16 "Instalar GPartEd y Midnight Commander para poder visualizar los cambios realizados" on
    17 "Apagar la máquina virtual" off
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
            sudo mkdir -p /UnraidOS/PartEFI/
            sudo mount -t auto $vPrimerDisco"1" /UnraidOS/PartEFI/
          # Crear carpeta donde guardar los archivos
            sudo mkdir -p /CopSegUnraidOS/$vFechaDeEjec/PartEFI/
          # Copiar archivos
            sudo cp -r /UnraidOS/PartEFI/* /CopSegUnraidOS/$vFechaDeEjec/PartEFI/
          # Desmontar partición 
            sudo umount /UnraidOS/PartEFI/
            sudo rm -rf  /UnraidOS/PartEFI/

        ;;

        2)

          echo ""
          echo "  Creando las particiones..."
          echo ""
          sudo rm -rf /UnraidOS/PartEFI/*
          sudo umount $vPrimerDisco"1" 2> /dev/null
          sudo umount $vPrimerDisco"2" 2> /dev/null
          sudo umount $vPrimerDisco"3" 2> /dev/null
          sudo swapoff -a
          # Crear tabla de particiones GPT
            sudo parted -s $vPrimerDisco mklabel gpt
          # Crear la partición EFI
            sudo parted -s $vPrimerDisco mkpart UNRAID ext4 1MiB 4096MiB
          # Crear la partición de intercambio
            sudo parted -s $vPrimerDisco mkpart Intercambio ext4 4096MiB 100%

        ;;

        3)

          echo ""
          echo "  Formateando las particiones..."
          echo ""
          # Formatear la partición para EFI como fat32
            sudo mkfs -t vfat -F 32 -n UNRAID $vPrimerDisco"1"
          # Formatear la partición para Intercambio como swap
            sudo mkswap -L Intercambio $vPrimerDisco"2"

        ;;

        4)

          echo ""
          echo "  Marcando la partición EFI como esp..."
          echo ""
          sudo parted -s $vPrimerDisco set 1 esp on

        ;;

        5)

          echo ""
          echo "  Determinando la última versión de UnraidOS..."
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
  
          vUltVersUnraidOS=$(curl -sL https://unraid.com | grep eleases  head -n1 | cut -d'"' -f2 | cut -d'/' -f2)

          echo ""
          echo "    La última versión estable de UnraidOS es la $vUltVersUnraidOS."
          echo ""

        ;;

        6)

          echo ""
          echo "  Montando las particiones..."
          echo ""
          sudo mkdir -p /UnraidOS/PartEFI/ 2> /dev/null
          sudo mount -t auto /dev/sda1 /UnraidOS/PartEFI/

        ;;

        7)

          echo ""
          echo "  Descargando el zip con UnraidOS..."
          echo ""
          rm -rf /UnraidOS/PartEFI/*
          # Comprobar si el paquete wget está instalado. Si no lo está, instalarlo.
            if [[ $(dpkg-query -s wget 2>/dev/null | grep installed) == "" ]]; then
              echo ""
              echo "    El paquete wget no está instalado. Iniciando su instalación..."
              echo ""
              sudo apt-get -y update
              sudo apt-get -y install wget
              echo ""
            fi
          # sudo wget http://hacks4geeks.com/_/premium/descargas/UnraidOSX86/PartEFI/EFI/Boot/bootx64.efi -O /UnraidOS/PartEFI/EFI/Boot/bootx64.efi
          sudo wget $vURLDescargaUltVersEstable -O /UnraidOS/PartEFI/unraid.zip
                    
        ;;

        8)

          echo ""
          echo "  Descomprimiendo el archivo zip de UnraidOS..."
          echo ""
          # Comprobar si el paquete unzip está instalado. Si no lo está, instalarlo.
            if [[ $(dpkg-query -s unzip 2>/dev/null | grep installed) == "" ]]; then
              echo ""
              echo "    El paquete unzip no está instalado. Iniciando su instalación..."
              echo ""
              sudo apt-get -y update
              sudo apt-get -y install unzip
              echo ""
            fi
          sudo unzip /UnraidOS/PartEFI/unraid.zip -d /UnraidOS/PartEFI/
          sudo mv /UnraidOS/PartEFI/EFI-/  /UnraidOS/PartEFI/EFI/

        ;;

        15)

          echo ""
          echo "  Moviendo copia de seguridad de la instalación anterior a la instalación nueva..."
          echo ""
          # Crear carpeta en la nueva partición
          sudo mkdir -p /UnraidOS/PartExt4/CopSeg/
          # Mover archivos
            sudo mv /CopSegUnraidOS/$vFechaDeEjec/ /UnraidOS/PartExt4/CopSeg/
          # Borrar carpeta de copia de seguridad de la partición de Debian Live
            sudo rm -rf  /CopSegUnraidOS/
        ;;

        16)

          echo ""
          echo "  Instalando Midnight Commander para poder visualizar los cambios realizados..."
          echo ""
          sudo apt-get -y install mc
          sudo apt-get -y install gparted

        ;;

        17)

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
