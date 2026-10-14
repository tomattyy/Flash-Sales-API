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

Configure nas regras de proteção do GitHub que `main` e `develop` só aceitem pull requests e exijam os checks **Application Validation**, **Secret Scan**, **Static Application Security Testing** e **Dependency Vulnerability Scan**. Essa configuração fica nas regras do repositório GitHub, não no workflow versionado.

## Segurança e dependências

O workflow `CI - Security` executa:

- Gitleaks sobre o histórico Git completo para detectar segredos versionados;
- Semgrep com as regras padrão para análise estática do código;
- `npm audit` sobre as dependências de produção e desenvolvimento.

O gate de dependências falha para vulnerabilidades de severidade alta ou crítica (`--audit-level=high`). Vulnerabilidades moderadas ainda são reportadas pelo npm, mas não bloqueiam este gate. Na configuração inicial, foi removido `ts-node-dev`, que não era utilizado e introduzia uma dependência vulnerável sem correção disponível; as vulnerabilidades restantes estão abaixo do limite configurado.

Não há arquivos Terraform ou outra configuração de IaC neste estágio. A análise de IaC será adicionada junto da implementação de infraestrutura, para verificar arquivos reais em vez de executar uma etapa sem alvo.
