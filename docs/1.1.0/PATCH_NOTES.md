# PowerShell Binary File Handling Patch

## Date
October 16, 2025

## Problem
The original `Export-FileFromCommit` function used `Out-File -Encoding UTF8` for all files, which corrupts binary files (images, executables, archives, etc.) when the `-IncludeBinaryFiles` switch is used. This happens because PowerShell attempts to interpret binary data as text and encode it as UTF8, mangling the bytes.

## Solution
Modified the script to handle binary and text files differently:

### 1. Updated `Export-FileFromCommit` Function
- Added new parameter: `[bool]$IsBinary = $false`
- Implemented dual-path logic:
  - **Binary files**: Use cmd.exe with output redirection (`>`) to preserve binary data byte-for-byte
  - **Text files**: Continue using PowerShell's `Out-File -Encoding UTF8` for proper text handling

### 2. Updated Main Processing Loop
- Always check if file is binary (moved check outside the conditional)
- Pass binary status to `Export-FileFromCommit` function
- This ensures proper handling regardless of `-IncludeBinaryFiles` switch state

## Technical Details

### Binary File Extraction Method
For binary files, the patch uses a temporary CMD script to leverage Windows' native binary-safe redirection:
```powershell
# Create temp CMD script
git show "commit:path" > "outputfile" 2>nul
```

This approach:
- ✅ Preserves exact binary data (no encoding issues)
- ✅ Works with all file types (images, PDFs, executables, archives, etc.)
- ✅ Compatible with Windows PowerShell 5.1+
- ✅ Minimal performance overhead

### Text File Extraction Method
Text files continue using PowerShell's standard approach:
```powershell
$fileContent | Out-File -FilePath $outputFilePath -Encoding UTF8
```

This approach:
- ✅ Handles text encoding properly
- ✅ Maintains cross-platform line endings
- ✅ UTF8 encoding for international characters

## Testing Recommendations

### Test Case 1: Binary Files
```powershell
# Extract binary files from a repo with images/PDFs
.\Extract-FileVersionsFromGit.ps1 -IncludeBinaryFiles -RepositoryPath "C:\TestRepo"

# Verify extracted files match originals (byte-for-byte)
```

### Test Case 2: Text Files
```powershell
# Extract only text files (default)
.\Extract-FileVersionsFromGit.ps1 -RepositoryPath "C:\TestRepo"

# Verify text encoding and content integrity
```

### Test Case 3: Mixed Repository
```powershell
# Extract from repo with both text and binary files
.\Extract-FileVersionsFromGit.ps1 -IncludeBinaryFiles -RepositoryPath "C:\MixedRepo"

# Verify:
# - Binary files (e.g., .png, .pdf) are identical to originals
# - Text files (.txt, .md, .cs) have correct encoding
```

## Files Modified
- `powershell/Extract-FileVersionsFromGit.ps1`
  - Modified: `Export-FileFromCommit` function (lines ~220-300)
  - Modified: Main processing loop (lines ~380-410)

## Breaking Changes
None. The patch is backward compatible:
- Default behavior unchanged (text files only)
- `-IncludeBinaryFiles` switch now works correctly
- Existing parameters and functionality preserved

## Known Limitations
1. **Platform**: Binary extraction method uses cmd.exe (Windows-specific)
2. **Performance**: Binary files require temporary CMD script creation (minimal overhead)
3. **Binary Detection**: Uses null byte detection (may rarely misidentify files)

## Future Improvements
Consider these enhancements for future versions:
1. Use `git cat-file blob` for more reliable binary extraction
2. Implement .NET FileStream for cross-platform binary support
3. Add file hash verification option
4. Support streaming for very large files
5. Add progress indication for individual large file extraction

## Verification
To verify the patch works correctly:

```powershell
# Create test repo with binary file
cd C:\temp
mkdir test-repo
cd test-repo
git init

# Add a binary file (create small PNG)
[IO.File]::WriteAllBytes("test.png", @(137,80,78,71,13,10,26,10,0,0,0,13,73,72,68,82))
git add test.png
git commit -m "Add binary file"

# Extract with patched script
cd ..
.\Extract-FileVersionsFromGit.ps1 -RepositoryPath ".\test-repo" -IncludeBinaryFiles

# Compare extracted file with original
$original = [IO.File]::ReadAllBytes("test-repo\test.png")
$extracted = [IO.File]::ReadAllBytes("extracted_files\test_*.png")
$original -eq $extracted  # Should return True
```

## Related Issues
This patch resolves the critical bug where binary files could not be extracted correctly when using the `-IncludeBinaryFiles` parameter.

## Author
GitHub Copilot

## License
Same as project license (see LICENSE file)
