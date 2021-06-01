# ubulive-scripts

Los "ubulive-scripts" son scripts pensados para ejecutarse desde la terminal de un LiveCD de Ubuntu.

## Ejecución:

Para ejecutar un ubulive-script abre una terminal (CTRL+T) y ejecuta wget "pipeando" el script en "crudo" hacia bash. Por ejemplo:

```
wget -O - https://raw.githubusercontent.com/nipegun/ubulive-scripts/main/OpenWrtX86-InstalarEnMVDeProxmox.sh.sh | bash
```
