#Requires -Version 5.1
<#
.SYNOPSIS
    Exporta custos mensais do Azure de forma interativa
.DESCRIPTION
    Este script permite selecionar Tenant, Subscription e Conta interativamente,
    além de escolher o período e exportar custos detalhados para Excel
.NOTES
    Requer módulos: Az.Accounts, ImportExcel
    Autor: Azure Cost Export Tool
    Versão: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$TenantId,

    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $false)]
    [string]$Account,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [DateTime]$StartDate,

    [Parameter(Mandatory = $false)]
    [DateTime]$EndDate
)

# Função para instalar módulos necessários
function Install-RequiredModules {
    Write-Host "Verificando módulos necessários..." -ForegroundColor Cyan

    $requiredModules = @(
        @{Name = "Az.Accounts"; MinVersion = "2.0.0"},
        @{Name = "ImportExcel"; MinVersion = "7.0.0"}
    )

    foreach ($module in $requiredModules) {
        $installedModule = Get-Module -ListAvailable -Name $module.Name |
            Where-Object { $_.Version -ge [Version]$module.MinVersion } |
            Select-Object -First 1

        if (-not $installedModule) {
            Write-Host "Instalando módulo $($module.Name)..." -ForegroundColor Yellow
            try {
                Install-Module -Name $module.Name -MinimumVersion $module.MinVersion -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
                Write-Host "✓ Módulo $($module.Name) instalado com sucesso" -ForegroundColor Green
            }
            catch {
                Write-Error "ERRO CRÍTICO: Falha ao instalar módulo $($module.Name): $_"
                throw
            }
        }
        else {
            Write-Host "✓ Módulo $($module.Name) já está instalado (versão $($installedModule.Version))" -ForegroundColor Green
        }
    }

    # Importar módulos
    Write-Host "Importando módulos..." -ForegroundColor Cyan
    Import-Module Az.Accounts -ErrorAction Stop
    Import-Module ImportExcel -ErrorAction Stop
    Write-Host "✓ Módulos importados com sucesso" -ForegroundColor Green
}

