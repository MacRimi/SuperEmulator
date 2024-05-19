#!/bin/bash

# Asegurarse de que el script se ejecute con permisos de superusuario
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecute este script como root."
  exit 1
fi

# Función para comprobar si el volumen lógico está usando todo el espacio disponible
check_volume() {
  local LV_PATH=$(lvscan | grep "ACTIVE" | awk '{print $4}' | tr -d "'")
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

# Función para extender el volumen lógico
extend_volume() {
  local LV_PATH=$(lvscan | grep "ACTIVE" | awk '{print $4}' | tr -d "'")
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

# Función para instalar RetroPie
install_retropie() {
  # Verificar si expect está instalado, si no, instalarlo
  if ! command -v expect &> /dev/null; then
    echo "El paquete expect no está instalado. Instalándolo..."
    apt-get update
    apt-get install -y expect
  fi

  # Descargar el script bootstrap.sh
  wget -q https://raw.githubusercontent.com/MizterB/RetroPie-Setup-Ubuntu/master/bootstrap.sh

  # Ejecutar el script bootstrap.sh
  bash ./bootstrap.sh

  # Simular presionar Enter para aceptar el disclaimer y continuar con la instalación (usando expect)
  expect << EOF
  spawn sudo ./RetroPie-Setup-Ubuntu/retropie_setup_ubuntu.sh
  expect {
      "Press any key to continue" { send "\r"; exp_continue }
      "RetroPie Setup" { send "\r"; exp_continue }
      "Exit" { send "\r" }
  }
EOF

  # Reboot del sistema
  reboot
}

# Menú principal
main_menu() {
  echo "Seleccione una opción:"
  echo "[1] Instalar RetroPie"
  echo "[2] Extender disco a su máxima capacidad e instalar RetroPie"
  echo "[3] Salir"
  read -p "Opción: " option

  case $option in
    1)
      if ! check_volume; then
        echo "El volumen de instalación no está usando toda la capacidad del disco, esto podría ocasionar que pudieras quedarte sin espacio pronto."
        read -p "¿Quieres expandir la capacidad del disco y luego instalar RetroPie? (s/n): " expand
        if [[ "$expand" == "s" || "$expand" == "S" ]]; then
          extend_volume
        fi
      fi
      install_retropie
      ;;
    2)
      extend_volume
      install_retropie
      ;;
    3)
      echo "Saliendo..."
      exit 0
      ;;
    *)
      echo "Opción no válida."
      main_menu
      ;;
  esac
}

# Inicio del script
check_volume
main_menu
