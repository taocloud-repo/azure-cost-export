#Requires -Version 5.1
<#
.SYNOPSIS
    Exporta custos do Azure para CSV (compatível com Azure Cloud Shell)
.DESCRIPTION
    Versão simplificada que exporta para CSV em vez de Excel
    Ideal para uso no Azure Cloud Shell
.NOTES
    Compatível com Azure Cloud Shell
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [DateTime]$StartDate,

    [Parameter(Mandatory = $false)]
    [DateTime]$EndDate
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Azure Cost Export (Cloud Shell)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Verificar se está no Cloud Shell
$isCloudShell = $env:ACC_CLOUD -eq 'AZURE'
if ($isCloudShell) {
    Write-Host "✓ Executando no Azure Cloud Shell" -ForegroundColor Green
} else {
    Write-Host "⚠ Não está no Cloud Shell, mas pode continuar" -ForegroundColor Yellow
}

# Obter contexto atual
$context = Get-AzContext

if (-not $context) {
    Write-Host "❌ Não está conectado ao Azure!" -ForegroundColor Red
    Write-Host "Execute: Connect-AzAccount" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n✓ Conectado ao Azure" -ForegroundColor Green
Write-Host "  Conta: $($context.Account.Id)" -ForegroundColor Gray
Write-Host "  Subscription: $($context.Subscription.Name)" -ForegroundColor Gray

# Selecionar subscription se não fornecida
if (-not $SubscriptionId) {
    $SubscriptionId = $context.Subscription.Id

    $change = Read-Host "`nUsar esta subscription? (S/N)"

    if ($change -eq 'N' -or $change -eq 'n') {
        Write-Host "`nListando subscriptions disponíveis..." -ForegroundColor Cyan
        $subscriptions = Get-AzSubscription

        for ($i = 0; $i -lt $subscriptions.Count; $i++) {
            $sub = $subscriptions[$i]
            Write-Host "[$($i + 1)] $($sub.Name) - $($sub.Id)" -ForegroundColor Yellow
        }

        $selection = Read-Host "`nSelecione a subscription (1-$($subscriptions.Count))"
        $index = [int]$selection - 1

        $selectedSub = $subscriptions[$index]
        Set-AzContext -SubscriptionId $selectedSub.Id | Out-Null
        $SubscriptionId = $selectedSub.Id

        Write-Host "✓ Subscription alterada" -ForegroundColor Green
    }
}

# Selecionar período
if (-not $StartDate -or -not $EndDate) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  Seleção de Período" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[1] Mês atual" -ForegroundColor Yellow
    Write-Host "[2] Mês anterior" -ForegroundColor Yellow
    Write-Host "[3] Últimos 30 dias" -ForegroundColor Yellow
    Write-Host "[4] Últimos 90 dias" -ForegroundColor Yellow
    Write-Host "[5] Período personalizado" -ForegroundColor Yellow
    Write-Host ""

    $choice = Read-Host "Digite sua opção (1-5)"
    $today = Get-Date

    switch ($choice) {
        "1" {
            $StartDate = Get-Date -Day 1
            $EndDate = $today
        }
        "2" {
            $firstDayLastMonth = (Get-Date -Day 1).AddMonths(-1)
            $StartDate = $firstDayLastMonth
            $EndDate = (Get-Date -Day 1).AddDays(-1)
        }
        "3" {
            $EndDate = $today
            $StartDate = $today.AddDays(-30)
        }
        "4" {
            $EndDate = $today
            $StartDate = $today.AddDays(-90)
        }
        "5" {
            $startInput = Read-Host "Data inicial (YYYY-MM-DD)"
            $endInput = Read-Host "Data final (YYYY-MM-DD)"
            $StartDate = [DateTime]::Parse($startInput)
            $EndDate = [DateTime]::Parse($endInput)
        }
        default {
            $StartDate = Get-Date -Day 1
            $EndDate = $today
        }
    }
}

Write-Host "`nPeríodo: $($StartDate.ToString('dd/MM/yyyy')) até $($EndDate.ToString('dd/MM/yyyy'))" -ForegroundColor Cyan

# Definir output path
if (-not $OutputPath) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    if ($isCloudShell) {
        $OutputPath = "~/clouddrive/AzureCosts_$timestamp"
    } else {
        $OutputPath = "./AzureCosts_$timestamp"
    }
}

# Função para obter custos por Resource Group
function Get-CostsByResourceGroup {
    param(
        [string]$SubscriptionId,
        [DateTime]$StartDate,
        [DateTime]$EndDate
    )

    Write-Host "`n[1/2] Obtendo custos por Resource Group..." -ForegroundColor Cyan

    $scope = "/subscriptions/$SubscriptionId"
    $startDateStr = $StartDate.ToString("yyyy-MM-dd")
    $endDateStr = $EndDate.ToString("yyyy-MM-dd")

    $bodyObject = @{
        type = "ActualCost"
        timeframe = "Custom"
        timePeriod = @{
            from = $startDateStr
            to = $endDateStr
        }
        dataset = @{
            granularity = "None"
            aggregation = @{
                totalCost = @{
                    name = "PreTaxCost"
                    function = "Sum"
                }
            }
            grouping = @(
                @{
                    type = "Dimension"
                    name = "ResourceGroup"
                }
            )
        }
    }

    $body = $bodyObject | ConvertTo-Json -Depth 10
    $apiVersion = "2023-03-01"
    $path = "$scope/providers/Microsoft.CostManagement/query?api-version=$apiVersion"

    $response = Invoke-AzRestMethod -Path $path -Method POST -Payload $body

    if ($response.StatusCode -eq 200) {
        $content = $response.Content | ConvertFrom-Json

        $costData = @()
        foreach ($row in $content.properties.rows) {
            $costData += [PSCustomObject]@{
                ResourceGroup = if ($row[1]) { $row[1] } else { "Não Alocado" }
                Custo = [math]::Round($row[0], 2)
                Moeda = $row[2]
            }
        }

        $costData = $costData | Sort-Object Custo -Descending

        Write-Host "✓ $($costData.Count) Resource Groups encontrados" -ForegroundColor Green

        return $costData
    }
}

