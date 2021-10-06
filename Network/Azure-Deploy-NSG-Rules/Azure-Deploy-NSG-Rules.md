**Script Azure-Deploy-NSG-Rules.ps1**

J'ai développé ce script il y a plusieurs années pour pouvoir gérer le déploiement et la mise à jour les règles des Network Security Group à partir d'un fichier CSV ce qui pourrait s'apparenter à de l'Infra As Code en mode très simple et facilement accessible.
Le fichier CSV pouvant être rempli par un profil non technique après lui avoir expliqué les valeurs attendues et **servir de matrice de flux**.

Le script va effectuer les actions suivantes :

*Créer le NSG si il n'existe pas
*Créer/Mettre à jour les règles dans le NSG (La mise à jour nécessite une validation)
*optionnellement la possiblité de demander une suppression de toutes les règles du NSG avant la création des règles (La suppression est soumise à validation)
*Chaque mise à jour de règle ou suppression de la totalité des règles du NSG entraine une sauvegarde de la ou des règles actuelle(s) sous forme de fichier Csv que vous pouvez rejouer avec le script


Lors de sa publication j'ai mis à jour le script :

* Pour passer les commandes "AzureRM" en "Az"
* Enlever tous les avertissements Visual Studio Code

Le script n'a pas été retester et, idéalement, il aurait fallu intégrer la gestion des ASG et une détection des règles n'existant plus dans le fichier csv pour donner la possiblité unitaire de les supprimer.