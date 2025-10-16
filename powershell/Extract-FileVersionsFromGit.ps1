<#
    VERSION: 1.1.0
#>
#Requires -Version 5.1
<#
.SYNOPSIS
    Extract all versions of every file from a Git repository.

.DESCRIPTION
    This script iterates through every commit in a Git repository and extracts all files
    that existed at each commit. Each extracted file is renamed to include the commit
    date and time in the format: originalname_YYYYMMDD_HHmmss.extension
    
    Supports filtering commits by date range using StartDate and EndDate parameters.

.PARAMETER RepositoryPath
    The path to the Git repository to process. Defaults to current directory.

.PARAMETER OutputPath
    The path where extracted files will be saved. Defaults to "extracted_files" in current directory.

.PARAMETER IncludeBinaryFiles
    Switch to include binary files in extraction. By default, only text files are extracted.

.PARAMETER MaxCommits
    Maximum number of commits to process. Useful for testing. If not specified, all commits are processed.

.PARAMETER StartDate
    Only process commits on or after this date. Can be combined with EndDate for a date range.

.PARAMETER EndDate
    Only process commits on or before this date. Can be combined with StartDate for a date range.

.EXAMPLE
    .\Extract-FileVersionsFromGit.ps1 -RepositoryPath "C:\MyRepo" -OutputPath "C:\ExtractedFiles"

.EXAMPLE
    .\Extract-FileVersionsFromGit.ps1 -RepositoryPath "." -IncludeBinaryFiles -MaxCommits 10

.EXAMPLE
    .\Extract-FileVersionsFromGit.ps1 -RepositoryPath "." -StartDate "2025-01-01" -EndDate "2025-12-31"

.EXAMPLE
    .\Extract-FileVersionsFromGit.ps1 -RepositoryPath "." -StartDate "2025-10-01"

.NOTES
    Requires Git to be installed and available in PATH.
    Author: GitHub Copilot
    Version: 1.1.0
    Release Date: 2025-10-16
    Changelog:
      - 1.1.0: Major binary file handling fix, improved UTF-8 support, enhanced detection, full test suite
#>

[CmdletBinding()]
# Script version
$VERSION = "1.1.0"
param(
    [Parameter(Mandatory = $false)]
    [string]$RepositoryPath = ".",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "extracted_files",
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeBinaryFiles,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxCommits = 0,
    
    [Parameter(Mandatory = $false)]
    [DateTime]$StartDate = [DateTime]::MinValue,
    
    [Parameter(Mandatory = $false)]
    [DateTime]$EndDate = [DateTime]::MaxValue
)

# Function to check if Git is available
function Test-GitAvailable {
    try {
        $null = git --version 2>$null
        return $true
    }
    catch {
        return $false
    }
}

# Function to check if a path is a Git repository
function Test-GitRepository {
    param([string]$Path)
    
    $originalLocation = Get-Location
    try {
        Set-Location $Path
        $null = git rev-parse --git-dir 2>$null
        return $?
    }
    catch {
        return $false
    }
    finally {
        Set-Location $originalLocation
    }
}

# Function to get all commits in chronological order (oldest first)
function Get-AllCommits {
    param(
        [string]$RepoPath,
        [int]$MaxCommits,
        [DateTime]$StartDate = [DateTime]::MinValue,
        [DateTime]$EndDate = [DateTime]::MaxValue
    )
    
    $originalLocation = Get-Location
    try {
        Set-Location $RepoPath
        
        # Get commits in reverse chronological order (oldest first)
        $gitArgs = @("log", "--pretty=format:%H|%ci|%s", "--reverse")
        if ($MaxCommits -gt 0) {
            $gitArgs += "-n"
            $gitArgs += $MaxCommits.ToString()
        }
        
        $commits = & git $gitArgs 2>$null | Where-Object { $_ }
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to retrieve Git commits"
        }
        
        $commitObjects = @()
        foreach ($commit in $commits) {
            if ($commit -and $commit.Trim()) {
                $parts = $commit.Trim() -split '\|', 3
                if ($parts.Count -ge 2) {
                    $commitDateTime = [DateTime]::Parse($parts[1].Trim())
                    
                    # Apply date range filtering
                    $includeCommit = $true
                    if ($StartDate -ne [DateTime]::MinValue -and $commitDateTime -lt $StartDate) {
                        $includeCommit = $false
                    }
                    if ($EndDate -ne [DateTime]::MaxValue -and $commitDateTime -gt $EndDate) {
                        $includeCommit = $false
                    }
                    
                    if ($includeCommit) {
                        $commitObjects += [PSCustomObject]@{
                            Hash = $parts[0].Trim()
                            DateTime = $commitDateTime
                            Message = if ($parts.Count -gt 2) { $parts[2].Trim() } else { "" }
                        }
                    }
                }
            }
        }
        
        return ,$commitObjects
    }
    finally {
        Set-Location $originalLocation
    }
}

