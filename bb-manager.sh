#!/usr/bin/env bash

# Functions definition
show_help() {
	echo "Ayuda del Administrador de Black Box"
	echo "Modo de uso: bb-manager opción"
	echo "Opciones:"
	echo "-h: Muestra esta ayuda"
	echo "-f: Instalación completa de GPS y Haz Flix"
	echo "-g: Instalación del módulo GPS"
	echo "-a: Instalación del módulo de Haz Flix"
	echo "-c: Adicionar una camara, se le pasa el id de la camara en el admin. Ej. (bb-manager -c 5)"	
}

install_common_dependencies() {
	echo "instalando dependencias comunes"
	sudo apt update
	sudo apt-get update
}

install_gps_dependencies() {
	install_common_dependencies
	echo "instalando dependencias gps"
	echo instalando python-pip
	sudo apt-get install python-pip
	echo instalando python setuptools
	sudo pip install setuptools
	echo instalando python pyserial
	sudo pip install pyserial
	echo instalando nodejs
	curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
	sudo apt-get install -y nodejs
	echo instalando pm2
	sudo npm install pm2@latest -g
	echo instalando ffmpeg
	sudo apt-get install sshfs ffmpeg
	echo instalando gstreamer
	sudo apt-get install gstreamer1.0-rtsp gstreamer1.0-tools gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav
}

install_hazflix_dependencies() {
	install_common_dependencies
	echo "instalando dependencias haz flix"
	echo "instalando apache"
	sudo apt-get install apache2
}

create_gps_folders() {
	echo "creando carpetas y ficheros para gps"
	cd ~
	echo clonando el proyecto
	git clone https://github.com/alecoexposito/bb.git
	cd ~/bb
	echo corriendo npm install
	npm install
	echo creando carpetas necesarias
	mkdir ~/camera
	mkdir ~/camera-local
	echo 0 > ~/camera-local/camera-1.jpg
	mkdir ~/video-backup
	mkdir ~/.db
	echo copiando base de datos sqlite
	cp ~/bb/data/bb.sqlite ~/.db
	echo copiando scripts
	cp ~/bb/scripts ~/ -r
	sudo mkdir /usr/scripts
	sudo cp ~/bb/scripts/* /usr/scripts
	sudo chmod 777 /usr/scripts -R
	echo "activando gps"
	cd ~/scripts
	echo "Adicionando linea para activar gps en /etc/rc.local"
	sudo sed -i "\$i python /home/zurikato/scripts/at-command.py AT+QGPS=1" /etc/rc.local
	echo "Activando GPS ahora"
	python at-command.py AT+QGPS=1
}

initialize_gps_flow() {
	cd ~/bb
	cp .env.default .env
	read -p "Enter IMEI: " imei
	sed -i 's:^[ \t]*DEVICE_IMEI[ \t]*=\([ \t]*.*\)$:DEVICE_IMEI='${imei}':' .env
	echo "iniciando app bb, se mostrarán los logs para que verifique que todo esté bien, salir de los logs con Ctrl + C"
	pm2 start server.js
	pm2 restart server; pm2 logs server
	echo "Debe mirar en el admin para ver el id de la bb adicionada"
	read -p "Entre el id de la bb: " bb_id
	pm2 stop server
	sed -i 's:^[ \t]*DEVICE_ID[ \t]*=\([ \t]*.*\)$:DEVICE_ID='${bb_id}':' .env
	pm2 start server
}

create_hazflix_folders() {
	echo "creando carpetas y ficheros para haz flix"
	cd ~/installer
	sudo cp install_files/apache2/www/* /var/www/html/ -r
	sudo mkdir /var/www/html/uploads
	sudo chmod 777 /var/www/html/uploads -R
	sudo cp install_files/apache2/sites_available/* /etc/apache2/sites_available
	sudo a2ensite android windows apple uploads
	sudo a2enmod rewrite
	sudo systemctl apache2 restart
}

setup_modem() {
	sudo apt-get install ppp
	sudo cp install_files/modem/quectel-chat-connect /etc/ppp/peers/
	sudo cp install_files/modem/quectel-chat-disconnect /etc/ppp/peers/
	sudo cp install_files/modem/quectel-ppp /etc/ppp/peers/
	read -p "Presione Enter para editar el fichero quectel-ppp y ponerle el usuario, contraseña y proveedor para internet"
	sudo nano /etc/ppp/peers/quectel-ppp
	echo "Adicionando linea pppd call quectel-ppp & al fichero /etc/rc.local"
	sudo sed -i "\$i quectel-ppp &" /etc/rc.local
	echo "linea adicionada:"
	cat /etc/rc.local
	echo "modem instalado, debe reiniciar para aplicar los cambios"
	reboot_var = 's'
	read -p "Reiniciar ahora? (S/n)" reboot_var
	if [[ $reboot_var == 's|S' ]]; then
		sudo reboot
	fi
}

setup_watchdog() {
	
}

install_gps() {
	install_common_dependencies
	install_gps_dependencies
	create_gps_folders
	initialize_gps_flow
}

install_hazflix() {
	install_common_dependencies
	install_hazflix_dependencies
	create_hazflix_folders
}

install_full() {
	install_gps
	install_hazflix
}

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
output_file=""
camera_id=0

while getopts "hgac:" opt; do
    case "$opt" in
    h)
        show_help
        exit 0
        ;;
    g)  install_gps_dependencies
		exit 0
        ;;
    a)	install_hazflix_dependencies
		exit 0
		;;
    c)  camera_id=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift

#echo "verbose=$verbose, output_file='$output_file', Leftovers: $@"
