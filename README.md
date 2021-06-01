# ubulive-scripts

Los "ubulive-scripts" son scripts pensados para ejecutarse desde la terminal de un LiveCD de Ubuntu.

## ¿Cómo se ejecutan?

Para ejecutar un ubulive-script abre una terminal (CTRL+T) en el escritorio de la versión de Ubuntu Live que hayas iniciado y ejecuta wget "pipeando" el script en "crudo" hacia bash. Por ejemplo:

```
wget -O - https://raw.githubusercontent.com/nipegun/ubulive-scripts/main/OpenWrtX86-InstalarEnMVDeProxmox.sh | bash
```
