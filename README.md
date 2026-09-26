# Backstage Templates

Template inicial: Node.js + PostgreSQL. Gera arquivos, cria um repositório privado
no GitHub e registra a aplicação no catálogo. O deploy via Docker Compose é manual.

## Publicar este repositório

Com a GitHub CLI instalada e autenticada, execute nesta pasta:

```bash
gh repo create paulo-fabiano/backstage-templates --public --source=. --remote=origin --push
```

## Configurar Backstage

Mescle os campos abaixo na configuração de produção, preservando as outras locations:

```yaml
integrations:
  github:
    - host: github.com
      token: ${GITHUB_TOKEN}
catalog:
  locations:
    - type: url
      target: https://github.com/paulo-fabiano/backstage-templates/blob/main/catalog-info.yaml
      rules:
        - allow: [Location, Template]
```

Defina GITHUB_TOKEN no ambiente do Backstage com acesso de leitura a este repositório
e permissões de criação e publicação no destino escolhido. O backend precisa do
módulo @backstage/plugin-scaffolder-backend-module-github.

Para adicionar templates, crie outra pasta em templates/ e inclua seu template.yaml
na lista spec.targets do catalog-info.yaml. Atualize a Location no catálogo após publicar.

Use /create no Backstage para executar o template. Confira o responsável do template
(spec.owner) caso publique em outra organização.

## Ambiente de teste para uma aplicação existente

O template **Criar ambiente de teste Node.js** dispara o workflow
`.github/workflows/deploy-node-test.yaml` deste repositório. A pipeline constrói
a imagem da aplicação e a envia via SSH para um servidor separado.

Consulte [a configuração e o uso](templates/node-test-environment/README.md).
