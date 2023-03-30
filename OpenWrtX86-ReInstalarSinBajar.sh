#!/bin/bash

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
sudo rm -rf /OpenWrt/PartExt4/bin
sudo rm -rf /OpenWrt/PartExt4/dev
sudo rm -rf /OpenWrt/PartExt4/etc
sudo rm -rf /OpenWrt/PartExt4/lib
sudo rm -rf /OpenWrt/PartExt4/lib64
sudo rm -rf /OpenWrt/PartExt4/mnt
sudo rm -rf /OpenWrt/PartExt4/overlay
sudo rm -rf /OpenWrt/PartExt4/proc
sudo rm -rf /OpenWrt/PartExt4/rom
sudo rm -rf /OpenWrt/PartExt4/root
sudo rm -rf /OpenWrt/PartExt4/sbin
sudo rm -rf /OpenWrt/PartExt4/sys
sudo rm -rf /OpenWrt/PartExt4/tmp
sudo rm -rf /OpenWrt/PartExt4/usr
sudo rm -rf /OpenWrt/PartExt4/var
sudo rm -rf /OpenWrt/PartExt4/www


echo ""
echo "Volviendo a crear de cero el sistema raíz de OpenWrt versión $VersOpenWrt"
echo ""

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
sudo cp /OpenWrt/PartEFI/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh /OpenWrt/PartExt4/root/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh
sudo chmod +x /OpenWrt/PartExt4/root/scripts/3-PrepararOpenWrtParaMVDeProxmox.sh

echo ""
echo "Ejecución del script, finalizada."
echo ""
echo "Reinicia el sistema con:"
echo "sudo shutdown -r now"
echo ""
echo "Recuerda quitar el DVD de la unidad antes de que vuelve a arrancar la máquina virtual."
echo ""
