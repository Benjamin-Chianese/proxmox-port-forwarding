#!/bin/bash

# Questionnaire pour récupérer les variables
read -p "Entrez l'interface WAN (par défaut: vmbr0): " WAN_INTERFACE
WAN_INTERFACE=${WAN_INTERFACE:-vmbr0}

read -p "Entrez l'interface LAN (par défaut: vmbr1): " LAN_INTERFACE
LAN_INTERFACE=${LAN_INTERFACE:-vmbr1}

read -p "Entrez l'adresse IP WAN: " IP_WAN

read -p "Entrez l'adresse IP du PVE: " IP_PVE
IP_PVE=${IP_PVE:-10.255.255.1}

read -p "Entrez l'adresse IP du firewall: " IP_FW
IP_FW=${IP_FW:-10.255.255.2/30}

read -p "Entrez le sous-réseau du firewall (par défaut: 10.255.255.0/30): " SUBNET_FW
SUBNET_FW=${SUBNET_FW:-10.255.255.0/30}

read -p "Entrez l'adresse IP LAN du PVE (par défaut: 192.168.1.254/24): " IP_PVE_LAN
IP_PVE_LAN=${IP_PVE_LAN:-192.168.1.254/24}

read -p "Entrez la passerelle LAN (par défaut: 192.168.1.1): " GATEWAY_LAN
GATEWAY_LAN=${GATEWAY_LAN:-192.168.1.1}

# Afficher un résumé des variables et demander une validation
echo "Résumé des variables:"
echo "Interface WAN: $WAN_INTERFACE"
echo "Interface LAN: $LAN_INTERFACE"
echo "Adresse IP WAN: $IP_WAN"
echo "Adresse IP du PVE: $IP_PVE"
echo "Adresse IP du firewall: $IP_FW"
echo "Sous-réseau du firewall: $SUBNET_FW"
echo "Adresse IP LAN du PVE: $IP_PVE_LAN"
echo "Passerelle LAN: $GATEWAY_LAN"

read -p "Les variables sont-elles correctes? (y/n): " CONFIRMATION

if [ "$CONFIRMATION" != "y" ]; then
    echo "Veuillez relancer le script et entrer les variables correctes."
    exit 1
fi

# Sauvegarde de la configuration réseau actuelle
cp /etc/network/interfaces /etc/network/interfaces.bak

# Vérification et suppression des interfaces existantes
if grep -q "$WAN_INTERFACE" /etc/network/interfaces; then
    sed -i "/$WAN_INTERFACE/,+5d" /etc/network/interfaces
fi

if grep -q "$LAN_INTERFACE" /etc/network/interfaces; then
    sed -i "/$LAN_INTERFACE/,+5d" /etc/network/interfaces
fi

# Configuration des interfaces réseau
cat <<EOF >> /etc/network/interfaces
# Interco_PVE_FW
auto $WAN_INTERFACE
iface $WAN_INTERFACE inet static
    address $IP_PVE/30
    bridge-ports none
    bridge-stp off
    bridge-fd 0
#WAN_FW

auto $LAN_INTERFACE
iface $LAN_INTERFACE inet static
    address $IP_PVE_LAN
    gateway $GATEWAY_LAN
    bridge-ports none
    bridge-stp off
    bridge-fd 0
#LAN

# Configuration des règles iptables
post-up iptables -t nat -A POSTROUTING -s $SUBNET_FW -o $WAN_INTERFACE -j MASQUERADE

# ICMP
post-up iptables -t nat -A PREROUTING -d $IP_WAN/32 -i $WAN_INTERFACE -p icmp -j DNAT --to-destination $IP_FW
# TCP/UDP 1:8005
post-up iptables -t nat -A PREROUTING -d $IP_WAN/32 -i $WAN_INTERFACE -p tcp -m tcp --dport 1:8005 -j DNAT --to-destination $IP_FW:1-8005
post-up iptables -t nat -A PREROUTING -d $IP_WAN/32 -i $WAN_INTERFACE -p udp -m udp --dport 1:8005 -j DNAT --to-destination $IP_FW:1-8005

# TCP/UDP 8007:65535
post-up iptables -t nat -A PREROUTING -d $IP_WAN/32 -i $WAN_INTERFACE -p tcp -m tcp --dport 8007:65535 -j DNAT --to-destination $IP_FW:8007-65535
post-up iptables -t nat -A PREROUTING -d $IP_WAN/32 -i $WAN_INTERFACE -p udp -m udp --dport 8007:65535 -j DNAT --to-destination $IP_FW:8007-65535

post-down iptables -t nat -D POSTROUTING -s $SUBNET_FW -o $WAN_INTERFACE -j MASQUERADE

# ICMP
post-down iptables -t nat -D PREROUTING -d $IP_WAN/32 -i $WAN_INTERFACE -p icmp -j DNAT --to-destination $IP_FW
# TCP/UDP 1:8005
post-down iptables -t nat -D PREROUTING -d $IP_WAN/32 -i $WAN_INTERFACE -p tcp -m tcp --dport 1:8005 -j DNAT --to-destination $IP_FW:1-8005
post-down iptables -t nat -D PREROUTING -d $IP_WAN/32 -i $WAN_INTERFACE -p udp -m udp --dport 1:8005 -j DNAT --to-destination $IP_FW:1-8005

# TCP/UDP 8007:65535
post-down iptables -t nat -D PREROUTING -d $IP_WAN/32 -i $WAN_INTERFACE -p tcp -m tcp --dport 8007:65535 -j DNAT --to-destination $IP_FW:8007-65535
post-down iptables -t nat -D PREROUTING -d $IP_WAN/32 -i $WAN_INTERFACE -p udp -m udp --dport 8007:65535 -j DNAT --to-destination $IP_FW:8007-65535

# Mise en place de la bonne route par défaut sur le PVE
post-up ip route del default
post-up ip route add default via $IP_WAN dev $WAN_INTERFACE
EOF

# Activer le net v4 forwarder
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# Demande de redémarrage du serveur
read -p "Voulez-vous redémarrer le serveur maintenant? (y/n): " REBOOT_CONFIRMATION

if [ "$REBOOT_CONFIRMATION" == "y" ]; then
    reboot
else
    echo "Configuration appliquée avec succès! Redémarrage du serveur annulé."
fi
