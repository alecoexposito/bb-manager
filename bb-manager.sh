#!/usr/bin/env bash

# Functions definition
show_help() {
	echo "Ayuda del Administrador de Black Box"
	echo "Modo de uso: bb-manager opción"
	echo "Opciones:"
	echo "-h: Muestra esta ayuda"
	echo "-m: Configurar el modem"
	echo "-f: Instalación completa de GPS y Haz Flix"
	echo "-g: Instalación del módulo GPS"
	echo "-a: Instalación del módulo de Haz Flix"
	echo "-c: Adicionar una camara"
  	echo "-n: Configurar hostpad"
  	echo "-v: Configurar vpn"
  	echo "-p: Configurar panic"
}

install_common_dependencies() {
	echo "instalando dependencias comunes"
	sudo apt update
	sudo apt-get update
	echo "instalando dependencias gps"
	echo instalando python-pip
	sudo apt-get install python-pip
	echo "instalando python-dev"
	sudo apt-get install python-dev
	echo instalando python setuptools
	sudo pip install setuptools
	echo "instalando netifaces"
	sudo pip install netifaces
	echo "installing python-daemon"
	sudo pip install python-daemon
	echo instalando python pyserial
	sudo pip install pyserial
}

install_gps_dependencies() {
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
	echo 0 > ~/camera-local/camera-3.jpg
	mkdir ~/video-backup
	mkdir ~/.db
	echo copiando base de datos sqlite
	cp ~/bb/data/bb.sqlite ~/.db
	echo copiando scripts
	cp install_files/scripts ~/ -r
	sudo mkdir /usr/scripts
	sudo cp install_files/scripts/* /usr/scripts
	sudo chmod 777 /usr/scripts -R
	cd ~/scripts
	#wget https://github.com/alecoexposito/bb-watchdog/raw/master/classes/main.py -O bb-watchdog.py
	#sudo cp bb-watchdog.py /usr/scripts/bb-watchdog.py
	echo "activando gps"
	cd ~/scripts
	echo "Adicionando linea para activar gps en /etc/rc.local"
	sudo sed -i "\$i python /home/zurikato/scripts/at-command.py AT+QGPS=1 &" /etc/rc.local
	echo "Activando GPS ahora"
	python at-command.py AT+QGPS=1
}

initialize_gps_flow() {
	cd ~/bb
	echo "Selecciona el IMEI"
	sudo qmicli -d /dev/cdc-wdm0 --dms-get-ids
  imei_tmp=$(sudo qmicli -d /dev/cdc-wdm0 --dms-get-ids | grep -Po 'IMEI:.+' | cut -d \' -f 2)
	cp .env.default .env
  sleep 2;
	read -p "Entre el IMEI: " -i $imei_tmp -e imei < /dev/tty

	sed -i 's:^[ \t]*DEVICE_IMEI[ \t]*=\([ \t]*.*\)$:DEVICE_IMEI='${imei}':' .env
	read -p "Entre el ip del server donde esta el tracker: " -i "69.64.32.172" -e ip_tracker < /dev/tty

	sed -i 's:^[ \t]*TRACKER_IP[ \t]*=\([ \t]*.*\)$:TRACKER_IP='${ip_tracker}':' .env
  api_url="http://${ip_tracker}:3007/api/v1"
  sed -i 's@^[ \t]*API_URL[ \t]*=\([ \t]*.*\)$@API_URL='${api_url}'@' .env

	echo "iniciando app bb"
	pm2 start server.js
	pm2 restart server
	echo "Debe mirar en el admin para ver el id de la bb adicionada"
	read -p "Entre el id de la bb: " bb_id < /dev/tty

	pm2 stop server
	sed -i 's:^[ \t]*DEVICE_ID[ \t]*=\([ \t]*.*\)$:DEVICE_ID='${bb_id}':' .env
	pm2 start server
	pm2 startup
	sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u zurikato --hp /home/zurikato
	pm2 save
}

create_hazflix_folders() {
	echo "creando carpetas y ficheros para haz flix"
	cd ~/installer
	sudo cp install_files/apache2/www/* /var/www/html/ -r
	sudo mkdir /var/www/html/uploads
	sudo chmod 777 /var/www/html/uploads -R
	sudo cp install_files/apache2/sites_available/* /etc/apache2/sites-available
	sudo a2ensite android windows apple uploads
	sudo a2enmod rewrite
	sudo systemctl restart apache2
}

setup_modem() {
	echo "copying modem files"

	sudo apt-get install libqmi-utils udhcpc
	# sudo apt-get install perl
	# sudo cpan install Device::Modem
	# sudo cpan install Device::Gsm
	sudo cp install_files/modem/etc/network/interfaces.d/wwan0 /etc/network/interfaces.d/
	sudo cp install_files/modem/etc/qmi-network.conf /etc/
	sudo cp install_files/modem/usr/local/bin/qmi-network-raw /usr/local/bin/
	echo "starting modem"
	sudo /sbin/ifdown wwan0
	sleep 3
	sudo /sbin/ifup wwan0
  echo "copiando scripts"
	mkdir /home/zurikato/scripts
	sudo cp install_files/scripts/ /home/zurikato/ -r
	sudo chmod +x /home/zurikato/scripts/watchdog.sh
	sudo chmod +x /home/zurikato/scripts/at-command.py

	line="*/2 * * * * /home/zurikato/scripts/watchdog.sh >> /root/log/watchdog.log; /bin/sync /root/log/watchdog.log; /bin/sync"
	(sudo crontab -u root -l; sudo echo "$line" ) | sudo crontab -u root -
	echo "agregado watchdog al crontab de root"

  setup_restart

}

