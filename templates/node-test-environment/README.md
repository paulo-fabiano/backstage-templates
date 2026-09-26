# Criar ambiente de teste Node.js

Recebe um repositório existente e uma branch, tag ou commit. O Backstage dispara
GitHub Actions neste repositório; o runner constrói a imagem e a envia via SSH
para o servidor de testes. Não cria outro repositório nem registra um novo serviço
no catálogo. Não executa `npm test`: cria um ambiente para testar a aplicação.

## 1. Preparar o servidor

Use um servidor Linux dedicado a testes, com Bash, OpenSSL, Docker Engine e
Docker Compose v2 com suporte a `up --wait`. O servidor precisa ter a mesma
arquitetura do runner `ubuntu-latest` (x86_64) e acesso ao Docker Hub caso use
PostgreSQL. Caso use ARM, adapte o build/runner antes de executar.

Crie um usuário de deploy com acesso ao Docker sem sudo e configure sua chave
pública em `~/.ssh/authorized_keys`. Esse acesso permite controlar o Docker do
servidor; use apenas repositórios e operadores confiáveis.

O runner do GitHub precisa alcançar a porta SSH. A porta escolhida para a aplicação
precisa estar disponível e liberada no firewall para quem for testar. Não é preciso
instalar Node nem clonar a aplicação no servidor. O PostgreSQL não publica porta.

## 2. Configurar GitHub Actions

Publique o workflow e os scripts deste repositório na branch `main` (a branch
padrão deve conter o workflow para habilitar o disparo manual). Em **Settings →
Environments**, crie o environment `test-server` e configure os secrets:

| Secret | Conteúdo |
| --- | --- |
| `TEST_SSH_HOST` | DNS ou IPv4 do servidor, sem protocolo |
| `TEST_SSH_USER` | Usuário de deploy |
| `TEST_SSH_PORT` | Porta SSH; opcional, padrão `22` |
| `TEST_SSH_PRIVATE_KEY` | Chave SSH privada completa do usuário de deploy |
| `TEST_SSH_KNOWN_HOSTS` | Entrada verificada do servidor no formato `known_hosts` |
| `SOURCE_REPO_TOKEN` | Token com Contents: read no repositório da aplicação; necessário para repositórios privados externos |

Para obter a entrada de host, execute `ssh-keyscan -p 22 HOST` de uma máquina
administrativa e confira a impressão digital com o administrador antes de salvar.
Para outra porta, preserve o formato `[HOST]:PORT` produzido pelo comando.

Para repositórios públicos, o workflow pode usar seu `GITHUB_TOKEN`. O token de
origem não é enviado ao servidor. Configure restrições de branches do environment
para que somente a branch de infraestrutura confiável possa acessar os secrets.

## 3. Configurar Backstage

O backend deve ter `@backstage/plugin-scaffolder-backend-module-github` registrado,
e a ação `github:actions:dispatch` deve aparecer em `/create/actions`.
A integração GitHub do Backstage precisa de permissão **Actions: write** neste
repositório para disparar workflows, além das permissões de leitura do catálogo.

O template aponta para `paulo-fabiano/backstage-templates`, branch `main`. Se usar
outro destino, ajuste `repoUrl`, `branchOrTagName` e o link em `output.links` no
`template.yaml`. O token de origem é independente da credencial do Backstage.

Publique também o `catalog-info.yaml` atualizado e atualize a Location no Backstage
para que o novo template apareça em `/create`.

## 4. Preparar a aplicação

A aplicação precisa de um `Dockerfile` na raiz que produza uma imagem executável
com `CMD` ou `ENTRYPOINT`. Use `.dockerignore` para excluir `.git`, `node_modules`,
`.env` e outros segredos do contexto. O build acontece no runner, sem secrets de
build ou suporte configurado a dependências npm privadas.

A aplicação deve escutar em `0.0.0.0`, na porta interna informada. O deploy define
`PORT`, mas seu código precisa respeitar essa variável ou usar a mesma porta fixa.
Para apps com build TypeScript, o Dockerfile deve compilar e iniciar o resultado.

Variáveis adicionais e segredos ficam no servidor em:

```text
~/backstage-environments/NOME-DO-AMBIENTE/app.env
```

Crie esse arquivo antes do primeiro deploy se a aplicação exigir essas variáveis.
Ele segue o formato `CHAVE=valor` e é preservado nos próximos deploys. Não passe
segredos pelo formulário do Backstage. O deploy cria um arquivo vazio se ausente.

Com PostgreSQL habilitado, a aplicação recebe `DB_HOST`, `DB_PORT`, `DB_NAME`,
`DB_USER`, `DB_PASSWORD` e `DATABASE_URL`. O banco é `appdb`, o usuário é `appuser`,
e a senha é gerada no servidor e preservada em `postgres.env`. Essas variáveis e
`PORT` prevalecem sobre `app.env`. Migrações e carga de dados são responsabilidade
da aplicação. Não há cópia de dados de produção.

## 5. Criar e acessar o ambiente

No Backstage, escolha **Criar ambiente de teste Node.js** e informe, por exemplo:

- Repositório: `minha-organizacao/minha-api`
- Branch: `main`
- Ambiente: `minha-api-login`
- Porta no servidor: `3001`
- Porta interna: `3000`
- PostgreSQL: `Sim`, se necessário

Clique em Criar e acompanhe o link para o workflow. O sucesso da tarefa no
Backstage confirma o disparo, não a conclusão do deploy. Após o workflow terminar,
acesse `http://HOST-DO-SERVIDOR:3001` e valide uma rota da aplicação.

O Compose espera os containers iniciarem e os healthchecks existentes passarem.
Sem `HEALTHCHECK` no Dockerfile, isso não garante que o HTTP esteja pronto. Este
fluxo não configura domínio, HTTPS ou rollback automático.

Cada nome corresponde a um projeto Compose `test-NOME`, com rede e volume próprios.
Use nomes exclusivos por aplicação e portas externas diferentes. Repetir o nome
atualiza o ambiente e preserva os dados do PostgreSQL. Desabilitar PostgreSQL remove
o container do banco, mas preserva o volume. Os deploys são serializados para o
servidor; uma porta ocupada faz o deploy falhar e não há alocação automática.
O GitHub pode substituir execuções ainda pendentes no mesmo grupo de concorrência;
confira o status e dispare novamente se uma solicitação for cancelada.

## Operação no servidor

Substitua `minha-api-login` pelo nome escolhido:

```bash
cd ~/backstage-environments/minha-api-login
docker compose -p test-minha-api-login logs -f app
```

Para reaplicar variáveis após editar `app.env`:

```bash
docker compose -p test-minha-api-login up -d
```

Para encerrar preservando os dados:

```bash
docker compose -p test-minha-api-login down
```

Para excluir também os dados do banco, use `down --volumes` intencionalmente.
Imagens de deploys anteriores permanecem no servidor; planeje sua limpeza conforme
o espaço disponível. O template não remove ambientes automaticamente.

Referências: [ação de dispatch do Backstage](https://backstage.io/api/stable/functions/_backstage_plugin-scaffolder-backend-module-github.createGithubActionsDispatchAction.html)
e [workflow_dispatch do GitHub](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow).
