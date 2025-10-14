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
    Version: 1.0
#>

[CmdletBinding()]
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
            $content = git show "${CommitHash}:${FilePath}" 2>$null
            if ($LASTEXITCODE -ne 0) {
                return $false
            }
            
            # Check if content contains null bytes (indication of binary file)
            return $content -match [char]0
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
        [DateTime]$CommitDateTime
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
        
        # Extract the file from the commit
        $fileContent = git show "${CommitHash}:${FilePath}" 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            # Write content to file
            $fileContent | Out-File -FilePath $outputFilePath -Encoding UTF8
            return $outputFilePath
        } else {
            Write-Warning "Failed to extract file '$FilePath' from commit $CommitHash"
            return $null
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
                # Check if file is binary (skip if not including binary files)
                if (-not $IncludeBinaryFiles) {
                    $isBinary = Test-BinaryFile -RepoPath $repoFullPath -CommitHash $commit.Hash -FilePath $file
                    if ($isBinary) {
                        Write-Verbose "Skipping binary file: $file"
                        $skippedFiles++
                        continue
                    }
                }
                
                # Extract the file
                $extractedPath = Export-FileFromCommit -RepoPath $repoFullPath -CommitHash $commit.Hash -FilePath $file -OutputDir $outputFullPath -CommitDateTime $commit.DateTime
                
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