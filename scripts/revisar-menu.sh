#!/bin/bash

# Comprobar si 'dialog' está instalado
if ! command -v dialog &> /dev/null; then
    echo "'dialog' no está instalado. Instalando 'dialog'..."
    sudo apt-get update
    sudo apt-get install -y dialog
fi

# Definir variables globales
platforms_cfg="/opt/retropie/configs/all/platforms.cfg"
es_systems_cfg="/etc/emulationstation/es_systems.cfg"

#############################
# Función para añadir RPCS3
#############################
instalar_rpcs3() {
    local script_path=~/RetroPie-Setup/scriptmodules/emulators/rpcs3-appImage.sh
    wget -q --show-progress https://raw.githubusercontent.com/raelgc/retropie_rpcs3-appImage/master/rpcs3-appImage.sh -O "$script_path"
    chmod +x "$script_path"

    # Verificar si existe platforms.cfg
    if [ -f "$platforms_cfg" ]; then
        # Agregar las líneas al final del archivo
        echo "Añadiendo configuración de RPCS3 a platforms.cfg..."
        echo "ps3_exts=\".ps3\"" >> "$platforms_cfg"
        echo "ps3_fullname=\"PlayStation 3\"" >> "$platforms_cfg"
    else
        # Crear platforms.cfg y agregar las líneas
        echo "Creando platforms.cfg y añadiendo configuración de RPCS3..."
        echo "ps3_exts=\".ps3\"" > "$platforms_cfg"
        echo "ps3_fullname=\"PlayStation 3\"" >> "$platforms_cfg"
    fi
}

############################
# Función para añadir Yuzu
############################
instalar_yuzu() {
    local script_path=~/RetroPie-Setup/scriptmodules/emulators/yuzu-AppImage.sh
    wget -q --show-progress https://raw.githubusercontent.com/MacRimi/Super-RetroPie/main/scripts/yuzu-AppImage.sh -O "$script_path"
    chmod +x "$script_path"

    # Verificar si existe platforms.cfg
    if [ -f "$platforms_cfg" ]; then
        # Agregar las líneas al final del archivo
        echo "Añadiendo configuración de Yuzu a platforms.cfg..."
        echo "yuzu_exts=\".nsp .xci\"" >> "$platforms_cfg"
        echo "yuzu_fullname=\"Nintendo Switch\"" >> "$platforms_cfg"
    else
        # Crear platforms.cfg y agregar las líneas
        echo "Creando platforms.cfg y añadiendo configuración de Yuzu..."
        echo "yuzu_exts=\".nsp .xci\"" > "$platforms_cfg"
        echo "yuzu_fullname=\"Nintendo Switch\"" >> "$platforms_cfg"
    fi
}

