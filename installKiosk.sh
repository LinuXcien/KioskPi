#!/bin/bash
# Raspberry Pi Kiosk system written in Bash and Python3 
# (c) 2014 LinuXcien B.V.
#

function switchErrorCheckingOn {
	# Check for variables that are not set (stop script):
	set -o nounset
	# Exit script if non-zero return code detected, unfortunately
	# BASH does not get to error code check, $? won't be set
	# To check for succesful completion of command chec like this
	# command || { echo "command failed"; exit 1; } :
	set -o errexit
}

function init {
	export VERSION=0.1 
	export PI_HOME="/home/pi"
	export DATE=`date +%Y%m%d%H%M%S`
	export PROGNAME=$(basename $0)
	export LOGFILE="installKiosk_$VERSION_$DATE.log"
	export LOCALE_VAR="nl_NL.UTF-8 UTF-8"
	export LOCALE_DEFAULT="nl_NL.UTF-8"
	export AUTOLOGINUSER="pi"
	export KIOSKPAGE="http://127.0.0.1:8000/cgi-bin/kiosk.py"
	export CRONTAB_AUTOLOGINUSER='*/5 * * * * /home/pi/bin/cronScript.sh'
	export CRONTAB_ROOT='0 5 * * *  /sbin/shutdown -r now'
	export PY3BINARY=/usr/bin/python3
	export CGI_BIN="cgi-bin"
	echo "Script $PROGNAME, version $VERSION"
	echo "Prepare fresh Raspbian Kiosk"
}

function create_log_file() {
	touch $LOGFILE || oops "$LINENO: Cannot create logfile."
}

function oops {
	# Using tput setaf to set forground color to red and back to white
	echo -n "$(tput setaf 1)"
	echo -n "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	echo "$(tput setaf 7)"
	echo "${PROGNAME}: ${1:-"Unknown Error"}" >>$LOGFILE
	exit 1 
}

function fix_locale {
	echo "Locale setup....."
	sudo bash -c 'echo "nl_NL.UTF-8 UTF-8"  >> /etc/locale.gen' || oops "$LINENO: Error writing to /etc/local.gen."
	sudo cp /etc/default/locale /etc/default/locale.backup.$DATE >>$LOGFILE ||  sudo touch /etc/default/locale
	sudo bash -c 'echo LANG=nl_NL.UTF-8  > /etc/default/locale' || oops "$LINENO: Error writing to /etc/default/locale."
	sudo bash -c 'echo LC_ALL=nl_NL.UTF-8  >> /etc/default/locale' || oops "$LINENO: Error writing to /etc/default/locale."
	sudo bash -c 'echo LANGUAGE=nl_NL.UTF-8  >> /etc/default/locale' || oops "$LINENO: Error writing to /etc/default/locale."
	sudo locale-gen >>$LOGFILE || oops "$LINENO: Error running locale-gen."
	#source /etc/default/locale || oops "$LINENO: Failing to add language environment variables from default locale."
	export LC_ALL=nl_NL.UTF-8 
	export LANG=nl_NL.UTF-8
}

function set_keyboard_layout() {
	echo "Setting keyboard layout.... (Dutch)"
	sudo cp /etc/default/keyboard /etc/default/locale.backup.$DATE >>$LOGFILE ||  sudo touch /etc/default/keyboard
	sudo bash -c 'echo XKBMODEL="pc105" > /etc/default/keyboard' || oops "$LINENO: Error writing to /etc/default/keyboard."
	sudo bash -c 'echo XKBLAYOUT="us" >> /etc/default/keyboard' || oops "$LINENO: Error writing to /etc/default/keyboard."
	sudo bash -c 'echo XKBVARIANT="euro" >> /etc/default/keyboard' || oops "$LINENO: Error writing to /etc/default/keyboard."
	sudo bash -c 'echo XKBOPTIONS="" >>  /etc/default/keyboard' || oops "$LINENO: Error writing to /etc/default/keyboard."
	sudo bash -c 'echo BACKSPACE="guess" >> /etc/default/keyboard' || oops "$LINENO: Error writing to /etc/default/keyboard."
	sudo udevadm trigger --subsystem-match=input --action=change || oops "$LINENO: Error running udevadm to update keyboard layout."
}

