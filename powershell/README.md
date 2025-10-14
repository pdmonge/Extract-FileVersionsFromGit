# Extract-FileVersionsFromGit (PowerShell Version)

A comprehensive PowerShell script that extracts every version of every file that ever existed in a Git repository. Each extracted file is renamed by appending the date and time of the commit that included it to the base filename in the format `_YYYYMMDD_HHmmss`.

This is the **Windows-native** implementation, optimized for PowerShell environments and Windows workflows.

## Features

- **Complete History Extraction**: Processes every commit in chronological order (oldest first)
- **Smart File Naming**: Appends commit timestamp to filenames (e.g., `file.txt` becomes `file_20251014_154738.txt`)
- **Directory Structure Preservation**: Maintains the original folder structure in the output
- **Date Range Filtering**: Extract files only from commits within a specified date range
- **Binary File Handling**: Intelligent binary file detection with inclusion option
- **Progress Reporting**: Real-time progress with Windows progress bars
- **Execution Policy Support**: Includes batch wrapper for execution policy bypass
- **Comprehensive Error Handling**: Windows-specific error messages and validation
- **PowerShell Integration**: Native PowerShell cmdlets and patterns

## Requirements

- **Windows PowerShell 5.1** or later, or **PowerShell Core 6.0+**
- **Git for Windows** installed and accessible via PATH
- **Windows Operating System** (Windows 10/11, Windows Server 2016+)
- **Execution Policy**: Unrestricted, RemoteSigned, or use the provided batch wrapper

## Installation

### Option 1: Direct Download
1. Download the PowerShell files:
   - `Extract-FileVersionsFromGit.ps1` (main script)
   - `Extract-FileVersionsFromGit.bat` (execution wrapper)

2. Place both files in the same directory

3. Ensure Git is installed and available in PATH

### Option 2: Clone Repository
```powershell
git clone https://github.com/pdmonge/Extract-FileVersionsFromGit.git
cd Extract-FileVersionsFromGit\powershell
```

## Usage

### Method 1: Batch File Wrapper (Recommended)

The easiest way to run the script, especially if you have execution policy restrictions:

```cmd
Extract-FileVersionsFromGit.bat
```

With parameters:
```cmd
Extract-FileVersionsFromGit.bat -RepositoryPath "C:\MyRepo" -OutputPath "C:\ExtractedFiles"
```

### Method 2: Direct PowerShell Execution

If your execution policy allows it:

```powershell
.\Extract-FileVersionsFromGit.ps1
```

Or bypass execution policy:
```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\Extract-FileVersionsFromGit.ps1"
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `RepositoryPath` | String | `.` (current directory) | Path to the Git repository to process |
| `OutputPath` | String | `extracted_files` | Directory where extracted files will be saved |
| `IncludeBinaryFiles` | Switch | `False` | Include binary files in extraction |
| `MaxCommits` | Integer | `0` (all commits) | Maximum number of commits to process (useful for testing) |
| `StartDate` | DateTime | (none) | Only process commits on or after this date |
| `EndDate` | DateTime | (none) | Only process commits on or before this date |

### Parameter Examples

**Basic repository processing:**
```powershell
.\Extract-FileVersionsFromGit.ps1 -RepositoryPath "C:\Source\MyProject"
```

**Custom output location:**
```powershell
.\Extract-FileVersionsFromGit.ps1 -OutputPath "D:\BackupVersions"
```

**Include binary files:**
```powershell
.\Extract-FileVersionsFromGit.ps1 -IncludeBinaryFiles
```

**Limit processing for testing:**
```powershell
.\Extract-FileVersionsFromGit.ps1 -MaxCommits 50
```

**Date range filtering:**
```powershell
.\Extract-FileVersionsFromGit.ps1 -StartDate "2025-01-01" -EndDate "2025-12-31"
```

**Complex example:**
```powershell
.\Extract-FileVersionsFromGit.ps1 `
  -RepositoryPath "C:\Projects\WebApp" `
  -OutputPath "C:\Backup\WebApp_Versions" `
  -StartDate "2025-10-01" `
  -EndDate "2025-10-31" `
  -IncludeBinaryFiles `
  -MaxCommits 100
