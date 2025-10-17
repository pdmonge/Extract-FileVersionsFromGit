# Binary File Handling - Quick Reference

## What Changed?

### Before (BROKEN for binary files)
```powershell
function Export-FileFromCommit {
    # ... setup code ...
    
    # Extract file
    $fileContent = git show "${CommitHash}:${FilePath}"
    
    # ❌ PROBLEM: This corrupts binary files!
    $fileContent | Out-File -FilePath $outputFilePath -Encoding UTF8
}
```

### After (FIXED)
```powershell
function Export-FileFromCommit {
    param(
        # ... existing params ...
        [bool]$IsBinary = $false  # ✅ NEW parameter
    )
    
    # ... setup code ...
    
    if ($IsBinary) {
        # ✅ Binary files: Use cmd.exe for byte-safe extraction
        $tempScript = [System.IO.Path]::GetTempFileName() + ".cmd"
        "@echo off`ngit show `"${CommitHash}:${FilePath}`" > `"$outputFilePath`" 2>nul" | 
            Out-File -FilePath $tempScript -Encoding ASCII
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$tempScript`"" -Wait
        Remove-Item $tempScript
    } else {
        # ✅ Text files: Use PowerShell UTF8 encoding
        $fileContent = git show "${CommitHash}:${FilePath}"
        $fileContent | Out-File -FilePath $outputFilePath -Encoding UTF8
    }
}
```

## Why This Works

| Aspect | Text Files | Binary Files |
|--------|-----------|--------------|
| **Method** | PowerShell pipeline | CMD redirection |
| **Encoding** | UTF8 | None (raw bytes) |
| **Data Integrity** | Characters preserved | Bytes preserved |
| **Use Case** | .txt, .md, .cs, .js | .png, .pdf, .exe, .zip |

## Usage Examples

### Extract text files only (default)
```powershell
.\Extract-FileVersionsFromGit.ps1 -RepositoryPath "C:\MyRepo"
# Only text files extracted, binary files skipped
```

### Extract ALL files including binaries
```powershell
.\Extract-FileVersionsFromGit.ps1 -RepositoryPath "C:\MyRepo" -IncludeBinaryFiles
# ✅ Text files: UTF8 encoded
# ✅ Binary files: Byte-perfect copies
```

## Key Benefits

1. ✅ **No corruption**: Binary files extracted byte-for-byte
2. ✅ **Backward compatible**: Text files work as before
3. ✅ **Simple**: Automatic detection and handling
4. ✅ **Safe**: Temp files cleaned up properly

## Common File Types

### Handled as Text
- `.txt`, `.md`, `.csv`
- `.js`, `.ts`, `.py`, `.ps1`, `.sh`
- `.html`, `.css`, `.xml`, `.json`, `.yaml`
- `.c`, `.cpp`, `.cs`, `.java`, `.go`

### Handled as Binary (when `-IncludeBinaryFiles` used)
- Images: `.png`, `.jpg`, `.gif`, `.bmp`, `.ico`
- Documents: `.pdf`, `.docx`, `.xlsx`
- Archives: `.zip`, `.7z`, `.tar`, `.gz`
- Executables: `.exe`, `.dll`, `.so`
- Media: `.mp3`, `.mp4`, `.avi`
