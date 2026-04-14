#!/bin/bash

# Configurações
TOKEN="<token>"
CODIGO="<codigo>"
ARQUIVO_CACHE="/tmp/rastreio_cache.json"
LOG="/home/luiz/log.txt"

ATUAL=$(date +'%d/%m/%Y %H:%M:%S')
# Registra a execução no log
echo "[$ATUAL] SCRIPT EXECUTADO" >> $LOG

# 1. Faz a consulta na API
RESPONSE=$(curl -s -X POST --header "17token:$TOKEN" \
     --header "Content-Type:application/json" \
     --data "[{\"number\":\"$CODIGO\", \"carrier\":190271}]" \
     https://api.17track.net/track/v2.4/gettrackinfo)

# 2. Extrai apenas a parte que importa (o histórico de eventos) para comparar
# Usamos o jq para pegar o array de eventos bruto
EVENTOS_ATUAIS=$(echo "$RESPONSE" | jq -c '.data.accepted[0].track_info.tracking.providers[0].events')

# 3. Verifica se o arquivo de cache existe
if [ -f "$ARQUIVO_CACHE" ]; then
    EVENTOS_ANTIGOS=$(cat "$ARQUIVO_CACHE")
else
    EVENTOS_ANTIGOS=""
fi

# 4. Compara o novo com o antigo
if [ "$EVENTOS_ATUAIS" != "$EVENTOS_ANTIGOS" ]; then

    # SALVA O NOVO ESTADO NO CACHE
    echo "$EVENTOS_ATUAIS" > "$ARQUIVO_CACHE"

    # --- INÍCIO DO DISPARO DE EVENTO ---
    echo "[$ATUAL] NOVA ATUALIZAÇÃO DETECTADA!" >> $LOG
    # Pega apenas o evento mais recente (o primeiro do array) para exibir
    ULTIMO_EVENTO=$(echo "$EVENTOS_ATUAIS" | jq -c '.[0]')
    DATA_ISO=$(echo "$ULTIMO_EVENTO" | jq -r '.time_iso')
    DESC=$(echo "$ULTIMO_EVENTO" | jq -r '.description')

    DATA_BR=$(date -d "$DATA_ISO" +"%d/%m/%Y %H:%M:%S")

#    echo "Status: $DESC"
#    echo "Hora: $DATA_BR"

    # Aqui você pode colocar o comando para enviar o Telegram, ex:
    # ./enviar_telegram.sh "Novo status: $DESC em $DATA_BR"
    curl -s -H "Title: Atualização de Rastreio: $CODIGO"  \
    -H "Priority: high" \
    -H "Tags: package,truck" \
    -d "$DESC ($DATA_BR)" ntfy.sh/<topico> > /dev/null 2>&1
    # --- FIM DO DISPARO ---

else
    # Opcional: apenas para debug no terminal
    echo "Sem alterações desde a última consulta." > /dev/null
fi
