**Script Azure-Deploy-VM.ps1**

J'ai développé ce script il y a plusieurs années pour pouvoir déployer des VMs à partir d'un fichier CSV ce qui pourrait s'apparenter à de l'Infra As Code en mode très simple et facilement accessible. Le fichier CSV pouvant être rempli par un profil non technique après lui avoir expliqué les valeurs attendues.

Lors de sa publication j'ai mis à jour le script :

* Pour passer les commandes "AzureRM" en "Az"
* Enlever tous les avertissements Visual Studio Code

Le script n'a pas été retester et, idéalement, il aurait aussi fallu lui ajouter la gestion des disques managés qui sont maintenant le standard de déploiement.

Une amélioration de la gestion d'erreur avec l'ajout de Try/Catch serait aussi un plus.