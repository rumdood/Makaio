function Get-SubModulesFromFiles {
    Param(
        [Parameter(ParameterSetName="Files")]
        [System.IO.FileInfo[]] $Files,
        [Parameter(ParameterSetName="Path")]
        [string] $Path,
        [Parameter(ParameterSetName="FileNames")]
        [string[]] $FileNames
    )

    if ($null -ne $FileNames -and $FileNames.Count -gt 0) {
        return $FileNames | 
            Where-Object { -not [System.IO.Path]::GetFileName($_).StartsWith("_") } |
            Sort-Object -Unique
    }

    if ($Path) {
        $files = @(Get-ChildItem -Path $Path -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue) | Sort-Object -Property Name
    }

    if (!$files) {
        Write-Error "No files found to build submodules from at [$Path]"
        return
    }

    return $files |
        Where-Object { !$_.Name.StartsWith("_") } | 
        Select-Object -ExpandProperty FullName | 
        Sort-Object -Unique
}