# Função para selecionar credenciais Azure
function Get-AzureCredentials {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  Configuração de Credenciais Azure" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    Write-Host "`nComo deseja configurar as credenciais?" -ForegroundColor White
    Write-Host ""
    Write-Host "[1] Informar manualmente (Tenant ID, Subscription ID, E-mail)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "[2] Fazer login e selecionar da lista (RECOMENDADO) ⭐" -ForegroundColor Yellow
    Write-Host "    - Suporta MFA (autenticação multifator)" -ForegroundColor DarkGray
    Write-Host "    - Lista todas as subscriptions disponíveis" -ForegroundColor DarkGray
    Write-Host ""

    $choice = Read-Host "Digite sua opção (1-2)"

    switch ($choice) {
        "1" {
            # Informar manualmente
            Write-Host "`nInforme as credenciais:" -ForegroundColor White
            Write-Host ""

            $tenantId = Read-Host "Tenant ID"
            $subscriptionId = Read-Host "Subscription ID"
            $account = Read-Host "E-mail da conta"

            Write-Host "`n✓ Credenciais configuradas" -ForegroundColor Green
            Write-Host "  Tenant: $tenantId" -ForegroundColor Gray
            Write-Host "  Subscription: $subscriptionId" -ForegroundColor Gray
            Write-Host "  Account: $account" -ForegroundColor Gray

            return @{
                TenantId = $tenantId
                SubscriptionId = $subscriptionId
                Account = $account
                AlreadyConnected = $false
            }
        }
        "2" {
            # Login e seleção interativa
            Write-Host "`n✓ Fazendo login no Azure..." -ForegroundColor Cyan
            Write-Host "Uma janela de login será aberta..." -ForegroundColor Yellow

            # Limpar sessões antigas
            Disconnect-AzAccount -ErrorAction SilentlyContinue | Out-Null
            Clear-AzContext -Force -ErrorAction SilentlyContinue | Out-Null

            # Fazer login sem especificar tenant (mostra todos os tenants disponíveis)
            $loginResult = Connect-AzAccount -ErrorAction Stop

            if ($loginResult) {
                Write-Host "✓ Login realizado com sucesso!" -ForegroundColor Green

                # Obter contexto atual
                $currentContext = Get-AzContext

                # Perguntar se quer mudar de subscription
                Write-Host "`nSubscription atual selecionada:" -ForegroundColor Cyan
                Write-Host "  Nome: $($currentContext.Subscription.Name)" -ForegroundColor White
                Write-Host "  ID: $($currentContext.Subscription.Id)" -ForegroundColor Gray
                Write-Host "  Tenant: $($currentContext.Tenant.Id)" -ForegroundColor Gray
                Write-Host ""

                $change = Read-Host "Deseja usar esta subscription? (S/N)"

                if ($change -eq 'N' -or $change -eq 'n') {
                    # Listar todas as subscriptions disponíveis
                    Write-Host "`nBuscando subscriptions disponíveis..." -ForegroundColor Cyan
                    $subscriptions = Get-AzSubscription

                    if ($subscriptions.Count -gt 0) {
                        Write-Host "`nSubscriptions disponíveis:" -ForegroundColor White
                        Write-Host ""

                        for ($i = 0; $i -lt $subscriptions.Count; $i++) {
                            $sub = $subscriptions[$i]
                            Write-Host "[$($i + 1)] $($sub.Name)" -ForegroundColor Yellow
                            Write-Host "    ID: $($sub.Id)" -ForegroundColor DarkGray
                            Write-Host "    Tenant: $($sub.TenantId)" -ForegroundColor DarkGray
                            Write-Host ""
                        }

                        do {
                            $selection = Read-Host "Selecione a subscription (1-$($subscriptions.Count))"
                            $index = [int]$selection - 1
                            $validSelection = $index -ge 0 -and $index -lt $subscriptions.Count
                            if (-not $validSelection) {
                                Write-Host "Seleção inválida!" -ForegroundColor Red
                            }
                        } while (-not $validSelection)

                        $selectedSub = $subscriptions[$index]
                        Set-AzContext -SubscriptionId $selectedSub.Id -TenantId $selectedSub.TenantId | Out-Null

                        $currentContext = Get-AzContext
                        Write-Host "`n✓ Subscription alterada para: $($selectedSub.Name)" -ForegroundColor Green
                    }
                    else {
                        Write-Host "Nenhuma subscription encontrada. Usando subscription atual." -ForegroundColor Yellow
                    }
                }

                return @{
                    TenantId = $currentContext.Tenant.Id
                    SubscriptionId = $currentContext.Subscription.Id
                    Account = $currentContext.Account.Id
                    AlreadyConnected = $true
                }
            }
        }
        default {
            Write-Host "`nOpção inválida! Por favor, execute o script novamente." -ForegroundColor Red
            throw "Opção inválida selecionada"
        }
    }
}

