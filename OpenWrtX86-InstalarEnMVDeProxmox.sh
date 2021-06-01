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

echo ""
echo "Creando carpetas para montar las particiones..."
echo ""
sudo mkdir -p /OpenWrt/PartOVMF/
sudo mkdir -p /OpenWrt/PartExt4/

echo ""
echo "Creando las particiones..."
echo ""
  ## Crear tabla de particiones GPT
  echo "type=83" | sudo sfdisk $PrimerDisco
  ## Crear la partición OVMF
     parted $PrimerDisco mklabel gpt mkpart P1 ext4 1MiB 8MiB
  ## Crear la partición ext4
     parted -a optimal $PrimerDisco mkpart primary 0% 4096MB


echo ""
echo "Montando las particiones..."
echo ""
sudo mount -t auto /dev/sda1 /OpenWrt/PartOVMF/
sudo mount -t auto /dev/sda2 /OpenWrt/PartExt4/

echo ""
echo "Borrando el contenido de la partición ext4..."
echo ""
sudo rm -rf /OpenWrt/PartExt4/*

echo ""
echo "Volviendo a crear de cero el sistema raíz de OpenWrt versión $VersOpenWrt"
echo ""

echo ""
echo "Bajando y posicionando el Kernel..."
echo ""
sudo mkdir -p /OpenWrt/PartExt4/boot
## Comprobar si el paquete wget está instalado. Si no lo está, instalarlo.
   if [[ $(dpkg-query -s wget 2>/dev/null | grep installed) == "" ]]; then
     echo ""
     echo "  wget no está instalado. Iniciando su instalación..."
     echo ""
     sudo apt-get -y update
     sudo apt-get -y install wget
     echo ""
   fi
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

echo ""
echo "Configurando la MV de OpenWrt para que pille IP por DHCP"
echo ""
sudo rm -rf /OpenWrt/PartExt4/etc/config/network
sudo cp /OpenWrt/PartOVMF/scripts/network /OpenWrt/PartExt4/etc/config/

echo ""
echo "Copiando el script de instalación de paquetes..."
echo ""
sudo mkdir -p /OpenWrt/PartExt4/root/scripts/
sudo cp /OpenWrt/PartOVMF/scripts/1-InstalarPaquetes.sh /OpenWrt/PartExt4/root/scripts/1-InstalarPaquetes.sh
sudo chmod +x                                           /OpenWrt/PartExt4/root/scripts/1-InstalarPaquetes.sh

echo ""
echo "Copiando el script de instalación de los o-scripts..."
echo ""
sudo cp /OpenWrt/PartOVMF/scripts/2-InstalarOScripts.sh /OpenWrt/PartExt4/root/scripts/2-InstalarOScripts.sh
sudo chmod +x                                           /OpenWrt/PartExt4/root/scripts/2-InstalarOScripts.sh

echo ""
echo "Copiando el script de preparación de OpenWrt para funcionar como una MV de Proxmox..."
echo ""
sudo cp /OpenWrt/PartOVMF/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh /OpenWrt/PartExt4/root/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
sudo chmod +x                                                         /OpenWrt/PartExt4/root/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh

echo ""
echo "Ejecución del script, finalizada."
echo ""
echo "Reinicia el sistema con:"
echo "sudo shutdown -r now"
echo ""
echo "Recuerda quitar el DVD de la unidad antes de que vuelve a arrancar la máquina virtual."
echo ""

serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1 --rtscts=off
terminal_input console serial; terminal_output console serial

set default="0"
set timeout="1"
set root='(hd0,2)'

menuentry "OpenWrt" {
  linux /boot/vmlinuz root=/dev/sda2 rootfstype=ext4 rootwait console=tty0 console=ttyS0,115200n8 noinitrd
}
menuentry "OpenWrt (failsafe)" {
  linux /boot/vmlinuz failsafe=true root=/dev/sda2 rootfstype=ext4 rootwait console=tty0 console=ttyS0,115200n8 noinitrd
}
