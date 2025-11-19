# 💰 Azure Cost Export Tool

Ferramenta em PowerShell para exportar custos do Azure segregados por Resource Group e por Recursos individuais para Excel.

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Azure](https://img.shields.io/badge/Azure-Cost%20Management-0078D4.svg)](https://azure.microsoft.com/)

---

## 🎯 Funcionalidades

- ✅ **Exportação de custos por Resource Group** - Visão consolidada por grupo de recursos
- ✅ **Exportação detalhada por Recurso** - Inclui nome, tipo, location e resource ID
- ✅ **Seleção interativa** - Escolha Tenant, Subscription e Conta durante a execução
- ✅ **Suporte a MFA** - Compatível com autenticação multifator
- ✅ **Períodos flexíveis** - Mês atual, mês anterior, últimos 30/90 dias ou personalizado
- ✅ **Detecção automática de moeda** - Suporta BRL, USD, EUR e outras
- ✅ **Excel profissional** - Arquivo formatado com 2 abas, gráficos e totais

---

## 📋 Pré-requisitos

### Software necessário:
- **PowerShell 5.1** ou superior (Windows PowerShell ou PowerShell Core)
- **Conexão com internet** (para instalar módulos e consultar Azure)

### Módulos PowerShell (instalados automaticamente):
- `Az.Accounts` (v2.0.0+)
- `ImportExcel` (v7.0.0+)

### Permissões no Azure:
- **Cost Management Reader** (mínimo recomendado)
- Ou qualquer role superior: `Contributor`, `Owner`, etc.
- Acesso de leitura à subscription desejada

> **💡 Dica:** Se não tiver certeza sobre suas permissões, execute o script - ele verificará automaticamente.

---

## 🚀 Instalação e Uso

### Opção 1: Executar direto do GitHub (Recomendado) ⭐

Execute esta linha no PowerShell:

```powershell
irm https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPO/main/Export-AzureCostInteractive-Public.ps1 | iex
```

> **Vantagens:** Sempre usa a versão mais recente, sem precisar baixar nada!

### Opção 2: Baixar e executar localmente

```powershell
# Baixar o script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPO/main/Export-AzureCostInteractive-Public.ps1" -OutFile "Export-AzureCost.ps1"

# Executar
.\Export-AzureCost.ps1
```

### Opção 3: Clonar o repositório

```bash
git clone https://github.com/SEU_USUARIO/SEU_REPO.git
cd SEU_REPO
.\Export-AzureCostInteractive-Public.ps1
```

---

## 📖 Como Usar

### 🔐 Passo 1: Seleção de Credenciais

Ao executar, você verá este menu:

```
========================================
  Configuração de Credenciais Azure
========================================

Como deseja configurar as credenciais?

[1] Informar manualmente (Tenant ID, Subscription ID, E-mail)

[2] Fazer login e selecionar da lista (RECOMENDADO) ⭐
    - Suporta MFA (autenticação multifator)
    - Lista todas as subscriptions disponíveis

Digite sua opção (1-2):
```

#### **Opção 1: Informar Manualmente**
- Você digita:
  - Tenant ID
  - Subscription ID
  - E-mail da conta
- Use quando já souber os IDs

#### **Opção 2: Login Interativo** ⭐ **RECOMENDADO**
- Abre janela de login do Azure
- Suporta MFA automaticamente
- Lista todas as subscriptions disponíveis
- Você escolhe qual usar
- **Ideal para ambientes corporativos com MFA**

---

### 📅 Passo 2: Seleção de Período

```
========================================
  Seleção de Período
========================================

Escolha o período:

[1] Mês atual
[2] Mês anterior
[3] Últimos 30 dias
[4] Últimos 90 dias
[5] Período personalizado

Digite sua opção (1-5):
```

Se escolher **[5] Período personalizado**, você digita as datas:
```
Data inicial (YYYY-MM-DD): 2024-10-01
Data final (YYYY-MM-DD): 2024-10-31
```

---

### 📊 Resultado: Arquivo Excel com 2 Abas

O script gera um arquivo Excel profissional:

#### **Aba 1: Custos por Resource Group**

| Resource Group | Custo | Moeda |
|---|---:|---|
| rg-production | 1,234.56 | USD |
| rg-development | 567.89 | USD |
| rg-infrastructure | 234.12 | USD |
| **TOTAL** | **2,036.57** | **USD** |

#### **Aba 2: Custos por Resources** (Detalhado)

| Nome do Recurso | Resource Group | Tipo | Location | Custo | Moeda | Resource ID |
|---|---|---|---|---:|---|---|
| vm-prod-web-01 | rg-production | Microsoft.Compute/virtualMachines | eastus | 500.00 | USD | /subscriptions/.../vm-prod-web-01 |
| storage-backup | rg-production | Microsoft.Storage/storageAccounts | brazilsouth | 123.45 | USD | /subscriptions/.../storage-backup |
| sql-db-main | rg-production | Microsoft.Sql/servers/databases | eastus2 | 611.11 | USD | /subscriptions/.../sql-db-main |
| app-service-api | rg-development | Microsoft.Web/sites | westus | 345.67 | USD | /subscriptions/.../app-service-api |

**Funcionalidades do Excel:**
- ✅ Formatação automática de moeda (R$, US$, €)
- ✅ Filtros automáticos em todas as colunas
- ✅ Linha de total destacada
- ✅ Cabeçalhos fixos ao rolar
- ✅ Colunas auto-ajustadas
- ✅ Bordas e formatação profissional

---

## 🔧 Uso Avançado

### Executar com parâmetros (pula menus interativos)

```powershell
.\Export-AzureCost.ps1 `
  -TenantId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" `
  -SubscriptionId "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy" `
  -Account "usuario@domain.com" `
  -StartDate "2024-10-01" `
  -EndDate "2024-10-31" `
  -OutputPath "C:\Relatorios\Custos_Outubro.xlsx"
```

### Parâmetros disponíveis:

| Parâmetro | Tipo | Descrição | Exemplo |
|---|---|---|---|
| `-TenantId` | String | ID do Tenant Azure | `8ded861f-...` |
| `-SubscriptionId` | String | ID da Subscription | `54e11e69-...` |
| `-Account` | String | E-mail da conta | `user@domain.com` |
| `-StartDate` | DateTime | Data inicial | `2024-10-01` |
| `-EndDate` | DateTime | Data final | `2024-10-31` |
| `-OutputPath` | String | Caminho do arquivo Excel | `C:\Relatorios\custos.xlsx` |

---

## 💡 Exemplos Práticos

### Exemplo 1: Custos do mês atual (interativo)

```powershell
.\Export-AzureCost.ps1
```

1. Escolha **[2]** - Login interativo
2. Faça login no Azure
3. Selecione a subscription
4. Escolha **[1]** - Mês atual
5. Pronto! 📊

---

### Exemplo 2: Custos do trimestre (automatizado)

```powershell
$startDate = (Get-Date).AddMonths(-3).ToString("yyyy-MM-dd")
$endDate = (Get-Date).ToString("yyyy-MM-dd")

.\Export-AzureCost.ps1 `
  -StartDate $startDate `
  -EndDate $endDate `
  -OutputPath ".\Custos_Trimestre.xlsx"
```

---

### Exemplo 3: Múltiplas subscriptions

```powershell
# Para cada subscription, execute:
.\Export-AzureCost.ps1 `
  -SubscriptionId "sub-1-id" `
  -OutputPath ".\Custos_Subscription1.xlsx"

.\Export-AzureCost.ps1 `
  -SubscriptionId "sub-2-id" `
  -OutputPath ".\Custos_Subscription2.xlsx"
```

---

### Exemplo 4: Relatório mensal automatizado

Crie um script `relatorio-mensal.ps1`:

```powershell
# Calcula primeiro e último dia do mês anterior
$firstDay = (Get-Date -Day 1).AddMonths(-1).ToString("yyyy-MM-dd")
$lastDay = (Get-Date -Day 1).AddDays(-1).ToString("yyyy-MM-dd")
$monthName = (Get-Date).AddMonths(-1).ToString("yyyy-MM")

# Executa o export
.\Export-AzureCost.ps1 `
  -StartDate $firstDay `
  -EndDate $lastDay `
  -OutputPath ".\Relatorios\Custos_$monthName.xlsx"

# Enviar por e-mail (exemplo com Send-MailMessage)
Send-MailMessage `
  -To "financeiro@empresa.com" `
  -From "azure-reports@empresa.com" `
  -Subject "Relatório de Custos Azure - $monthName" `
  -Body "Segue anexo relatório de custos do mês $monthName" `
  -Attachments ".\Relatorios\Custos_$monthName.xlsx" `
  -SmtpServer "smtp.empresa.com"
```

Agende no **Task Scheduler** para executar todo dia 1º do mês! 📅

---

## 🐛 Troubleshooting

### ❌ Erro: "Cannot find tenant id for provided tenant domain"

**Causa:** Problema com MFA ou tenant incorreto.

**Solução:**
1. Execute o script novamente
2. Escolha **opção [2]** (Login interativo)
3. Faça login normalmente com MFA

---

### ❌ Erro: "The access token is invalid"

**Causa:** Token de autenticação expirado.

**Solução:**
```powershell
# Limpar sessões antigas
Disconnect-AzAccount
Clear-AzContext -Force

# Executar novamente
.\Export-AzureCost.ps1
```

---

### ❌ Erro: "Nenhum dado de custo encontrado"

**Causas possíveis:**
1. Período sem custos (subscription nova)
2. Sem permissões de Cost Management
3. Subscription desativada

**Solução:**
1. Verifique se há recursos ativos na subscription
2. Confirme permissões no Portal Azure:
   - Vá em **Subscriptions** → Sua subscription
   - Clique em **Access control (IAM)**
   - Verifique se tem role **Cost Management Reader** ou superior

---

### ❌ Erro: "Módulos não instalados"

**Solução manual:**

```powershell
# Instalar módulos manualmente
Install-Module -Name Az.Accounts -Scope CurrentUser -Force
Install-Module -Name ImportExcel -Scope CurrentUser -Force

# Executar novamente
.\Export-AzureCost.ps1
```

---

### ❌ Erro: "Execution of scripts is disabled"

**Causa:** Política de execução do PowerShell bloqueando scripts.

**Solução:**

```powershell
# Permitir execução de scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Ou executar com bypass temporário
powershell -ExecutionPolicy Bypass -File .\Export-AzureCost.ps1
```

---

## 🔒 Segurança e Privacidade

### ✅ O que o script FAZ:
- ✅ Lê dados de custo via Azure Cost Management API
- ✅ Gera arquivos Excel localmente na sua máquina
- ✅ Usa autenticação oficial da Microsoft (Az.Accounts)

### ❌ O que o script NÃO FAZ:
- ❌ Não envia dados para servidores externos
- ❌ Não armazena credenciais
- ❌ Não modifica recursos no Azure
- ❌ Não compartilha informações com terceiros

### 🔐 Boas práticas:
1. **Não commite arquivos Excel** no Git (já está no `.gitignore`)
2. **Não compartilhe Tenant/Subscription IDs** publicamente
3. **Use MFA** sempre que possível (opção 2 de login)
4. **Revise permissões** regularmente no Azure

---

## 🤝 Contribuindo

Contribuições são muito bem-vindas! 🎉

### Como contribuir:

1. **Fork** o projeto
2. **Crie uma branch** para sua feature:
   ```bash
   git checkout -b feature/MinhaNovaFuncionalidade
   ```
3. **Commit** suas mudanças:
   ```bash
   git commit -m 'Adiciona filtro por tags'
   ```
4. **Push** para a branch:
   ```bash
   git push origin feature/MinhaNovaFuncionalidade
   ```
5. **Abra um Pull Request** 🚀

### Ideias de melhorias:
- [ ] Adicionar filtros por tags
- [ ] Exportar para CSV além de Excel
- [ ] Gráficos automáticos no Excel
- [ ] Comparação mês a mês
- [ ] Alertas de custos acima do orçamento
- [ ] Suporte para múltiplas subscriptions em um único arquivo

---

## 📝 Changelog

### v1.0.0 (2024-11-19)
- ✨ Lançamento inicial
- ✅ Exportação por Resource Group
- ✅ Exportação detalhada por Resource
- ✅ Seleção interativa de credenciais
- ✅ Suporte a MFA
- ✅ Detecção automática de moeda
- ✅ Múltiplos períodos pré-definidos

---

## 📄 Licença

Este projeto está sob a licença **MIT**. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

Resumo da licença:
- ✅ Uso comercial permitido
- ✅ Modificação permitida
- ✅ Distribuição permitida
- ✅ Uso privado permitido
- ⚠️ Sem garantias

---

## ✨ Autor

**[Seu Nome]**

- 🐙 GitHub: [@SEU_USUARIO](https://github.com/SEU_USUARIO)
- 💼 LinkedIn: [Seu Perfil](https://linkedin.com/in/seu-perfil)
- 📧 E-mail: seu.email@exemplo.com

---

## 🙏 Agradecimentos

- [Microsoft Azure Team](https://azure.microsoft.com/) - Pela excelente Cloud Platform
- [PowerShell Community](https://github.com/PowerShell/PowerShell) - Pela ferramenta incrível
- [ImportExcel Module](https://github.com/dfinke/ImportExcel) - Por tornar Excel fácil no PowerShell
- Todos os contribuidores e usuários deste projeto! ❤️

---

## 📚 Recursos Úteis

- 📖 [Documentação Azure Cost Management](https://docs.microsoft.com/azure/cost-management-billing/)
- 📖 [PowerShell Documentation](https://docs.microsoft.com/powershell/)
- 📖 [Az PowerShell Module](https://docs.microsoft.com/powershell/azure/)
- 📖 [ImportExcel Examples](https://github.com/dfinke/ImportExcel)

---

## ⭐ Gostou do projeto?

Se este projeto foi útil para você, considere dar uma ⭐ no GitHub!

Isso ajuda mais pessoas a encontrarem e usarem a ferramenta.

---

**Desenvolvido com ❤️ para a comunidade Azure**
