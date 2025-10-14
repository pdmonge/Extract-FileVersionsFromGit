# Extract-FileVersionsFromGit (Bash Version)

A bash script that extracts every version of every file that ever existed in a Git repository. Each extracted file is renamed by appending the date and time of the commit that included it to the base filename in the format `_YYYYMMDD_HHmmss`.

This is the Unix/Linux/macOS equivalent of the PowerShell version, providing the same functionality with bash-native implementation.

## Features

- **Complete History Extraction**: Processes every commit in chronological order (oldest first)
- **Smart File Naming**: Appends commit timestamp to filenames (e.g., `file.txt` becomes `file_20251014_154738.txt`)
- **Directory Structure Preservation**: Maintains the original folder structure in the output
- **Date Range Filtering**: Extract files only from commits within a specified date range
- **Binary File Handling**: Option to include or exclude binary files from extraction
- **Progress Reporting**: Shows real-time progress with commit processing status
- **Colored Output**: User-friendly colored terminal output for better readability
- **Verbose Mode**: Optional detailed logging for troubleshooting
- **Cross-Platform**: Works on Linux, macOS, and Windows (via WSL/Git Bash)

## Requirements

- **Git**: Must be installed and accessible via PATH
- **Bash**: Version 4.0 or later
- **Standard Unix utilities**: `date`, `mkdir`, `grep`, `cut`, `dirname`, `basename`, `realpath`
- **Operating System**: Linux, macOS, or Windows with WSL/Git Bash

## Installation

1. Download the script:
   ```bash
   wget https://raw.githubusercontent.com/pdmonge/Extract-FileVersionsFromGit/main/bash/extract-file-versions-from-git.sh
   ```

2. Make it executable:
   ```bash
   chmod +x extract-file-versions-from-git.sh
   ```

3. Optionally, move to a directory in your PATH:
   ```bash
   sudo mv extract-file-versions-from-git.sh /usr/local/bin/
   ```

## Usage

### Basic Syntax

```bash
./extract-file-versions-from-git.sh [OPTIONS]
```

### Command Line Options

| Option | Long Form | Type | Default | Description |
|--------|-----------|------|---------|-------------|
| `-r` | `--repository-path` | String | `.` (current directory) | Path to the Git repository to process |
| `-o` | `--output-path` | String | `extracted_files` | Directory where extracted files will be saved |
| `-b` | `--include-binary-files` | Switch | `false` | Include binary files in extraction |
| `-m` | `--max-commits` | Integer | `0` (all commits) | Maximum number of commits to process |
| `-s` | `--start-date` | Date | (none) | Only process commits on or after this date |
| `-e` | `--end-date` | Date | (none) | Only process commits on or before this date |
| `-v` | `--verbose` | Switch | `false` | Enable verbose output |
| `-h` | `--help` | Switch | - | Show help message |

### Date Format

All dates must be in **YYYY-MM-DD** format (e.g., `2025-10-14`).

## Examples

### Basic Usage

Extract all files from the current directory repository:
```bash
./extract-file-versions-from-git.sh
```

### Specify Repository and Output Paths

```bash
./extract-file-versions-from-git.sh -r /path/to/repo -o /path/to/output
```

### Include Binary Files

```bash
./extract-file-versions-from-git.sh --include-binary-files
```

### Limit Processing for Testing

```bash
./extract-file-versions-from-git.sh --max-commits 10
```

### Enable Verbose Output

```bash
./extract-file-versions-from-git.sh --verbose
```

### Date Range Examples

Extract files from commits in the last month:
```bash
./extract-file-versions-from-git.sh --start-date 2025-09-01 --end-date 2025-09-30
```

Extract files from commits after a specific date:
```bash
./extract-file-versions-from-git.sh --start-date 2025-10-01
```

Extract files from commits before a specific date:
```bash
./extract-file-versions-from-git.sh --end-date 2025-12-31
```

Extract files from a specific date range with binary files included:
```bash
./extract-file-versions-from-git.sh -s 2025-01-01 -e 2025-12-31 -b -v
```

### Complex Example