# Função para conectar ao Azure
function Connect-AzureAccount {
    param(
        [string]$TenantId,
        [string]$SubscriptionId,
        [string]$Account,
        [bool]$AlreadyConnected = $false
    )

    Write-Host "`nVerificando conexão ao Azure..." -ForegroundColor Cyan
    Write-Host "Tenant ID: $TenantId" -ForegroundColor Gray
    Write-Host "Subscription ID: $SubscriptionId" -ForegroundColor Gray
    Write-Host "Account: $Account" -ForegroundColor Gray

    try {
        # Verificar se já está conectado
        $currentContext = Get-AzContext -ErrorAction SilentlyContinue

        if ($currentContext -and
            $currentContext.Tenant.Id -eq $TenantId -and
            $currentContext.Subscription.Id -eq $SubscriptionId) {
            Write-Host "✓ Já conectado com as credenciais corretas" -ForegroundColor Green
            Write-Host "  - Conta: $($currentContext.Account.Id)" -ForegroundColor Gray
            Write-Host "  - Subscription: $($currentContext.Subscription.Name)" -ForegroundColor Gray
            Write-Host "  - Tenant: $($currentContext.Tenant.Id)" -ForegroundColor Gray
            return $currentContext
        }

        # Se já conectado pela opção 2 mas precisa trocar subscription
        if ($AlreadyConnected -and $currentContext) {
            Write-Host "Ajustando contexto para subscription correta..." -ForegroundColor Gray
            try {
                $context = Set-AzContext -SubscriptionId $SubscriptionId -TenantId $TenantId -ErrorAction Stop
                Write-Host "✓ Contexto ajustado com sucesso" -ForegroundColor Green
                Write-Host "  - Conta: $($context.Account.Id)" -ForegroundColor Gray
                Write-Host "  - Subscription: $($context.Subscription.Name)" -ForegroundColor Gray
                Write-Host "  - Tenant: $($context.Tenant.Id)" -ForegroundColor Gray
                return $context
            }
            catch {
                Write-Host "⚠ Não foi possível ajustar o contexto. Tentando nova autenticação..." -ForegroundColor Yellow
            }
        }

        # Limpar contextos antigos apenas se não estiver usando opção 2
        if (-not $AlreadyConnected) {
            Write-Host "Limpando sessões antigas..." -ForegroundColor Gray
            Disconnect-AzAccount -ErrorAction SilentlyContinue | Out-Null
            Clear-AzContext -Force -ErrorAction SilentlyContinue | Out-Null
        }

        # Conectar ao Azure
        Write-Host "Autenticando (uma janela de login pode abrir)..." -ForegroundColor Yellow
        Write-Host "  Tenant: $TenantId" -ForegroundColor DarkGray

        try {
            $connectResult = Connect-AzAccount -TenantId $TenantId -ErrorAction Stop
        }
        catch {
            # Se falhar com tenant específico, tentar sem tenant (permite MFA)
            Write-Host "  Tentativa com tenant específico falhou, tentando método alternativo..." -ForegroundColor Yellow
            $connectResult = Connect-AzAccount -ErrorAction Stop
        }

        if ($connectResult) {
            Write-Host "✓ Autenticação realizada com sucesso" -ForegroundColor Green

            # Definir subscription correta
            Write-Host "Selecionando subscription..." -ForegroundColor Gray
            $context = Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop

            Write-Host "✓ Conectado ao Azure:" -ForegroundColor Green
            Write-Host "  - Conta: $($context.Account.Id)" -ForegroundColor Gray
            Write-Host "  - Subscription: $($context.Subscription.Name)" -ForegroundColor Gray
            Write-Host "  - Tenant: $($context.Tenant.Id)" -ForegroundColor Gray

            return $context
        }
    }
    catch {
        Write-Host ""
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
        Write-Host "  ERRO DE AUTENTICAÇÃO" -ForegroundColor Red
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
        Write-Host ""
        Write-Host "Erro: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Possíveis causas:" -ForegroundColor Yellow
        Write-Host "  1. O Tenant ID não existe ou você não tem acesso" -ForegroundColor White
        Write-Host "  2. A conta não pertence a este tenant" -ForegroundColor White
        Write-Host "  3. MFA (autenticação multifator) bloqueou a conexão" -ForegroundColor White
        Write-Host ""
        Write-Host "Soluções:" -ForegroundColor Yellow
        Write-Host "  1. Execute o script novamente e use a opção [2]" -ForegroundColor Cyan
        Write-Host "     (Fazer login e selecionar da lista)" -ForegroundColor Cyan
        Write-Host "  2. Verifique se o Tenant ID está correto" -ForegroundColor Cyan
        Write-Host "  3. Entre no Portal do Azure para confirmar acesso" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
        throw
    }
}

