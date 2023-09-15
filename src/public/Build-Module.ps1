function Build-Module {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [string] $SourcePath = ".",
        [string] $Name,
        [string] $OutputPath,
        [Parameter(ParameterSetName="WithSubModules")]
        [switch] $WithNestedModules,
        [Parameter(ParameterSetName="SingleFile")]
        [switch] $SingleFile,
        [string] $Guid,
        [string] $Author,
        [string] $CompanyName,
        [string] $Copyright,
        [string] $Version,
        [string[]] $PublicFunctions,
        [string] $MetaDataPath = "makaio_meta.ps1",
        [switch] $NoClean,
        [switch] $BuilInPlace,
        [switch] $DisplayConfiguration
    )

    Write-Host "Starting build of Powershell Module in [$SourcePath]..." -ForegroundColor DarkGreen

    try {
        $stopWatch = [System.Diagnostics.Stopwatch]::StartNew()

        if (Test-Path -Path $MetaDataPath) {
            Write-Host "Loading metadata from [$MetaDataPath]..." -ForegroundColor DarkGreen
            
            # get the metadata from the file
            # $metaData = Get-Content -Path $MetaDataPath -Raw | ConvertFrom-Json
            Import-Module -Name (Resolve-Path $MetaDataPath) -Force -Scope Local
            $Name = Get-ValueOrDefault -Value $Name -MetaValue $meta.Name
            $OutputPath = $BuildInPlace ? $SourcePath : (Get-ValueOrDefault -Value $OutputPath -MetaValue $meta.OutputPath -DefaultValue $Defaults.OutputPath)
            $Guid = Get-ValueOrDefault -Value $Guid -MetaValue $meta.Guid -DefaultValue (New-Guid).ToString()
            $Author = Get-ValueOrDefault -Value $Author -MetaValue $meta.Author -DefaultValue $env:USERNAME
            $CompanyName = Get-ValueOrDefault -Value $CompanyName -MetaValue $meta.CompanyName
            $Copyright = Get-ValueOrDefault -Value $CopyRight -MetaValue $meta.CopyRight
            $Version = Get-ValueOrDefault -Value $Version -MetaValue $meta.Version -DefaultValue $Defaults.Version
            $PublicFunctions = $null -ne $PublicFunctions -and $PublicFunctions.Count -gt 0 ? $PublicFunctions : $meta.PublicFunctions ?? @()
        } else {
            Write-Host "No metadata found, using provided parameters/defaults" -ForegroundColor Yellow
        }

        $Name = $Name ?? (Split-Path $SourcePath -Leaf)

        Write-Host "Building module [$Name]..." -ForegroundColor Green

        $Author = $Author.Length -gt 0 ? $Author : $env:USERNAME
        $Copyright = $Copyright.Length -gt 0 ? $Copyright : "(c) $($null -ne $CompanyName ? $CompanyName : $Author). All rights reserved."
        $OutputPath = Join-Path $OutputPath "Modules" $Name
        $Guid = $Guid.Length -gt 0 ? $Guid : (New-Guid).ToString()

        if ($DisplayConfiguration) {
            Write-Host "Build Configuration:" -ForegroundColor Cyan
            Write-Host "###########################################################" -ForegroundColor Cyan
            Write-Host "    Name:               $Name" -ForegroundColor Cyan
            Write-Host "    Source Path:        $SourcePath" -ForegroundColor Cyan
            Write-Host "    Output Path:        $OutputPath" -ForegroundColor Cyan
            Write-Host "    With Nested Modules $WithNestedModules" -ForegroundColor Cyan
            Write-Host "    Single File:        $SingleFile" -ForegroundColor Cyan
            Write-Host "    Guid:               $Guid" -ForegroundColor Cyan
            Write-Host "    Author:             $Author" -ForegroundColor Cyan
            Write-Host "    Company Name:       $CompanyName" -ForegroundColor Cyan
            Write-Host "    Version:            $Version" -ForegroundColor Cyan
            Write-Host "    Public Functions:   $($PublicFunctions -join ", ")" -ForegroundColor Cyan
            Write-Host "    No Clean:           $NoClean" -ForegroundColor Cyan
            Write-Host "    Build In Place:     $BuildInPlace" -ForegroundColor Cyan
            Write-Host "###########################################################" -ForegroundColor Cyan
        }

        if ((Test-Path -Path $OutputPath) -and !$BuildInPlace -and !$NoClean) {
            Write-Host "    Cleaning up [$OutputPath]" -ForegroundColor Yellow

            if ($PSCmdlet.ShouldProcess($OutputPath, "Remove-Item")) {
                Remove-Item -Path $OutputPath -Recurse -Force -ErrorAction Inquire
            }
        }

        $files = @(Get-ChildItem -Path $SourcePath -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue) | Sort-Object -Property Name

        $rootModule = "$Name.psm1"
        $psm1Path = Join-Path $OutputPath $rootModule
        $subModules = @()
        $content = ""

        $PublicFunctions = $PublicFunctions.Count -gt 0 ? 
            $PublicFunctions : 
            (Get-PublicFunctionsFromFiles -Files $files)

        $qualifiedSourcePath = [System.IO.Path]::IsPathFullyQualified($SourcePath) ? $SourcePath : (Join-Path (Get-Location).Path $SourcePath)
        $qualifiedOutputPath = [System.IO.Path]::IsPathFullyQualified($OutputPath) ? $OutputPath : (Join-Path (Get-Location).Path $OutputPath)

        if ($WithNestedModules) {
            Write-Host "Building module using nested modules..." -ForegroundColor DarkGray
            if ($qualifiedOutputPath -ne $qualifiedSourcePath -and !$BuildInPlace) {
                
                $targetFiles = @()

                # the module files should be copied to the output path
                foreach ($file in $files) {
                    $endPath = $file.DirectoryName.Substring($qualifiedSourcePath.Length)
                    $targetPath = Join-Path $qualifiedOutputPath $endPath
                    $targetFile = Join-Path $targetPath $file.Name
                    $targetFiles += $targetFile
                    if ($PSCmdlet.ShouldProcess($targetFile, "Copy-Item")) {
                        
                        if (-not (Test-Path -Path $targetPath -PathType Container)) {
                            New-Item -Path $targetPath -ItemType Directory | Out-Null
                        }

                        Write-Host "    Copying [$($file.FullName)] to [$targetPath]" -ForegroundColor DarkGray
                        Copy-Item -Path $file.FullName -Destination $targetPath
                    }
                }
                $subModules = Get-SubModulesFromFiles -FileNames $targetFiles
            } else {
                $subModules = Get-SubModulesFromFiles -Path $OutputPath
            }

            $asm = [System.Management.Automation.Language.Parser]::ParseInput($DynamicModuleContent, [ref]$null, [ref]$null)
            $moduleContent = $asm.EndBlock.Extent.Text
            
            $content = $moduleContent
        } else {
            Write-Host "Building module using single file..." -ForegroundColor Green
            $content = Get-ModuleContentFromFiles -Name $Name -Files $files
        }

        # create the output path if it doesn't exist
        if (-not (Test-Path -Path $OutputPath -PathType Container)) {
            Write-Host "    Creating output folder [$OutputPath]" -ForegroundColor DarkGray
            New-Item -Path $OutputPath -ItemType Directory | Out-Null
        }

        Write-Host "    Writing to module file [$psm1Path]" -ForegroundColor DarkGray
        
        $content | Out-File -FilePath $psm1Path -Encoding utf8

        # Generate the manifest
        $manifestPath = Join-Path $OutputPath "$Name.psd1"
        Write-Verbose "    Generating Manifest with $rootModule / $($subModules -join ", ") / $($PublicFunctions -join ", ") / $Guid / $Author / $CompanyName / $Copyright ..."
        New-ModuleManifest -Path $manifestPath -RootModule $rootModule -NestedModules $subModules -FunctionsToExport $PublicFunctions -Guid $Guid -Author $Author -ModuleVersion $Version -CompanyName $CompanyName -Copyright $Copyright

        Write-Host "    Saved manifest to [$manifestPath]" -ForegroundColor DarkGray
        Write-Host ""

        $stopWatch.Stop()

        Write-Host "DONE - Build Completed in $($stopWatch.Elapsed.Minutes) minutes $($stopWatch.Elapsed.Seconds) seconds $($stopWatch.Elapsed.Milliseconds) milliseconds" -ForegroundColor Green
    } catch {
        Write-Error -Message "Failed to build module: $_"
        Write-Error -Message $_.ScriptStackTrace
    }
}