# Function to get all files in a specific commit
function Get-FilesInCommit {
    param(
        [string]$RepoPath,
        [string]$CommitHash
    )
    
    $originalLocation = Get-Location
    try {
        Set-Location $RepoPath
        
        # Get list of all files in the commit
        $files = git ls-tree -r --name-only $CommitHash 2>$null
        
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to get files for commit $CommitHash"
            return @()
        }
        
        return $files
    }
    finally {
        Set-Location $originalLocation
    }
}

# Function to check if a file is binary
function Test-BinaryFile {
    param(
        [string]$RepoPath,
        [string]$CommitHash,
        [string]$FilePath
    )
    
    $originalLocation = Get-Location
    try {
        Set-Location $RepoPath
        
        # Get file content and check for null bytes (simple binary detection)
        try {
            # Use git to check if file is binary (more reliable than manual detection)
            $checkBinary = git diff --numstat 4b825dc642cb6eb9a060e54bf8d69288fbee4904 "${CommitHash}" -- "${FilePath}" 2>$null
            
            if ($LASTEXITCODE -eq 0 -and $checkBinary) {
                # Git diff --numstat shows "-" for binary files
                if ($checkBinary -match "^-\s+-\s+") {
                    return $true
                }
            }
            
            # Fallback: Check for null bytes in content
            $content = git show "${CommitHash}:${FilePath}" 2>$null
            if ($LASTEXITCODE -ne 0) {
                return $false
            }
            
            # Check if content contains null bytes (indication of binary file)
            # Use -Raw parameter to get as single string if possible
            $contentString = if ($content -is [array]) { $content -join "`n" } else { $content }
            return [bool]($contentString -match "`0")
        }
        catch {
            # If we can't read content, assume it's binary
            return $true
        }
    }
    finally {
        Set-Location $originalLocation
    }
}