# Função para obter custos por Resource Group
function Get-AzureCostByResourceGroup {
    param(
        [string]$SubscriptionId,
        [DateTime]$StartDate,
        [DateTime]$EndDate
    )

    Write-Host "`n[1/2] Obtendo custos por Resource Group..." -ForegroundColor Cyan
    Write-Host "Período: $($StartDate.ToString('yyyy-MM-dd')) até $($EndDate.ToString('yyyy-MM-dd'))" -ForegroundColor Cyan

    try {
        $scope = "/subscriptions/$SubscriptionId"

        # Preparar parâmetros
        $startDateStr = $StartDate.ToString("yyyy-MM-dd")
        $endDateStr = $EndDate.ToString("yyyy-MM-dd")

        # Criar query
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

        # Fazer requisição
        $apiVersion = "2023-03-01"
        $path = "$scope/providers/Microsoft.CostManagement/query?api-version=$apiVersion"

        $response = Invoke-AzRestMethod -Path $path -Method POST -Payload $body -ErrorAction Stop

        if ($response.StatusCode -eq 200) {
            Write-Host "✓ Requisição bem-sucedida!" -ForegroundColor Green
            $responseContent = $response.Content | ConvertFrom-Json
        }
        else {
            throw "Status code: $($response.StatusCode) - $($response.Content)"
        }

        # Processar resultados
        $costData = @()
        $detectedCurrency = $null

        if ($responseContent.properties.rows.Count -gt 0) {
            # Detectar moeda
            if ($responseContent.properties.rows[0].Count -gt 2) {
                $detectedCurrency = $responseContent.properties.rows[0][2]
            }
            if (-not $detectedCurrency) {
                $detectedCurrency = "USD"
            }

            Write-Host "💰 Moeda detectada: $detectedCurrency" -ForegroundColor Cyan

            foreach ($row in $responseContent.properties.rows) {
                $costData += [PSCustomObject]@{
                    'Resource Group' = if ($row[1]) { $row[1] } else { "Não Alocado" }
                    'Custo' = [math]::Round($row[0], 2)
                    'Moeda' = $row[2]
                }
            }

            # Ordenar
            $costData = $costData | Sort-Object 'Custo' -Descending

            # Total
            $totalCost = ($costData | Measure-Object 'Custo' -Sum).Sum
            $costData += [PSCustomObject]@{
                'Resource Group' = "TOTAL"
                'Custo' = $totalCost
                'Moeda' = $detectedCurrency
            }

            Write-Host "✓ $($costData.Count - 1) Resource Groups encontrados" -ForegroundColor Green
            Write-Host "💵 Total: $('{0:N2}' -f $totalCost) $detectedCurrency" -ForegroundColor Cyan
        }
        else {
            Write-Warning "Nenhum dado encontrado"
        }

        return @{
            Data = $costData
            Currency = $detectedCurrency
        }
    }
    catch {
        Write-Error "Erro ao obter custos por Resource Group: $_"
        throw
    }
}

# Função para obter custos por Recurso
function Get-AzureCostByResource {
    param(
        [string]$SubscriptionId,
        [DateTime]$StartDate,
        [DateTime]$EndDate
    )

    Write-Host "`n[2/2] Obtendo custos por Recurso individual..." -ForegroundColor Cyan
    Write-Host "Período: $($StartDate.ToString('yyyy-MM-dd')) até $($EndDate.ToString('yyyy-MM-dd'))" -ForegroundColor Cyan

    try {
        $scope = "/subscriptions/$SubscriptionId"

        # Preparar parâmetros
        $startDateStr = $StartDate.ToString("yyyy-MM-dd")
        $endDateStr = $EndDate.ToString("yyyy-MM-dd")

        # Criar query agrupado por ResourceId
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

        # Fazer requisição
        $apiVersion = "2023-03-01"
        $path = "$scope/providers/Microsoft.CostManagement/query?api-version=$apiVersion"

        Write-Host "Consultando API (isso pode demorar um pouco)..." -ForegroundColor Gray
        $response = Invoke-AzRestMethod -Path $path -Method POST -Payload $body -ErrorAction Stop

        if ($response.StatusCode -eq 200) {
            Write-Host "✓ Requisição bem-sucedida!" -ForegroundColor Green
            $responseContent = $response.Content | ConvertFrom-Json
        }
        else {
            throw "Status code: $($response.StatusCode) - $($response.Content)"
        }

        # Processar resultados
        $resourceData = @()
        $detectedCurrency = $null

        if ($responseContent.properties.rows.Count -gt 0) {
            # Detectar moeda
            if ($responseContent.properties.rows[0].Count -gt 4) {
                $detectedCurrency = $responseContent.properties.rows[0][5]
            }
            if (-not $detectedCurrency) {
                $detectedCurrency = "USD"
            }

            Write-Host "Processando $($responseContent.properties.rows.Count) recursos..." -ForegroundColor Gray

            foreach ($row in $responseContent.properties.rows) {
                $resourceId = $row[1]
                $resourceName = if ($resourceId) {
                    $parts = $resourceId -split '/'
                    $parts[-1]
                } else {
                    "Desconhecido"
                }

                $resourceData += [PSCustomObject]@{
                    'Nome do Recurso' = $resourceName
                    'Resource Group' = if ($row[4]) { $row[4] } else { "Não Alocado" }
                    'Tipo' = if ($row[2]) { $row[2] } else { "N/A" }
                    'Location' = if ($row[3]) { $row[3] } else { "N/A" }
                    'Custo' = [math]::Round($row[0], 2)
                    'Moeda' = if ($row[5]) { $row[5] } else { $detectedCurrency }
                    'Resource ID' = $resourceId
                }
            }

            # Ordenar
            $resourceData = $resourceData | Sort-Object 'Custo' -Descending

            # Total
            $totalCost = ($resourceData | Measure-Object 'Custo' -Sum).Sum
            $resourceData += [PSCustomObject]@{
                'Nome do Recurso' = "TOTAL"
                'Resource Group' = ""
                'Tipo' = ""
                'Location' = ""
                'Custo' = $totalCost
                'Moeda' = $detectedCurrency
                'Resource ID' = ""
            }

            Write-Host "✓ $($resourceData.Count - 1) Recursos encontrados" -ForegroundColor Green
            Write-Host "💵 Total: $('{0:N2}' -f $totalCost) $detectedCurrency" -ForegroundColor Cyan
        }
        else {
            Write-Warning "Nenhum recurso encontrado"
        }

        return @{
            Data = $resourceData
            Currency = $detectedCurrency
        }
    }
    catch {
        Write-Error "Erro ao obter custos por Recurso: $_"
        throw
    }
}

