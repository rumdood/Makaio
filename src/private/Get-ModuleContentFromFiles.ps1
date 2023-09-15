function Get-ModuleContentFromFiles {
    <#
    .SYNOPSIS
        Builds a single Powershell file from the specified folder
    .DESCRIPTION
        Builds a single Powershell file from the specified folder
    .EXAMPLE
        PS> Get-ModuleContentFromFiles -Name "ServiceTitanDev" -SourcePath "src"
    #>
    Param(
        [Parameter(Mandatory)]
        [string] $Name,
        [Parameter(Mandatory)]
        [System.IO.FileInfo[]] $Files
    )

    # use the source path to get all psm1 files and then combine them into a single psm1 file in the folder Modules/$Name/$Name.psm1
    $files = @(Get-ChildItem -Path $SourcePath -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue) | Sort-Object -Property Name

    $content = ""

    foreach ($file in $files) {
        Write-Host "    Processing $($file.Name)" -ForegroundColor DarkGray
        try {
            $content += Get-Content $file.FullName -Raw
            $content += [System.Environment]::NewLine
        }
        catch {
            Write-Error -Message "Failed to load $($file.FullName): $_"
        }
    }

    return $content
}
