https://github.com/raelgc/retropie_rpcs3-appImage

https://ericslenk.com/posts/running-steam-games-from-emulationstation

https://github.com/MizterB/RetroPie-Setup-Ubuntu

https://github.com/archtaurus/RetroPieBIOS

https://www.reddit.com/r/retroid/comments/1b7ugxj/upcoming_emulationstation_removes_yuzu_option/

https://github.com/ivan-hc/Steam-appimage



desactivar audio USB:
```
sudo nano /etc/modprobe.d/blacklist.conf
```
```
# Desactivar audio USB
blacklist snd_usb_audio
```
instalar super retropie:
```
sudo bash -c "$(wget -qLO - https://raw.githubusercontent.com/MacRimi/Super-RetroPie/main/super-retropie.sh)"
```
menu:
```
sudo bash -c "$(wget -qLO - https://raw.githubusercontent.com/MacRimi/Super-RetroPie/main/scripts/menu-super-retropie.sh)"
```

######### yuzu ##########
```
wget https://raw.githubusercontent.com/MacRimi/SuperEmulator/main/scripts/yuzu-AppImage.sh -O ~/RetroPie-Setup/scriptmodules/emulators/yuzu-AppImage.sh
```

######### cemu ########
```
wget https://raw.githubusercontent.com/MacRimi/SuperEmulator/main/scripts/cemu.AppImage.sh -O ~/RetroPie-Setup/scriptmodules/emulators/cemu.AppImage.sh
```
######## steam ########
```
wget https://raw.githubusercontent.com/MacRimi/SuperEmulator/main/scripts/steam-AppImage.sh -O ~/RetroPie-Setup/scriptmodules/emulators/steam-AppImage.sh
```
evitar mensaje de confirmacion al ejecutar:
```
sudo dpkg-reconfigure debconf
```
```
cd ~/RetroPie-Setup
sudo ./retropie_setup.sh
```

