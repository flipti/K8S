#!/bin/bash

# Nome do arquivo contendo a lista de URLs
URL_FILE="/home/user/listas_url.txt"

# Verifica se o arquivo de URLs existe
if [ ! -f "$URL_FILE" ]; then
    echo "O arquivo $URL_FILE não existe."
    exit 1
fi

# Loop para ler e processar cada URL do arquivo
while read -r url; do
    # Faz uma solicitação HTTP usando curl e obtém o código de status HTTP
    http_status=$(curl -L -s -o /dev/null -w "%{http_code}" "$url")
    echo "$url - Código HTTP: $http_status"
done < "$URL_FILE"
