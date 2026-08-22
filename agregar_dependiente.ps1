# Agregar un dependiente al usuario id=1 (Supabase/PostgREST)
# Uso:
#   powershell -ExecutionPolicy Bypass -File .\agregar_dependiente.ps1 -Nombre "Pedro" -Relacion "Hijo" -Ocupacion "Estudiante" -FechaNacimiento "2010-05-12" -PesoEconomico 2
# Campos opcionales pueden omitirse.

param(
    [Parameter(Mandatory = $true)]
    [string]$Nombre,
    [string]$Relacion = "",
    [string]$Ocupacion = "",
    [string]$FechaNacimiento = "",
    [int]$PesoEconomico = 1,
    [int]$UserId = 1
)

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path $projectDir ".env"

$url = ""
$key = ""

Get-Content $envFile | ForEach-Object {
    if ($_ -match "^\s*([A-Z_]+)=(.*)$") {
        $name = $matches[1]
        $val = $matches[2].Trim().Trim('"', "'")
        if ($name -eq "SUPABASE_URL") { $url = $val }
        if ($name -eq "SUPABASE_ANON_KEY") { $key = $val }
    }
}

if (-not $url -or -not $key) {
    Write-Error "No se encontraron SUPABASE_URL / SUPABASE_ANON_KEY en .env"
    exit 1
}

$data = [ordered]@{
    id_usuario      = $UserId
    nombre          = $Nombre
    peso_economico  = $PesoEconomico
}
if ($Relacion)          { $data.relacion = $Relacion }
if ($Ocupacion)         { $data.ocupacion = $Ocupacion }
if ($FechaNacimiento)   { $data.fecha_nacimiento = $FechaNacimiento }

$body = $data | ConvertTo-Json

$h = @{
    apikey = $key
    Authorization = "Bearer $key"
    "Content-Type" = "application/json"
    Prefer = "return=representation"
}

Write-Host "Insertando dependiente para id_usuario=$UserId"
Write-Host "Body: $body"

try {
    $r = Invoke-WebRequest -Uri "$url/rest/v1/dependientes" -Method POST -Headers $h -Body $body -UseBasicParsing
    Write-Host "[$($r.StatusCode)] Dependiente creado:"
    Write-Host $r.Content
} catch {
    $resp = $_.Exception.Response
    if ($resp) {
        $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
        $msg = $sr.ReadToEnd()
        Write-Host "[$([int]$resp.StatusCode)] ERROR: $msg"
        if ($msg -match "42501") {
            Write-Host ""
            Write-Host "Falta la politica de insercion para dependientes. Corre esto en Supabase SQL Editor:"
            Write-Host 'CREATE POLICY "anon_insert" ON public.dependientes FOR INSERT WITH CHECK (true);'
        }
    } else {
        Write-Host "ERROR: $($_.Exception.Message)"
    }
}