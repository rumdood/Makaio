function Initialize-Module {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory,Position=0)]
        [Alias("n")]
        [string] $Name,
        [string] $OutputPath,
        [Parameter(ParameterSetName="WithSubModules")]
        [switch] $WithNestedModules,
        [Parameter(ParameterSetName="SingleFile")]
        [switch] $SingleFile,
        [Alias("g")]
        [string] $Guid = (New-Guid).ToString(),
        [Alias("a")]
        [string] $Author = $env:USERNAME,
        [string] $CompanyName,
        [string] $Copyright,
        [Alias("v")]
        [string] $Version = "0.0.1",
        [Alias("p")]
        [string[]] $PublicFunctions,
        [Alias("m")]
        [string] $MetaDataPath = "makaio_meta.ps1"
    )

    $sourceFolders = @("Public", "Private", "Classes")

    if ($OutputPath -ne $Name) {
        Write-Host "Adding Name [$Name] to OutputPath [$OutputPath]..."
        $OutputPath = Join-Path $OutputPath $Name
    }

    if (-not [System.IO.Path]::IsPathFullyQualified($OutputPath)) {
        $OutputPath = Join-Path $PWD $OutputPath
    }

    if (-not (Test-Path $OutputPath)) {
        Write-Host "Creating output path [$OutputPath]..." -ForegroundColor DarkGreen
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    foreach ($folder in $sourceFolders) {
        Write-Host "Creating [$folder]..." -ForegroundColor DarkGreen
        New-Item -Path (Join-Path $OutputPath $folder) -ItemType Directory -Force | Out-Null
    }
    
    Write-Host "Building Meta File..." -ForegroundColor DarkGreen
    $metaFile = $MetaFileTemplate -replace "{NAME}", $Name -replace "{OUTPUTPATH}", $OutputPath -replace "{GUID}", $Guid -replace "{AUTHOR}", $Author -replace "{COMPANYNAME}", $CompanyName -replace "{COPYRIGHT}", $CopyRight -replace "{VERSION}", $Version -replace "{PUBLICFUNCTIONS}", ($PublicFunctions -join ",")

    $MetaDataPath = Join-Path $OutputPath $MetaDataPath
    $metaFile | Out-File -FilePath $MetaDataPath -Force
    Write-Host "DONE" -ForegroundColor Green
}