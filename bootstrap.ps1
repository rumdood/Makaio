$Files  = @( Get-ChildItem -Path (Join-Path $PSScriptRoot src) -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue )

foreach($import in $Files)
{
    try
    {
        Write-Host "Importing $($import.FullName)" -ForegroundColor DarkGray
        Import-Module -Name $import.FullName -Force -ErrorAction Stop
    }
    catch
    {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

Write-Host "Executing Build-Module on Makaio" -ForegroundColor DarkGray
Build-Module -SourcePath src -OutputPath bld -SingleFile -MetaDataPath ((Get-Item -Path .\makaio_meta.ps1).FullName) -DisplayConfiguration