function set_timezone() {
	echo "Timezone setup....."
	#echo "sudo debconf-set-selections debconf/frontend select noninteractive" | sudo debconf-set-selections || oops "$LINENO: Error setting Debian packaging to non-interactive."
	sudo bash -c 'echo "Europe/Amsterdam" > /etc/timezone' || oops "$LINENO: Error writing to /etc/timezone."
	#sudo dpkg-reconfigure -f noninteractive tzdata << _EOF_ >>$LOGFILE || oops "$LINENO: Could not set timezone."
#Europe
#Amsterdam
#_EOF_
	sudo dpkg-reconfigure -f noninteractive tzdata
}

function updateDebian {
	echo "Updating Debian system ....."
	sudo apt-get -y update >>$LOGFILE || oops "$LINENO: Error running apt-get update." 
	sudo apt-get -y upgrade >>$LOGFILE || oops "$LINENO: Error running apt-get upgrade."
	# sudo apt-get -y dist-upgrade || oops "$LINENO: Error running apt-get dist-upgrade."
}

function enableBootToDesktop() {
	# Inspired by raspi-config
	echo "Enable boot to desktop for $AUTOLOGINUSER."
	if [ -e /etc/init.d/lightdm ]; then
		if id -u $AUTOLOGINUSER > /dev/null 2>&1; then
			sudo update-rc.d lightdm enable 2 >>$LOGFILE || oops "$LINENO: Failed to enable lightdm."
			sudo sed /etc/lightdm/lightdm.conf -i -e "s/^#autologin-user=.*/autologin-user=$AUTOLOGINUSER/" >>$LOGFILE || oops "$LINENO: Failed to adjust lightdm configuration."
			#disable_boot_to_scratch
			# disable_raspi_config_at_boot
		else
			oops "$LINENO: The $AUTOLOGINUSER user does not exist, can't set up boot to desktop" 
		fi
	else
		oops "$LINENO: Do sudo apt-get install lightdm to allow configuration of boot to desktop" 
	fi
}

function silent_boot {
	echo "Enable quiet boot startup process."
	sudo cp /boot/cmdline.txt /boot/cmdline.txt_$DATE >>$LOGFILE || oops "$LINENO: Failing to make backup copy of /boot/cmdline.txt."
	sudo sed /boot/cmdline.txt -i -e "s/console=tty1/console=tty3/g" >>$LOGFILE || oops "$LINENO: Error adjusting redirection output to tty3."
	if grep "quiet boot" /boot/cmdline.txt; then
		echo "cmdline.tx already patched, skipping."
	else
		sudo sed /boot/cmdline.txt -i -e "s/$/ quiet boot/g" >>$LOGFILE || oops "$LINENO: Error enabling silent boot."
	fi
}

