# ☁️ Azure Cost Export - Cloud Shell Edition

Versão simplificada para **Azure Cloud Shell** que exporta custos do Azure para CSV.

[![PowerShell](https://img.shields.io/badge/PowerShell-Cloud%20Shell-blue.svg)](https://shell.azure.com/)
[![Azure](https://img.shields.io/badge/Azure-Cost%20Management-0078D4.svg)](https://azure.microsoft.com/)

---

## 🎯 Por que usar a versão Cloud Shell?

- ✅ **Não precisa instalar nada** - Roda direto no navegador
- ✅ **Já vem autenticado** - Usa sua sessão do Azure Portal
- ✅ **Funciona de qualquer lugar** - Só precisa de um navegador
- ✅ **Sem módulos externos** - Não depende de ImportExcel
- ✅ **Exporta para CSV** - Compatível com Excel, Google Sheets, etc.

---

## 🚀 Uso Rápido (3 passos)

### 1️⃣ Abra o Azure Cloud Shell

Acesse: **https://shell.azure.com/**

Ou clique no ícone **>_** no topo do Portal do Azure e escolha **PowerShell**.

### 2️⃣ Execute o script

Copie e cole este comando:

```powershell
irm https://raw.githubusercontent.com/zoidelamina/azure-cost-export/main/Export-AzureCost-CloudShell.ps1 | iex
```

### 3️⃣ Baixe os arquivos CSV

Após a execução, use um destes métodos:

**Método A - Comando download:**
```powershell
download ~/clouddrive/AzureCosts_*_ResourceGroups.csv
download ~/clouddrive/AzureCosts_*_Resources.csv
```

**Método B - Interface gráfica:**
1. Clique no ícone **📁** (Upload/Download files)
2. Escolha **Download**
3. Digite o caminho do arquivo que o script mostrou

---

## 📖 Como Funciona

### Passo a Passo

Quando você executa o script, ele:

1. **Verifica sua conexão** ao Azure (já autenticado no Cloud Shell)
2. **Pergunta qual subscription** usar (ou confirma a atual)
3. **Pergunta o período:**
   - [1] Mês atual
   - [2] Mês anterior
   - [3] Últimos 30 dias
   - [4] Últimos 90 dias
   - [5] Período personalizado
4. **Busca os dados** de custo via API do Azure
5. **Gera 2 arquivos CSV:**
   - `AzureCosts_YYYYMMDD_HHMMSS_ResourceGroups.csv`
   - `AzureCosts_YYYYMMDD_HHMMSS_Resources.csv`

---

## 📊 Arquivos Gerados

### Arquivo 1: ResourceGroups.csv

Custos consolidados por Resource Group

| ResourceGroup | Custo | Moeda |
|---|---:|---|
| rg-production | 1234.56 | USD |
| rg-development | 567.89 | USD |
| rg-infrastructure | 234.12 | USD |

### Arquivo 2: Resources.csv

Custos detalhados por recurso individual

| NomeDoRecurso | ResourceGroup | Tipo | Location | Custo | Moeda | ResourceID |
|---|---|---|---|---:|---|---|
| vm-prod-01 | rg-production | Microsoft.Compute/virtualMachines | eastus | 500.00 | USD | /subscriptions/.../vm-prod-01 |
| storage-backup | rg-production | Microsoft.Storage/storageAccounts | brazilsouth | 123.45 | USD | /subscriptions/.../storage-backup |

---

## 📥 Como Importar no Excel

### Método Recomendado (mantém formatação numérica)

1. **Abra o Excel** (arquivo em branco)
2. Vá em **Dados** → **De Texto/CSV**
3. Selecione o arquivo CSV baixado
4. Configurações de importação:
   - **Delimitador:** Vírgula
   - **Detecção de tipo:** Automática
5. Clique em **Carregar**

### Formatar como Moeda

1. Selecione a coluna **Custo**
2. Botão direito → **Formatar Células**
3. Escolha **Moeda** ou **Contábil**
4. Símbolo: R$, US$, EUR, etc.
5. Casas decimais: 2

---

## 🔧 Uso Avançado

### Executar com parâmetros específicos

```powershell
# Baixar o script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/zoidelamina/azure-cost-export/main/Export-AzureCost-CloudShell.ps1" -OutFile "Export-Cost.ps1"

# Executar com subscription específica
./Export-Cost.ps1 -SubscriptionId "sua-subscription-id"

# Executar com período personalizado
./Export-Cost.ps1 `
  -StartDate "2024-10-01" `
  -EndDate "2024-10-31" `
  -OutputPath "~/clouddrive/Custos_Outubro"
```

### Parâmetros disponíveis

| Parâmetro | Tipo | Descrição | Exemplo |
|---|---|---|---|
| `-SubscriptionId` | String | ID da subscription | `54e11e69-...` |
| `-StartDate` | DateTime | Data inicial | `2024-10-01` |
| `-EndDate` | DateTime | Data final | `2024-10-31` |
| `-OutputPath` | String | Caminho base dos arquivos | `~/clouddrive/MeuRelatorio` |

---

## 💡 Exemplos Práticos

### Exemplo 1: Relatório do mês anterior

```powershell
irm https://raw.githubusercontent.com/zoidelamina/azure-cost-export/main/Export-AzureCost-CloudShell.ps1 | iex
```
Escolha a opção **[2] Mês anterior**

### Exemplo 2: Comparar custos de 2 subscriptions

```powershell
# Baixar o script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/zoidelamina/azure-cost-export/main/Export-AzureCost-CloudShell.ps1" -OutFile "cost.ps1"

# Subscription 1
./cost.ps1 -SubscriptionId "sub-1-id" -StartDate "2024-10-01" -EndDate "2024-10-31" -OutputPath "~/clouddrive/Sub1"

# Subscription 2
./cost.ps1 -SubscriptionId "sub-2-id" -StartDate "2024-10-01" -EndDate "2024-10-31" -OutputPath "~/clouddrive/Sub2"

# Baixar todos
download ~/clouddrive/Sub1_ResourceGroups.csv
download ~/clouddrive/Sub2_ResourceGroups.csv
```

### Exemplo 3: Análise trimestral

```powershell
# Baixar script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/zoidelamina/azure-cost-export/main/Export-AzureCost-CloudShell.ps1" -OutFile "cost.ps1"

# Executar
./cost.ps1 -StartDate "2024-07-01" -EndDate "2024-09-30" -OutputPath "~/clouddrive/Q3_2024"
```

---

## 🐛 Solução de Problemas

### ❌ Erro: "Cannot convert null to type System.DateTime"

**Causa:** Versão antiga do script.

**Solução:**
```powershell
# Limpar cache e executar novamente
irm https://raw.githubusercontent.com/zoidelamina/azure-cost-export/main/Export-AzureCost-CloudShell.ps1?$(Get-Date -Format yyyyMMddHHmmss) | iex
```

---

### ❌ Erro: "Nenhum dado de custo encontrado"

**Causas possíveis:**
1. Subscription sem recursos/custos no período
2. Período muito antigo (Azure só mantém dados dos últimos 13 meses)
3. Sem permissões de Cost Management

**Solução:**
1. Verifique se há recursos ativos: `Get-AzResource`
2. Confirme permissões:
   ```powershell
   Get-AzRoleAssignment -SignInName (Get-AzContext).Account.Id | Where-Object {$_.RoleDefinitionName -match "Cost|Owner|Contributor"}
   ```

---

### ❌ Excel não reconhece números na coluna Custo

**Solução:**

Ao importar no Excel:
1. Use **Dados** → **De Texto/CSV** (não abra diretamente)
2. Verifique se o delimitador está correto (vírgula)
3. Se ainda estiver como texto, use **Dados** → **Texto para Colunas**

Ou substitua vírgulas por pontos:
```powershell
# No PowerShell, após download
(Get-Content arquivo.csv) -replace ',(\d+\.\d+),', '.$1,' | Set-Content arquivo_fixed.csv
```

---

### ⚠️ Arquivos desaparecem após fechar o Cloud Shell

**Causa:** Arquivos salvos fora do `clouddrive` são temporários.

**Solução:**
O script já salva automaticamente em `~/clouddrive/`, que é persistente.

Para verificar seus arquivos persistentes:
```powershell
ls ~/clouddrive/AzureCosts_*
```

---

## 🔒 Segurança

### ✅ O que o script faz:
- ✅ Lê custos via Azure Cost Management API
- ✅ Gera arquivos CSV no seu clouddrive
- ✅ Usa credenciais do Cloud Shell (já autenticado)

### ❌ O que o script NÃO faz:
- ❌ Não envia dados para servidores externos
- ❌ Não armazena credenciais
- ❌ Não modifica recursos do Azure
- ❌ Não acessa dados além de custos

### 🔐 Boas práticas:
1. **Revise o código** antes de executar: [Ver código fonte](https://github.com/zoidelamina/azure-cost-export/blob/main/Export-AzureCost-CloudShell.ps1)
2. **Não compartilhe arquivos CSV** com dados sensíveis
3. **Delete arquivos antigos** do clouddrive periodicamente:
   ```powershell
   rm ~/clouddrive/AzureCosts_*
   ```

---

## 📋 Requisitos

### Mínimos:
- ✅ Acesso ao Azure Portal
- ✅ Permissão de leitura na subscription
- ✅ Role: **Cost Management Reader** (ou superior)

### Não precisa:
- ❌ PowerShell instalado localmente
- ❌ Módulos Az instalados
- ❌ Permissões de administrador

---

## 🆚 Cloud Shell vs Versão Desktop

| Característica | Cloud Shell (CSV) | Desktop (Excel) |
|---|:---:|:---:|
| Instalação necessária | ❌ Não | ✅ Sim (módulos) |
| Funciona no navegador | ✅ Sim | ❌ Não |
| Formato de saída | CSV | XLSX (Excel) |
| Formatação automática | ⚠️ Manual | ✅ Automática |
| Gráficos incluídos | ❌ Não | ✅ Sim (futuramente) |
| Velocidade | 🚀 Rápida | 🐢 Moderada |
| Ideal para | Consultas rápidas | Relatórios formais |

**Recomendação:** Use Cloud Shell para análises rápidas e a versão Desktop para relatórios oficiais.

---

## 🔗 Links Úteis

- 📖 [Versão Desktop (Excel)](./README.md)
- 🐙 [Código Fonte](https://github.com/zoidelamina/azure-cost-export)
- 📚 [Azure Cost Management Docs](https://docs.microsoft.com/azure/cost-management-billing/)
- ☁️ [Azure Cloud Shell Docs](https://docs.microsoft.com/azure/cloud-shell/overview)

---

## ❓ FAQ

### Posso usar no Bash do Cloud Shell?

Não, este script é para **PowerShell**. Certifique-se de selecionar PowerShell ao abrir o Cloud Shell.

### Os arquivos ficam salvos permanentemente?

Sim, arquivos em `~/clouddrive/` são permanentes e compartilhados entre sessões.

### Quanto tempo leva a execução?

Depende da quantidade de recursos:
- Pequeno (< 100 recursos): ~30 segundos
- Médio (100-1000 recursos): 1-2 minutos
- Grande (> 1000 recursos): 3-5 minutos

### Posso automatizar a execução?

Sim! Use Azure Automation ou Logic Apps para agendar:
```powershell
# Exemplo em Azure Automation Runbook
$params = @{
    SubscriptionId = "sua-sub-id"
    StartDate = (Get-Date).AddMonths(-1).ToString("yyyy-MM-dd")
    EndDate = (Get-Date).ToString("yyyy-MM-dd")
}

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/zoidelamina/azure-cost-export/main/Export-AzureCost-CloudShell.ps1" -OutFile "cost.ps1"
./cost.ps1 @params
```

### Posso exportar múltiplas subscriptions de uma vez?

Sim! Crie um loop:
```powershell
$subscriptions = @("sub-1-id", "sub-2-id", "sub-3-id")

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/zoidelamina/azure-cost-export/main/Export-AzureCost-CloudShell.ps1" -OutFile "cost.ps1"

foreach ($sub in $subscriptions) {
    ./cost.ps1 -SubscriptionId $sub -OutputPath "~/clouddrive/Sub_$sub"
}
```

---

## 🤝 Contribuindo

Encontrou um bug ou tem uma sugestão?

1. Abra uma [Issue](https://github.com/zoidelamina/azure-cost-export/issues)
2. Ou envie um [Pull Request](https://github.com/zoidelamina/azure-cost-export/pulls)

---

## 📝 Changelog

### v1.0.0 (2024-11-19)
- ✨ Lançamento inicial da versão Cloud Shell
- ✅ Exportação para CSV
- ✅ Suporte a seleção interativa de período
- ✅ Compatibilidade total com Azure Cloud Shell
- ✅ Formatação numérica correta para Excel

---

## 📄 Licença

MIT License - Veja [LICENSE](LICENSE) para detalhes.

---

## ✨ Autor

**Desenvolvido por zoidelamina**

- 🐙 GitHub: [@zoidelamina](https://github.com/zoidelamina)
- 📧 E-mail: otaviomcsa@gmail.com

---

## ⭐ Gostou?

Se este script foi útil, considere dar uma ⭐ no [repositório](https://github.com/zoidelamina/azure-cost-export)!

---

**Desenvolvido com ☁️ para a comunidade Azure Cloud Shell**
