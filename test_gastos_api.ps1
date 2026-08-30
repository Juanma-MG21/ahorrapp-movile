# Test de las APIs de gastos (Supabase/PostgREST)
# Lee SUPABASE_URL y SUPABASE_ANON_KEY del archivo .env del proyecto.
# Uso:  powershell -ExecutionPolicy Bypass -File .\test_gastos_api.ps1

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path $projectDir ".env"

$url = ""
$key = ""
$userId = 1

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

$h = @{
    apikey = $key
    Authorization = "Bearer $key"
    "Content-Type" = "application/json"
    Prefer = "return=representation"
}

function Req($name, $method, $path, $body) {
    $a = @{ Uri = "$url$path"; Method = $method; Headers = $h; UseBasicParsing = $true }
    if ($body) { $a.Body = $body }
    try {
        $r = Invoke-WebRequest @a
        Write-Host "[$($r.StatusCode)] $name -> $path"
        Write-Host "      $($r.Content)"
    } catch {
        $resp = $_.Exception.Response
        if ($resp) {
            $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
            Write-Host "[$([int]$resp.StatusCode)] $name -> $path"
            Write-Host "      ERROR: $($sr.ReadToEnd())"
        } else {
            Write-Host "ERROR: $($_.Exception.Message)"
        }
    }
}

Write-Host "=== 1-3. LECTURA ==="
Req "GET categorias" GET "/rest/v1/categorias?select=*&or=(id_usuario.eq.$userId,es_global.eq.true)&limit=5" $null
Req "GET dependientes" GET "/rest/v1/dependientes?select=*&id_usuario=eq.$userId&limit=5" $null
Req "GET gastos" GET "/rest/v1/gastos?select=*,categorias(nombre),dependientes(nombre)&order=fecha_registro.desc&limit=5" $null

Write-Host "`n=== 4-8. ESCRITURA (crea, edita y borra un gasto de prueba) ==="
$fecha = Get-Date -Format "yyyy-MM-dd"

# 4. Crear movimiento
$r = Invoke-WebRequest -Uri "$url/rest/v1/movimientos" -Method POST -Headers $h -Body ('{"id_usuario":' + $userId + ',"tipo_flujo":"Salida","subtipo_modulo":"Gasto"}') -UseBasicParsing
$idMovimiento = (($r.Content | ConvertFrom-Json)[0]).id_movimiento
Write-Host "[$($r.StatusCode)] POST movimientos -> id_movimiento=$idMovimiento"

# 5. Crear salida
$r = Invoke-WebRequest -Uri "$url/rest/v1/salida" -Method POST -Headers $h -Body ('{"id_movimiento":' + $idMovimiento + '}') -UseBasicParsing
$idSalida = (($r.Content | ConvertFrom-Json)[0]).id_salida
Write-Host "[$($r.StatusCode)] POST salida -> id_salida=$idSalida"

# 6. Crear gasto
$body6 = '{"id_salida":' + $idSalida + ',"id_categoria":1,"monto":25000,"descripcion":"Gasto de prueba","fecha_registro":"' + $fecha + '"}'
$r = Invoke-WebRequest -Uri "$url/rest/v1/gastos" -Method POST -Headers $h -Body $body6 -UseBasicParsing
$idGasto = (($r.Content | ConvertFrom-Json)[0]).id_gastos
Write-Host "[$($r.StatusCode)] POST gastos -> id_gastos=$idGasto"

# 7. Editar gasto (PATCH)
$r = Invoke-WebRequest -Uri "$url/rest/v1/gastos?id_gastos=eq.$idGasto" -Method PATCH -Headers $h -Body '{"monto":27000,"descripcion":"Gasto de prueba editado"}' -UseBasicParsing
Write-Host "[$($r.StatusCode)] PATCH gastos -> id_gastos=$idGasto"

# 8. Borrar gasto (DELETE)
$r = Invoke-WebRequest -Uri "$url/rest/v1/gastos?id_gastos=eq.$idGasto" -Method DELETE -Headers $h -UseBasicParsing
Write-Host "[$($r.StatusCode)] DELETE gastos -> id_gastos=$idGasto"

Write-Host "`nNota: quedan registros huerfanos en salida($idSalida)/movimientos($idMovimiento)."
Write-Host "Para limpiarlos corre en Supabase: DELETE FROM public.salida WHERE id_salida=$idSalida; DELETE FROM public.movimientos WHERE id_movimiento=$idMovimiento;"