# Função para obter custos por Recurso
function Get-CostsByResource {
    param(
        [string]$SubscriptionId,
        [DateTime]$StartDate,
        [DateTime]$EndDate
    )

    Write-Host "`n[2/2] Obtendo custos por Recurso..." -ForegroundColor Cyan

    $scope = "/subscriptions/$SubscriptionId"
    $startDateStr = $StartDate.ToString("yyyy-MM-dd")
    $endDateStr = $EndDate.ToString("yyyy-MM-dd")

    $bodyObject = @{
        type = "ActualCost"
        timeframe = "Custom"
        timePeriod = @{
            from = $startDateStr
            to = $endDateStr
        }
        dataset = @{
            granularity = "None"
            aggregation = @{
                totalCost = @{
                    name = "PreTaxCost"
                    function = "Sum"
                }
            }
            grouping = @(
                @{
                    type = "Dimension"
                    name = "ResourceId"
                },
                @{
                    type = "Dimension"
                    name = "ResourceType"
                },
                @{
                    type = "Dimension"
                    name = "ResourceLocation"
                },
                @{
                    type = "Dimension"
                    name = "ResourceGroupName"
                }
            )
        }
    }

    $body = $bodyObject | ConvertTo-Json -Depth 10
    $apiVersion = "2023-03-01"
    $path = "$scope/providers/Microsoft.CostManagement/query?api-version=$apiVersion"

    $response = Invoke-AzRestMethod -Path $path -Method POST -Payload $body

    if ($response.StatusCode -eq 200) {
        $content = $response.Content | ConvertFrom-Json

        $resourceData = @()
        foreach ($row in $content.properties.rows) {
            $resourceId = $row[1]
            $resourceName = if ($resourceId) {
                $parts = $resourceId -split '/'
                $parts[-1]
            } else {
                "Desconhecido"
            }

            $resourceData += [PSCustomObject]@{
                NomeDoRecurso = $resourceName
                ResourceGroup = if ($row[4]) { $row[4] } else { "Não Alocado" }
                Tipo = if ($row[2]) { $row[2] } else { "N/A" }
                Location = if ($row[3]) { $row[3] } else { "N/A" }
                Custo = [math]::Round($row[0], 2)
                Moeda = if ($row[5]) { $row[5] } else { "USD" }
                ResourceID = $resourceId
            }
        }

        $resourceData = $resourceData | Sort-Object Custo -Descending

        Write-Host "✓ $($resourceData.Count) Recursos encontrados" -ForegroundColor Green

        return $resourceData
    }
}

# Obter dados
$rgData = Get-CostsByResourceGroup -SubscriptionId $SubscriptionId -StartDate $StartDate -EndDate $EndDate
$resourceData = Get-CostsByResource -SubscriptionId $SubscriptionId -StartDate $StartDate -EndDate $EndDate

# Exportar para CSV
Write-Host "`nExportando para CSV..." -ForegroundColor Cyan

$rgCsvPath = "$OutputPath`_ResourceGroups.csv"
$resourceCsvPath = "$OutputPath`_Resources.csv"

$rgData | Export-Csv -Path $rgCsvPath -NoTypeInformation -Encoding UTF8
$resourceData | Export-Csv -Path $resourceCsvPath -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  ✓ Exportação concluída!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Arquivos gerados:" -ForegroundColor Cyan
Write-Host "  1. $rgCsvPath" -ForegroundColor White
Write-Host "  2. $resourceCsvPath" -ForegroundColor White
Write-Host ""

if ($isCloudShell) {
    Write-Host "💡 Para baixar os arquivos:" -ForegroundColor Yellow
    Write-Host "  1. Clique no ícone 'Upload/Download files' no Cloud Shell" -ForegroundColor Gray
    Write-Host "  2. Selecione 'Download'" -ForegroundColor Gray
    Write-Host "  3. Digite o caminho: $rgCsvPath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Ou use o comando:" -ForegroundColor Yellow
    Write-Host "  download $rgCsvPath" -ForegroundColor Cyan
    Write-Host "  download $resourceCsvPath" -ForegroundColor Cyan
}

# Mostrar resumo
Write-Host "`n📊 Resumo:" -ForegroundColor Cyan
$totalRG = ($rgData | Measure-Object Custo -Sum).Sum
$totalResource = ($resourceData | Measure-Object Custo -Sum).Sum
Write-Host "  Resource Groups: $($rgData.Count)" -ForegroundColor White
Write-Host "  Recursos: $($resourceData.Count)" -ForegroundColor White
Write-Host "  Total: $('{0:N2}' -f $totalRG) $($rgData[0].Moeda)" -ForegroundColor White
