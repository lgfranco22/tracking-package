#!/bin/bash
# rastreio correios br

# Configurações
TOKEN="<token>"
CODIGO="<codigo_de_rastreamento>"
ARQUIVO_CACHE="/home/luiz/rastreio-br_cache.json"
LOG="/home/luiz/log_br_rastreio.txt"

ATUAL=$(date +'%d/%m/%Y %H:%M:%S')

# 1. Faz a consulta na API (Carrier 2151 = Correios Brasil)
RESPONSE=$(curl -s -X POST --header "17token:$TOKEN" \
     --header "Content-Type:application/json" \
     --data "[{\"number\":\"$CODIGO\", \"carrier\":2151}]" \
     https://api.17track.net/track/v2.4/gettrackinfo)

# 2. Extrai o array de eventos
# Adicionei o filtro 'select(. != null)' para evitar erros caso a API responda mas o array de eventos ainda não exista
EVENTOS_ATUAIS=$(echo "$RESPONSE" | jq -c '.data.accepted[0].track_info.tracking.providers[0].events | select(. != null)')

if [ "$EVENTOS_ATUAIS" == "[]" ] || [ -z "$EVENTOS_ATUAIS"]; then
     EVENTOS_ATUAIS="Nenhum evento encontrado ainda."
else
     EVENTOS_ATUAIS=$EVENTOS_ATUAIS
fi

# Se a API falhar ou não houver eventos, encerra silenciosamente para não corromper o cache
if [ -z "$EVENTOS_ATUAIS" ] || [ "$EVENTOS_ATUAIS" == "null" ]; then
    echo "[$ATUAL] Sem dados de eventos disponíveis no momento." >> $LOG
    exit 0
fi

# 3. Verifica o cache
if [ -f "$ARQUIVO_CACHE" ]; then
    EVENTOS_ANTIGOS=$(cat "$ARQUIVO_CACHE")
else
    EVENTOS_ANTIGOS=""
fi

# 4. Compara e dispara se houver novidade
if [ "$EVENTOS_ATUAIS" != "$EVENTOS_ANTIGOS" ]; then

    # Atualiza o Log e o Cache
    echo "[$ATUAL] NOVA ATUALIZAÇÃO DETECTADA!" >> $LOG
    echo "$EVENTOS_ATUAIS" > "$ARQUIVO_CACHE"

    # Extrai detalhes do evento mais recente
    DESC=$(echo "$EVENTOS_ATUAIS" | jq -r '.[0].description')
    DATA_ISO=$(echo "$EVENTOS_ATUAIS" | jq -r '.[0].time_iso')
    CIDADE=$(echo "$EVENTOS_ATUAIS" | jq -r '.[0].address.city // "Local não informado"')

    # Formata a data ISO para o padrão brasileiro
    # O comando date -d lida bem com o sufixo -03:00 do JSON
    DATA_BR=$(date -d "$DATA_ISO" +"%d/%m %H:%M")

    # --- DISPARO NTFY ---
    # Adicionei a cidade na mensagem para ficar mais informativo
    curl -s -H "Title: Atualização de Rastreio: $CODIGO" \
         -H "Priority: high" \
         -H "Tags: package,truck" \
         -d "$DESC - $CIDADE ($DATA_BR)" \
         ntfy.sh/<topico> > /dev/null 2>&1

    echo "[$ATUAL] Notificação enviada: $DESC" >> $LOG

else
    # Apenas log de rotina (opcional, pode comentar se o log crescer demais)
    echo "[$ATUAL] SCRIPT EXECUTADO - Sem alterações" >> $LOG
fi
