#!/bin/bash 
	# This script is for monitering 
	# server partition and send mail
	# alerts if reached threshold
# written by Suhas U Kekuda 

#Email address
SENDER_USERNAME="suk.creations@gmail.com"
SENDER_PASSWORD="***********"

#SMPT details 
RELAY_SERVER="smtp://smtp.gmail.com:587"


#Recipient address
RECIPIENT_ADDRESS="suhaskekuda@gmail.com"

#Mailer notification
MAIL_CONTENT="mailer.txt"

#Directory to validate space seperated as array 
declare -a DIRECTORIES=("/" "/boot")

#limit for hardisk threshold 
THRESHOLD_RED="80"
THRESHOLD_AMBER="60"


SEND_MAIL(){
	curl --connect-timeout 15 -v --insecure ${RELAY_SERVER} -u "${SENDER_USERNAME}:${SENDER_PASSWORD}" --mail-from ${SENDER_USERNAME} --mail-rcpt ${RECIPIENT_ADDRESS} -T ${MAIL_CONTENT} --ssl	>> /dev/null 2>&1
	
	RET=$?
	if [ "x${RET}" == "x0" ];then
		echo "Mail sent successfully to ${RECIPIENT_ADDRESS}"	
	fi
}


VALIDATE_USAGE(){
	> ${MAIL_CONTENT}
	RED=0
	AMBER=0
	
	
	echo -e "Subject: Critical diskspace for partition \n" >> ${MAIL_CONTENT}
	printf "%20s %10s\n" "Partition" "Status" >> ${MAIL_CONTENT}
	for i in "${DIRECTORIES[@]}"
	do
		VALIDATE_VALUE=$(df -P | grep -w "${i}" | awk '{print $5}' | tr -d '%')
		EXEC_OPT=0
		STATE="GREEN"
		
		if [ ${VALIDATE_VALUE} -ge ${THRESHOLD_AMBER} ];then 
			EXEC_OPT=1
			STATE="AMBER"
			((AMBER=AMBER + 1))
		fi
		
		if [ ${VALIDATE_VALUE} -ge ${THRESHOLD_RED} ];then 
			EXEC_OPT=1
			STATE="RED"
			((RED=RED + 1))
			((AMBER=AMBER - 1))
		fi
		
		printf "%20s %10s\n" ${i} ${STATE} >> ${MAIL_CONTENT}
	done	
	
	
	INSIGHT="Out of ${#DIRECTORIES[@]} partitions,"
	if [ ${AMBER} -ge 1 ];then
		INSIGHT="${INSIGHT} ${AMBER} partition in Amber and"
	fi
	
	if [ ${RED} -ge 1 ];then
		INSIGHT="${INSIGHT} ${RED} in Red"
	fi
	
	echo -e "\n${INSIGHT}" >> ${MAIL_CONTENT}
	
	if [ ${AMBER} -ge 1 ] || [ ${RED} -ge 1 ] ;then
		SEND_MAIL	
	fi
	
}


SHOW_HELP() {
	cat <<_EOF
		Usage  : $0 <options>	     
	Options:
	--validate   for running partition validation
_EOF
	}


MAIN(){
	case $1 in
		--validate)
			VALIDATE_USAGE
		;;
		*)	
			SHOW_HELP
		;;
	esac	
}

MAIN $*