###########################
# Función para añadir Steam
###########################
instalar_steam() {
    local script_path=~/RetroPie-Setup/scriptmodules/emulators/steam-AppImage.sh
    wget -q --show-progress https://raw.githubusercontent.com/MacRimi/Super-RetroPie/main/scripts/steam-AppImage.sh -O "$script_path"
    chmod +x "$script_path"

    # Verificar si existe platforms.cfg
    if [ -f "$platforms_cfg" ]; then
        # Agregar las líneas al final del archivo
        echo "Añadiendo configuración de Steam a platforms.cfg..."
        echo "steam_exts=\".sh\"" >> "$platforms_cfg"
        echo "steam_fullname=\"Steam\"" >> "$platforms_cfg"
        echo "steam_command=\"%ROM%\"" >> "$platforms_cfg"
        # Añadir ajustes
        # echo "ajustes_exts=\".sh\"" >> "$platforms_cfg"
        # echo "ajustes_fullname=\"Ajustes\"" >> "$platforms_cfg"
        # echo "ajustes_command=\"%ROM%\"" >> "$platforms_cfg"
        # echo "ajustes_platform=\"config\"" >> "$platforms_cfg"
    else
        # Crear platforms.cfg y agregar las líneas
        echo "Creando platforms.cfg y añadiendo configuración de Steam..."
        echo "steam_exts=\".sh\"" > "$platforms_cfg"
        echo "steam_fullname=\"Steam\"" >> "$platforms_cfg"
        echo "steam_command=\"%ROM%\"" >> "$platforms_cfg"
        # Añadir ajustes
        # echo "ajustes_exts=\".sh\"" >> "$platforms_cfg"
        # echo "ajustes_fullname=\"Ajustes\"" >> "$platforms_cfg"
        # echo "ajustes_command=\"%ROM%\"" >> "$platforms_cfg"
        # echo "ajustes_platform=\"config\"" >> "$platforms_cfg"
    fi

    if ! grep -q '<name>ajustes</name>' "$es_systems_cfg"; then
        # Definir el nuevo sistema
        nuevo_sistema=$(cat << EOF
  <system>
    <name>ajustes</name>
    <fullname>Configuraciones</fullname>
    <path>/root/RetroPie/roms/ajustes</path>
    <extension>.sh</extension>
    <command>%ROM%</command>
    <platform>config</platform>
    <theme>ajustes</theme>
  </system>
EOF
)
        # Insertar el nuevo sistema antes de la etiqueta </systemList>
        awk -v new_system="$nuevo_sistema" '/<\/systemList>/ {print new_system} 1' "$es_systems_cfg" > temp.xml && mv temp.xml "$es_systems_cfg"
    fi
}