# Função para exportar para Excel
function Export-ToExcel {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$ResourceGroupData,

        [Parameter(Mandatory = $true)]
        [object[]]$ResourceData,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [DateTime]$StartDate,
        [DateTime]$EndDate,

        [string]$Currency = "USD"
    )

    Write-Host "`nExportando para Excel..." -ForegroundColor Cyan

    # Determinar formato de moeda
    $currencyFormat = switch ($Currency) {
        "BRL" { "R$ #,##0.00" }
        "USD" { "US$ #,##0.00" }
        "EUR" { "€ #,##0.00" }
        default { "#,##0.00" }
    }

    try {
        # Remover arquivo existente
        if (Test-Path $OutputPath) {
            Remove-Item $OutputPath -Force
        }

        # ABA 1: Resource Groups
        Write-Host "  Criando aba 'Custos por Resource Group'..." -ForegroundColor Gray

        $excelParams1 = @{
            Path = $OutputPath
            AutoSize = $true
            AutoFilter = $true
            BoldTopRow = $true
            FreezeTopRow = $true
            WorksheetName = "Custos por Resource Group"
        }

        $ResourceGroupData | Export-Excel @excelParams1 -PassThru | ForEach-Object {
            $ws = $_.Workbook.Worksheets["Custos por Resource Group"]

            $ws.InsertRow(1, 3)
            $ws.Cells["A1"].Value = "Relatório de Custos do Azure - Por Resource Group"
            $ws.Cells["A1"].Style.Font.Size = 16
            $ws.Cells["A1"].Style.Font.Bold = $true

            $ws.Cells["A2"].Value = "Período: $($StartDate.ToString('dd/MM/yyyy')) a $($EndDate.ToString('dd/MM/yyyy')) | Moeda: $Currency"
            $ws.Cells["A2"].Style.Font.Size = 11
            $ws.Cells["A2"].Style.Font.Bold = $true

            $ws.Cells["A3"].Value = "Gerado em: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
            $ws.Cells["A3"].Style.Font.Size = 10
            $ws.Cells["A3"].Style.Font.Italic = $true

            $lastRow = $ws.Dimension.End.Row
            $costColumn = $ws.Cells["B5:B$lastRow"]
            $costColumn.Style.Numberformat.Format = $currencyFormat

            $totalRow = $ws.Cells["A$($lastRow):C$($lastRow)"]
            $totalRow.Style.Font.Bold = $true
            $totalRow.Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
            $totalRow.Style.Fill.BackgroundColor.SetColor([System.Drawing.Color]::LightGray)

            $dataRange = $ws.Cells["A4:C$lastRow"]
            $dataRange.Style.Border.Top.Style = [OfficeOpenXml.Style.ExcelBorderStyle]::Thin
            $dataRange.Style.Border.Left.Style = [OfficeOpenXml.Style.ExcelBorderStyle]::Thin
            $dataRange.Style.Border.Right.Style = [OfficeOpenXml.Style.ExcelBorderStyle]::Thin
            $dataRange.Style.Border.Bottom.Style = [OfficeOpenXml.Style.ExcelBorderStyle]::Thin

            $_.Save()
        }

        Write-Host "  ✓ Aba 1 criada" -ForegroundColor Green

        # ABA 2: Resources
        Write-Host "  Criando aba 'Custos por Resources'..." -ForegroundColor Gray

        $excelParams2 = @{
            Path = $OutputPath
            AutoSize = $true
            AutoFilter = $true
            BoldTopRow = $true
            FreezeTopRow = $true
            WorksheetName = "Custos por Resources"
        }

        $ResourceData | Export-Excel @excelParams2 -PassThru | ForEach-Object {
            $ws = $_.Workbook.Worksheets["Custos por Resources"]

            $ws.InsertRow(1, 3)
            $ws.Cells["A1"].Value = "Relatório de Custos do Azure - Por Recurso Individual"
            $ws.Cells["A1"].Style.Font.Size = 16
            $ws.Cells["A1"].Style.Font.Bold = $true

            $ws.Cells["A2"].Value = "Período: $($StartDate.ToString('dd/MM/yyyy')) a $($EndDate.ToString('dd/MM/yyyy')) | Moeda: $Currency"
            $ws.Cells["A2"].Style.Font.Size = 11
            $ws.Cells["A2"].Style.Font.Bold = $true

            $ws.Cells["A3"].Value = "Gerado em: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
            $ws.Cells["A3"].Style.Font.Size = 10
            $ws.Cells["A3"].Style.Font.Italic = $true

            $lastRow = $ws.Dimension.End.Row
            $costColumn = $ws.Cells["E5:E$lastRow"]
            $costColumn.Style.Numberformat.Format = $currencyFormat

            $totalRow = $ws.Cells["A$($lastRow):G$($lastRow)"]
            $totalRow.Style.Font.Bold = $true
            $totalRow.Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
            $totalRow.Style.Fill.BackgroundColor.SetColor([System.Drawing.Color]::LightGray)

            $dataRange = $ws.Cells["A4:G$lastRow"]
            $dataRange.Style.Border.Top.Style = [OfficeOpenXml.Style.ExcelBorderStyle]::Thin
            $dataRange.Style.Border.Left.Style = [OfficeOpenXml.Style.ExcelBorderStyle]::Thin
            $dataRange.Style.Border.Right.Style = [OfficeOpenXml.Style.ExcelBorderStyle]::Thin
            $dataRange.Style.Border.Bottom.Style = [OfficeOpenXml.Style.ExcelBorderStyle]::Thin

            $ws.Column(7).Width = 80

            $_.Save()
        }

        Write-Host "  ✓ Aba 2 criada" -ForegroundColor Green
        Write-Host "`n✓ Arquivo Excel criado: $OutputPath" -ForegroundColor Green

        $openFile = Read-Host "`nDeseja abrir o arquivo? (S/N)"
        if ($openFile -eq 'S' -or $openFile -eq 's') {
            Start-Process $OutputPath
        }
    }
    catch {
        Write-Error "Erro ao exportar para Excel: $_"
        throw
    }
}