setup_restart() {
  echo "configurando para que reinicie por admin y por sms"
	sudo chmod +x /home/zurikato/scripts/restart-bb.py
	LINE_REBOOT="@reboot sleep 10; /usr/bin/python /home/zurikato/scripts/restart-bb.py &"
	(sudo crontab -u root -l; sudo echo "$LINE_REBOOT" ) | sudo crontab -u root -
	echo "agregado restart al crontab de root para reiniciar desde admin"

  echo "instalando smstools"
  sudo apt-get install smstools
	sudo chmod +x /home/zurikato/scripts/receive-message.sh

  sudo cp install_files/restart/smsd.conf /etc/smsd.conf
}



install_gps() {
	install_common_dependencies
	install_gps_dependencies
	create_gps_folders
	initialize_gps_flow
  line="@reboot sleep 15; pm2 restart server"
  (crontab -u zurikato -l; echo "$line" ) | crontab -u zurikato -
  echo "agregado restart pm2 en crontab de zurikato"
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

add_camera() {
	read -p "Entre el IP de la camara: " -i "192.168.1.30" -e ip_camera < /dev/tty
	read -p "Entre el ID de la camara: " id_camera < /dev/tty
	mkdir /home/zurikato/video-backup/$id_camera
	mkdir /home/zurikato/camera-local
	echo 0 > /home/zurikato/camera-local/camera-$id_camera.jpg
  echo 0 > /home/zurikato/camera-local/single-camera.jpg
	pm2 start --name record-video-$id_camera /usr/scripts/record-video.sh -- $id_camera $ip_camera
	pm2 startup
	sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u zurikato --hp /home/zurikato
	pm2 save
}

setup_hostpad() {

  sudo cp install_files/hostpad/etc/network/interfaces /etc/network
  read -p "Entre el ip: " -i "192.168.1.50" -e ip_hostapd < /dev/tty
  sudo sed -i '0,/address/{s:^[ \t]*address[ \t]\([ \t]*.*\)$:address '${ip_hostapd}':}' /etc/network/interfaces
  sudo cp install_files/hostpad/etc/hostapd.conf /etc
  read -p "Entre el SSID: " -i "BB-NETWORK" -e ssid < /dev/tty
  sudo sed -i 's:^[ \t]*ssid[ \t]*=\([ \t]*.*\)$:ssid='${ssid}':' /etc/hostapd.conf
  echo 'printf "%s\n" DAEMON_CONF=\"/etc/hostapd.conf\" >> /etc/default/hostapd' | sudo su
  sudo apt-get purge wpasupplicant
  sudo sed -i "\$i net.ipv4.ip_forward=1" /etc/sysctl.conf

#  echo 'printf "%s\n" net.ipv4.ip_forward=1 >> /etc/sysctl.conf' | sudo su
  sudo apt-get install dnsmasq
  sudo cp install_files/hostpad/etc/dnsmasq.conf /etc

  sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
  sudo iptables -t nat -A POSTROUTING -o wwan0 -j MASQUERADE
  sudo iptables -A FORWARD -i wwan0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
  sudo iptables -A FORWARD -i wlan0 -o wwan0 -j ACCEPT
  sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"


  sudo apt-get install ntp
  sudo apt-get install ntpdate
  sudo cp install_files/hostpad/etc/ntp.conf /etc
  sudo service ntp restart
  # echo 'Reiniciando...'
  # sudo reboot
}

install_vpn() {
	echo "instalando paquetes necesarios"
	sudo apt-get install openvpn
	sudo cp install_files/vpn/etc/sudoers.d/zurikato /etc/sudoers.d/zurikato
	sudo update-rc.d openvpn disable

	echo "Adicionando IP Tables"
	sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
	sudo iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
	sudo iptables -A FORWARD -i tun0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
	sudo iptables -A FORWARD -i wlan0 -o tun0 -j ACCEPT
	sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"

	echo "instalada la vpn, ahora debe copiar el fichero /etc/openvpn/strongvpn.conf"
}

install_panic() {
  sudo apt-get install python-pip
  sudo pip install setuptools
  sudo pip install socketclusterclient
  cp install_files/panic/ /home/zurikato -r
  cd /home/zurikato/panic
  sudo git clone https://github.com/herzig/orangepi_PC_gpio_pyH5.git
  cd /home/zurikato/panic/orangepi_PC_gpio_pyH5
  sudo python setup.py install
  cd /home/zurikato/bb-manager
  sudo chmod +x /home/zurikato/panic/run-panic.sh
  line="@reboot sleep 10; /home/zurikato/panic/run-panic.sh"
  (sudo crontab -u root -l; sudo echo "$line" ) | sudo crontab -u root -
  echo "agregado el panic al crontab de root"
  echo "Debe reiniciar para que los cambios tengan efecto"

}

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
output_file=""

while getopts "hgamcnvpi:" opt; do
    case "$opt" in
    h)
        show_help
        exit 0
        ;;
    g)  install_gps
		exit 0
        ;;
    a)	install_hazflix
		exit 0
		;;
    m)	setup_modem
		exit 0
		;;
    n)
      setup_hostpad
      exit 0
      ;;
    v)
      install_vpn
      exit 0
      ;;
    p)
      install_panic
      exit 0
      ;;
    c)
		add_camera
		;;
    esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift

#echo "verbose=$verbose, output_file='$output_file', Leftovers: $@"
