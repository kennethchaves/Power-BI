# Prefijo para los nombres de los informes a filtrar
$reportNamePrefix = "NOMBRE AQUI"

# Descomenta la siguiente línea si necesitas instalar el módulo de Power BI
# Install-Module -Name MicrosoftPowerBIMgmt

# Iniciar sesión en la cuenta de servicio de Power BI
Login-PowerBIServiceAccount

# Obtener el token de acceso de Power BI
$token = Get-PowerBIAccessToken -AsString

# Configurar el encabezado de autorización para las solicitudes API
$auth_header = @{
    'Content-Type' = 'application/json'
    'Authorization' = $token
}

# Intentar obtener la lista de informes de Power BI
try {
    $reports = Invoke-RestMethod -Uri "https://api.powerbi.com/v1.0/myorg/admin/reports" -Headers $auth_header -Method GET
} catch {
    Write-Error "Error al obtener los informes de Power BI: $_"
    exit
}

# Verificar si la respuesta contiene informes
if ($null -eq $reports.value) {
    Write-Error "No se encontraron informes en la respuesta de la API."
    exit
}

# Filtrar los informes que comienzan con el prefijo especificado
$filteredReports = $reports.value | Where-Object { $_.name.StartsWith($reportNamePrefix) }

# Inicializar un array para almacenar los datos de los informes
$dataArray = @()

# Recorrer cada informe filtrado usando foreach
foreach ($report in $filteredReports) {
    Write-Host "Procesando informe: $($report.name)"
    try {
        # Agregar detalles del informe al array
        $dataArray += [pscustomobject]@{
            datasetId = $report.datasetId
            reportId = $report.id
            reportName = $report.name
            webUrl = $report.webUrl
            workspaceId = $report.workspaceId
        }
    } catch {
        Write-Error "Fallo al recuperar informacion sobre el conjunto de datos para el informe: $($report.name)"
    }
}

# Verificar si el directorio de destino existe, si no, crearlo
$exportPath = "C:\temp\archivo.csv"
$exportDir = [System.IO.Path]::GetDirectoryName($exportPath)
if (-not (Test-Path -Path $exportDir)) {
    New-Item -ItemType Directory -Path $exportDir | Out-Null
}

# Exportar los datos recopilados a un archivo CSV
$dataArray | Export-Csv -Path $exportPath -NoTypeInformation