# Função para solicitar período
function Get-DatePeriod {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  Seleção de Período" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    Write-Host "`nEscolha o período:" -ForegroundColor White
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
            $startDate = Get-Date -Day 1
            $endDate = $today
            Write-Host "✓ Mês atual" -ForegroundColor Green
        }
        "2" {
            $firstDayLastMonth = (Get-Date -Day 1).AddMonths(-1)
            $startDate = $firstDayLastMonth
            $endDate = (Get-Date -Day 1).AddDays(-1)
            Write-Host "✓ Mês anterior" -ForegroundColor Green
        }
        "3" {
            $endDate = $today
            $startDate = $today.AddDays(-30)
            Write-Host "✓ Últimos 30 dias" -ForegroundColor Green
        }
        "4" {
            $endDate = $today
            $startDate = $today.AddDays(-90)
            Write-Host "✓ Últimos 90 dias" -ForegroundColor Green
        }
        "5" {
            Write-Host "`nPeríodo personalizado:" -ForegroundColor White
            do {
                $startDateInput = Read-Host "Data inicial (YYYY-MM-DD)"
                try {
                    $startDate = [DateTime]::Parse($startDateInput)
                    $validStart = $true
                }
                catch {
                    Write-Host "Data inválida!" -ForegroundColor Red
                    $validStart = $false
                }
            } while (-not $validStart)

            do {
                $endDateInput = Read-Host "Data final (YYYY-MM-DD)"
                try {
                    $endDate = [DateTime]::Parse($endDateInput)
                    if ($endDate -lt $startDate) {
                        Write-Host "Data final deve ser maior que inicial!" -ForegroundColor Red
                        $validEnd = $false
                    }
                    else {
                        $validEnd = $true
                    }
                }
                catch {
                    Write-Host "Data inválida!" -ForegroundColor Red
                    $validEnd = $false
                }
            } while (-not $validEnd)

            Write-Host "✓ Período personalizado" -ForegroundColor Green
        }
        default {
            Write-Host "Opção inválida! Usando mês atual como padrão." -ForegroundColor Yellow
            $startDate = Get-Date -Day 1
            $endDate = $today
        }
    }

    Write-Host "`nPeríodo: $($startDate.ToString('dd/MM/yyyy')) até $($endDate.ToString('dd/MM/yyyy'))" -ForegroundColor Cyan

    return @{
        StartDate = $startDate
        EndDate = $endDate
    }
}

