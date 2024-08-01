##Instructions d’Installation
Définir les Variables : Remplacez les valeurs des variables dans la section “Variables” selon votre configuration réseau.
Configurer les Interfaces Réseau :
Ouvrez le fichier de configuration des interfaces réseau : /etc/network/interfaces.
Ajoutez les sections de configuration des interfaces réseau en utilisant les variables définies.
Ajouter les Règles IPTables :
Ouvrez le fichier de configuration des interfaces réseau : /etc/network/interfaces.
Ajoutez les règles IPTables dans les sections post-up et post-down en utilisant les variables définies.
Ajouter la Route Additionnelle :
Ajoutez les commandes de route additionnelle dans le fichier de configuration des interfaces réseau.
Redémarrer les Interfaces Réseau :
Redémarrez les interfaces réseau pour appliquer les modifications : ifdown $WAN_INTERFACE && ifup $WAN_INTERFACE.
Vérifier la Configuration :
Vérifiez que les règles IPTables sont appliquées correctement : iptables -t nat -L -n -v.
Vérifiez que les interfaces réseau sont configurées correctement : ip addr show.
##Support
N’hésitez pas à me contacter si vous avez des questions ou des problèmes!
