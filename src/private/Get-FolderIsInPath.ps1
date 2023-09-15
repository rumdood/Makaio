function Get-FolderIsInPath {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName="File", Position=0)]
        [System.IO.FileInfo] $File,
        [Parameter(ParameterSetName="Directory", Position=0)]
        [System.IO.DirectoryInfo] $Directory,
        [Parameter(ParameterSetName="Path", Position=0)]
        [string] $Path,
        [Parameter(Mandatory, Position=1)]
        [string] $FolderName
    )

    if ($PSCmdlet.ParameterSetName -eq "Path") {
        $item = Get-Item -Path $Path

        if ($item -is [System.IO.FileInfo]) {
            return Get-FolderIsInPath -Directory $item.Directory -FolderName $FolderName
        }

        if ($item -is [System.IO.DirectoryInfo]) {
            return Get-FolderIsInPath -Directory $item -FolderName $FolderName
        }
    }

    if ($PSCmdlet.ParameterSetName -eq "File") {
        return Get-FolderIsInPath -Directory $File.Directory -FolderName $FolderName
    }

    if ($PSCmdlet.ParameterSetName -eq "Directory") {
        if ($Directory.Name -eq $FolderName) {
            return $true
        }

        if ($null -eq $Directory.Parent) {
            return $false
        }

        return Get-FolderIsInPath -Directory $Directory.Parent -FolderName $FolderName
    }
}