# ============================
# SCRIPT PRINCIPAL
# ============================

try {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Exportação Interativa de Custos Azure" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    # 1. Obter credenciais
    $alreadyConnected = $false
    if (-not $TenantId -or -not $SubscriptionId -or -not $Account) {
        $credentials = Get-AzureCredentials
        $TenantId = $credentials.TenantId
        $SubscriptionId = $credentials.SubscriptionId
        $Account = $credentials.Account
        $alreadyConnected = if ($credentials.AlreadyConnected) { $true } else { $false }
    }
    else {
        Write-Host "`nUsando credenciais fornecidas por parâmetro" -ForegroundColor Cyan
    }

    # 2. Obter período
    if (-not $StartDate -or -not $EndDate) {
        $dateRange = Get-DatePeriod
        $StartDate = $dateRange.StartDate
        $EndDate = $dateRange.EndDate
    }

    # 3. Definir nome do arquivo se não fornecido
    if (-not $OutputPath) {
        $OutputPath = ".\AzureCosts_$($StartDate.ToString('yyyyMMdd'))_$($EndDate.ToString('yyyyMMdd')).xlsx"
    }

    # 4. Instalar módulos
    Install-RequiredModules

    # 5. Conectar ao Azure
    $azContext = Connect-AzureAccount -TenantId $TenantId -SubscriptionId $SubscriptionId -Account $Account -AlreadyConnected $alreadyConnected

    if (-not $azContext) {
        throw "Falha ao conectar ao Azure."
    }

    # 6. Obter custos por Resource Group
    $rgResult = Get-AzureCostByResourceGroup -SubscriptionId $SubscriptionId -StartDate $StartDate -EndDate $EndDate

    # 7. Obter custos por Recurso
    $resourceResult = Get-AzureCostByResource -SubscriptionId $SubscriptionId -StartDate $StartDate -EndDate $EndDate

    # 8. Exportar para Excel
    if ($rgResult.Data -and $resourceResult.Data) {
        Export-ToExcel -ResourceGroupData $rgResult.Data -ResourceData $resourceResult.Data -OutputPath $OutputPath -StartDate $StartDate -EndDate $EndDate -Currency $rgResult.Currency

        Write-Host "`n========================================" -ForegroundColor Green
        Write-Host "  ✓ Processo concluído com sucesso!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "`nArquivo: $OutputPath" -ForegroundColor White
        Write-Host "Abas:" -ForegroundColor Cyan
        Write-Host "  1. Custos por Resource Group" -ForegroundColor White
        Write-Host "  2. Custos por Resources (detalhado)" -ForegroundColor White
    }
    else {
        Write-Warning "Nenhum dado para exportar."
    }
}
catch {
    Write-Host "`n========================================" -ForegroundColor Red
    Write-Host "  Erro durante a execução" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Error $_
    exit 1
}
