# Extract-FileVersionsFromGit

A PowerShell script that extracts every version of every file that ever existed in a Git repository. Each extracted file is renamed by appending the date and time of the commit that included it to the base filename in the format `_YYYYMMDD_HHmmss`.

## Features

- **Complete History Extraction**: Processes every commit in chronological order (oldest first)
- **Smart File Naming**: Appends commit timestamp to filenames (e.g., `file.txt` becomes `file_20251014_154738.txt`)
- **Directory Structure Preservation**: Maintains the original folder structure in the output
- **Date Range Filtering**: Extract files only from commits within a specified date range
- **Binary File Handling**: Option to include or exclude binary files from extraction
- **Progress Reporting**: Shows real-time progress with commit processing status
- **Error Handling**: Robust error handling with detailed feedback
- **Flexible Parameters**: Configurable repository path, output directory, and processing limits

## Requirements

- Windows PowerShell 5.1 or later
- Git installed and accessible via PATH
- Git repository to process

## Usage

### Option 1: Using the Batch File (Recommended)

The easiest way to run the script is using the provided batch file wrapper:

```cmd
Extract-FileVersionsFromGit.bat
```

You can also pass parameters:

```cmd
Extract-FileVersionsFromGit.bat -RepositoryPath "C:\MyRepo" -OutputPath "C:\ExtractedFiles"
```

### Option 2: Direct PowerShell Execution

If you prefer to run the PowerShell script directly:

```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\Extract-FileVersionsFromGit.ps1"
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `RepositoryPath` | String | `.` (current directory) | Path to the Git repository to process |
| `OutputPath` | String | `extracted_files` | Directory where extracted files will be saved |
| `IncludeBinaryFiles` | Switch | False | Include binary files in extraction |
| `MaxCommits` | Integer | 0 (all commits) | Maximum number of commits to process (useful for testing) |
| `StartDate` | DateTime | (none) | Only process commits on or after this date |
| `EndDate` | DateTime | (none) | Only process commits on or before this date |

## Examples

### Basic Usage

Extract all files from the current directory repository:
```powershell
.\Extract-FileVersionsFromGit.ps1
```

### Specify Repository and Output Paths

```powershell
.\Extract-FileVersionsFromGit.ps1 -RepositoryPath "C:\MyProject" -OutputPath "C:\AllVersions"
```

### Include Binary Files

```powershell
.\Extract-FileVersionsFromGit.ps1 -IncludeBinaryFiles
```

### Limit Processing for Testing

```powershell
.\Extract-FileVersionsFromGit.ps1 -MaxCommits 10
```

### Complete Example

```powershell
.\Extract-FileVersionsFromGit.ps1 -RepositoryPath "C:\MyRepo" -OutputPath "C:\Extracted" -IncludeBinaryFiles -MaxCommits 50
```

### Date Range Examples

Extract files from commits in the last month:
```powershell
.\Extract-FileVersionsFromGit.ps1 -StartDate "2025-09-01" -EndDate "2025-09-30"
```

Extract files from commits after a specific date:
```powershell
.\Extract-FileVersionsFromGit.ps1 -StartDate "2025-10-01"
```

Extract files from commits before a specific date:
```powershell
.\Extract-FileVersionsFromGit.ps1 -EndDate "2025-12-31"
```

Extract files from a specific date range with binary files included:
```powershell
.\Extract-FileVersionsFromGit.ps1 -StartDate "2025-01-01" -EndDate "2025-12-31" -IncludeBinaryFiles
```

## Output Structure

The script creates an output directory with the following structure:

```
extracted_files/
├── file1_20251014_154738.txt
├── file1_20251014_162145.txt
├── subfolder/
│   ├── file2_20251014_154738.js
│   └── file2_20251014_170922.js
└── README_20251014_154738.md
```

Each file is named using the pattern: `originalname_YYYYMMDD_HHmmss.extension`

Where:
- `YYYYMMDD` is the commit date
- `HHmmss` is the commit time
- The original file extension is preserved

## How It Works

1. **Repository Validation**: Verifies that the specified path is a valid Git repository
2. **Commit Enumeration**: Retrieves all commits in chronological order (oldest first)
3. **Date Range Filtering**: Optionally filters commits to only include those within the specified date range
4. **File Discovery**: For each commit, identifies all files that existed at that point
5. **Binary Detection**: Optionally filters out binary files based on content analysis
6. **File Extraction**: Extracts each file version using `git show`
7. **Timestamp Formatting**: Formats commit date/time into the filename
8. **Directory Structure**: Preserves the original directory structure in the output

## Troubleshooting

### PowerShell Execution Policy Issues

If you get an execution policy error, use the batch file wrapper or run:
```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\Extract-FileVersionsFromGit.ps1"
```

### Git Not Found

Ensure Git is installed and available in your PATH. Test with:
```cmd
git --version
```

### Large Repositories

For very large repositories, consider using the `-MaxCommits` parameter to test with a subset first:
```powershell
.\Extract-FileVersionsFromGit.ps1 -MaxCommits 100
```

### Binary Files

By default, binary files are skipped. To include them, use the `-IncludeBinaryFiles` switch. Note that this may significantly increase output size and processing time.

## Performance Considerations

- Processing time depends on repository size and number of commits
- Binary files significantly increase extraction time and disk usage
- Use `-MaxCommits` for testing on large repositories
- The script processes commits sequentially to maintain chronological order

## License

This project is licensed under the same terms as specified in the LICENSE file.

## Contributing

Feel free to submit issues and enhancement requests!