```

## Output Structure

The script creates an output directory with the following structure:

```
extracted_files/
├── file1_20251014_154738.txt
├── file1_20251014_162145.txt
├── src/
│   ├── component_20251014_154738.js
│   └── component_20251014_170922.js
├── docs/
│   └── README_20251014_154738.md
└── config/
    ├── app_20251014_154738.json
    └── settings_20251014_162145.xml
```

### File Naming Convention

Each file is named using the pattern: `originalname_YYYYMMDD_HHmmss.extension`

- **`originalname`**: Original filename without extension
- **`YYYYMMDD`**: Commit date (Year-Month-Day)
- **`HHmmss`**: Commit time (Hour-Minute-Second)
- **`.extension`**: Original file extension preserved

## How It Works

1. **Parameter Validation**: Validates all input parameters and paths
2. **Git Availability Check**: Ensures Git is installed and accessible
3. **Repository Validation**: Verifies the target is a valid Git repository
4. **Commit Enumeration**: Retrieves all commits in chronological order (oldest first)
5. **Date Range Filtering**: Optionally filters commits within specified date range
6. **Progress Initialization**: Sets up Windows progress reporting
7. **Commit Processing Loop**:
   - For each commit, gets list of all files
   - Applies binary file filtering if needed
   - Extracts each file with timestamp naming
   - Preserves directory structure
   - Reports progress and statistics
8. **Completion Summary**: Displays extraction statistics and results

## Advanced Features

### Binary File Detection

The script uses intelligent binary file detection:
```powershell
# Automatically skip binary files (default)
.\Extract-FileVersionsFromGit.ps1

# Include binary files explicitly
.\Extract-FileVersionsFromGit.ps1 -IncludeBinaryFiles
```

### Date Range Processing

Process only specific time periods:
```powershell
# Last quarter of 2025
.\Extract-FileVersionsFromGit.ps1 -StartDate "2025-10-01" -EndDate "2025-12-31"

# Everything after a major release
.\Extract-FileVersionsFromGit.ps1 -StartDate "2025-06-15"

# Everything before a cutoff date
.\Extract-FileVersionsFromGit.ps1 -EndDate "2025-09-30"
```

### Progress Monitoring

The script provides comprehensive progress reporting:
- **Commit-by-commit progress** with percentage completion
- **File processing statistics** (processed vs. skipped)
- **Real-time status updates** with commit hashes and timestamps
- **Final summary** with totals and output location

## Error Handling

### Common Issues and Solutions

#### Execution Policy Errors
```
cannot be loaded because running scripts is disabled on this system
```

**Solution**: Use the batch wrapper or temporarily bypass:
```cmd
REM Use the batch wrapper
Extract-FileVersionsFromGit.bat

REM Or bypass execution policy
powershell.exe -ExecutionPolicy Bypass -File ".\Extract-FileVersionsFromGit.ps1"
```

#### Git Not Found
```
Git is not available in PATH
```

**Solution**: Install Git for Windows and ensure it's in PATH:
```cmd
git --version
```

#### Repository Not Found
```
Path 'C:\Invalid\Path' is not a Git repository
```

**Solution**: Verify the path points to a valid Git repository:
```powershell
cd "C:\Valid\Git\Repository"
.\Extract-FileVersionsFromGit.ps1
```

#### Permission Denied
```
Access to the path 'C:\...' is denied
```

**Solution**: Run PowerShell as Administrator or choose a writable output path:
```powershell
.\Extract-FileVersionsFromGit.ps1 -OutputPath "C:\Users\$env:USERNAME\Desktop\Extracted"
```

### Verbose Output

Enable detailed logging for troubleshooting:
```powershell
.\Extract-FileVersionsFromGit.ps1 -Verbose
```

## Performance Considerations

### Large Repositories

For repositories with thousands of commits:
```powershell
# Test with limited commits first
.\Extract-FileVersionsFromGit.ps1 -MaxCommits 100

