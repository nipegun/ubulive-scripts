#!/bin/bash

# Pongo a disposición pública este script bajo el término de "software de dominio público".
# Puedes hacer lo que quieras con él porque es libre de verdad; no libre con condiciones como las licencias GNU y otras patrañas similares.
# Si se te llena la boca hablando de libertad entonces hazlo realmente libre.
# No tienes que aceptar ningún tipo de términos de uso o licencia para utilizarlo o modificarlo porque va sin CopyLeft.

#--------------------------------------------------------------------------------------------
#  Script de NiPeGun para instalar OpenWrt en un ordenador UEFI iniciando desde Ubuntu Live 
#--------------------------------------------------------------------------------------------

ColorVerde="\033[1;32m"
FinColor="\033[0m"

echo ""
echo -e "${ColorVerde}Iniciando el script de instalación de OpenWrt en ordenador UEFI...${FinColor}"
echo ""

## Comprobar si el paquete curl está instalado. Si no lo está, instalarlo.
   if [[ $(dpkg-query -s curl 2>/dev/null | grep installed) == "" ]]; then
     echo ""
     echo "curl no está instalado. Iniciando su instalación..."
     echo ""
     sudo apt-get -y update
     sudo apt-get -y install curl
   fi
  
VersOpenWrt=$(curl --silent https://downloads.openwrt.org | grep rchive | grep eleases | grep OpenWrt | head -n 1 | cut -d'/' -f 5)

echo ""
echo "La última versión estable de OpenWrt es la $VersOpenWrt"
echo ""

echo ""
echo "Creando carpetas para montar las particiones..."
echo ""
sudo mkdir -p /OpenWrt/PartEFI/
sudo mkdir -p /OpenWrt/PartExt4/

echo ""
echo "Montando las particiones..."
echo ""
sudo mount -t auto /dev/sda1 /OpenWrt/PartEFI/
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
     echo "wget no está instalado. Iniciando su instalación..."
     echo ""
     sudo apt-get -y update
     sudo apt-get -y install wget
   fi
sudo wget --no-check-certificate https://downloads.openwrt.org/releases/$VersOpenWrt/targets/x86/64/openwrt-$VersOpenWrt-x86-64-vmlinuz -O /OpenWrt/PartExt4/boot/vmlinuz

echo ""
echo "Bajando el archivo con el sistema root..."
echo ""
rm -rf /OpenWrt/PartEFI/rootfs.tar.gz
sudo wget --no-check-certificate https://downloads.openwrt.org/releases/$VersOpenWrt/targets/x86/64/openwrt-$VersOpenWrt-x86-64-generic-rootfs.tar.gz -O /OpenWrt/PartEFI/rootfs.tar.gz

echo ""
echo "Descomprimiendo el sistema de archivos root en la partición ext4..."
echo ""
## Comprobar si el paquete tar está instalado. Si no lo está, instalarlo.
   if [[ $(dpkg-query -s tar 2>/dev/null | grep installed) == "" ]]; then
     echo ""
     echo "tar no está instalado. Iniciando su instalación..."
     echo ""
     sudo apt-get -y update
     sudo apt-get -y install tar
   fi
sudo tar -xf /OpenWrt/PartEFI/rootfs.tar.gz -C /OpenWrt/PartExt4/

echo ""
echo "Configurando la MV de OpenWrt para que pille IP por DHCP"
echo ""
sudo rm -rf /OpenWrt/PartExt4/etc/config/network
sudo cp /OpenWrt/PartEFI/scripts/network /OpenWrt/PartExt4/etc/config/

echo ""
echo "Copiando el script de instalación de paquetes..."
echo ""
sudo mkdir -p /OpenWrt/PartExt4/root/scripts/
sudo cp /OpenWrt/PartEFI/scripts/1-InstalarPaquetes.sh /OpenWrt/PartExt4/root/scripts/1-InstalarPaquetes.sh
sudo chmod +x                                        /OpenWrt/PartExt4/root/scripts/1-InstalarPaquetes.sh

echo ""
echo "Copiando el script de instalación de los o-scripts..."
echo ""
sudo cp /OpenWrt/PartEFI/scripts/2-InstalarOScripts.sh /OpenWrt/PartExt4/root/scripts/2-InstalarOScripts.sh
sudo chmod +x /OpenWrt/PartExt4/root/scripts/2-InstalarOScripts.sh


echo ""
echo "Copiando el script de preparación de OpenWrt para funcionar como una MV de Proxmox..."
echo ""

echo ""
echo -e "${ColorVerde}Script de instalación de OpenWrt en ordenador UEFI, finalizado${FinColor}"
echo ""
