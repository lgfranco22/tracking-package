# 17TRACK Monitor & ntfy.sh Alerter

Script em Bash para monitoramento automático de encomendas via API v2.4 do **17TRACK** com notificações instantâneas via **ntfy.sh**. Ideal para rodar em servidores Linux (VPS) via `cron`.

## 🚀 Funcionalidades
* **Consulta Inteligente:** Utiliza o ID de transportadora específico (Cainiao/Global) para evitar erros de sincronização.
* **Economia de Créditos:** Baseado no modelo de faturamento por registro; consultas de status (`gettrackinfo`) não consomem créditos extras.
* **Detecção de Mudança:** Armazena o estado anterior em cache e só dispara notificações quando surge um novo evento.
* **Fuso Horário:** Converte automaticamente o horário da China (UTC+8) para o horário local do servidor (Brasília -03:00).
* **Push Notifications:** Integração nativa com o app `ntfy` (Android/iOS/Web).

## 🛠️ Pré-requisitos
O script utiliza ferramentas nativas do Linux e o processador de JSON `jq`.
```bash
sudo apt update && sudo apt install curl jq -y
```

## ⚙️ Configuração
Edite as variáveis no início do arquivo `track.sh`:

1.  **TOKEN:** Sua chave de API do 17TRACK.
2.  **CODIGO:** O código de rastreio (ex: `NN112233445BR`).
3.  **ntfy.sh/\<topico>:** Substitua pelo seu tópico privado no ntfy.

### Caso deseje alterar a transportadora, veja nesse link o codigo correto
```url
https://res.17track.net/asset/carrier/info/apicarrier.all.json
```

## 📂 Estrutura de Arquivos
* `/home/luiz/log.txt`: Registra cada execução e disparos de alertas.
* `/tmp/rastreio_cache.json`: Armazena o último estado do rastreio para comparação.

## ⏲️ Automação (Crontab)
Para monitorar o pacote a cada 10 minutos, adicione a seguinte linha ao seu `crontab -e`:

```bash
*/10 * * * * /bin/bash /home/luiz/track.sh
```

## 📝 Lógica de Funcionamento
1.  O script registra a execução no `log.txt`.
2.  Consulta a API e extrai o array `.data.accepted[0].track_info.tracking.providers[0].events`.
3.  Compara o conteúdo atual com o arquivo de cache em `/tmp`.
4.  Se houver diferença:
    * Atualiza o cache.
    * Formata a data ISO para o padrão brasileiro.
    * Envia um `POST` para o `ntfy.sh` com prioridade alta e tags visuais.

---
*Desenvolvido para monitoramento de alta precisão em ambiente de servidor.*
