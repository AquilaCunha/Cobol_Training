param(
    [string]$Programa,
    [switch]$SomenteCompilar
)

$ErrorActionPreference = 'Stop'
$raiz = $PSScriptRoot

if (-not (Get-Command cobc -ErrorAction SilentlyContinue)) {
    throw 'GNUCobol (cobc) não foi encontrado no PATH. Instale-o ou ajuste a variável Path.'
}

$alvos = @(
    @{ Nome = 'etapas/01-ola-mundo'; Fontes = @('etapas/01-ola-mundo.cob'); Entrada = @() },
    @{ Nome = 'etapas/02-calculadora'; Fontes = @('etapas/02-calculadora.cob'); Entrada = @('10.50', '20.00') },
    @{ Nome = 'etapas/03-controle-fluxo'; Fontes = @('etapas/03-controle-fluxo.cob'); Entrada = @('8.0', '6.0', '4.0') },
    @{ Nome = 'etapas/04-tabelas'; Fontes = @('etapas/04-tabelas.cob'); Entrada = @('7.0', '8.0', '5.0', '9.0', '6.0') },
    @{ Nome = 'etapas/05-arquivo-sequencial'; Fontes = @('etapas/05-arquivo-sequencial.cob'); Entrada = @('Ana', '8.5', 'FIM') },
    @{ Nome = 'etapas/06-principal'; Fontes = @('etapas/06-principal.cob', 'etapas/06-calcular-desconto.cob'); Entrada = @('100.00', '10.00') },
    @{ Nome = 'etapas/07-ordenacao'; Fontes = @('etapas/07-ordenacao.cob'); Entrada = @() },
    @{ Nome = 'etapas/08-cadastro-produtos'; Fontes = @('etapas/08-cadastro-produtos.cob'); Entrada = @('1', '10', 'Caneta', '3.50', '2', '3') },
    @{ Nome = 'financeiro/01-consulta-saldo'; Fontes = @('financeiro/01-consulta-saldo.cob'); Entrada = @('1000.00', '500.00', '300.00') },
    @{ Nome = 'financeiro/02-lancamento-financeiro'; Fontes = @('financeiro/02-lancamento-financeiro.cob'); Entrada = @('D', '150.00') },
    @{ Nome = 'financeiro/03-extrato-sequencial'; Fontes = @('financeiro/03-extrato-sequencial.cob'); Entrada = @('01/01/2026', 'Venda', 'C', '250.00', 'FIM') },
    @{ Nome = 'financeiro/04-contas-a-pagar'; Fontes = @('financeiro/04-contas-a-pagar.cob'); Entrada = @('Fornecedor A', '10/01/2026', '500.00', 'FIM') },
    @{ Nome = 'financeiro/05-simulador-juros'; Fontes = @('financeiro/05-simulador-juros.cob', 'financeiro/05-calcular-juros.cob'); Entrada = @('1000.00', '1.500', '12') },
    @{ Nome = 'financeiro/06-fluxo-de-caixa'; Fontes = @('financeiro/06-fluxo-de-caixa.cob'); Entrada = @('Venda', 'E', '500.00', 'Aluguel', 'S', '200.00', 'Servico', 'E', '300.00', 'Energia', 'S', '80.00', 'Frete', 'S', '50.00') },
    @{ Nome = 'portfolio/01-ranking-vendas'; Fontes = @('portfolio/01-ranking-vendas.cob'); Entrada = @() },
    @{ Nome = 'portfolio/02-conciliacao-bancaria'; Fontes = @('portfolio/02-conciliacao-bancaria.cob'); Entrada = @() },
    @{ Nome = 'portfolio/03-simulador-parcelas'; Fontes = @('portfolio/03-simulador-parcelas.cob'); Entrada = @('1200.00', '3') }
)

if ($Programa) {
    $alvos = @($alvos | Where-Object { $_.Nome -eq $Programa })
    if ($alvos.Count -eq 0) { throw "Programa não encontrado: $Programa" }
}

New-Item -ItemType Directory -Force -Path (Join-Path $raiz 'bin') | Out-Null
$resultados = @()

foreach ($alvo in $alvos) {
    $nomeExe = $alvo.Nome.Replace('/', '-')
    $executavel = Join-Path $raiz "bin/$nomeExe.exe"
    $fontes = $alvo.Fontes | ForEach-Object { Join-Path $raiz $_ }

    & cobc -x -free -o $executavel @fontes
    $compilou = $LASTEXITCODE -eq 0
    $executou = $false

    if ($compilou -and -not $SomenteCompilar) {
        $sandbox = Join-Path ([System.IO.Path]::GetTempPath()) ("cobol-teste-" + [guid]::NewGuid())
        New-Item -ItemType Directory -Force -Path "$sandbox/dados", "$sandbox/financeiro/dados", "$sandbox/portfolio/dados" | Out-Null
        try {
            Push-Location $sandbox
            if ($alvo.Entrada.Count -gt 0) {
                $alvo.Entrada | & $executavel 2>&1 | Out-Null
            }
            else {
                & $executavel 2>&1 | Out-Null
            }
            $executou = $LASTEXITCODE -eq 0
        }
        finally {
            Pop-Location
            Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    $resultados += [PSCustomObject]@{
        Programa = $alvo.Nome
        Compilacao = if ($compilou) { 'OK' } else { 'FALHOU' }
        Execucao = if ($SomenteCompilar) { 'NA' } elseif ($executou) { 'OK' } else { 'FALHOU' }
    }
}

Write-Host "`nRELATORIO GNUCOBOL"
$resultados | Format-Table -AutoSize
$falhas = $resultados | Where-Object { $_.Compilacao -eq 'FALHOU' -or $_.Execucao -eq 'FALHOU' }
if ($falhas) { exit 1 }
Write-Host ("Sucesso: {0} programa(s) compilado(s) e executado(s)." -f $resultados.Count)
