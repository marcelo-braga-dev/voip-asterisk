#!/bin/bash

# Definir a cor vermelha e reset
RED='\033[0;31m'
RESET='\033[0m'

# Localize o arquivo .env e carregue as variáveis
ENV_FILE="/etc/asterisk/.env"

if [ -f "$ENV_FILE" ]; then
    echo "Carregando variáveis do arquivo .env..."
    export $(cat $ENV_FILE | xargs)
else
    echo -e "${RED}ERROR: Arquivo .env não encontrado.${RESET}" >&2
    exit 1
fi

# Validar execução como root
if [ "$(id -u)" != "0" ]; then
  echo -e  "${RED}Este script deve ser executado como root.${RESET}" >&2
  exit 1
fi

# Criar usuário e grupo 'asterisk'
groupadd -r asterisk && useradd -r -g asterisk asterisk

# Criar diretórios necessários
echo "Verificando e criando diretórios necessários..."
mkdir -p /var/lib/asterisk /var/log/asterisk /var/run/asterisk /var/spool/asterisk/outgoing
chown -R asterisk:asterisk /var/lib/asterisk /var/log/asterisk /var/run/asterisk /etc/asterisk /var/spool/asterisk
chmod -R 750 /var/lib/asterisk /var/log/asterisk /var/run/asterisk /etc/asterisk /var/spool/asterisk

# Substituir variáveis de ambiente nos templates
echo "Configurando arquivos do Asterisk..."
envsubst < /etc/asterisk/template/ari.conf.template > /etc/asterisk/ari.conf
envsubst < /etc/asterisk/template/manager.conf.template > /etc/asterisk/manager.conf
envsubst < /etc/asterisk/template/pjsip.conf.template > /etc/asterisk/pjsip.conf

# Determinar nível de log com base no ambiente
if [[ "${ENVIRONMENT}" == "production" ]]; then
  LOG_LEVEL="-vv"
  echo "Iniciando em modo PRODUÇÃO."
else
  LOG_LEVEL="-vvvvvc"
  echo "Iniciando em modo DESENVOLVIMENTO."
fi

# Iniciar o Asterisk
echo "==== INICIANDO O ASTERISK ===="
exec /usr/sbin/asterisk -f -U asterisk -G asterisk ${LOG_LEVEL} || {
  echo -e "${RED}Erro ao iniciar o Asterisk.${RESET}" >&2
  exit 1
}

