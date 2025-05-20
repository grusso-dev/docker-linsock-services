FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV ACCEPT_EULA=Y

# Instalar herramientas necesarias y sqlcmd
RUN apt-get update && apt-get install -y \
    curl \
    apt-transport-https \
    gnupg \
    software-properties-common \
    cron \
    unzip \
    bash \
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update && ACCEPT_EULA=Y apt-get install -y \
    msodbcsql17 \
    mssql-tools \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV PATH="${PATH}:/opt/mssql-tools/bin"

COPY backup.sh /usr/local/bin/backup.sh
COPY crontab.txt /etc/cron.d/sqlbackup

RUN chmod +x /usr/local/bin/backup.sh && \
    chmod 0644 /etc/cron.d/sqlbackup && \
    crontab /etc/cron.d/sqlbackup

CMD ["cron", "-f"]