# Use date ranges to limit scope
.\Extract-FileVersionsFromGit.ps1 -StartDate "2025-01-01"

# Process in smaller chunks
.\Extract-FileVersionsFromGit.ps1 -StartDate "2025-01-01" -EndDate "2025-06-30"
.\Extract-FileVersionsFromGit.ps1 -StartDate "2025-07-01" -EndDate "2025-12-31"
```

### Binary Files

Binary files significantly impact performance:
```powershell
# Skip binary files for faster processing (default)
.\Extract-FileVersionsFromGit.ps1

# Include only when necessary
.\Extract-FileVersionsFromGit.ps1 -IncludeBinaryFiles
```

### Disk Space Management

Monitor disk usage for large extractions:
- **Text files**: Minimal space impact
- **Binary files**: Can consume significant disk space
- **Multiple versions**: Space scales with file count × version count

## Integration Examples

### Automated Backup Script

```powershell
# Create a monthly backup script
param(
    [string]$RepoPath = "C:\Source\MainProject",
    [string]$BackupRoot = "D:\ProjectBackups"
)

$timestamp = Get-Date -Format "yyyy-MM"
$outputPath = Join-Path $BackupRoot "Backup_$timestamp"

.\Extract-FileVersionsFromGit.ps1 `
    -RepositoryPath $RepoPath `
    -OutputPath $outputPath `
    -StartDate (Get-Date).AddMonths(-1).ToString("yyyy-MM-01") `
    -EndDate (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
```

### CI/CD Integration

```powershell
# Integrate with build pipeline
if ($env:BUILD_REASON -eq "Schedule") {
    .\Extract-FileVersionsFromGit.ps1 `
        -RepositoryPath $env:BUILD_SOURCESDIRECTORY `
        -OutputPath "$env:BUILD_ARTIFACTSTAGINGDIRECTORY\FileVersions" `
        -StartDate $env:LAST_BACKUP_DATE
}
```

## Comparison with Bash Version

| Feature | PowerShell Version | Bash Version |
|---------|-------------------|--------------|
| **Platform** | Windows (native) | Unix/Linux/macOS (native) |
| **Progress Bars** | Windows native progress | Colored terminal output |
| **Error Handling** | PowerShell exceptions | Bash error codes |
| **Date Format** | Flexible parsing | YYYY-MM-DD required |
| **Binary Detection** | Advanced content analysis | Null byte detection |
| **Path Handling** | Windows path conventions | Unix path conventions |
| **Integration** | Windows PowerShell ecosystem | Unix shell scripting |

### When to Use PowerShell Version

✅ **Windows environments**  
✅ **PowerShell-based workflows**  
✅ **Windows Server automation**  
✅ **Integration with Windows tools**  
✅ **Enterprise Windows environments**  

### When to Use Bash Version

✅ **Linux/macOS environments**  
✅ **Docker containers**  
✅ **CI/CD pipelines (Linux-based)**  
✅ **Cross-platform shell scripting**  
✅ **WSL environments**  

## Contributing

When contributing to the PowerShell version:

1. **Follow PowerShell best practices**: Use approved verbs, proper error handling
2. **Test on multiple Windows versions**: Windows 10, 11, Server 2019/2022
3. **Validate PowerShell versions**: Test with both Windows PowerShell 5.1 and PowerShell 7+
4. **Update documentation**: Keep this README synchronized with code changes
5. **Cross-reference bash version**: Maintain feature parity when possible

## License

This project is licensed under the same terms as specified in the main LICENSE file.

## See Also

- **[Bash Version](../bash/)**: Cross-platform bash implementation for Unix/Linux/macOS
- **[Main README](../README.md)**: General project information and platform selection guide
- **[PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)**: Official PowerShell documentation