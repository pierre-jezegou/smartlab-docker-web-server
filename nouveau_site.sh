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
cp "/home/docker-manager/creation_site/docker-compose.yml" $docker_container_path"$website_name/docker-compose.yml"
sed -i "s/WEBSITE/$website_name/" $docker_container_path"$website_name/docker-compose.yml"
echo
echo Ports utilisés :
for container in $(docker ps -aq); do docker port $container;done
echo "Choix du port :"
read port
sed -i "s/PORT/$port/" $docker_container_path"$website_name/docker-compose.yml"
echo $website_name > $docker_container_path"/$website_name/website/index.php"
cd $docker_container_path$website_name
docker compose up -d && echo Accès au site : $(/sbin/ip -o -4 addr list enp3s0f0 | awk '{print $4}' | cut -d/ -f1):$port && echo Accès au site 10.17.6.12:$port
