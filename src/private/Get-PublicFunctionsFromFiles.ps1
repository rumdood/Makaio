function Get-PublicFunctionsFromFiles {
    [CmdletBinding()]
    Param(
        [System.IO.FileInfo[]] $Files
    )

    return $Files | 
    Where-Object { !$_.Name.StartsWith("_") -and (Get-FolderIsInPath $_ "Public") } | 
    ForEach-Object { [System.IO.Path]::GetFileNameWithoutExtension($_.Name) } | 
    Sort-Object -Unique
}
