#!/bin/bash

# Extract-FileVersionsFromGit.sh
# Extract all versions of every file from a Git repository
# 
# This script iterates through every commit in a Git repository and extracts all files
# that existed at each commit. Each extracted file is renamed to include the commit
# date and time in the format: originalname_YYYYMMDD_HHmmss.extension
# 
# Supports filtering commits by date range using --start-date and --end-date parameters.
#
# Requirements:
# - Git installed and accessible via PATH
# - bash 4.0 or later
# - Standard Unix utilities (date, mkdir, etc.)
#
# Author: GitHub Copilot
# Version: 1.0

set -euo pipefail

# Default values
REPOSITORY_PATH="."
OUTPUT_PATH="extracted_files"
INCLUDE_BINARY_FILES=false
MAX_COMMITS=0
START_DATE=""
END_DATE=""
VERBOSE=false

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display help
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Extract all versions of every file from a Git repository.

OPTIONS:
    -r, --repository-path PATH    Path to the Git repository to process (default: current directory)
    -o, --output-path PATH        Directory where extracted files will be saved (default: extracted_files)
    -b, --include-binary-files    Include binary files in extraction (default: false)
    -m, --max-commits NUMBER      Maximum number of commits to process (default: all commits)
    -s, --start-date DATE         Only process commits on or after this date (YYYY-MM-DD format)
    -e, --end-date DATE           Only process commits on or before this date (YYYY-MM-DD format)
    -v, --verbose                 Enable verbose output
    -h, --help                    Show this help message

EXAMPLES:
    $0 -r /path/to/repo -o /path/to/output
    $0 --include-binary-files --max-commits 10
    $0 --start-date 2025-01-01 --end-date 2025-12-31
    $0 --start-date 2025-10-01 --verbose

NOTES:
    - Requires Git to be installed and available in PATH
    - Date format must be YYYY-MM-DD (e.g., 2025-10-14)
    - The script preserves directory structure in the output
    - Binary files are skipped by default unless --include-binary-files is specified

EOF
}

# Function to log messages
log() {
    local level="$1"
    shift
    case "$level" in
        "ERROR")
            echo -e "${RED}ERROR: $*${NC}" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}WARNING: $*${NC}" >&2
            ;;
        "INFO")
            echo -e "${GREEN}$*${NC}"
            ;;
        "VERBOSE")
            if [[ "$VERBOSE" == true ]]; then
                echo -e "${CYAN}VERBOSE: $*${NC}"
            fi
            ;;
        *)
            echo "$*"
            ;;
    esac
}

# Function to check if Git is available
check_git_available() {
    if ! command -v git &> /dev/null; then
        log "ERROR" "Git is not available in PATH. Please install Git and ensure it's accessible."
        return 1
    fi
    return 0
}

# Function to check if a path is a Git repository
check_git_repository() {
    local repo_path="$1"
    local original_dir=$(pwd)
    
    cd "$repo_path" 2>/dev/null || {
        log "ERROR" "Repository path '$repo_path' does not exist."
        return 1
    }
    
    if ! git rev-parse --git-dir &>/dev/null; then
        cd "$original_dir"
        log "ERROR" "Path '$repo_path' is not a Git repository."
        return 1
    fi
    
    cd "$original_dir"
    return 0
}

# Function to validate date format
validate_date() {
    local date_str="$1"
    local date_type="$2"
    
    if [[ -n "$date_str" ]]; then
        if ! date -d "$date_str" &>/dev/null; then
            log "ERROR" "$date_type date '$date_str' is not in valid YYYY-MM-DD format."
            return 1
        fi
    fi
    return 0
}

# Function to compare dates (returns 0 if date1 <= date2, 1 otherwise)
date_compare() {
    local date1="$1"
    local date2="$2"
    
    local timestamp1=$(date -d "$date1" +%s)
    local timestamp2=$(date -d "$date2" +%s)
    
    [[ $timestamp1 -le $timestamp2 ]]
}

