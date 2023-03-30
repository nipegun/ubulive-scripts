#!/bin/bash

# Pongo a disposición pública este script bajo el término de "software de dominio público".
# Puedes hacer lo que quieras con él porque es libre de verdad; no libre con condiciones como las licencias GNU y otras patrañas similares.
# Si se te llena la boca hablando de libertad entonces hazlo realmente libre.
# No tienes que aceptar ningún tipo de términos de uso o licencia para utilizarlo o modificarlo porque va sin CopyLeft.

# ----------
# Script de NiPeGun para instalar OpenWrt en una máquina virtual de ProxmoxVE inciando desde Ubuntu Live 
#
# Ejecución remota:
#   curl -s https://raw.githubusercontent.com/nipegun/ubulive-scripts/main/OpenWrtX86-InstalarEnMVDeProxmox.sh | bash
# ----------

vColorVerde="\033[1;32m"
vFinColor="\033[0m"

vPrimerDisco="/dev/sda"

echo ""
echo -e "${vColorVerde}  Iniciando el script de instalación de OpenWrt X86 para máquinas virtuales de Proxmox...${vFinColor}"
echo ""

# Comprobar si el paquete dialog está instalado. Si no lo está, instalarlo.
  if [[ $(dpkg-query -s dialog 2>/dev/null | grep installed) == "" ]]; then
    echo ""
    echo "  dialog no está instalado. Iniciando su instalación..."
    echo ""
    sudo sed -i -e 's|main restricted|main universe restricted|g' /etc/apt/sources.list
    sudo apt-get -y update
    sudo apt-get -y install dialog
    echo ""
  fi

menu=(dialog --timeout 5 --checklist "Instalación de OpenWrt X86:" 22 94 16)
  opciones=(
    1 "Instalar la última versión de OpenWrt 22" off
    2 "Reservada..." off
    3 "Reservada..." off
  )
  choices=$("${menu[@]}" "${opciones[@]}" 2>&1 >/dev/tty)
  clear

  for choice in $choices
    do
      case $choice in

        1)

          # Comprobar si el paquete curl está instalado. Si no lo está, instalarlo.
            if [[ $(dpkg-query -s curl 2>/dev/null | grep installed) == "" ]]; then
              echo ""
              echo "  curl no está instalado. Iniciando su instalación..."
              echo ""
              sudo sed -i -e 's|main restricted|main universe restricted|g' /etc/apt/sources.list
              sudo apt-get -y update
              sudo apt-get -y install curl
              echo ""
            fi

          # Ejecutar el script remoto de instalación
            curl -sL https://raw.githubusercontent.com/nipegun/ubulive-scripts/main/OpenWrtX86-v22-InstalarEnMVDeProxmox.sh | bash

        ;;

      esac

done

