# 🚀 Generador de Clientes WireGuard (Bash)

Script en Bash para automatizar el alta de clientes en un servidor WireGuard. Gestiona la asignación secuencial de direcciones IP, genera archivos de configuración `.conf`, muestra el código QR en terminal y guarda un registro de auditoría con marcas de tiempo.

---

## 🛠️ Requisitos Previos

Instala las herramientas requeridas según tu distribución Linux:

```bash
# Debian / Ubuntu / Kali Linux
sudo apt update && sudo apt install -y wireguard-tools qrencode gawk

# Arch Linux
sudo pacman -S wireguard-tools qrencode gawk

# RHEL / Fedora
sudo dnf install wireguard-tools qrencode gawk
```
⚙️ Configuración (config_wg.conf)

Crea un archivo llamado config_wg.conf en el mismo directorio del script. Copia la siguiente plantilla y reemplaza los valores de ejemplo por los de tu infraestructura:
```
# Clave pública de la interfaz del servidor WireGuard
KEY_PUB_SERVER=SU_CLAVE_PUBLICA_AQUI

# Endpoint del servidor (IP pública o dominio + Puerto UDP)
IP_SERVER=vpn.ejemplo.com:51820

# Subred interna de la VPN WireGuard (con máscara CIDR)
IP_RANGE=192.168.169.0/24

# Último octeto inicial para la asignación de clientes (ej: 8 -> 192.168.169.8)
IP_INIT=8
```
Detalle de los Parámetros

    KEY_PUB_SERVER: Clave pública de la interfaz de tu servidor WireGuard.

    IP_SERVER: Dirección IP pública o nombre de dominio (FQDN) junto con el puerto de escucha del servidor (ej: 203.0.113.1:51820 o vpn.ejemplo.com:51820).

    IP_RANGE: Subred en formato CIDR que utiliza la red VPN (ej: 192.168.169.0/24). El script extrae los tres primeros octetos para formar el direccionamiento.

    IP_INIT: Octeto de inicio para el direccionamiento secuencial. Si valor es 8, el primer cliente asignado obtendrá la IP .8, el siguiente la .9, etc.

🚀 Uso del Script

  Asigna permisos de ejecución al script:
  Bash
```
chmod +x crear_cliente_wg.sh
```
Ejecuta el script con privilegios de superusuario:
Bash
```
    sudo ./crear_cliente_wg.sh
```
    Introduce el nombre del cliente cuando se te solicite. Presiona ENTER para aceptar los valores predeterminados de config_wg.conf o escribe un valor alternativo para sobrescribirlos en esa ejecución.

📂 Archivos Generados

En cada ejecución, el script genera o actualiza los siguientes archivos:

    <nombre_cliente>.conf: Archivo de configuración listo para importar en el dispositivo cliente.

    Código QR en pantalla: Representación visual en consola del archivo .conf para escanear desde la app móvil de WireGuard.

    ips_wireguard.log: Registro de IPs asignadas y nombres de cliente. Sirve de base de datos para calcular la siguiente IP disponible.

    acciones_wireguard.log: Registro de auditoría con fecha y hora (YYYY-MM-DD HH:MM:SS) que almacena las claves públicas y privadas generadas.

🔒 Archivo .gitignore Recomendado

Añade un archivo .gitignore al proyecto para evitar la subida accidental de información sensible:
Fragmento de código
```
# Archivo de configuración privada
config_wg.conf

# Configuración de clientes generados
*.conf

# Base de datos de IPs y logs de auditoría
*.log
```
