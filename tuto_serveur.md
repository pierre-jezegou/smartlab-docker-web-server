# Mise en place du serveur Web

## Installation de Linux
Installation de Linux via *Raspberry Pi Imager*. Set up du ssh etd et des comptes :
- identifiant : `livinglab`
- Mot de passe : `**********`

Configuration réseau : configuration de l'adresse IPv4 statique. On se connecte donc au serveur (via ssh) avec la commande `ssh livinglab@192.168.0.103`
> On peur trouver l'adresse IP que le serveur a pris en se branchant dessus, ou bien en lançant un scan nmap du réseau `nmap 192.168.0.0/24`

On modifie le fichier de configuration des interfaces :
```shell
sudo nano /etc/network/interfaces
```
```
auto eth0
iface eth0 inet static
  address 192.168.0.50
  netmask 255.255.255.0
  gateway 192.168.0.1
```
On relance ensuite le service r&seau : `sudo systemctl restart networking``

On peut vérifier si l'adresse IP  bien été changée avec la commande `ip a`

## Connexion au serveur
Une fois que l'adresse IP a été modifiée en statique, on peut se connecter (en ssh) au serveur avec la commande :
```
ssh livinglab@10.17.9.195 --port 2224
```

## Installation de docker
Les informations d'installation sont mentionnées sur le site de Docker : https://docs.docker.com/engine/install/debian/
On suit donc le tutoriel.

On commence par mettre à jour le "catalogue" des paquets disponibles à l'installation.
```
sudo apt-get update
```

On installe ensuite les premiers paquets nécessaires à l'installation de docker
```
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
```
On crée un dossier avec la commande `mkdir`

```
sudo mkdir -p /etc/apt/keyrings
```
```
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```
```
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```
```
sudo apt-get update
```
```
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```
## Création du compte docker, celui qui gère les conteneurs
On crée un nouvel utilisateur pour qu'il puisse gérer/modifier les conteneurs qu'on va créer par la suite
```
sudo useradd -m -c "Docker administration" docker-manager
```
>*L'option `-m` permet de créer un dossier home à `/home/username`.\
L'option `-c` permet de rajouter u . commentaire à l'utilisateur*

Ensuite, on ajoute l'utilisateur *docker-manager* au groupe docker rpour qu'il puisse effectuer toute sles actions liées aux conteneurs.
> Pour l'instant, toutes les commandes docker nécessitent les autorisations root, on donne les autorisations à l'utilisateur nouvellement créé...
```bash
sudo usermod -aG docker docker-manager
```


## Installation de phpmyadmin et php
### Installation d'Apache
- Mise à jour du catalogue et des applications : `sudo apt-get update && sudo apt-get upgrade`
- Installation du paquet Apache : `sudo apt-get install apache2`
- Lancer Apache automatiquement au démarrage de la machine : `sudo systemctl enable apache2`
- Pour vérifier qu'Apache est bien lancé, on peut aller voir sur un navigateur `http://[IP du serveur]`

### Installation de php
*Suivi du tutoriel de ce site : https://www.php.net/manual/en/install.unix.debian.php*
- `sudo apt-get install php-common libapache2-mod-php php-cli php-mysql php-curl`
- Pour vérifier que tout fonctionne, on peut créer un fichier `index.php` dans `/var/www/html` contenant :
```php
<?php phpinfo(); ?>
```

### Installation de phpmyadmin et mariadb
On installe *MariaBD* `sudo apt-get install mariadb-server`

On peut ensuite suivre les instructions de ce site https://www.digitalocean.com/community/tutorials/how-to-install-phpmyadmin-from-source-debian-10 pour installer phpmyadmin.

On modifie l'accès à la base de données (pour pouvoir y accéder depuis les conteneurs) :
```bash
sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf
```
On modifie la ligne contenant le `bind-address=127.0.0.1` en
```
bind-address=0.0.0.0
```
Modification du BindAdress dans le fichier `/etc/mysql/my.cnf`aussi

# Création d'un script de création de conteneurs
Structure du projet :
- Racine avec les fichiers :
  ```bash
  docker-manager@raspberrypi:~ $ tree -La 2 .creation_site/ docker/ nouveau_site.sh 
  .creation_site/
  ├── docker-compose.yml
  ├── Dockerfile
  └── port_number
  docker/
  ├── essai_database
  │   └── index.php
  ├── livinglab
  │   ├── docker-compose.yml
  │   ├── Dockerfile
  │   ├── livinglab.sql
  │   └── website
  ├── pierre
  │   ├── docker-compose.yml
  │   └── website
  ├── test_scss
  │   ├── docker-compose.yml
  │   ├── Dockerfile
  │   ├── .DS_Store
  │   ├── index.php
  │   ├── logs_saas.log
  │   ├── .sass-cache
  │   ├── style.css
  │   ├── style.css.map
  │   ├── style.scss
  │   └── website
  └── tests_php
      ├── alpine.png
      ├── docker-compose.yaml
      ├── index2.html
      ├── index.html
      ├── mclaren.png
      ├── redbull_F1.png
      └── style.css
  ```
- `.creation_site/` : dossier avec les éléments nécessaires à la création des conteneurs (`Dockerfile`, modèle de `docker-compose.yml`)
- Dossier `docker` avec tous les dossiers projet :
  - Fichier `docker-compose.yml``
  - dossier `website` contenant les fichiers du projet (équivalent `/var/www/html`)

Voici le script :
```bash
#!/bin/bash
docker_container_path="/home/docker-manager/docker/"
echo "--- CREATION D'UN NOUVEAU SITE ---"
echo $docker_container_path
echo "Saisissez le nom du site souhaité : (enter to continue)"
read website_name
echo "Site en création : " $website_name

mkdir -p -- $docker_container_path$website_name
echo $docker_container_path$website_name
mkdir -p -- $docker_container_path"$website_name/website/"
cp "/home/docker-manager/.creation_site/docker-compose.yml" $docker_container_path"$website_name/docker-compose.yml"
sed -i "s/WEBSITE/$website_name/" $docker_container_path"$website_name/docker-compose.yml"
echo
echo Ports utilisés :
for container in $(docker ps -aq); do docker port $container;done
echo "Choix du port :"
read port
sed -i "s/PORT/$port/" $docker_container_path"$website_name/docker-compose.yml"
echo "$(($port+1))" > .creation_site/port_number
echo $website_name > $docker_container_path"/$website_name/website/index.php"
cd $website_name
docker compose up -d && echo Accès au site : $(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1):$port
```


# Création d'utilisateur et gestion des accès
On crée un utilisateur qui pourra seulement intéragir avec le dossier où se trouvent les dossiers et qui ne pourra pas gérer autre chose (ne gère pas docker, n'a pas les droits root...).
- Création du groupe `smartlab` : tous les utilisateur de ce groupe auront le droit de faire les actions qu'on a définies ci-dessus.

```
sudo groupadd smartlab
```
- Ensuite
