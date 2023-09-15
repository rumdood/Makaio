function Get-ValueOrDefault {
    Param(
        [Parameter(Mandatory)]
        $Value,
        $MetaValue,
        [string] $DefaultValue = [string]::Empty
    )

    if ($null -eq $Value -or $Value.Length -eq 0) {
        if ($null -ne $MetaValue -and $MetaValue.Length -gt 0) {
            return $MetaValue
        } else {
            return $DefaultValue
        }
    } else {
        return $Value
    }
}
