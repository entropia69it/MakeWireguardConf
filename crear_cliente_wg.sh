#!/bin/bash

# ==============================================================================
# Script de Automatización de Clientes WireGuard
# ==============================================================================

# Archivos de configuración y registros
CONFIG_FILE="config_wg.conf"
LOG_IP="ips_wireguard.log"
LOG_ACCIONES="acciones_wireguard.log"

# 1. Comprobación de herramientas necesarias
for cmd in wg qrencode awk; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: El comando '$cmd' no está instalado o no es accesible."
        echo "Por favor, instala la herramienta requerida antes de continuar."
        exit 1
    fi
done

# 2. Cargar archivo de configuración
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Error: No se encontró el archivo '$CONFIG_FILE'."
    echo "Copia 'config_wg.conf.example' a '$CONFIG_FILE' y ajusta tus parámetros."
    exit 1
fi

# Validar que los parámetros esenciales están presentes
if [ -z "$KEY_PUB_SERVER" ] || [ -z "$IP_SERVER" ] || [ -z "$IP_RANGE" ] || [ -z "$IP_INIT" ]; then
    echo "Error: El archivo '$CONFIG_FILE' no contiene todos los parámetros necesarios."
    exit 1
fi

# Extraer el prefijo de la red (ej: 192.168.169.) a partir del IP_RANGE
PREFIJO_IP=$(echo "$IP_RANGE" | cut -d'/' -f1 | cut -d'.' -f1-3)"."

# Función para registrar logs de acciones con marca de tiempo
log_accion() {
    local mensaje="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $mensaje" >> "$LOG_ACCIONES"
}

# 3. Solicitud interactiva de datos
echo "=========================================================="
echo "    Generador de Clientes WireGuard"
echo "=========================================================="
echo ""

read -p "Introduce el nombre del cliente: " CLIENTE
if [ -z "$CLIENTE" ]; then
    echo "Error: El nombre del cliente no puede estar vacío."
    exit 1
fi

# Permite modificar el Endpoint predeterminado o usar el del config
read -p "Endpoint del servidor [$IP_SERVER]: " INPUT_ENDPOINT
ENDPOINT="${INPUT_ENDPOINT:-$IP_SERVER}"

# Permite modificar la clave pública predeterminada o usar la del config
read -p "Clave pública del servidor [$KEY_PUB_SERVER]: " INPUT_SERVER_PUBKEY
SERVER_PUBKEY="${INPUT_SERVER_PUBKEY:-$KEY_PUB_SERVER}"

if [ -z "$SERVER_PUBKEY" ]; then
    echo "Error: La clave pública del servidor no puede estar vacía."
    exit 1
fi

# 4. Cálculo de la siguiente IP disponible
if [ ! -f "$LOG_IP" ]; then
    PROXIMA_IP=$IP_INIT
else
    # Extrae el último octeto de la última IP registrada y suma 1
    ULTIMO_OCTETO=$(tail -n 1 "$LOG_IP" | awk '{print $1}' | awk -F'.' '{print $4}')
    if [[ "$ULTIMO_OCTETO" =~ ^[0-9]+$ ]]; then
        PROXIMA_IP=$((ULTIMO_OCTETO + 1))
    else
        PROXIMA_IP=$IP_INIT
    fi
fi

CLIENT_IP="${PREFIJO_IP}${PROXIMA_IP}"

# 5. Generación de par de claves para el cliente
CLIENT_PRIVKEY=$(wg genkey)
CLIENT_PUBKEY=$(echo "$CLIENT_PRIVKEY" | wg pubkey)

# 6. Guardar asignación en el log de IPs
echo "${CLIENT_IP} ${CLIENTE}" >> "$LOG_IP"

# 7. Generar el archivo .conf para el cliente
CONF_CLIENTE="${CLIENTE}.conf"

cat <<EOF > "$CONF_CLIENTE"
[Interface]
PrivateKey = ${CLIENT_PRIVKEY}
Address = ${CLIENT_IP}/32
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = ${SERVER_PUBKEY}
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = ${ENDPOINT}
PersistentKeepalive = 25
EOF

# Registrar evento en el log de auditoría de acciones
log_accion "Alta cliente: $CLIENTE | IP: $CLIENT_IP | PubKey Cliente: $CLIENT_PUBKEY | PrivKey Cliente: $CLIENT_PRIVKEY | Server PubKey: $SERVER_PUBKEY"

# 8. Mostrar resumen y código QR
echo ""
echo "=========================================================="
echo " Cliente '$CLIENTE' generado con éxito"
echo " IP asignada: ${CLIENT_IP}/32"
echo " Archivo de configuración: $CONF_CLIENTE"
echo "=========================================================="
echo ""

qrencode -t ansiutf8 < "$CONF_CLIENTE"

echo ""
echo "Añade la siguiente sección a la configuración de tu servidor WireGuard (/etc/wireguard/wg0.conf):"
echo ""
echo "# Cliente: $CLIENTE"
echo "[Peer]"
echo "PublicKey = $CLIENT_PUBKEY"
echo "AllowedIPs = ${CLIENT_IP}/32"
echo ""