# Function to extract a file from a specific commit
function Export-FileFromCommit {
    param(
        [string]$RepoPath,
        [string]$CommitHash,
        [string]$FilePath,
        [string]$OutputDir,
        [DateTime]$CommitDateTime,
        [bool]$IsBinary = $false
    )
    
    $originalLocation = Get-Location
    try {
        Set-Location $RepoPath
        
        # Format the timestamp
        $timeStamp = $CommitDateTime.ToString("yyyyMMdd_HHmmss")
        
        # Get file extension and base name
        $fileInfo = [System.IO.FileInfo]$FilePath
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
        $extension = $fileInfo.Extension
        
        # Create new filename with timestamp
        $newFileName = "${baseName}_${timeStamp}${extension}"
        
        # Preserve directory structure
        $relativeDir = [System.IO.Path]::GetDirectoryName($FilePath)
        if ($relativeDir) {
            $outputSubDir = Join-Path $OutputDir $relativeDir
        } else {
            $outputSubDir = $OutputDir
        }
        
        # Create output directory if it doesn't exist
        if (-not (Test-Path $outputSubDir)) {
            New-Item -ItemType Directory -Path $outputSubDir -Force | Out-Null
        }
        
        # Full output path
        $outputFilePath = Join-Path $outputSubDir $newFileName
        
        # Extract the file from the commit directly to disk
        # Use git archive or git show with binary-safe output redirection
        if ($IsBinary) {
            # For binary files, use git's binary-safe output with cmd.exe redirection
            # This avoids PowerShell's string encoding issues
            $tempScript = [System.IO.Path]::GetTempFileName() + ".cmd"
            try {
                # Create a cmd script to handle binary output properly
                "@echo off`ngit show `"${CommitHash}:${FilePath}`" > `"$outputFilePath`" 2>nul" | Out-File -FilePath $tempScript -Encoding ASCII
                $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$tempScript`"" -NoNewWindow -Wait -PassThru -WorkingDirectory $RepoPath
                
                if ($process.ExitCode -eq 0 -and (Test-Path $outputFilePath)) {
                    return $outputFilePath
                } else {
                    Write-Warning "Failed to extract binary file '$FilePath' from commit $CommitHash"
                    if (Test-Path $outputFilePath) {
                        Remove-Item $outputFilePath -Force
                    }
                    return $null
                }
            }
            finally {
                if (Test-Path $tempScript) {
                    Remove-Item $tempScript -Force
                }
            }
        } else {
            # For text files, use cmd.exe redirection as well to preserve encoding
            # Git handles UTF-8 properly, and cmd redirection preserves it
            $tempScript = [System.IO.Path]::GetTempFileName() + ".cmd"
            try {
                # Create a cmd script to handle text output with proper encoding
                "@echo off`nchcp 65001 >nul`ngit show `"${CommitHash}:${FilePath}`" > `"$outputFilePath`" 2>nul" | Out-File -FilePath $tempScript -Encoding ASCII
                $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$tempScript`"" -NoNewWindow -Wait -PassThru -WorkingDirectory $RepoPath
                
                if ($process.ExitCode -eq 0 -and (Test-Path $outputFilePath)) {
                    return $outputFilePath
                } else {
                    Write-Warning "Failed to extract text file '$FilePath' from commit $CommitHash"
                    if (Test-Path $outputFilePath) {
                        Remove-Item $outputFilePath -Force
                    }
                    return $null
                }
            }
            finally {
                if (Test-Path $tempScript) {
                    Remove-Item $tempScript -Force
                }
            }
        }
    }
    finally {
        Set-Location $originalLocation
    }
}

# Main execution
function Main {
    Write-Host "Git File Version Extractor" -ForegroundColor Green
    Write-Host "=========================" -ForegroundColor Green
    
    # Validate Git availability
    if (-not (Test-GitAvailable)) {
        Write-Error "Git is not available in PATH. Please install Git and ensure it's accessible."
        return 1
    }
    
    # Resolve full paths
    $repoFullPath = Resolve-Path $RepositoryPath -ErrorAction SilentlyContinue
    if (-not $repoFullPath) {
        Write-Error "Repository path '$RepositoryPath' does not exist."
        return 1
    }
    
    # Validate Git repository
    if (-not (Test-GitRepository $repoFullPath)) {
        Write-Error "Path '$repoFullPath' is not a Git repository."
        return 1
    }
    
    # Create output directory
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    $outputFullPath = Resolve-Path $OutputPath
    
    Write-Host "Repository: $repoFullPath" -ForegroundColor Cyan
    Write-Host "Output Directory: $outputFullPath" -ForegroundColor Cyan
    Write-Host "Include Binary Files: $IncludeBinaryFiles" -ForegroundColor Cyan
    if ($MaxCommits -gt 0) {
        Write-Host "Max Commits: $MaxCommits" -ForegroundColor Cyan
    }
    if ($StartDate -ne [DateTime]::MinValue) {
        Write-Host "Start Date: $($StartDate.ToString('yyyy-MM-dd'))" -ForegroundColor Cyan
    }
    if ($EndDate -ne [DateTime]::MaxValue) {
        Write-Host "End Date: $($EndDate.ToString('yyyy-MM-dd'))" -ForegroundColor Cyan
    }
    Write-Host ""
    
    # Get all commits
    Write-Host "Retrieving commit history..." -ForegroundColor Yellow
    try {
        $commits = Get-AllCommits -RepoPath $repoFullPath -MaxCommits $MaxCommits -StartDate $StartDate -EndDate $EndDate
        Write-Host "Found $($commits.Count) commits to process." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to retrieve commits: $($_.Exception.Message)"
        return 1
    }
    
    if ($commits.Count -eq 0) {
        Write-Warning "No commits found in repository."
        return 0
    }
    
    # Process each commit
    $totalFiles = 0
    $processedFiles = 0
    $skippedFiles = 0
    
    for ($i = 0; $i -lt $commits.Count; $i++) {
        $commit = $commits[$i]
        $progress = [math]::Round(($i / $commits.Count) * 100, 2)
        
        Write-Progress -Activity "Processing Commits" -Status "Commit $($i + 1) of $($commits.Count) ($progress%)" -PercentComplete $progress
        Write-Host "Processing commit $($i + 1)/$($commits.Count): $($commit.Hash.Substring(0,8)) - $($commit.DateTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
        
        # Get files in this commit
        $files = Get-FilesInCommit -RepoPath $repoFullPath -CommitHash $commit.Hash
        $totalFiles += $files.Count
        
        foreach ($file in $files) {
            try {
                # Check if file is binary
                $isBinary = Test-BinaryFile -RepoPath $repoFullPath -CommitHash $commit.Hash -FilePath $file
                
                # Skip binary files if not including them
                if ($isBinary -and -not $IncludeBinaryFiles) {
                    Write-Verbose "Skipping binary file: $file"
                    $skippedFiles++
                    continue
                }
                
                # Extract the file (passing binary status for proper handling)
                $extractedPath = Export-FileFromCommit -RepoPath $repoFullPath -CommitHash $commit.Hash -FilePath $file -OutputDir $outputFullPath -CommitDateTime $commit.DateTime -IsBinary $isBinary
                
                if ($extractedPath) {
                    $processedFiles++
                    Write-Verbose "Extracted: $file -> $extractedPath"
                } else {
                    $skippedFiles++
                }
            }
            catch {
                Write-Warning "Error processing file '$file' in commit $($commit.Hash): $($_.Exception.Message)"
                $skippedFiles++
            }
        }
    }
    
    Write-Progress -Activity "Processing Commits" -Completed
    
    # Summary
    Write-Host ""
    Write-Host "Extraction Complete!" -ForegroundColor Green
    Write-Host "===================" -ForegroundColor Green
    Write-Host "Total files found: $totalFiles" -ForegroundColor White
    Write-Host "Files processed: $processedFiles" -ForegroundColor Green
    Write-Host "Files skipped: $skippedFiles" -ForegroundColor Yellow
    Write-Host "Output directory: $outputFullPath" -ForegroundColor Cyan
    
    return 0
}

# Execute main function
exit (Main)