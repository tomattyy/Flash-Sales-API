# Flash Sales API

API REST para processamento de vendas, desenvolvida com Node.js 24, TypeScript e Express.

## Pré-requisitos

- Node.js 24
- npm
- PostgreSQL e Redis para executar a aplicação completa

## Instalação e execução

```bash
npm ci
npm run dev
```

A aplicação usa a configuração de ambiente para conectar aos serviços. Não versione credenciais; mantenha-as fora do repositório.

## Validação local

```bash
npm run lint
npm run format:check
npm run typecheck
npm run build
npm test
```

O build TypeScript gera os arquivos de produção em `dist/`, que não deve ser versionado.

## CI e fluxo de branches

O workflow `CI - Validation` executa em pushes para `main`, `develop` e branches `feature/*`, `fix/*`, `release/*` e `hotfix/*`. Pull requests com destino a `develop` ou `main` passam pelas verificações de lint, formatação, tipos, build e testes.

O fluxo de trabalho é `feature/*` ou `fix/*` → pull request → `develop`; releases seguem de `develop` para `release/*` e depois para `main`. Hotfixes partem de `main`.

Configure nas regras de proteção do GitHub que `main` e `develop` só aceitem pull requests e exijam o check **Application Validation**. Essa configuração fica nas regras do repositório GitHub, não no workflow versionado.
