#!/bin/bash

NAMESPACE="db-apis-ms"
OUTPUT_FILE="deployment_appsettings_output.txt"

# Limpa o arquivo de saída
> "$OUTPUT_FILE"

# Obtém todos os deployments no namespace
DEPLOYMENTS=$(kubectl get deployments -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')

for DEPLOYMENT in $DEPLOYMENTS; do
    # Remove o sufixo "-app" do nome do deployment
    LABEL_NAME=${DEPLOYMENT%-app}

    echo "Processando deployment: $DEPLOYMENT com label: $LABEL_NAME"

    # Busca um pod associado ao deployment com a label ajustada
    POD=$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$LABEL_NAME" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

    if [ -n "$POD" ]; then
        echo "Executando comando no pod: $POD"
        OUTPUT=$(kubectl exec -n "$NAMESPACE" "$POD" -- cat appsettings.json 2>/dev/null)

        if [ $? -eq 0 ]; then
            echo "Nome do Deployment: $DEPLOYMENT" >> "$OUTPUT_FILE"
            echo "Saída do comando:" >> "$OUTPUT_FILE"
            echo "$OUTPUT" >> "$OUTPUT_FILE"
            echo "-------------------------------" >> "$OUTPUT_FILE"
        else
            echo "Erro ao executar o comando no pod: $POD" >> "$OUTPUT_FILE"
        fi
    else
        echo "Nenhum pod encontrado para o deployment: $DEPLOYMENT" >> "$OUTPUT_FILE"
    fi
done

echo "Processamento concluído. Confira o arquivo: $OUTPUT_FILE"