function installLinuXcienBackground {
	echo "Setting LinuXcien background for $AUTOLOGINUSER."
	sudo mv /etc/alternatives/desktop-background /etc/alternatives/desktop-background-original >>$LOGFILE || oops "$LINENO: Failing to make backup copy of original background logo."
	sudo ln -s /home/$AUTOLOGINUSER/bin/DesignedByLinuXcien.png /etc/alternatives/desktop-background  >>$LOGFILE || oops "$LINENO: Failing to install LinuXcien background logo."
	sudo rm /home/$AUTOLOGINUSER/Desktop/* 

}

function installVim {
	echo "Installing VIM ....."
	sudo apt-get -y install vim >>$LOGFILE || oops "$LINENO: Error installing vim."
}

function install_lighttpd() {
	echo "Installing lighttpd."
	sudo apt-get -y install lighttpd >>$LOGFILE || oops "$LINENO: Error installing lighttpd"
	sudo chown -R www-data:www-data /var/www >>$LOGFILE || oops "$LINENO: Failing to set security on /var/www."
	# Enabling fast-cgi and fast-cgi for PHP
	sudo ln -s /etc/lighttpd/conf-available/10-fastcgi.conf /etc/lighttpd/conf-enabled/10-fastcgi.conf >>$LOGFILE || oops "$LINENO: Failing to enable fastcgi."
	sudo ln -s /etc/lighttpd/conf-available/15-fastcgi-php.conf /etc/lighttpd/conf-enabled/15-fastcgi-php.conf >>$LOGFILE || oops "$LINENO: Failing to enable fastcgi for PHP."
	sudo apt-get -y install php5-common php5-cgi php5 >>$LOGFILE || oops "$LINENO: Failing to install php5 modules."
	#sudo lighty-enable-mod fastcgi-php >>$LOGFILE || oops "$LINENO: Failing to enable fastcgi-php."
	sudo service lighttpd restart >>$LOGFILE || oops "$LINENO: Failing to restart lighttpd."
}

function preparePython {
	echo "Installing required Python 3 modules."
	sudo apt-get install -y python3-pip >>$LOGFILE || oops "$LINENO: Error installing python3 pip."
	#sudo apt-get -y install python3-bs4 >>$LOGFILE || oops "$LINENO: Error installing Python3 bs."
	sudo /usr/bin/pip-3.2 install beautifulsoup4 >>$LOGFILE || oops "$LINENO: Error installing Beautiful Soup 4 through pip."
	sudo /usr/bin/pip-3.2 install pyvirtualdisplay >>$LOGFILE || oops "$LINENO: Error installing pyvirtualdisplay through pip."
	sudo /usr/bin/pip-3.2 install -U selenium >>$LOGFILE || oops "$LINENO: Error installing selenium through pip."
	mkdir $PI_HOME/cgi-bin >>$LOGFILE || oops "$LINENO: Error making Python cgi-bin directory."
	cp /home/$AUTOLOGINUSER/bin/kiosk.py $PI_HOME/cgi-bin
	chmod u+x $PI_HOME/cgi-bin/kiosk.py
}

function install_CGIServer_script() {
	# Adjust the IP address in httpd object to 0.0.0.0 for access on all interfaces (security risk!)
	echo "On Python 3.2 can only enable Python CGI server from within script."
	cat > /home/$AUTOLOGINUSER/bin/CGIServer.py << _EOF_ || oops "$LINENO: Error installing Python 3.2 CGIServer script."
#!/usr/bin/env python3
import http.server

class Handler(http.server.CGIHTTPRequestHandler):
	cgi_directories = ['/cgi-bin']

httpd = http.server.HTTPServer(("127.0.0.1", 8000), Handler)
httpd.serve_forever()
_EOF_
	chmod +x /home/$AUTOLOGINUSER/bin/CGIServer.py || oops "$LINENO: Cannot set execute permissions on CGIServer script."
}

function installChromium {
	echo "Installing Chromium browser (will run Kiosk mode)."
	sudo apt-get -y install chromium >>$LOGFILE || oops "$LINENO: Error installing Chromium."
	# Must be done for user account that will run Chrome
	#sed -i 's/"exited_cleanly": false/"exited_cleanly": true/' ~/.config/chromium/Default/Preferences >>$LOGFILE || oops "$LINENO: Error adjusting Chromium exited clean setting."

}

function install_Chromium_startupscript() {
	echo "Installing Chromium startup script (run from LXDE autostart)"
	cat > /home/$AUTOLOGINUSER/bin/startChromium.sh << _EOF_ || oops "$LINENO: Error installing Chromium auto startup script."
#!/bin/sh
killall -TERM chromium 2>/dev/null;
killall -9 chromium 2>/dev/null;
rm -rf /home/$AUTOLOGINUSER/.cache;
rm -rf /home/$AUTOLOGINUSER/.config/chromium;
rm -rf /home/$AUTOLOGINUSER/.pki;
mkdir -p /home/$AUTOLOGINUSER/.config/chromium/Default
sqlite3 /home/$AUTOLOGINUSER/.config/chromium/Default/Web\ Data "CREATE TABLE meta(key LONGVARCHAR NOT NULL UNIQUE PRIMARY KEY, value LONGVARCHAR); INSERT INTO meta VALUES('version','46'); CREATE TABLE keywords (foo INTEGER);";
chromium --noerrdialogs --disable-translate --disable-infobars --disable-suggestions-service --kiosk http://127.0.0.1:8000/cgi-bin/kiosk.py
_EOF_
	chmod u+x /home/$AUTOLOGINUSER/bin/startChromium.sh  >> $LOGFILE || oops "$LINENO: Error setting executable security on Chromium auto startup script."
}

function installXserverutilsUnclutter {
	echo "Installing x11 server utilities and unclutter (removes cursus from screen)."
	sudo apt-get -y install x11-xserver-utils unclutter >>$LOGFILE || oops "$LINENO: Error installing x11 server utils and unclutter."
}

function install_sqlite {
	echo "Installing sqlite3."
	sudo apt-get -y install sqlite3 libsqlite3-dev php5-sqlite >>$LOGFILE || oops "$LINENO: Error installing sqlite version 3."
	#sudo service lighttpd restart >>$LOGFILE || oops "$LINENO: Failing to restart lighttpd."
}


function prepareKiosk() {
	echo "Preparing Pi for kiosk functionality."
	cat > /home/$AUTOLOGINUSER/bin/startChromium.sh << _EOF_ || oops "$LINENO: Error creating Chromium startup script."
#!/bin/sh
# Clean up previously running apps, gracefully at first then harshly
killall -TERM chromium 2>/dev/null;
killall -9 chromium 2>/dev/null;
# Clean out existing profile information
rm -rf /home/pi/.cache;
rm -rf /home/pi/.config/chromium;
rm -rf /home/pi/.pki;
# Generate the bare minimum to keep Chromium happy!
# Solves problem with Chromium detecting improper shutdown
mkdir -p /home/pi/.config/chromium/Default
sqlite3 /home/pi/.config/chromium/Default/Web\ Data "CREATE TABLE meta(key LONGVARCHAR NOT NULL UNIQUE PRIMARY KEY, value LONGVARCHAR); INSERT INTO meta VALUES('version','46'); CREATE TABLE keywords (foo INTEGER);";
chromium --noerrdialogs --disable-translate --disable-infobars --disable-suggestions-service --kiosk $KIOSKPAGE
_EOF_
	chmod +x /home/$AUTOLOGINUSER/bin/startChromium.sh >>$LOGFILE ||  oops "$LINENO: Cannot set execute on Chromium startup script."
	# Disabling screensaver:
	sudo cp /etc/xdg/lxsession/LXDE/autostart /etc/xdg/lxsession/LXDE/autostart_$DATE >>$LOGFILE || oops "$LINENO: Failing to make backup copy of LXDE autostart."
	sudo sed -i 's/@xscreensaver -no-splash/#@xscreensaver -no-splash/g' /etc/xdg/lxsession/LXDE/autostart >>$LOGFILE || oops "$LINENO: Error dsiabling screensaver."
	sudo chmod 777 /etc/xdg/lxsession/LXDE/autostart >>$LOGFILE || oops "$LINENO: Error setting security to 777 for /etc/xdg/lxsession/LXDE/autostart."
	cat > /etc/xdg/lxsession/LXDE/autostart << _EOF_  || oops "$LINENO: Error writing to /etc/xdg/lxsession/LXDE/autostart."
@xset s off
@xset -dpms
@xset s noblank
#$PY3BINARY -m http.server --cgi
/home/$AUTOLOGINUSER/bin/CGIServer.py
/home/$AUTOLOGINUSER/bin/startChromium.sh
_EOF_
	sudo chmod 644 /etc/xdg/lxsession/LXDE/autostart >>$LOGFILE || oops "$LINENO: Error setting security to 644 for /etc/xdg/lxsession/LXDE/autostart."
}

function install_phantomjs() {
	echo "Installing phantomjs in /usr/local/bin"
	sudo cp /home/$AUTOLOGINUSER/bin/phantomjs /usr/local/bin >>$LOGFILE || oops "$LINENO: Error copying phantomjs."
}

function install_static_content() {
	echo "Installing static Kiosk web site content in ~/includes. Files should be uploaded in ~/bin"
	mkdir /home/$AUTOLOGINUSER/includes >>$LOGFILE || oops "$LINENO: Error created includes folder for static content."
	cp /home/$AUTOLOGINUSER/bin/DesignedByLinuXcien_background.png /home/$AUTOLOGINUSER/includes >>$LOGFILE || oops "$LINENO: Cannot copy LinuXcien background image."
	cp /home/$AUTOLOGINUSER/bin/footer.html /home/$AUTOLOGINUSER/includes >>$LOGFILE || oops "$LINENO: Cannot copy footer."
	cp /home/$AUTOLOGINUSER/bin/header.html /home/$AUTOLOGINUSER/includes >>$LOGFILE || oops "$LINENO: Cannot copy header"
	cp /home/$AUTOLOGINUSER/bin/styles.css /home/$AUTOLOGINUSER/includes >>$LOGFILE || oops "$LINENO: Cannot copy styles"
	cp /home/$AUTOLOGINUSER/bin/scraped_included.html /home/$AUTOLOGINUSER/includes >>$LOGFILE || oops "$LINENO: Cannot copy initial scraped content"
}

function prepare_cron_script() {
	echo "Preparing Pi for kiosk functionality."
	echo "#!/bin/bash" > /home/$AUTOLOGINUSER/bin/cronScript.sh  || oops "$LINENO: Error creating cron script."
        echo "export DATE=\`date +\"%Y-%m-%d-%H:%M:%S\"\`" >> /home/$AUTOLOGINUSER/bin/cronScript.sh  || oops "$LINENO: Error creating cron script."
	echo "export AUTOLOGINUSER=$AUTOLOGINUSER">> /home/$AUTOLOGINUSER/bin/cronScript.sh  || oops "$LINENO: Error creating cron script."
	echo "export SCRAPED=/home/$AUTOLOGINUSER/bin/scraped.html" >> /home/$AUTOLOGINUSER/bin/cronScript.sh  || oops "$LINENO: Error creating cron script."
	echo "export SCRAPED_INCLUDE=/home/$AUTOLOGINUSER/includes/scraped_included.html" >> /home/$AUTOLOGINUSER/bin/cronScript.sh  || oops "$LINENO: Error creating cron script."
	echo "export ERROR=/home/$AUTOLOGINUSER/bin/webscrapererror.log" >> /home/$AUTOLOGINUSER/bin/cronScript.sh  || oops "$LINENO: Error creating cron script."
	echo "export PY3BINARY=$PY3BINARY" >> /home/$AUTOLOGINUSER/bin/cronScript.sh  || oops "$LINENO: Error creating cron script."
	echo ""  >> /home/$AUTOLOGINUSER/bin/cronScript.sh  || oops "$LINENO: Error creating cron script."
	echo "function oops {"  >> /home/$AUTOLOGINUSER/bin/cronScript.sh  || oops "$LINENO: Error creating cron script."
	echo "    printf \"\${PROGNAME}: \${1:-\"Unknown Error\"}\/n\" > \$ERROR"  >> /home/$AUTOLOGINUSER/bin/cronScript.sh || oops "$LINENO: Error creating cron script."
	echo "    exit 1" >> /home/$AUTOLOGINUSER/bin/cronScript.sh  || oops "$LINENO: Error creating cron script."
	echo "}" >> /home/$AUTOLOGINUSER/bin/cronScript.sh  || oops "$LINENO: Error creating cron script."
	echo "" >> /home/$AUTOLOGINUSER/bin/cronScript.sh  || oops "$LINENO: Error creating cron script."
	echo "cd /home/$AUTOLOGINUSER/bin" >> /home/$AUTOLOGINUSER/bin/cronScript.sh  || oops "$LINENO: Error creating cron script."
	echo "$PY3BINARY /home/$AUTOLOGINUSER/bin/webScraper.py > \$SCRAPED 2> \$ERROR || oops \"\$LINENO: Problem running Python web scraper.\"" >> /home/$AUTOLOGINUSER/bin/cronScript.sh  || oops "$LINENO: Error creating cron script."
echo "if [ -s "\$SCRAPED" ]" >> /home/$AUTOLOGINUSER/bin/cronScript.sh  || oops "$LINENO: Error creating cron script."
	echo "then" >> /home/$AUTOLOGINUSER/bin/cronScript.sh  || oops "$LINENO: Error creating cron script."
	echo "    printf \"\$SCRAPED has data, \$DATE\\n\" > \$ERROR" >> /home/$AUTOLOGINUSER/bin/cronScript.sh  || oops "$LINENO: Error creating cron script."
	echo "    cp \$SCRAPED \$SCRAPED_INCLUDE" >> /home/$AUTOLOGINUSER/bin/cronScript.sh  || oops "$LINENO: Error creating cron script."
	echo "else" >> /home/$AUTOLOGINUSER/bin/cronScript.sh  || oops "$LINENO: Error creating cron script."
	#echo "    touch empty\$DATE" >> /home/$AUTOLOGINUSER/bin/cronScript.sh  || oops "$LINENO: Error creating cron script."
	echo "    printf \"\$SCRAPED is empty, \$DATE\\n\" > \$ERROR" >> /home/$AUTOLOGINUSER/bin/cronScript.sh  || oops "$LINENO: Error creating cron script."
	echo "fi" >> /home/$AUTOLOGINUSER/bin/cronScript.sh  || oops "$LINENO: Error creating cron script."
	chmod +x /home/$AUTOLOGINUSER/bin/cronScript.sh
}

function set_crontabs() {
	echo "Installing crontab for $AUTOLOGINUSER."
	(crontab -l ; echo "*/5 * * * * /home/pi/bin/cronScript.sh") 2>&1 | grep -v "no crontab" | sort | uniq | crontab - >>$LOGFILE || oops "$LINENO: Error setting crontab for $AUTOLOGINUSER." 
	echo "Creating weekly crontab reboot."
	sudo bash -c '/bin/touch /etc/cron.weekly/kioskReboot' || oops "$LINENO: Error creating weekly automatic reboot crontab."
	sudo bash -c 'echo "#!/bin/sh" > /etc/cron.weekly/kioskReboot' || oops "$LINENO: Error creating weekly automatic reboot crontab."
	sudo bash -c 'echo "shutdown -r now" >> /etc/cron.weekly/kioskReboot' || oops "$LINENO: Error creating weekly automatic reboot crontab."
	sudo chmod +x /etc/cron.weekly/kioskReboot
}	

init
create_log_file
fix_locale
set_keyboard_layout
set_timezone
updateDebian
installVim
enableBootToDesktop
silent_boot
installLinuXcienBackground
#install_lighttpd
install_sqlite
preparePython
install_phantomjs
install_static_content
install_CGIServer_script
installChromium
install_Chromium_startupscript
installXserverutilsUnclutter
prepareKiosk
prepare_cron_script
set_crontabs

