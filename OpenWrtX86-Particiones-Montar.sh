#!/bin/bash

# Pongo a disposición pública este script bajo el término de "software de dominio público".
# Puedes hacer lo que quieras con él porque es libre de verdad; no libre con condiciones como las licencias GNU y otras patrañas similares.
# Si se te llena la boca hablando de libertad entonces hazlo realmente libre.
# No tienes que aceptar ningún tipo de términos de uso o licencia para utilizarlo o modificarlo porque va sin CopyLeft.

# ----------
#  Script de NiPeGun para montar las particiones de OpenWrt en Ubuntu Live 
#
# Ejecución remota:
# curl -s https://raw.githubusercontent.com/nipegun/ubulive-scripts/main/OpenWrtX86-Particiones-Montar.sh | bash
# ----------

# Crear las carpetas para montar las particiones
  echo ""
  echo "  Creando las carpetas para montas las particiones..."
  echo ""
  sudo mkdir -p /OpenWrt/PartOVMF/ 2> /dev/null
  sudo mkdir -p /OpenWrt/PartExt4/ 2> /dev/null

# Montar las particiones
  echo ""
  echo "  Montando las particiones..."
  echo ""
  sudo mount -t auto /dev/sda1 /OpenWrt/PartOVMF/
  sudo mount -t auto /dev/sda2 /OpenWrt/PartExt4/

# Abrir nautilus en la carpeta /OpenWrt
  echo ""
  echo "  Abriendo nautilus en la carpeta /OpenWrt..."
  echo ""
  sudo nautilus /OpenWrt