#################################
# Función para ajustar emuladores
#################################
ajustes_emuladores() {
    # Directorio de emuladores
    local emulators_dir="/opt/retropie/emulators"
    # Directorio de ajustes
    local ajustes_dir="/home/$SUDO_USER/RetroPie/roms/ajustes"

    # Verificar si existe platforms.cfg
    if [ -f "$platforms_cfg" ]; then
        # Agregar las líneas al final del archivo
        echo "ajustes_exts=\".sh\"" >> "$platforms_cfg"
        echo "ajustes_fullname=\"Ajustes\"" >> "$platforms_cfg"
        echo "ajustes_command=\"%ROM%\"" >> "$platforms_cfg"
        echo "ajustes_platform=\"config\"" >> "$platforms_cfg"
    else
        # Crear platforms.cfg y agregar las líneas
        echo "ajustes_exts=\".sh\"" > "$platforms_cfg"
        echo "ajustes_fullname=\"Ajustes\"" >> "$platforms_cfg"
        echo "ajustes_command=\"%ROM%\"" >> "$platforms_cfg"
        echo "ajustes_platform=\"config\"" >> "$platforms_cfg"
    fi

    mkdir -p "$ajustes_dir"

    for emulador in "$emulators_dir"/*; do
        # Obtener el nombre del emulador
        emulador_name=$(basename "$emulador")
        # Directorio binario del emulador
        bin_dir="$emulador/bin"

        # Verificar si el emulador no es retroarch ni mupen64plus,
        # si el directorio binario existe y no está vacío
        if [[ "$emulador_name" != "retroarch" && "$emulador_name" != "mupen64plus" && -d "$bin_dir" && -n "$(ls -A "$bin_dir")" ]]; then
            # Iterar sobre los archivos en el directorio binario
            for executable in "$bin_dir"/*; do
                # Verificar si el archivo es ejecutable
                if [ -x "$executable" ]; then
                    # Obtener el nombre del ejecutable
                    executable_name=$(basename "$executable")

                    # Omitir rpcs3.AppImage_old
                    if [[ "$executable_name" == "rpcs3.AppImage_old" ]]; then
                        continue
                    fi

                    # Crear el script especial para rpcs3.AppImage
                    if [[ "$emulador_name" == "rpcs3-appImage" && "$executable_name" == "rpcs3.AppImage" ]]; then
                        # Script para actualizar rpcs3
                        local update_script_path="$ajustes_dir/actualizar_rpcs3.sh"
                        echo "Creando script especial para actualizar el emulador $emulador_name ($executable_name)..."
                        echo "#!/bin/bash" > "$update_script_path"
                        echo "cd \"$bin_dir\"" >> "$update_script_path"
                        echo "sudo ./$executable_name" >> "$update_script_path"
                        chmod +x "$update_script_path"

                        # Script para ejecutar rpcs3 después de la actualización
                        if [ -f "$bin_dir/rpcs3.AppImage_old" ]; then
                            local execute_script_path="$ajustes_dir/rpcs3.sh"
                            echo "Creando script para ejecutar el emulador actualizado $emulador_name..."
                            echo "#!/bin/bash" > "$execute_script_path"
                            echo "cd \"$bin_dir\"" >> "$execute_script_path"
                            echo "./$executable_name" >> "$execute_script_path"
                            chmod +x "$execute_script_path"
                        fi
                    else
                        # Crear la ruta completa y correcta del ejecutable
                        local executable_path="$bin_dir/$executable_name"
                        # Crear el script en el directorio de ajustes
                        local script_path="$ajustes_dir/$executable_name.sh"
                        echo "Creando script para el emulador $emulador_name ($executable_name)..."
                        echo "#!/bin/bash" > "$script_path"
                        echo "cd \"$bin_dir\"" >> "$script_path"
                        echo "./$executable_name" >> "$script_path"
                        chmod +x "$script_path"
                    fi
                fi
            done
        fi
    done

    if ! grep -q '<name>ajustes</name>' "$es_systems_cfg"; then
        # Definir el nuevo sistema
        nuevo_sistema=$(cat << EOF
  <system>
    <name>ajustes</name>
    <fullname>Configuraciones</fullname>
    <path>/root/RetroPie/roms/ajustes</path>
    <extension>.sh</extension>
    <command>%ROM%</command>
    <platform>config</platform>
    <theme>ajustes</theme>
  </system>
EOF
)
        # Insertar el nuevo sistema antes de la etiqueta </systemList>
        awk -v new_system="$nuevo_sistema" '/<\/systemList>/ {print new_system} 1' "$es_systems_cfg" > temp.xml && mv temp.xml "$es_systems_cfg"
    fi
}

###################################################

while true; do
    # Mostrar el menú y capturar la selección
    opciones=$(dialog --checklist "Seleccione los scripts a ejecutar:" 20 60 5 \
        1 "Instalar RPCS3 (Play Station 3)" off \
        2 "Instalar Yuzu (Nintendo Switch)" off \
        3 "Instalar Steam" off \
        4 "Ajustes Emuladores" off \
        5 "Salir" off 3>&1 1>&2 2>&3 3>&-)

    respuesta=$?

    if [[ $respuesta -eq 1 || $respuesta -eq 255 || "$opciones" == *5* ]]; then
        clear
        echo "Salida del script de Super-Retropie."
        echo "Instalación cancelada."
        exit 1
    fi

    # Mostrar advertencia si se selecciona Yuzu
    if echo "$opciones" | grep -q "2"; then
        dialog --msgbox "Para poder instalar Yuzu, necesitas previamente tener yuzu.AppImage en la carpeta de Descargas de tu equipo." 10 60
    fi

    # Confirmar la selección
    dialog --yesno "¿Desea continuar con la instalación de los scripts seleccionados?" 10 60
    if [[ $? -eq 0 ]]; then
        # Acciones basadas en la selección del usuario
        clear
        for opcion in $opciones; do
            case $opcion in
                1)
                    echo "Instalando RPCS3..."
                    instalar_rpcs3
                    ;;
                2)
                    echo "Instalando Yuzu..."
                    instalar_yuzu
                    ;;
                3)
                    echo "Instalando Steam..."
                    instalar_steam
                    ;;
                4)
                    echo "Ajustando Emuladores..."
                    ajustes_emuladores
                    ;;
            esac
        done
        echo "Instalación completada."
    fi
done
