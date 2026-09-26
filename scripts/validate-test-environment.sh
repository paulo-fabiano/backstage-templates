#!/usr/bin/env bash
set -euo pipefail
[[ "${SOURCE_REPOSITORY:-}" =~ ^[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9_.-]+$ ]] || { echo 'Repositório inválido'; exit 1; }
[[ "${ENVIRONMENT_NAME:-}" =~ ^[a-z][a-z0-9-]{0,39}$ ]] || { echo 'Nome do ambiente inválido'; exit 1; }
[[ "${HOST_PORT:-}" =~ ^[1-9][0-9]{0,4}$ ]] && (( HOST_PORT >= 1024 && HOST_PORT <= 65535 )) || { echo 'Porta externa inválida'; exit 1; }
[[ "${CONTAINER_PORT:-}" =~ ^[1-9][0-9]{0,4}$ ]] && (( CONTAINER_PORT >= 1 && CONTAINER_PORT <= 65535 )) || { echo 'Porta interna inválida'; exit 1; }
[[ "${POSTGRES:-}" == true || "${POSTGRES:-}" == false ]] || { echo 'Opção PostgreSQL inválida'; exit 1; }
