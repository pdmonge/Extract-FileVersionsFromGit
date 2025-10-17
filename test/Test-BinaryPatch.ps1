#Requires -Version 5.1
<#
.SYNOPSIS
    Test script to verify binary file handling in Extract-FileVersionsFromGit.ps1

.DESCRIPTION
    Creates a test repository with both text and binary files, runs the extraction script,
    and verifies that binary files are extracted correctly without corruption.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ScriptPath = "..\powershell\Extract-FileVersionsFromGit.ps1"
)

$ErrorActionPreference = "Stop"

# Test configuration
$testRoot = Join-Path $PSScriptRoot "test_output"
$testRepoPath = Join-Path $testRoot "test_repo"
$extractedPath = Join-Path $testRoot "extracted"

# Color output helpers
function Write-TestHeader {
    param([string]$Message)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
}

function Write-TestSuccess {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-TestFailure {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-TestInfo {
    param([string]$Message)
    Write-Host "  $Message" -ForegroundColor Gray
}

# Cleanup function
function Remove-TestEnvironment {
    if (Test-Path $testRoot) {
        Write-TestInfo "Cleaning up test environment..."
        Remove-Item -Path $testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Create test binary files
function New-TestBinaryFile {
    param(
        [string]$Path,
        [string]$Type
    )
    
    switch ($Type) {
        "PNG" {
            # Minimal valid PNG file (1x1 red pixel)
            $bytes = @(
                0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,  # PNG signature
                0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,  # IHDR chunk
                0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,  # 1x1 dimensions
                0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,  # RGB, CRC
                0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,  # IDAT chunk
                0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,  # Image data (red)
                0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D,  # CRC
                0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,  # IEND chunk
                0x44, 0xAE, 0x42, 0x60, 0x82                      # CRC
            )
        }
        "ZIP" {
            # Minimal valid ZIP file (empty)
            $bytes = @(
                0x50, 0x4B, 0x05, 0x06, 0x00, 0x00, 0x00, 0x00,  # End of central directory
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00
            )
        }
        "EXE" {
            # Minimal PE header (not executable, but has PE signature)
            $bytes = @(
                0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00,  # MZ header
                0x04, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00,
                0xB8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
            ) + (@(0x00) * 32) + @(0x50, 0x45, 0x00, 0x00)  # PE signature at offset 0x3C
        }
        default {
            # Generic binary with null bytes
            $bytes = @(0x00, 0xFF, 0xAA, 0x55) * 16
        }
    }
    
    [System.IO.File]::WriteAllBytes($Path, $bytes)
    return $bytes
}

# Main test execution
try {
    Write-TestHeader "Binary File Patch Test Suite"
    
    # Verify script exists
    $scriptFullPath = Resolve-Path $ScriptPath -ErrorAction Stop
    Write-TestSuccess "Found extraction script: $scriptFullPath"
    
    # Cleanup previous test
    Remove-TestEnvironment
    
    # Create test environment
    Write-TestHeader "Setting Up Test Environment"
    New-Item -ItemType Directory -Path $testRepoPath -Force | Out-Null
    New-Item -ItemType Directory -Path $extractedPath -Force | Out-Null
    Write-TestSuccess "Created test directories"
    
    # Initialize git repository
    Push-Location $testRepoPath
    try {
        git init | Out-Null
        git config user.email "test@example.com" | Out-Null
        git config user.name "Test User" | Out-Null
        Write-TestSuccess "Initialized Git repository"
        
        # Test Case 1: Binary files
        Write-TestHeader "Test Case 1: Binary Files"
        
        $binaryTests = @(
            @{Name = "test.png"; Type = "PNG"; Description = "PNG image file"}
            @{Name = "test.zip"; Type = "ZIP"; Description = "ZIP archive file"}
            @{Name = "binary.dat"; Type = "BINARY"; Description = "Generic binary file"}
        )
        
        $originalHashes = @{}
        
        foreach ($test in $binaryTests) {
            Write-TestInfo "Creating $($test.Description)..."
            $filePath = Join-Path $testRepoPath $test.Name
            $bytes = New-TestBinaryFile -Path $filePath -Type $test.Type
            
            # Store hash of original
            $hash = (Get-FileHash -Path $filePath -Algorithm MD5).Hash
            $originalHashes[$test.Name] = @{
                Hash = $hash
                Size = $bytes.Length
            }
            
            git add $test.Name | Out-Null
            Write-TestInfo "  Original hash: $hash ($($bytes.Length) bytes)"
        }
        
        git commit -m "Add binary files" | Out-Null
        Write-TestSuccess "Committed binary files"
        
        # Test Case 2: Text files
        Write-TestHeader "Test Case 2: Text Files"
        
        $textContent = @"
# Test File
This is a test file with UTF-8 content.
Special characters: äöü ñ 中文 🎉
Line 1
Line 2
Line 3
"@
        
        $textPath = Join-Path $testRepoPath "test.txt"
        $textContent | Out-File -FilePath $textPath -Encoding UTF8
        git add "test.txt" | Out-Null
        git commit -m "Add text file" | Out-Null
        Write-TestSuccess "Committed text file"
        
        # Test Case 3: Mixed content in subdirectories
        Write-TestHeader "Test Case 3: Subdirectory Structure"
        
        $subDir = Join-Path $testRepoPath "subdir"
        New-Item -ItemType Directory -Path $subDir -Force | Out-Null
        
        $subBinaryPath = Join-Path $subDir "image.png"
        New-TestBinaryFile -Path $subBinaryPath -Type "PNG" | Out-Null
        
        $subTextPath = Join-Path $subDir "readme.md"
        "# Subdirectory README" | Out-File -FilePath $subTextPath -Encoding UTF8
        
        git add "subdir/*" | Out-Null
        git commit -m "Add subdirectory files" | Out-Null
        Write-TestSuccess "Committed subdirectory files"
        
        Write-TestInfo "Total commits: 3"
        
    } finally {
        Pop-Location
    }
    
    # Run extraction script
    Write-TestHeader "Running Extraction Script"
    
    Write-TestInfo "Extracting with -IncludeBinaryFiles..."
    $extractScript = @"
& '$scriptFullPath' -RepositoryPath '$testRepoPath' -OutputPath '$extractedPath' -IncludeBinaryFiles -Verbose
"@
    
    Invoke-Expression $extractScript
    Write-TestSuccess "Extraction completed"
    
    # Verify results
    Write-TestHeader "Verifying Extraction Results"
    
    $testsPassed = 0
    $testsFailed = 0
    
    # Check binary files
    foreach ($test in $binaryTests) {
        Write-TestInfo "Verifying $($test.Name)..."
        
        $extractedFiles = Get-ChildItem -Path $extractedPath -Recurse -Filter "$([System.IO.Path]::GetFileNameWithoutExtension($test.Name))_*$([System.IO.Path]::GetExtension($test.Name))"
        
        if ($extractedFiles.Count -eq 0) {
            Write-TestFailure "No extracted versions found for $($test.Name)"
            $testsFailed++
            continue
        }
        
        Write-TestInfo "  Found $($extractedFiles.Count) version(s)"
        
        $allMatch = $true
        foreach ($extracted in $extractedFiles) {
            $extractedHash = (Get-FileHash -Path $extracted.FullName -Algorithm MD5).Hash
            $extractedSize = $extracted.Length
            
            if ($extractedHash -eq $originalHashes[$test.Name].Hash -and 
                $extractedSize -eq $originalHashes[$test.Name].Size) {
                Write-TestInfo "  ✓ $($extracted.Name): Hash matches, size matches ($extractedSize bytes)"
            } else {
                Write-TestFailure "Hash/size mismatch for $($extracted.Name)"
                Write-TestInfo "    Expected: $($originalHashes[$test.Name].Hash) ($($originalHashes[$test.Name].Size) bytes)"
                Write-TestInfo "    Got:      $extractedHash ($extractedSize bytes)"
                $allMatch = $false
            }
        }
        
        if ($allMatch) {
            Write-TestSuccess "$($test.Name) - All versions match original"
            $testsPassed++
        } else {
            $testsFailed++
        }
    }
    
    # Check text file
    Write-TestInfo "Verifying test.txt..."
    $extractedTextFiles = Get-ChildItem -Path $extractedPath -Recurse -Filter "test_*.txt"
    
    if ($extractedTextFiles.Count -gt 0) {
        $textContent = Get-Content -Path $extractedTextFiles[0].FullName -Raw -Encoding UTF8
        if ($textContent -match "Special characters" -and $textContent -match "äöü") {
            Write-TestSuccess "test.txt - Content and encoding verified"
            $testsPassed++
        } else {
            Write-TestFailure "test.txt - Content verification failed"
            $testsFailed++
        }
    } else {
        Write-TestFailure "No extracted versions found for test.txt"
        $testsFailed++
    }
    
    # Check subdirectory structure
    Write-TestInfo "Verifying subdirectory structure..."
    $subDirFiles = Get-ChildItem -Path (Join-Path $extractedPath "subdir") -Recurse -ErrorAction SilentlyContinue
    
    if ($subDirFiles.Count -ge 2) {
        Write-TestSuccess "Subdirectory structure preserved"
        $testsPassed++
    } else {
        Write-TestFailure "Subdirectory structure not preserved correctly"
        $testsFailed++
    }
    
    # Final summary
    Write-TestHeader "Test Summary"
    Write-Host "Tests Passed: " -NoNewline
    Write-Host $testsPassed -ForegroundColor Green
    Write-Host "Tests Failed: " -NoNewline
    Write-Host $testsFailed -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })
    
    if ($testsFailed -eq 0) {
        Write-Host "`n🎉 All tests passed! Binary file handling is working correctly." -ForegroundColor Green
        $exitCode = 0
    } else {
        Write-Host "`n❌ Some tests failed. Please review the patch." -ForegroundColor Red
        $exitCode = 1
    }
    
    # Show extracted files
    Write-TestHeader "Extracted Files"
    Get-ChildItem -Path $extractedPath -Recurse -File | ForEach-Object {
        $relativePath = $_.FullName.Substring($extractedPath.Length + 1)
        Write-TestInfo "$relativePath ($($_.Length) bytes)"
    }
    
    Write-Host "`nTest output location: $testRoot" -ForegroundColor Cyan
    Write-Host "To cleanup: Remove-Item '$testRoot' -Recurse -Force`n" -ForegroundColor Gray
    
    exit $exitCode
    
} catch {
    Write-TestFailure "Test execution failed: $($_.Exception.Message)"
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
} finally {
    # Return to original location if we're stuck somewhere
    if ((Get-Location).Path -ne $PSScriptRoot) {
        Set-Location $PSScriptRoot -ErrorAction SilentlyContinue
    }
}
