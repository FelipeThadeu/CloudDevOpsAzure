# Documentação da Arquitetura Cloud e DevOps

Este documento fornece uma visão técnica geral da atual arquitetura de Cloud e DevOps, abrangendo a configuração da infraestrutura via Terraform, as configurações de workload no Kubernetes e o pipeline de CI/CD implementado no GitHub Actions.

## 1. Infraestrutura (Terraform)

A base da arquitetura é construída no Microsoft Azure e provisionada iterativamente usando uma abordagem IaC (Infraestrutura como Código) com o Terraform. A infraestrutura é totalmente modularizada.

### Componentes Principais
- **Resource Group**: Atua como o contêiner lógico para todos os recursos implantados.
- **Rede (Módulo VNet)**: 
  - Uma Virtual Network abrangente (`module/vnet`).
  - Sub-redes claramente segregadas por propósito: `aks_subnet` (para nós/pods), `apps_subnet` e `data_subnet`.
- **Armazenamento e Key Vault (Módulo Storage)**:
  - **Azure Container Registry (ACR)**: Registro centralizado para imagens Docker usadas pelo AKS.
  - **Azure Key Vault**: Armazena credenciais seguras (por exemplo, senhas de banco de dados, chaves de API, secrets JWT).
  - **Storage Account**: Armazenamento de uso geral configurado de acordo com a camada (tier) e os requisitos de replicação definidos.
- **Computação (Módulo AKS)**:
  - **Azure Kubernetes Service (AKS)**: Cluster Kubernetes gerenciado, escalonado dinamicamente com base na configuração de nós (autoscaling ativado).
  - **Managed Identity**: Usa uma Azure User Assigned Identity para que os nós do cluster AKS se identifiquem com segurança.
  - Integração com ACR, Key Vault e VNet.
- **Observabilidade**:
  - **Log Analytics Workspace e Application Insights**: Implantados para coletar métricas, logs e informações de rastreamento do cluster e das aplicações.

## 2. Workloads do Kubernetes

A aplicação (`api`) é implantada no Azure Kubernetes Service (AKS) dentro do namespace `production`. Os manifestos de implantação (deployment) focam fortemente em confiabilidade, zero downtime e segurança.

### Características e Melhores Práticas
- **Estratégia de Implantação (Deployment)**: Réplicas definidas como `3` com uma estratégia `RollingUpdate` (`maxUnavailable: 1`, `maxSurge: 1`).
- **Alta Disponibilidade (High Availability)**: `TopologySpreadConstraints` garantem que os pods sejam distribuídos uniformemente entre os nós e as zonas de disponibilidade. Um `PodDisruptionBudget` (PDB) garante que pelo menos 2 pods estejam sempre disponíveis durante a manutenção dos nós.
- **Identidade e Segurança (Workload Identity)**: Usa Azure Workload Identity para federar a ServiceAccount do Kubernetes (`api-sa`) diretamente com uma Managed Identity do Azure.
- **Gerenciamento de Secrets**: Os secrets do Azure Key Vault são montados diretamente nos pods usando o Secrets Store CSI Driver (`SecretProviderClass`).
- **Inicialização da Aplicação**:
  - Um `initContainer` (busybox) executa uma verificação com o `nc` (netcat) para garantir que o Banco de Dados esteja acessível antes do início do contêiner principal.
  - Recursos garantidos usando QoS (Burstable): Solicitações (Requests: 250m CPU, 256Mi RAM) e Limites (Limits: 500m CPU, 512Mi RAM).
  - Probes abrangentes configurados: `startupProbe`, `livenessProbe` e `readinessProbe`.
- **Contexto de Segurança (Security Context)**: O pod é executado como um usuário não-root (id 1000) com o perfil seccomp `RuntimeDefault`. O contêiner remove todas as permissões (capabilities) do Linux, permitindo apenas `NET_BIND_SERVICE`, e monta o sistema de arquivos raiz (root filesystem) como somente leitura.

## 3. Pipeline de CI/CD (GitHub Actions)

O workflow de CI/CD (`.github/workflows/build-deploy.yml`) é construído priorizando a Segurança da Cadeia de Suprimentos (Supply Chain Security - SLSA) e as práticas de GitOps.

### Estágios do Pipeline

1. **Build e Testes Unitários (`build`)**:
   - Acionado por push para a `main`/`develop` e PRs (Pull Requests) para a `main`.
   - Setup usando builds multi-stage do Docker.
   - Executa testes unitários e gera relatórios de cobertura (coverage).
   - Verificação de segurança (scan) usando Trivy (resultado da verificação de vulnerabilidades gerado no formato SARIF).
   - Autentica no Azure nativamente, evitando secrets de longa duração (via OIDC Federated Identity).
   - Gera declarações de SBOM e Provenance e, em seguida, assina a imagem enviada (push) para o ACR usando Sigstore Cosign.

2. **Deploy de Homologação / Staging (`deploy-staging`)**:
   - Acionado a partir da branch `develop`.
   - Autentica no Azure via OIDC.
   - Usa `kubectl set image` para atualizar a implantação (deployment payload).
   - Valida a implantação por meio de um smoke test (`curl` contra o endpoint `/health/ready`), emitindo um rollback automático (`kubectl rollout undo`) se falhar.

3. **Deploy de Produção (`deploy-production`)**:
   - Acionado a partir da branch `main`.
   - Utiliza GitHub Environments para regras de proteção (por exemplo, aprovações manuais).
   - Assim como o staging, atualiza a imagem da aplicação e verifica a integridade (health) por meio de smoke testing contínuo. Rollbacks são fortemente favorecidos em caso de falha.
   - **Atualização do Manifesto GitOps**: Como etapa final, um GitHub App Token é usado para clonar o repositório interno de manifestos `infra`, atualizar a tag de imagem da implantação (deploy) de forma computacional e realizar o commit/push de volta. Isso garante que o repositório de configuração atue como a única fonte da verdade, alinhando-se com o estado atual.
