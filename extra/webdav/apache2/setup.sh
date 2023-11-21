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
IMAGE_NAME=apache-webdav
CONTAINER_NAME=apache-webdav
APACHE_DIR=/usr/local/apache2
APACHE_CNF_DIR=/usr/local/apache2/conf

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
	echo -e "\t  (2) create http.conf file"
	echo -e "\t  (3) create initial password file"
	echo -e "\t  (4) show .env content"
	echo -e "\t  ---------------------- DO THESE WHILE DOCKER IS RUNNING"
	echo -e "\t  (a) add another user"
	echo -e "\t  (b) delete a user"
	echo -e "\t  (c) show password file content"
	echo -e "\t  ---------------------- DO THESE WHILE DOCKER IS RUNNING"
	echo -e ""
	echo -e ""
	read -p "       ...(x to exit): " selection

	case $selection in
		1) echo ""
			read -p "        Enter server port number (default:8080): " port
			read -p "        Enter media directory: " target
			# port number
			if [ -z "$port" ]
			then
				port=8080
			fi
			# check if port is number
			if [ "$port" -eq "$port" ] 2>/dev/null
			then
				# check if target is not empty
				if [ -z "target" ]
				then
					# target should be provided
					echo -e "\t${RED}media directory required...${NC}"
				else
					# create .env file
					echo "IMAGE_NAME:${IMAGE_NAME}" > ${SCRIPT_DIR}/.env
					echo "CONTAINER_NAME:${CONTAINER_NAME}" >> ${SCRIPT_DIR}/.env
					echo "PORT_NO:${port}" >> ${SCRIPT_DIR}/.env
					echo "TARGET_DIR:${target}" >> ${SCRIPT_DIR}/.env
					echo -e "\t.env file is created"
				fi
			else
				# port should be a number
				echo -e "\t${RED}invalid port number: ${port}...${NC}"
			fi
			;;

		2) echo ""
			read -p "        Enter Server Domain Name or IP address: " server
			read -p "        Enter Server Admin Email (optional): " admin
			# admin email
			if [ -z "$admin" ]
			then
				admin=you@example.com
			fi
			# server domain name
			if [ -z "$server" ]
			then
				# server name should be provided
				echo -e "\t${RED}server name is required...${NC}"
			else
				# create default config file
				docker run --rm httpd:alpine cat ${APACHE_CNF_DIR}/httpd.conf > httpd.conf
				# enable mod_dav
				sed -i -e "/mod_dav.so/{s/#LoadModule/LoadModule/}" httpd.conf
				# enable mod_dav_fs
				sed -i -e "/mod_dav_fs.so/{s/#LoadModule/LoadModule/}" httpd.conf
				# enable mod_auth_basic
				sed -i -e "/mod_auth_basic.so/{s/#LoadModule/LoadModule/}" httpd.conf
				# set ServerAdmin
				sed -i -e "s/^ServerAdmin.*/ServerAdmin ${admin}/" httpd.conf
				# set ServerName
				sed -i -e "s/^#ServerName.*/ServerName ${server}/" httpd.conf
				# enable httpd-dav.conf
				sed -i -e "/httpd-dav.conf/{s/#Include/Include/}" httpd.conf
			fi
			;;

		3) echo ""
			read -p "        Enter initial username (default: davuser): " username
			read -p "        Enter initial password (default: auto-generated): " password
			# username
			if [ -z "$username" ]
			then
				username=davuser
			fi
			# password
			if [ -z "$password" ]
			then
				password=$(head /dev/random | tr -dc A-Za-z0-9 | head -c12)
			fi
			# create user.passwd
			docker run --rm httpd:alpine htpasswd -nb ${username} ${password} > user.passwd
			# chown
			chown www-data:www-data user.passwd
			# print password
			echo -e "\tpassword file is created... ${LRED}Please keep the password:${NC} ${password}"
			;;

		4) echo ""
			# check if .env exists
			if [ -f ${SCRIPT_DIR}/.env ]
			then
				cat ${SCRIPT_DIR}/.env
			else
				echo -e "\tYou have no .env file... Please create one first."
			fi
			;;



		a) echo ""
			read -p "        Enter username: " username
			read -p "        Enter password (default: auto-generated) " password
			# username
			if [ -z "$username" ]
			then
				# server name should be provided
				echo -e "\t${RED}username is required...${NC}"
			else
				# password
				if [ -z "$password" ]
				then
					password=$(head /dev/random | tr -dc A-Za-z0-9 | head -c12)
				fi
				# create user.passwd inside the container
				docker exec --user www-data apache-webdav htpasswd -b ${APACHE_DIR}/user.passwd ${username} ${password}
				# print password
				echo -e "\tnew account is created. ${LRED}Please keep the password:${NC} ${password}"
			fi
			;;

		b) echo ""
			read -p "        Enter username to delete: " username
			# username
			if [ -z "$username" ]
			then
				# server name should be provided
				echo -e "\t${RED}username is required...${NC}"
			else
				# delete username line from the file
				docker exec apache-webdav sed -i "/${username}/d" ${APACHE_DIR}/user.passwd
				# notify
				echo -e "\taccount(${LGRN}${username}${NC}) is delete"
			fi
			;;

		c) echo ""
			docker exec apache-webdav cat ${APACHE_DIR}/user.passwd
			;;

		x) exit;;

		*) echo -e "\n\tinvalid selection"
	esac

	echo ""
	read -p "        Press enter to continue"
done