# Function to check if a commit date is within the specified range
is_date_in_range() {
    local commit_date="$1"
    
    # Extract just the date part (YYYY-MM-DD) from commit datetime
    local commit_date_only=$(echo "$commit_date" | cut -d' ' -f1)
    
    # Check start date
    if [[ -n "$START_DATE" ]]; then
        if ! date_compare "$START_DATE" "$commit_date_only"; then
            return 1
        fi
    fi
    
    # Check end date
    if [[ -n "$END_DATE" ]]; then
        if ! date_compare "$commit_date_only" "$END_DATE"; then
            return 1
        fi
    fi
    
    return 0
}

# Function to get all commits in chronological order
get_all_commits() {
    local repo_path="$1"
    local original_dir=$(pwd)
    
    cd "$repo_path"
    
    # Build git log command
    local git_args=("log" "--pretty=format:%H|%ci|%s" "--reverse")
    
    if [[ $MAX_COMMITS -gt 0 ]]; then
        git_args+=("-n" "$MAX_COMMITS")
    fi
    
    # Get commits and filter by date range
    local commits=()
    while IFS='|' read -r hash datetime message; do
        if [[ -n "$hash" && -n "$datetime" ]]; then
            if is_date_in_range "$datetime"; then
                commits+=("$hash|$datetime|$message")
            fi
        fi
    done < <(git "${git_args[@]}" 2>/dev/null || true)
    
    cd "$original_dir"
    
    # Return commits array
    printf '%s\n' "${commits[@]}"
}

# Function to get all files in a specific commit
get_files_in_commit() {
    local repo_path="$1"
    local commit_hash="$2"
    local original_dir=$(pwd)
    
    cd "$repo_path"
    
    local files
    files=$(git ls-tree -r --name-only "$commit_hash" 2>/dev/null || true)
    
    cd "$original_dir"
    
    echo "$files"
}

# Function to check if a file is binary
is_binary_file() {
    local repo_path="$1"
    local commit_hash="$2"
    local file_path="$3"
    local original_dir=$(pwd)
    
    cd "$repo_path"
    
    # Get file content and check for null bytes
    if git show "${commit_hash}:${file_path}" 2>/dev/null | grep -q $'\0'; then
        cd "$original_dir"
        return 0  # Is binary
    fi
    
    cd "$original_dir"
    return 1  # Is not binary
}

# Function to extract a file from a specific commit
extract_file_from_commit() {
    local repo_path="$1"
    local commit_hash="$2"
    local file_path="$3"
    local output_dir="$4"
    local commit_datetime="$5"
    local original_dir=$(pwd)
    
    cd "$repo_path"
    
    # Format the timestamp
    local timestamp=$(date -d "$commit_datetime" +"%Y%m%d_%H%M%S")
    
    # Get file extension and base name
    local dir_name=$(dirname "$file_path")
    local base_name=$(basename "$file_path")
    local extension=""
    local name_without_ext="$base_name"
    
    if [[ "$base_name" == *.* ]]; then
        extension=".${base_name##*.}"
        name_without_ext="${base_name%.*}"
    fi
    
    # Create new filename with timestamp
    local new_filename="${name_without_ext}_${timestamp}${extension}"
    
    # Preserve directory structure
    local output_subdir="$output_dir"
    if [[ "$dir_name" != "." ]]; then
        output_subdir="$output_dir/$dir_name"
        mkdir -p "$output_subdir"
    fi
    
    # Full output path
    local output_file_path="$output_subdir/$new_filename"
    
    # Extract the file from the commit
    if git show "${commit_hash}:${file_path}" > "$output_file_path" 2>/dev/null; then
        cd "$original_dir"
        echo "$output_file_path"
        return 0
    else
        cd "$original_dir"
        log "WARN" "Failed to extract file '$file_path' from commit $commit_hash"
        return 1
    fi
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--repository-path)
                REPOSITORY_PATH="$2"
                shift 2
                ;;
            -o|--output-path)
                OUTPUT_PATH="$2"
                shift 2
                ;;
            -b|--include-binary-files)
                INCLUDE_BINARY_FILES=true
                shift
                ;;
            -m|--max-commits)
                MAX_COMMITS="$2"
                shift 2
                ;;
            -s|--start-date)
                START_DATE="$2"
                shift 2
                ;;
            -e|--end-date)
                END_DATE="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Main function
