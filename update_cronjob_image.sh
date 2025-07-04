# ESSE SCRIPT BAIXA A IMAGEM DE TODOS OS CRONJOBS DE UM NAMESPACE, ALTERA UM VALOR DE UM ARQUIVO APPSETINGS.JSON, GERA UMA NOVATAG DA IMAGEM, EXECUTA O PUSH, E SETA A NOVA IMAGEM NO CRONJOB# AUTENTICAR NO GCLOUD COM O JSON
# EXEMPLO : docker login -u _json_key --password-stdin https://gcr.io < file.json
# LISTA AS CREDENCIAL AUTENTICADA : gcloud auth list

#!/bin/bash

# Namespace e lista de CronJobs alvo
NAMESPACE="db-apis-ms"
CRONJOBS=(

    "envio-nfse-cronjob"                            
    "envio-notas-nfse-cronjob"                      
    
)

# Novo IP
OLD_IP="10.193.10.3"
NEW_IP="10.119.100.230"

# Iterar sobre cada CronJob na lista
for CRONJOB_NAME in "${CRONJOBS[@]}"; do
    echo "Processando CronJob: $CRONJOB_NAME no namespace: $NAMESPACE"

    # Obter a imagem atual do CronJob
    CURRENT_IMAGE=$(kubectl get cronjob "$CRONJOB_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.jobTemplate.spec.template.spec.containers[0].image}')

    if [ -z "$CURRENT_IMAGE" ]; then
        echo "Erro: Não foi possível obter a imagem do CronJob $CRONJOB_NAME." >&2
        continue
    fi

    echo "Imagem atual: $CURRENT_IMAGE"

    # Separar repositório e tag
    IMAGE_REPO=$(echo "$CURRENT_IMAGE" | cut -d':' -f1)
    IMAGE_TAG=$(echo "$CURRENT_IMAGE" | cut -d':' -f2)

    # Nova tag incrementada
    NEW_TAG=$((IMAGE_TAG + 1))
    NEW_IMAGE="$IMAGE_REPO:$NEW_TAG"

    # Fazer o pull da imagem original
    echo "Fazendo pull da imagem $CURRENT_IMAGE..."
    docker pull "$CURRENT_IMAGE"

    # Criar um contêiner temporário
    CONTAINER_ID=$(docker create "$CURRENT_IMAGE")

    # Extrair, modificar e substituir o arquivo appsettings.json
    echo "Alterando o arquivo appsettings.json..."
    docker cp "$CONTAINER_ID:/app/appsettings.json" ./appsettings.json
    if [ ! -f ./appsettings.json ]; then
        echo "Erro: Arquivo appsettings.json não encontrado na imagem $CURRENT_IMAGE." >&2
        docker rm "$CONTAINER_ID"
        continue
    fi

    # Substituir o IP no arquivo local
    sed -i "s/$OLD_IP/$NEW_IP/g" ./appsettings.json

    # Substituir o arquivo no contêiner
    docker cp ./appsettings.json "$CONTAINER_ID:/app/appsettings.json"
	
	  # CHECK
	  cat appsettings.json  | grep -i connection

    # Commitar a nova imagem
    echo "Criando nova imagem $NEW_IMAGE..."
    docker commit "$CONTAINER_ID" "$NEW_IMAGE"

    # Fazer o push da nova imagem
    echo "Fazendo push da nova imagem $NEW_IMAGE..."
    docker push "$NEW_IMAGE"

    # Atualizar o CronJob com a nova imagem
    echo "Atualizando CronJob $CRONJOB_NAME para usar a imagem $NEW_IMAGE..."
    kubectl set image cronjob/"$CRONJOB_NAME" -n "$NAMESPACE" "$(kubectl get cronjob "$CRONJOB_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.jobTemplate.spec.template.spec.containers[0].name}')"="$NEW_IMAGE"

    # Limpar arquivos temporários
    docker rm "$CONTAINER_ID"
    rm -f ./appsettings.json

    echo "CronJob $CRONJOB_NAME atualizado com sucesso para a nova imagem: $NEW_IMAGE!"
done
