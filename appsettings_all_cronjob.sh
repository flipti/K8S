#!/bin/bash

# Nome do namespace
NAMESPACE="db-apis-ms"

# Nome do arquivo de saída
OUTPUT_FILE="cronjob_appsettings_output.txt"

# Limpa o arquivo de saída, se existir
> "$OUTPUT_FILE"

# Obtém a lista de CronJobs no namespace
CRONJOBS=$(kubectl get cronjobs -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')

# Itera sobre os CronJobs
for CRONJOB in $CRONJOBS; do
    echo "Processando CronJob: $CRONJOB"

    # Cria um Job temporário a partir do CronJob
    TEMP_JOB_NAME="temp-job-$CRONJOB"
    kubectl create job --from=cronjob/$CRONJOB "$TEMP_JOB_NAME" -n "$NAMESPACE"

    # Aguarda o pod do Job ficar pronto
    while true; do
        POD=$(kubectl get pods -n "$NAMESPACE" -l "job-name=$TEMP_JOB_NAME" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
        if [ -n "$POD" ]; then
            STATUS=$(kubectl get pod "$POD" -n "$NAMESPACE" -o jsonpath='{.status.phase}')
            if [ "$STATUS" == "Running" ] || [ "$STATUS" == "Succeeded" ]; then
                break
            fi
        fi
        sleep 2
    done

    # Executa o comando cat appsettings.json no pod
    if [ -n "$POD" ]; then
        OUTPUT=$(kubectl exec -n "$NAMESPACE" "$POD" -- cat appsettings.json 2>/dev/null)

        if [ $? -eq 0 ]; then
            echo "CronJob: $CRONJOB" >> "$OUTPUT_FILE"
            echo "Saída do comando:" >> "$OUTPUT_FILE"
            echo "$OUTPUT" >> "$OUTPUT_FILE"
            echo "##################" >> "$OUTPUT_FILE"
        else
            echo "CronJob: $CRONJOB" >> "$OUTPUT_FILE"
            echo "Saída do comando: Erro ao acessar appsettings.json" >> "$OUTPUT_FILE"
            echo "##################" >> "$OUTPUT_FILE"
        fi
    else
        echo "CronJob: $CRONJOB" >> "$OUTPUT_FILE"
        echo "Saída do comando: Nenhum pod encontrado" >> "$OUTPUT_FILE"
        echo "##################" >> "$OUTPUT_FILE"
    fi

    # Apaga o Job temporário
    kubectl delete job "$TEMP_JOB_NAME" -n "$NAMESPACE"
done

echo "Processamento concluído. Confira o arquivo: $OUTPUT_FILE"
