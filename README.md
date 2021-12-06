# ubulive-scripts

Los "ubulive-scripts" son scripts pensados para ejecutarse desde la terminal de un LiveCD de Ubuntu.

## ¿Cómo se ejecutan?

Para ejecutar un ubulive-script abre una terminal (Ctrl+Alt+t) en el escritorio de la versión de Ubuntu Live que hayas iniciado, elige curl o wget y "pipea" el script en "crudo" hacia bash.

Por ejemplo:


```
curl -s https://raw.githubusercontent.com/nipegun/ubulive-scripts/main/OpenWrtX86-InstalarEnMVDeProxmox.sh | bash
```

o

```
wget -O - https://raw.githubusercontent.com/nipegun/ubulive-scripts/main/OpenWrtX86-InstalarEnMVDeProxmox.sh | bash
```
