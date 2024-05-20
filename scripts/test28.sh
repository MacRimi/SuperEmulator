#!/bin/bash

# Directorio del usuario
USER_DIR="/home/$(whoami)"

# Nombre del repositorio
REPO_NAME="Super-RetroPie"

# Crear la carpeta en el directorio del usuario
TARGET_DIR="$USER_DIR/$REPO_NAME"
mkdir -p "$TARGET_DIR"

# URL base del repositorio
REPO_URL="https://raw.githubusercontent.com/MacRimi/Super-RetroPie/main"

# Descargar los archivos dentro de la carpeta creada
wget -q "$REPO_URL/version.txt" -O "$TARGET_DIR/version.txt"
wget -q "$REPO_URL/super-retropie.sh" -O "$TARGET_DIR/super-retropie.sh"

# Asignar permisos de ejecución al archivo descargado
chmod +x "$TARGET_DIR/super-retropie.sh"

# Ejecutar el script
sudo bash "$TARGET_DIR/super-retropie.sh"

# Función para comprobar si el volumen lógico está usando todo el espacio disponible
check_volume() {
  local LV_PATH=$(lvscan | grep "ACTIVE" | awk '{print $2}' | tr -d "'")
  if [ -z "$LV_PATH" ]; then
    echo "No se pudo determinar la ruta del volumen lógico. Asegúrate de que el volumen lógico está activo."
    exit 1
  fi

  local FREE_SPACE=$(vgdisplay | grep "Free  PE / Size" | awk '{print $5}')
  if [ "$FREE_SPACE" -gt 0 ]; then
    return 1
  else
    return 0
  fi
}

# Verificar si el paquete 'lvm2' está instalado, necesario para la instalación automatizada
if ! command -v lvextend &> /dev/null; then
    echo "El paquete 'lvm2' no está instalado. Instalándolo..."
    apt-get update
    apt-get install -y lvm2
fi

# Función para extender el volumen lógico
extend_volume() {
  local LV_PATH=$(lvscan | grep "ACTIVE" | awk '{print $2}' | tr -d "'")

  # Verificar si el volumen ya está extendido al máximo
  local EXTEND_STATUS=$(lvdisplay "$LV_PATH" | grep "Allocated to snapshot")
  if [[ -z "$EXTEND_STATUS" ]]; then
    echo "El volumen lógico ya está extendido al máximo."
    return
  fi

  echo "Extendiendo el volumen lógico..."
  lvextend -l +100%FREE "$LV_PATH"
  if [ $? -ne 0 ]; then
    echo "Error al extender el volumen lógico."
    exit 1
  fi

  echo "Redimensionando el sistema de archivos..."
  resize2fs "$LV_PATH"
  if [ $? -ne 0 ]; then
    echo "Error al redimensionar el sistema de archivos."
    exit 1
  fi

  echo "El volumen lógico y el sistema de archivos se han extendido correctamente."
}

# Función para instalar RetroPie con comprobación de volumen
install_retropie() {
    # Verificar si el paquete 'expect' está instalado, necesario para la instalación automatizada
    if ! command -v expect &> /dev/null; then
        echo "El paquete 'expect' no está instalado. Instalándolo..."
        apt-get update
        apt-get install -y expect
    fi

    # Comprobar el estado del volumen antes de proceder
    check_volume
    local volume_status=$?
    if [ "$volume_status" -eq 1 ]; then
        # El volumen tiene espacio libre, advertir al usuario
        dialog --yesno "Se va a proceder a instalar RetroPie en un volumen de espacio reducido, esto podría hacer que te quedaras sin espacio pronto. ¿Desea continuar?" 10 60
        if [[ $? -eq 0 ]]; then
            echo "Instalando RetroPie..."
        else
            echo "Instalación cancelada por el usuario."
            return
        fi
    fi

    # Descargar y ejecutar el script de instalación de RetroPie
    wget -q https://raw.githubusercontent.com/MizterB/RetroPie-Setup-Ubuntu/master/bootstrap.sh
    bash ./bootstrap.sh

    # Automatizar la interacción con el script de instalación de RetroPie
    expect << EOF
    spawn sudo ./RetroPie-Setup-Ubuntu/retropie_setup_ubuntu.sh
    expect {
        "Press any key to continue" { send "\r"; exp_continue }
        "RetroPie Setup" { send "\r"; exp_continue }
        "Exit" { send "\r" }
    }
EOF

    # Reiniciar el sistema tras la instalación
    reboot
}

# Función para mostrar el menú y capturar la selección del usuario
show_menu() {
  while true; do
    opciones=$(dialog --checklist "Seleccione los scripts a ejecutar:" 20 60 2 \
        1 "Extender disco a su máxima capacidad" off \
        2 "Instalar RetroPie" off 3>&1 1>&2 2>&3 3>&-)

    respuesta=$?

    if [[ $respuesta -eq 1 || $respuesta -eq 255 ]]; then
        clear
        echo "Instalación cancelada."
        exit 1
    fi

    if echo "$opciones" | grep -q "2"; then
        dialog --yesno "¿Desea continuar con la instalación de RetroPie?" 10 60
        if [[ $? -eq 0 ]]; then
            install_retropie
        else
            clear
        fi
    fi

    if echo "$opciones" | grep -q "1"; then
        dialog --yesno "Se va a proceder a dimensionar el volumen a su máxima capacidad, ¿seguro que quiere continuar?" 10 60
        if [[ $? -eq 0 ]]; then
            extend_volume
        else
            clear
        fi
    fi
  done
}

# Inicio del script
show_menu
