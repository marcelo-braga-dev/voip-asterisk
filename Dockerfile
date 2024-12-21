# Dockerfile
FROM debian:stable

# Instalar dependências necessárias
RUN apt-get update && \
    apt-get install -y \
    build-essential apt-utils \
    wget curl git bzip2 patch \
    libssl-dev libsrtp2-dev libspandsp-dev libcurl4-openssl-dev libncurses5-dev libncursesw5-dev libnewt-dev libxml2-dev \
    libsqlite3-dev uuid-dev libjansson-dev libedit-dev unixodbc-dev \
    sqlite3 pkg-config ca-certificates gettext \
    doxygen  graphviz xsltproc aptitude unixodbc iputils-ping && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Baixar e compilar o Asterisk versão 20
WORKDIR /usr/src
RUN wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-20-current.tar.gz && \
    tar -zxvf asterisk-20-current.tar.gz && \
    cd asterisk-20.* && \
    ./configure --with-pjproject-bundled --with-jansson-bundled && \
    make menuselect.makeopts && \
    make -j$(nproc) && \
    make install && \
    make config && \
    make samples && \
    make progdocs && \
    ldconfig

# Copiar arquivos de templates e o script de inicialização
COPY ./.env /etc/asterisk/.env
COPY ./asterisk-config /etc/asterisk
COPY ./scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Porta padrão do Asterisk
EXPOSE 5060/udp
EXPOSE 5061/tcp
EXPOSE 10000-10199/udp
EXPOSE 8088/tcp

# Usar o script como ponto de entrada
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
