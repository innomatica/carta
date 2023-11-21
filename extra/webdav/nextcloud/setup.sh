#!/bin/bash

NC='\033[0m'
BLK='\033[0;30m'
RED='\033[0;31m'
GRN='\033[0;32m'
BRN='\033[0;33m'
BLU='\033[0;34m'
PPL='\033[0;35m'
CYN='\033[0;36m'
GRY='\033[1;30m'
YEL='\033[1;33m'
WHT='\033[1;37m'
LRED='\033[1;31m'
LGRN='\033[1;32m'
LBLU='\033[1;34m'
LPPL='\033[1;35m'
LCYN='\033[1;36m'
LGRY='\033[0;37m'

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# check if docker is running
if ! docker info > /dev/null 2>&1; then
	echo -e "\n\t${RED}Docker is not running... exit${NC}"
	exit 1
fi

while :
do
	clear
	echo -e "\n\tSCRIPT_DIR: ${LGRN}${SCRIPT_DIR}${NC}\n"
	echo -e "\tSelect menu:\n"
	echo -e "\t  (1) create .env file"
	echo -e "\t  (2) mount media directory (DO THIS AFTER SETUP)"
	echo -e ""
	echo -e "\t  (a) show .env contents"
	echo -e ""
	read -p "       ...(x to exit): " selection

	case $selection in
		1) echo ""
			read -p "        Enter admin username (default: admin): " admin
			read -p "        Enter admin password (default: auto-generated): " password
			read -p "        Enter media directry: " target
			read -p "        Enter server domain name: " domain
			read -p "        Enter server port number (default: 8080): " port

			# username
			if [ -z "$admin" ]
			then
				admin=admin
			fi
			# password
			if [ -z "$password" ]
			then
				password=$(head /dev/random | tr -dc A-Za-z0-9 | head -c12)
			fi
			# port number
			if [ -z "$port" ]
			then
				port=8080
			fi

			# check if port is number
			if [ "$port" -eq "$port" ] 2>/dev/null
			then
				if [ -z "$domain" ]
				then
					cho -e "\t${RED}domain name required...${NC}"
				else
					# create nextcloud data directory
					sudo rm -rf /var/www/nextcloud
					sudo mkdir -p /var/www/nextcloud
					sudo chown www-data:www-data  /var/www/nextcloud
					# create .env file
					echo "ADMIN_USERNAME:${admin}" > ${SCRIPT_DIR}/.env
					echo "ADMIN_PASSWORD:${password}" >> ${SCRIPT_DIR}/.env
					echo "DOMAIN_NAME:${domain}" >> ${SCRIPT_DIR}/.env
					echo "PORT_NO:${port}" >> ${SCRIPT_DIR}/.env
					echo -e "\t.env file is created"
				fi
			else
				# port should be a number
				echo -e "\t${RED}invalid port number: ${port}...${NC}"
			fi
			;;

		2) echo ""
			read -p "        Did you initialize the Nextcloud? (y/n) " answer
			# ready to proceed?
			if [ ${answer} != "y" ]
			then
				echo -e "\tLog in to your Nextcloud server and initialize the database"
			else
				read -p "        Enter media directory: " target
				read -p "        Enter username to whom the directory belongs: " username
				# check if target is valid
				if [ -z "target" ]
				then
					echo -e "\t${RED}media directory required...${NC}"
				else
					# create directory
					echo "Creating Media directory"
					sudo mkdir -p /var/www/nextcloud/${username}/files/Media
					# mv or cp
					echo "Copying ${target} under Media directory"
					sudo cp -a ${target} /var/www/nextcloud/${username}/files/Media
					# chown
					sudo chown -R www-data:www-data /var/www/nextcloud/${username}/files/Media
					# call scan
					docker exec --user www-data nextcloud /var/www/html/occ files:scan --all
				fi
			fi
			;;

		a) echo ""

			if [ -f ${SCRIPT_DIR}/.env ]
			then
				cat ${SCRIPT_DIR}/.env
			else
				echo -e "\tYou have no .env file... Please create one first."
			fi
			;;

		x) exit;;

		*) echo -e "\n\tinvalid selection"
	esac
	echo ""
	read -p "        Press enter to continue"
done
