# Mise en place du serveur

## Installation de Linux
Installation de Linux via *Raspberry Pi Imager*. Set up du ssh et et des comptes utilisateur :
- identifiant : `docker-manager`
- Mot de passe : `**********`

> Pour générer un mot de passe, on peut utilsier la commande `pwgen` avec ses différentes options.

## Configuration réseau
La configuration réseau du serveur dépend du réseau sur lequel le serveur va se trouver.

### Configuration IP statique
Il peut être pratique de forcer la configuration de l'adresse IPv4 statique.
Cela permet de pouvoir pointer directement sur le serveur avec son IP, et de ne pas le perdre (l'IP étant fixe).

On se connecte donc au serveur (via ssh) avec la commande `ssh docker-manager@192.168.0.100`
> On peur trouver l'adresse IP que le serveur a pris en se branchant dessus, ou bien en lançant un scan nmap du réseau avec la commande `nmap 192.168.0.0/24`

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
> Il est possible que l'interface ne s'appelle pas `eth0`. On peut trouver son nom dans le output de la commande `ip a`.

On relance ensuite le service réseau : `sudo systemctl restart networking`

On peut vérifier si l'adresse IP  bien été changée avec la commande `ip a`

## Installation de docker
Les informations d'installation sont mentionnées sur le site de Docker : https://docs.docker.com/engine/install/debian/
On suit donc le tutoriel.

```bash
sudo apt-get update
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```
Ensuite, on ajoute l'utilisateur *docker-manager* au groupe docke rpour qu'il puisse effectuer toute sles actions liées aux conteneurs.
> Pour l'instant, toutes les commandes docker nécessitent les autorisations root...
```bash
sudo usermod -aG docker docker-manager
```

## Création d'un compte utilisateur
On doit créer un compte utilisateur avec des droits limoités pour que l'utilisateur dépose en sécurité les fichiers sur le serveur. On doit donc lui créer :
- Un dossier home avec les autorisations dessus
- Un 

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



# Création des conteneurs
## Docker pour un conteneur en PHP
On propose d'utiliser un docker-compose pour sa simplicité d'utilisation :
- On crée un service `web` pour lequel :
  - On donne un nom
  - On donne une image (ici on donne une image personnalisée avec le Dockerfile)
  - On programme le conteneur pour redémarrer à chaque fois qu'il s'éteint
  - On monte un volume extérieur pour la persistance des données
  On expose le port 80 à l'xtérieur du conteneur
```yaml
version: '3.8'
services:
  web:
    container_name: smartlab
    build: /home/docker-manager/creation_site/
    restart: always
    volumes:
      - ./website/:/var/www/html/
    ports:
      - 8080:80
```

On doit cependant personnaliser l'image php car l'image de base ne comprend pas l'utilisation de PDO par exemple. Voici donc le Dockerfile :
```docker
FROM php:7.3-apache
# Install stuff
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install sudo unzip wget -y && rm -rf /var/lib/apt/lists/*
RUN docker-php-ext-install mysqli pdo pdo_mysql
# Configure stuff
RUN a2enmod rewrite
```
- On n'oublie pas de vider le cache pour avoir une image docker plus petite à la fin. On peut retrouver plein d'informations dans la section *'Bonnes pratiques'* de la documentation Docker.

## Docker pour un conteneur en Python
Pour un conteneur en Python, les étapes sont environ les mêmes. En plus, on crée un `venv`pour installer les dépendances python.
```yaml
version: '3.8'
services:
  api:
    container_name: mail
    build: .
    restart: always
    ports:
      - 8000:8000
    volumes:
      - ./templates/:/templates

```
Et voici le Dockerfile adapté (pour créer une image personnalisée pour rappel).
```docker
FROM python:3.9-slim

ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

WORKDIR /app
# Install dependencies:
COPY requirements.txt .
RUN pip install -r requirements.txt --no-cache-dir

#Copytemplate files
COPY templates ./templates

# Run the application:
COPY main.py .
COPY script.py .
CMD uvicorn main:app --host 0.0.0.0
```
> *Ces fichiers (docker-compose et Dockerfile) donc personnalisés pour l'utilisation désirée dans le cadre du projet, mais les grandes étapes sont similaires quel que soit le projet.*


<!-- 
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
- Ensuite -->
