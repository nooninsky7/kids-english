$port = 8088
$htmlPath = Join-Path $PSScriptRoot "index.html"

# Wi-Fi IP 자동 감지
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    $_.InterfaceAlias -like "*Wi-Fi*" -or $_.InterfaceAlias -like "*무선*" -or $_.InterfaceAlias -like "*Ethernet*" 
} | Select-Object -ExpandProperty IPAddress -First 1)

if (-not $ip) { $ip = "10.76.231.75" }

$tabletUrl = "http://${ip}:${port}/"
$localUrl = "http://localhost:${port}/"

$endpoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, $port)
$listener = New-Object System.Net.Sockets.TcpListener($endpoint)

try {
    $listener.Start()
    Clear-Host
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host "  🎉 Pattern & Voca 태블릿 서버가 시작되었습니다!                 " -ForegroundColor Green
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  📱 [아이 태블릿에서 접속할 주소]" -ForegroundColor Yellow
    Write-Host "  👉 $tabletUrl" -ForegroundColor Yellow -BackgroundColor DarkBlue
    Write-Host ""
    Write-Host "  💻 [현재 PC 브라우저 주소]" -ForegroundColor Gray
    Write-Host "  👉 $localUrl" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  ※ 아이 태블릿이 이 PC와 '같은 Wi-Fi'에 연결되어 있어야 합니다." -ForegroundColor White
    Write-Host "  종료하려면 이 창을 닫거나 Ctrl + C 를 누르세요." -ForegroundColor DarkGray
    Write-Host "==================================================================" -ForegroundColor Cyan

    Start-Process $localUrl

    while ($true) {
        $client = $listener.AcceptTcpClient()
        [System.Threading.ThreadPool]::QueueUserWorkItem({
            param($c)
            try {
                $stream = $c.GetStream()
                $reader = New-Object System.IO.StreamReader($stream)
                $reqLine = $reader.ReadLine()
                while ($l = $reader.ReadLine()) {
                    if ([string]::IsNullOrWhiteSpace($l)) { break }
                }

                $path = Join-Path $using:PSScriptRoot "index.html"
                if (Test-Path $path) {
                    $bytes = [System.IO.File]::ReadAllBytes($path)
                    $header = "HTTP/1.1 200 OK`r`n" +
                              "Content-Type: text/html; charset=utf-8`r`n" +
                              "Content-Length: " + $bytes.Length + "`r`n" +
                              "Access-Control-Allow-Origin: *`r`n" +
                              "Connection: close`r`n`r`n"
                    $hBytes = [System.Text.Encoding]::ASCII.GetBytes($header)
                    $stream.Write($hBytes, 0, $hBytes.Length)
                    $stream.Write($bytes, 0, $bytes.Length)
                }
                $stream.Flush()
            } catch {}
            finally {
                $c.Close()
            }
        }, $client) | Out-Null
    }
} finally {
    $listener.Stop()
}
