**Vous trouverez dans te page des exemples de requête pour créer et mettre à jour un service principal**

- [Méthode par défaut en CLI pour générer un service principal](#méthode-par-défaut-en-cli-pour-générer-un-service-principal)
- [Méthode en CLI pour générer un service principal en choisissant la durée d'expiration du mot de passe](#méthode-en-cli-pour-générer-un-service-principal-en-choisissant-la-durée-dexpiration-du-mot-de-passe)
- [Mettre à jour le Service Principal d'un cluster AKS](#mettre-à-jour-le-service-principal-dun-cluster-aks)


# Méthode par défaut en CLI pour générer un service principal

C'est le type de commande que j'ai pu utiliser pour créer des Service Principal utiliser lors de la création d'un cluster AKS

    ad sp create-for-rbac --name "MY-SP-NAME" --skip-assignment 

# Méthode en CLI pour générer un service principal en choisissant la durée d'expiration du mot de passe

En effet même si en terme de sécurité on préférerait laisser la valeur par défaut, il faut parfois faire des compromis ! C'est notamment le cas pour les clients n'ayant pas les compétences nécessaire au renvouvellement d'un mot de passe d'un Service Principal AKS. La possibilité de créer des cluster AKS avec une identité managé devrait toutefois simplifier ce dernier point.

    az ad sp create-for-rbac -n "MY-SP-NAME" --skip-assignment --years 20

# Mettre à jour le Service Principal d'un cluster AKS

Si vous avez un cluster AKS utilisant un Service Principal, vous allez devoir le mettre à jour avant chaque expiration du mot de passe.

La documentation complète Microsoft : https://docs.microsoft.com/en-us/azure/aks/update-credentials

Pour cela vous allez devoir tout d'abord :
* Créer un nouveau Service Principal avec une expiration qui vous convient (Voir ci-dessus). Si l'expiration vous convenait vous avez aussi la possibilité de faire un reset du mot de passe toutefois l'upgrade devra alors être effectuée à la suite et elle pourrait même être programmé automatiquemment si vous avez un Scale Set ce qui est plus contraignant.
* Si vous avez créer un nouveau Service Principal il faut ensuite lui donner les mêmes droits que le précédent Service Principal soit généralement sur :
    * Le ressource groupe des noeuds du cluster AKS
    * La container registry si vous en avez une
* L'étape principale est ensuite la mise à jour du cluster. Cette étape va lancer une update de chacun des noeuds, il faut donc être vigilant à votre continuité de service. Pour lancer l'update il faut exécuter la commande CLI suivante en ayant pris soin de mettre à jour chaque variable:

      az aks update-credentials \
      --resource-group $AKS_RG_NAME \
      --name $AKS_CLUSTER_NAME \
      --reset-service-principal \
      --service-principal $SP_ID \
      --client-secret $SP_SECRET

Attention l'upgrade des noeuds va annuler toutes les personnalisations que vous auriez pu faire manuellement. 

Par exemple pour un client, nous avions Elastic Search qui nécessitait une configuration spécifique du Kernel des noeuds. Nous devions éxécuter la commande suivante en nous connectant en ssh sur chacun des noeuds :

    sudo sysctl -w vm.max_map_count=262144

Ce type de personnalisation du Kernel peut maitenant être intégré via la configuration personnalisé des noeuds : https://docs.microsoft.com/en-us/azure/aks/custom-node-configuration