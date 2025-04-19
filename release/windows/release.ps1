param($version,$binary)

If ( ! ( Test-Path Env:wix ) ) {
    Write-Error 'Could not find WiX binaries %wix%'
    exit 1
}

$msi="${binary}_${version}_amd64.msi"
$wixVersion="0.0.0"
$wixVersionMatch=[regex]::Match($version, '^([0-9]+\.[0-9]+\.[0-9]+)')
If ( $wixVersionMatch.success ) {
    $wixVersion=$wixVersionMatch.captures.groups[1].value
} Else {
    Write-Error "Invalid version $version"
    exit 1
}

.\build.ps1 `
  -version $version `
  -binary $binary

$appname=(Get-Culture).TextInfo.ToTitleCase($binary)

& "${env:wix}bin\candle.exe" `
  -nologo `
  -arch x64 `
  "-dAppVersion=$version" `
  "-dWixVersion=$wixVersion" `
  "-dAppName=$appname" `
  release.wxs
If ( $LastExitCode -ne 0 ) {
    exit $LastExitCode
}
& "${env:wix}bin\light.exe" `
  -nologo `
  -dcl:high `
  -ext WixUIExtension `
  -ext WixUtilExtension `
  release.wixobj `
  -o $msi
If ( $LastExitCode -ne 0 ) {
    exit $LastExitCode
}

echo file=$msi >> $env:GITHUB_OUTPUT