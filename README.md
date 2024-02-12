# Serveur hébergement projet Smartlab
> [!IMPORTANT]
> Ce dépôt est loin d'être un exemple à suivre dans le déploiement d'un serveur d'hébergement web via Docker. Cette démarche a été mise en place avec un but exclusivement pédagogique dans le cadre du projet LivingLab. Beaucoup de facettes (notamment en terme de sécurité) sont donc ici laissées de côté.

## But premier
Déployer serveur pour hébergement du projet SmartLab (Projet étudiant dans le cadre de l'École Centrale de Lille). Hébergement du logiciel conteneurisé via Docker : Stack docker-compose comprenant l'interface Web, l'API + le modèle IA de prédiction.

## Fichiers du dépôt
Le but de ce repo est de proposer un tutoriel simple et 100% adaptés aux besoins du projet. Ainsi, cela permet aux autres étudiants du projet de s'essayer au déploiement d'un logiciel du serveur physique jusqu'à la mise en production du logiciel via Docker. Cette étape se veut donc un partage de connaissances plutôt qu'une méthode de déploiement optimale.

## Utilisation du repo
Le fichier `installation.md` est plus détaillé (plus d'explications du pourquoi) que le fichier `tuto_serveur.md` qui se veut quant à lui plus synthétique.

## Génération conteneurs
Plusieurs fichiers permettent un déploiement simplifié des différents composants :
- Génération assistée des fichiers : `nouveau_site.sh`.
L'utilisateur est guidé dans la création d'un nouveau projet. Ce script crée les dossiers avec des maquettes de fichiers à remplir (docker-compose, Dockerfile...)

- Fichiers template : Les fichiers `Dockerfile` et `docker-compose.yml` sont des maquettes simplifiées (le Dockerfile est créé pour héberger un site PHP).

> [!NOTE]
> Par la suite, ces fichiers ont été modifiés pour s'adapter à 100% aux besoins du projet (stack complète docker-compose)

