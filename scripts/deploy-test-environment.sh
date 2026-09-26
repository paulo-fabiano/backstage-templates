#!/usr/bin/env bash
set -euo pipefail
# Argumentos validados novamente na fronteira SSH.
[[ $# == 5 ]] || exit 1
name=$1
host_port=$2
container_port=$3
postgres=$4
image=$5
[[ "$name" =~ ^[a-z][a-z0-9-]{0,39}$ ]] || exit 1
[[ "$host_port" =~ ^[1-9][0-9]{0,4}$ ]] && ((host_port >= 1024 && host_port <= 65535)) || exit 1
[[ "$container_port" =~ ^[1-9][0-9]{0,4}$ ]] && ((container_port >= 1 && container_port <= 65535)) || exit 1
[[ "$postgres" == true || "$postgres" == false ]] || exit 1
[[ "$image" =~ ^backstage-test/$name:[0-9]+-[0-9]+$ ]] || exit 1
umask 077
mkdir -p "$HOME/backstage-environments/$name"
cd "$HOME/backstage-environments/$name"
# Preserva variáveis da aplicação e a senha do banco em novos deploys.
touch app.env
if [[ "$postgres" == true && ! -f postgres.env ]]; then
  printf 'POSTGRES_PASSWORD=%s\n' "$(openssl rand -hex 24)" > postgres.env
fi
cat > .env <<ENV
DEPLOY_IMAGE=$image
HOST_PORT=$host_port
CONTAINER_PORT=$container_port
ENV
if [[ "$postgres" == true ]]; then
  cat postgres.env >> .env
fi
cat > compose.yaml <<'COMPOSE'
services:
  app:
    image: ${DEPLOY_IMAGE:?}
    restart: unless-stopped
    env_file: app.env
    ports:
      - "${HOST_PORT:?}:${CONTAINER_PORT:?}"
COMPOSE
if [[ "$postgres" == true ]]; then
  cat >> compose.yaml <<'COMPOSE'
    environment:
      PORT: ${CONTAINER_PORT:?}
      DB_HOST: postgres
      DB_PORT: '5432'
      DB_NAME: appdb
      DB_USER: appuser
      DB_PASSWORD: ${POSTGRES_PASSWORD:?}
      DATABASE_URL: postgres://appuser:${POSTGRES_PASSWORD:?}@postgres:5432/appdb
    depends_on:
      postgres:
        condition: service_healthy
  postgres:
    image: postgres:17-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: [CMD-SHELL, 'pg_isready -U appuser -d appdb']
      interval: 5s
      timeout: 5s
      retries: 20
volumes:
  postgres_data:
COMPOSE
else
  cat >> compose.yaml <<'COMPOSE'
    environment:
      PORT: ${CONTAINER_PORT:?}
COMPOSE
fi
docker compose -p "test-$name" config --quiet
docker compose -p "test-$name" up -d --remove-orphans --wait --wait-timeout 120
docker compose -p "test-$name" ps