main() {
    parse_arguments "$@"
    
    log "INFO" "Git File Version Extractor"
    log "INFO" "========================="
    
    # Validate Git availability
    if ! check_git_available; then
        exit 1
    fi
    
    # Validate repository path
    if ! check_git_repository "$REPOSITORY_PATH"; then
        exit 1
    fi
    
    # Validate date formats
    if ! validate_date "$START_DATE" "Start" || ! validate_date "$END_DATE" "End"; then
        exit 1
    fi
    
    # Create output directory
    mkdir -p "$OUTPUT_PATH"
    
    # Resolve full paths
    local repo_full_path=$(realpath "$REPOSITORY_PATH")
    local output_full_path=$(realpath "$OUTPUT_PATH")
    
    # Display configuration
    echo -e "${CYAN}Repository: $repo_full_path${NC}"
    echo -e "${CYAN}Output Directory: $output_full_path${NC}"
    echo -e "${CYAN}Include Binary Files: $INCLUDE_BINARY_FILES${NC}"
    
    if [[ $MAX_COMMITS -gt 0 ]]; then
        echo -e "${CYAN}Max Commits: $MAX_COMMITS${NC}"
    fi
    
    if [[ -n "$START_DATE" ]]; then
        echo -e "${CYAN}Start Date: $START_DATE${NC}"
    fi
    
    if [[ -n "$END_DATE" ]]; then
        echo -e "${CYAN}End Date: $END_DATE${NC}"
    fi
    
    echo ""
    
    # Get all commits
    log "INFO" "Retrieving commit history..."
    
    local commits
    readarray -t commits < <(get_all_commits "$repo_full_path")
    
    local commit_count=${#commits[@]}
    log "INFO" "Found $commit_count commits to process."
    
    if [[ $commit_count -eq 0 ]]; then
        log "WARN" "No commits found in repository."
        exit 0
    fi
    
    # Process each commit
    local total_files=0
    local processed_files=0
    local skipped_files=0
    
    for ((i=0; i<commit_count; i++)); do
        local commit="${commits[i]}"
        local progress=$(( (i + 1) * 100 / commit_count ))
        
        IFS='|' read -r commit_hash commit_datetime commit_message <<< "$commit"
        local short_hash="${commit_hash:0:8}"
        
        # Format datetime for display
        local display_datetime=$(date -d "$commit_datetime" "+%Y-%m-%d %H:%M:%S")
        
        echo -e "${CYAN}Processing commit $((i+1))/$commit_count: $short_hash - $display_datetime${NC}"
        
        # Get files in this commit
        local files
        readarray -t files < <(get_files_in_commit "$repo_full_path" "$commit_hash")
        
        # Filter out empty lines
        local filtered_files=()
        for file in "${files[@]}"; do
            if [[ -n "$file" ]]; then
                filtered_files+=("$file")
            fi
        done
        
        total_files=$((total_files + ${#filtered_files[@]}))
        
        for file in "${filtered_files[@]}"; do
            # Check if file is binary (skip if not including binary files)
            if [[ "$INCLUDE_BINARY_FILES" == false ]]; then
                if is_binary_file "$repo_full_path" "$commit_hash" "$file"; then
                    log "VERBOSE" "Skipping binary file: $file"
                    skipped_files=$((skipped_files + 1))
                    continue
                fi
            fi
            
            # Extract the file
            if extracted_path=$(extract_file_from_commit "$repo_full_path" "$commit_hash" "$file" "$output_full_path" "$commit_datetime"); then
                processed_files=$((processed_files + 1))
                log "VERBOSE" "Extracted: $file -> $extracted_path"
            else
                skipped_files=$((skipped_files + 1))
            fi
        done
    done
    
    # Summary
    echo ""
    log "INFO" "Extraction Complete!"
    log "INFO" "==================="
    echo "Total files found: $total_files"
    echo -e "${GREEN}Files processed: $processed_files${NC}"
    echo -e "${YELLOW}Files skipped: $skipped_files${NC}"
    echo -e "${CYAN}Output directory: $output_full_path${NC}"
    
    return 0
}

# Execute main function with all arguments
main "$@"