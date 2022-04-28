#!/bin/bash
# EXPORT A VARIAVEL REGISTRY ANTES COM O COMANDO ABAIXO
#export REGISTRY=mycontainerregistry


mycontainers=$(az acr repository list --name $REGISTRY  -u <usuario> -p <senha> --output tsv)
for i in $mycontainers
do
    echo -n "$REGISTRY.azurecr.io/$i:"
    az acr repository show-tags -n $REGISTRY --repository $i -u <user> -p <senha> --output tsv
done
