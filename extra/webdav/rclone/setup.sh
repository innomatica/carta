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
PASSWD_FNAME=davpass

while :
do
	clear
	echo -e "\n\tSCRIPT_DIR: ${LGRN}${SCRIPT_DIR}${NC}\n"
	echo -e "\tSelect menu:\n"
	echo -e "\t  (1) create a APR1 password file"
	echo -e "\t  (2) create a MD5 password file (not recommended)"
	echo -e ""
	read -p "       ...(x to exit): " selection

	case $selection in
		1) echo ""
			read -p "        Enter username (default: admin): " username
			read -p "        Enter password (default: auto-generated): " password
			# check username
			if [ -z "$username" ]
			then
				username=admin
			fi
			# check password
			if [ -z "$password" ]
			then
				password=$(head /dev/random | tr -dc A-Za-z0-9 | head -c12)
			fi
			# create a new password file
			printf "${username}:$(openssl passwd -apr1 ${password})\n" > ${PASSWD_FNAME}

			# print password
			echo -e "\n\tThe password file is created... "
			echo -e "\t${LRED}Keep the password in a safe place now: ${BLU}${password}${NC}"
			;;

		2) echo ""
			read -p "        Enter username (default: admin): " username
			read -p "        Enter password (default: auto-generated): " password
			# check username
			if [ -z "$username" ]
			then
				username=admin
			fi
			# check password
			if [ -z "$password" ]
			then
				password=$(head /dev/random | tr -dc A-Za-z0-9 | head -c12)
			fi
			# create a new password file
			printf "${username}:$(openssl passwd -1 ${password})\n" > ${PASSWD_FNAME}

			# print password
			echo -e "\n\tThe password file is created... "
			echo -e "\t${LRED}Keep the password in a safe place now: ${BLU}${password}${NC}"
			;;

		x) exit;;

		*) echo -e "\n\tinvalid selection"
	esac

	echo ""
	read -p "        Press enter to continue"
done

