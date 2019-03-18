#!/bin/bash


function usage() {
	echo "usage: $0 [-y]"
	exit 3
}

function affichage() {
echo "============================================================"
echo "$1"
echo "============================================================"
}


while getopts "hy" opts
do
        case $opts in
        y) _YES="-y"
        ;;
        h) usage
        ;;
        *)
        echo "Erreur mauvaise option"
        exit 3
        esac
done



#Configuration du bonding
function bonding(){
local _CONFIGURATION_DIR="/etc/sysconfig/network-scripts/"
while true
do
	while true
	do
		CPT=1
		for int in $(ifconfig | grep -v "^ " |sed -e "/^$/d" | awk '{print $1}')
		do
			echo "$CPT) $int"
			CPT=$(( $CPT + 1))
		done
		echo "Quelles interfaces voulez-vous utiliser pour creer un bonding"
		read _RES1
		read _RES2
		if [[ -n $_RES1 && -n $_RES2 ]]
		then
			break
		else
			echo "Mauvais choix veuillez recommencer"
			read _
		fi
	done
	_CPT=1
	OLD_IFS=$IFS
	for int in $(ifconfig | grep -v "^ " |sed -e "/^$/d" | awk '{print $1}')
	do
		case $_CPT in
		$_RES1)
		_INT1=$(echo $int | cut -d":" -f2)
		;;
		$_RES2)
		_INT2=$(echo $int | cut -d":" -f2)
		esac
		_CPT=$(($_CPT + 1 ))
	done
	echo "Vous avez choisi $_INT1 et $_INT2"
	echo "Veuillez confirmer"
	echo "y/n"
	read _RES
	if [[ $_RES = "n" || $_RES = "N" ]]
	then
		continue
	else
		break
	fi
	echo "Veuillez entrer l'adresse IP de l'interface réseau "
	read _IP_ADDR
	echo "Veuillez enter le masque de sous réseau"
	read _NETMASK
	echo "Veuillez entrer l'adresse IP de la passerelle"
	read _GATEWAY
	[ -e $_CONFIGURATION_DIR/ifcfg-$_INT1 ] && mv $_CONFIGURATION_DIR/ifcfg-$_INT1  $_CONFIGURATION_DIR/ifcfg-$_INT1  $_CONFIGURATION_DIR/ifcfg-$_INT1.old
	[ -e $_CONFIGURATION_DIR/ifcfg-$_INT2 ] && mv $_CONFIGURATION_DIR/ifcfg-$_INT2  $_CONFIGURATION_DIR/ifcfg-$_INT2  $_CONFIGURATION_DIR/ifcfg-$_INT2.old
	echo "DEVICE=bond0
NAME=bond0
Type=Bond
IPADDR=$_IP_ADDR
NETMASK=$_NETMASK
GATEWAY=$_GATEWAY
ONBOOT=yes
BOOTPROTO=static
BONDING_OPTS=\"mode=1 miimon=100\"" > $_CONFIGURATION_DIR/ifcfg-bond0
	echo "DEVICE=$_INT1
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=none
MASTER=bond0
SLAVE=yes" > $_CONFIGURATION_DIR/ifcfg-$_INT1
	echo "DEVICE=$_INT2
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=none
MASTER=bond0
SLAVE=yes" > $_CONFIGURATION_DIR/ifcfg-$_INT2
	echo "Redémarrage du service réseau"
	service network restart
	echo "Voulez-vous vérifier la configuration"
	echo "y/n"
	read _RES
	if [[ $_RES = "y" || $_RES = "Y" ]]
	then
		cat /proc/net/bonding/bond0
		echo "Tentative de ping de la passerelle"
		while true 
		do
			ping -c 1 $_GATEWAY
			if [[ $? -eq 0 ]]
			then
				break
			else
				echo "Le ping n'a pas fonctionné voulez-vous retenter"
				echo "y/n"
				read _RES
				if [[ $_RES = "n" || $_RES = "N" ]]
				then
					break
				fi
			fi
		done		
		echo "Ping avec arrêt de l'insterface $_INT1"
		ifdown $_INT1
		while true 
		do
			ping -c 1 $_GATEWAY
			if [[ $? -eq 0 ]]
			then
				break
			else
				echo "Le ping n'a pas fonctionné voulez-vous retenter"
				echo "y/n"
				read _RES
				if [[ $_RES = "n" || $_RES = "N" ]]
				then
					break
				fi
			fi
		done		
		ifup $_INT1
		echo "Ping avec arrêt de l'insterface $_INT2"
		ifdown $_INT2
		while true 
		do
			ping -c 1 $_GATEWAY
			if [[ $? -eq 0 ]]
			then
				break
			else
				echo "Le ping n'a pas fonctionné voulez-vous retenter"
				echo "y/n"
				read _RES
				if [[ $_RES = "n" || $_RES = "N" ]]
				then
					break
				fi
			fi
		done		
		ifup $_INT2
	fi
done
}

echo "==================================================="
echo "Configuration du reseau "
echo "==================================================="
echo "y/n"
read _RES
if [[ $_RES = "y" || $_RES = "Y" ]]
then
	bonding
fi
