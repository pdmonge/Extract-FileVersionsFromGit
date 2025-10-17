
# Extract-FileVersionsFromGit ![Version](https://img.shields.io/badge/version-1.2.0-blue)


A cross-platform solution for extracting every version of every file that ever existed in a Git repository. Each extracted file is renamed by appending the date and time of the commit that included it to the base filename in the format `_YYYYMMDD_HHmmss`.

---
**Current Version:** `1.2.0`  
**Release Date:** 2025-10-16
---

## 🚀 Quick Start

Choose the version that best fits your environment:

### Windows Users
```cmd
cd powershell
Extract-FileVersionsFromGit.bat
```

### Linux/macOS/WSL Users
```bash
cd bash
./extract-file-versions-from-git.sh
```

## 📋 Available Implementations

| Platform | Directory | Best For | Key Features |
|----------|-----------|----------|--------------|
| **Windows** | [`powershell/`](./powershell/) | Windows environments, PowerShell workflows | Native Windows integration, execution policy support |
| **Unix/Linux** | [`bash/`](./bash/) | Linux, macOS, WSL, cross-platform | POSIX compliance, colored output, lightweight |

## ✨ Common Features

Both implementations provide identical core functionality:

- **Complete History Extraction**: Processes every commit in chronological order (oldest first)
- **Smart File Naming**: Appends commit timestamp to filenames (e.g., `file.txt` becomes `file_20251014_154738.txt`)
- **Directory Structure Preservation**: Maintains the original folder structure in the output
- **Date Range Filtering**: Extract files only from commits within a specified date range
- **Binary File Handling**: Option to include or exclude binary files from extraction
- **Progress Reporting**: Shows real-time progress with commit processing status
- **Error Handling**: Robust error handling with detailed feedback
- **Flexible Parameters**: Configurable repository path, output directory, and processing limits

## 🎯 Platform Selection Guide

### Choose PowerShell Version When:
✅ **Windows is your primary platform**  
✅ **PowerShell-based automation workflows**  
✅ **Enterprise Windows environments**  
✅ **Windows Server deployments**  
✅ **Integration with Windows tooling**  

**📁 [View PowerShell Version →](./powershell/)**

### Choose Bash Version When:
✅ **Linux/macOS is your primary platform**  
✅ **Docker/container environments**  
✅ **CI/CD pipelines (Unix-based)**  
✅ **Cross-platform shell scripting**  
✅ **WSL (Windows Subsystem for Linux)**  

**📁 [View Bash Version →](./bash/)**

## 🔧 System Requirements

### General Requirements (Both Versions)
- **Git**: Installed and accessible via PATH
- **Git Repository**: Valid repository to process

### PowerShell Version
- **OS**: Windows 10/11, Windows Server 2016+
- **PowerShell**: 5.1+ or PowerShell Core 6.0+

### Bash Version  
- **OS**: Linux, macOS, or Windows with WSL/Git Bash
- **Shell**: Bash 4.0 or later
- **Utilities**: Standard Unix tools (`date`, `grep`, `cut`, etc.)

## 📖 Documentation

Each implementation has comprehensive documentation:

- **[PowerShell Documentation](./powershell/README.md)**: Windows-specific usage, parameters, and examples
- **[Bash Documentation](./bash/README.md)**: Unix/Linux usage, installation, and cross-platform notes

## 🏃‍♂️ Quick Examples

### PowerShell (Windows)
```powershell
# Basic extraction
powershell\Extract-FileVersionsFromGit.ps1

# With date range
powershell\Extract-FileVersionsFromGit.ps1 -StartDate "2025-01-01" -EndDate "2025-12-31"

# Include binary files
powershell\Extract-FileVersionsFromGit.ps1 -IncludeBinaryFiles
```

### Bash (Unix/Linux/macOS)
```bash
# Basic extraction  
bash/extract-file-versions-from-git.sh

# With date range
bash/extract-file-versions-from-git.sh --start-date 2025-01-01 --end-date 2025-12-31

# Include binary files with verbose output
bash/extract-file-versions-from-git.sh --include-binary-files --verbose
```

## 📁 Output Structure

Both versions produce identical output structure:

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

### Using on Non-Windows Platforms

If you're on Linux, macOS, or WSL, consider using the **bash version** instead:
```bash
cd bash/
./extract-file-versions-from-git.sh --help
```

The bash version provides the same functionality with Unix-native implementation. See [`bash/README.md`](./bash/README.md) for detailed documentation.

## Performance Considerations

- Processing time depends on repository size and number of commits
- Binary files significantly increase extraction time and disk usage
- Use `-MaxCommits` for testing on large repositories
- The script processes commits sequentially to maintain chronological order



## 📢 Recent Updates

### October 16, 2025 - v1.2.0 Enhanced Binary Detection

Enhanced the bash version with improved binary file detection that correctly handles extensionless text files like LICENSE, README (without .md), CHANGELOG, and other common repository files. The detection now uses a three-tier approach: extensionless file patterns, extension-based detection, and content analysis.

- 📄 [Release Notes](./docs/1.2.0/RELEASE_NOTES.md)

**Key Improvements:**
- ✅ Correctly identifies LICENSE, README, CHANGELOG as text files
- ✅ Enhanced extension-based detection with more file types
- ✅ More accurate binary/text classification
- ✅ Maintains backward compatibility


### October 16, 2025 - v1.1.0 Binary File Handling Patch

A major patch was released to fix binary file extraction in the PowerShell version. Binary files are now extracted byte-for-byte, and UTF-8 text handling is improved. The patch is fully tested and backward compatible.

- 📄 [Patch Summary](./docs/1.1.0/PATCH_SUMMARY.md)


## License

This project is licensed under the same terms as specified in the LICENSE file.

## Contributing

Feel free to submit issues and enhancement requests!
