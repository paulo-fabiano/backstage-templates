# ${{ values.appName }}

Aplicação Node.js com PostgreSQL gerada pelo Backstage.

## Executar no servidor com Docker Compose

Copie `.env.example` para `.env` e preencha `POSTGRES_PASSWORD` com uma senha forte.
Não versione `.env`. Execute:

```bash
docker compose up -d --build
curl http://localhost:${{ values.appPort }}/health
```

O banco persiste em um volume Docker. Este template não configura HTTPS,
backups nem deploy automático. Configure esses recursos antes do uso em produção.
