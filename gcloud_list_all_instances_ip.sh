#!/bin/bash

# Lista de todos os projetos
PROJECTS=$(gcloud projects list --format="value(projectId)")

# Iterar por todos os projetos
for PROJECT in $PROJECTS; do
  echo "Projetos em ${PROJECT}:"
   gcloud config set project $PROJECT
  
  # Listar todas as instâncias no projeto e exibir seus IPs públicos
  #INSTANCES=$(gcloud compute instances list --format="value(name,networkInterfaces[0].accessConfigs[0].natIP)")
  INSTANCES=$(gcloud compute instances list --format="value(name,networkInterfaces[0].networkIP,networkInterfaces[0].accessConfigs[0].natIP)")
  echo "$INSTANCES"
  echo ""
done

