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

As GitHub Actions são fixadas por SHA de commit para evitar alterações silenciosas atrás de tags mutáveis.

O gate de dependências falha para vulnerabilidades de severidade alta ou crítica (`--audit-level=high`). Vulnerabilidades moderadas ainda são reportadas pelo npm, mas não bloqueiam este gate. Na configuração inicial, foi removido `ts-node-dev`, que não era utilizado e introduzia uma dependência vulnerável sem correção disponível; as vulnerabilidades restantes estão abaixo do limite configurado.

Não há arquivos Terraform ou outra configuração de IaC neste estágio. A análise de IaC será adicionada junto da implementação de infraestrutura, para verificar arquivos reais em vez de executar uma etapa sem alvo.

## Docker local

Docker Engine e Docker Compose v2 são necessários. Defina uma senha de desenvolvimento para o PostgreSQL no ambiente antes de iniciar os serviços. No PowerShell:

```powershell
$env:DB_PASSWORD = "uma-senha-local"
docker compose up --build
```

Em shells POSIX, use `export DB_PASSWORD="uma-senha-local"` antes de executar `docker compose up --build`. O Compose mantém o PostgreSQL e o Redis acessíveis apenas na rede interna; a API é publicada em `127.0.0.1:3000`. Os dados do PostgreSQL persistem no volume `postgres-data`.

Verifique a API em `http://localhost:3000/health` e as métricas em `http://localhost:3000/metrics`. Encerre com `docker compose down`; para apagar também os dados locais do banco, use `docker compose down --volumes`.

O `Dockerfile` usa estágios separados para dependências, build e runtime, executa como usuário não-root e contém um healthcheck HTTP. O workflow `CI - Container` constrói a imagem em pull requests e pushes, bloqueia vulnerabilidades de severidade alta/crítica detectadas pelo Trivy e publica o SBOM CycloneDX como artefato do GitHub Actions.

### Publicação no Docker Hub

Configure os secrets do repositório GitHub `DOCKERHUB_USERNAME` e `DOCKERHUB_TOKEN`. Use um Docker Hub access token com permissão de escrita para o repositório de imagem `flash-sales-api` no namespace do usuário configurado.

A imagem somente é publicada depois do build, do scan Trivy e da geração do SBOM:

- Push em `main`: publica as tags `latest` e `sha-<commit completo>`.
- Tag semver `vMAJOR.MINOR.PATCH` apontando para um commit já integrado em `main`: publica `vMAJOR.MINOR.PATCH`, `MAJOR.MINOR.PATCH` e `sha-<commit completo>`.
- Pull requests, `develop` e branches de feature/fix são construídos e escaneados, mas não publicados.

Para uma release, crie e envie uma tag semver de um commit já integrado em `main`. Os workflows de validação, segurança e container também são acionados para tags `v*`.

## Terraform e LocalStack

A configuração Terraform cria no LocalStack um bucket S3 privado reservado para persistência futura de exports e uma chave KMS gerenciada pelo cliente, usada para criptografar os objetos e com rotação habilitada. O endpoint é local, as credenciais `test` são fictícias e o state local não deve ser commitado. Atualmente, `ExportService` ainda gera o relatório em memória e não grava objetos no bucket.

Pré-requisitos: Docker Engine, Docker Compose v2 e Terraform CLI `1.16.6`. No PowerShell, inicie LocalStack pelo profile `iac`:

```powershell
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"
$env:AWS_DEFAULT_REGION = "us-east-1"
docker compose --profile iac up -d localstack
terraform -chdir=terraform init
terraform -chdir=terraform plan -var="localstack_endpoint=http://localhost:4566"
terraform -chdir=terraform apply -auto-approve -var="localstack_endpoint=http://localhost:4566"
terraform -chdir=terraform output
terraform -chdir=terraform destroy -auto-approve -var="localstack_endpoint=http://localhost:4566"
docker compose --profile iac down
```

O provider AWS está configurado para apontar os serviços S3 e KMS somente ao endpoint do LocalStack e usar path-style addressing para S3. As credenciais de teste são fornecidas pelo ambiente e não ficam gravadas na configuração. Não use esses comandos contra uma conta AWS real. O workflow `CI - Terraform IaC` verifica formatação, inicialização, validação e segurança e aplica/destrói a infraestrutura em um LocalStack efêmero.