Process a specific repository with multiple options:
```bash
./extract-file-versions-from-git.sh \
  --repository-path /home/user/projects/myrepo \
  --output-path /tmp/extracted_versions \
  --include-binary-files \
  --start-date 2025-01-01 \
  --end-date 2025-10-31 \
  --max-commits 100 \
  --verbose
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

1. **Argument Parsing**: Processes command-line options and validates inputs
2. **Repository Validation**: Verifies that the specified path is a valid Git repository
3. **Date Validation**: Ensures date parameters are in correct YYYY-MM-DD format
4. **Commit Enumeration**: Retrieves all commits in chronological order (oldest first)
5. **Date Range Filtering**: Optionally filters commits to only include those within the specified date range
6. **File Discovery**: For each commit, identifies all files that existed at that point
7. **Binary Detection**: Optionally filters out binary files based on null byte detection
8. **File Extraction**: Extracts each file version using `git show`
9. **Timestamp Formatting**: Formats commit date/time into the filename
10. **Directory Structure**: Preserves the original directory structure in the output

## Error Handling

The script includes comprehensive error handling for:

- **Invalid arguments**: Clear error messages for unknown options
- **Missing Git**: Checks if Git is installed and accessible
- **Invalid repository**: Validates the repository path and Git status
- **Date format errors**: Validates date format before processing
- **File extraction failures**: Graceful handling of individual file extraction errors
- **Permission issues**: Clear error messages for file system permission problems

## Troubleshooting

### Git Not Found

Ensure Git is installed and available in your PATH:
```bash
git --version
```

### Permission Denied

Make sure the script is executable:
```bash
chmod +x extract-file-versions-from-git.sh
```

### Invalid Date Format

Dates must be in YYYY-MM-DD format:
```bash
# Correct
./extract-file-versions-from-git.sh --start-date 2025-10-14

# Incorrect
./extract-file-versions-from-git.sh --start-date 10/14/2025  # Wrong format
```

### Large Repositories

For very large repositories, consider using the `--max-commits` option to test with a subset first:
```bash
./extract-file-versions-from-git.sh --max-commits 50
```

### Binary Files

By default, binary files are skipped. To include them, use the `--include-binary-files` option. Note that this may significantly increase output size and processing time.

### Verbose Output

Use the `--verbose` flag to see detailed information about what the script is doing:
```bash
./extract-file-versions-from-git.sh --verbose
```

## Performance Considerations

- **Processing time** depends on repository size and number of commits
- **Binary files** significantly increase extraction time and disk usage
- **Date filtering** can dramatically reduce processing time for large repositories
- **Disk space** requirements scale with the number of file versions
- Use `--max-commits` for testing on large repositories

## Differences from PowerShell Version

### Similarities
- **Same functionality**: All features from the PowerShell version are implemented
- **Same output format**: Identical file naming and directory structure
- **Same date filtering**: Compatible date range filtering
- **Same binary detection**: Uses null byte detection method

### Differences
- **Command-line syntax**: Uses Unix-style options (`-r`, `--repository-path`)
- **Date format**: Requires YYYY-MM-DD format (more standardized)
- **Colored output**: Native terminal color support
- **Error handling**: Uses bash-native error handling patterns
- **Path handling**: Uses Unix path conventions and `realpath`

## Platform Compatibility

### Linux
✅ **Native support** - Works on all major distributions

### macOS
✅ **Native support** - Works with system bash or newer versions via Homebrew

### Windows
✅ **WSL support** - Works in Windows Subsystem for Linux
✅ **Git Bash support** - Works in Git for Windows bash environment
⚠️ **PowerShell recommended** - Use the PowerShell version for native Windows experience

## Contributing

When contributing to the bash version:

1. **Follow bash best practices**: Use `set -euo pipefail`, proper quoting, etc.
2. **Maintain compatibility**: Test on multiple platforms (Linux, macOS, WSL)
3. **Update documentation**: Keep this README in sync with code changes
4. **Cross-reference**: Ensure feature parity with the PowerShell version

## License

This project is licensed under the same terms as specified in the main LICENSE file.

## See Also

- **PowerShell version**: See the parent directory for the Windows PowerShell implementation
- **Main README**: See the root README.md for general project information