#!/bin/zsh

# file_mover.zsh - Script to move files of specific types from multiple directories to a destination
# Usage: ./file_mover.zsh

# Function to display usage information
show_help() {
  echo "File Mover - Move files of specific types from source directories to a destination."
  echo ""
  echo "Usage:"
  echo "  1. Enter source directories (comma-separated)"
  echo "  2. Specify file extensions (comma-separated or 'all' for all files)"
  echo "  3. Enter destination directory"
  echo ""
}

# Function to validate directory existence
validate_directory() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    echo "Error: Directory '$dir' does not exist."
    return 1
  fi
  return 0
}

# Show banner
echo "========================================="
echo "File Mover Script"
echo "========================================="
show_help

# Get source directories
echo -n "Enter source directories (comma-separated): "
read source_dirs_input
IFS=',' read -A source_dirs <<< "$source_dirs_input"

# Validate source directories
valid_sources=()
for dir in "${source_dirs[@]}"; do
  dir=$(echo "$dir" | sed 's/^[[:space:]]*//g; s/[[:space:]]*$//g')
  if validate_directory "$dir"; then
    valid_sources+=("$(cd "$dir" && pwd)")
  else
    echo "Skipping invalid directory: $dir"
  fi
done

if [[ ${#valid_sources[@]} -eq 0 ]]; then
  echo "Error: No valid source directories provided."
  exit 1
fi

# Get file extensions
echo -n "Enter file extensions to move (comma-separated, or 'all' for all files): "
read extensions_input
if [[ "$extensions_input" == "all" ]]; then
  use_all_files=true
else
  use_all_files=false
  IFS=',' read -A extensions <<< "$extensions_input"
  for i in "${!extensions[@]}"; do
    ext="${extensions[$i]}"
    ext=$(echo "$ext" | sed 's/^[[:space:]]*//g; s/[[:space:]]*$//g')
    [[ "$ext" != .* && "$ext" != "" ]] && extensions[$i]=".$ext"
  done
fi

# Get destination directory
echo -n "Enter destination directory: "
read destination
if ! validate_directory "$destination"; then
  echo -n "Destination directory doesn't exist. Create it? (y/n): "
  read create_dest
  if [[ "$create_dest" =~ ^[Yy]$ ]]; then
    mkdir -p "$destination" || { echo "Error: Failed to create destination."; exit 1; }
    echo "Created destination: $destination"
  else
    echo "Operation cancelled."
    exit 1
  fi
fi
destination=$(cd "$destination" && pwd)

# Move or copy
echo -n "Move files (m) or copy (c)? [m/c]: "
read op
if [[ "$op" =~ ^[Mm]$ ]]; then
  move_files=true
  echo "Will move files."
else
  move_files=false
  echo "Will copy files."
fi

# Display mode
echo -n "Detailed output or single progress bar? [d/s]: "
read dm
if [[ "$dm" =~ ^[Dd]$ ]]; then
  detailed=true
else
  detailed=false
fi
verbose_flag="$([ "$detailed" = true ] && echo -v || echo "")"

# Counters and file list
total=0
processed=0
errors=0
file_list=()

# Progress function
show_progress(){
  local c=$1; local t=$2; local p=0
  (( t>0 )) && p=$((c * 100 / t))
  local done=$((p/2)); local left=$((50-done))
  local bar="$(printf '%0.s#' $(seq 1 $done))"
  bar+="$(printf '%0.s ' $(seq 1 $left))"
  printf "\rProgress: [%s] %d%% (%d/%d)" "$bar" "$p" "$c" "$t"
}

# First pass: count files
echo "Counting files..."
for d in "${valid_sources[@]}"; do
  if $use_all_files; then
    cnt=$(find "$d" -type f | wc -l)
    total=$((total+cnt))
  else
    for e in "${extensions[@]}"; do
      [[ "$e" ]] && cnt=$(find "$d" -type f -name "*${e}" | wc -l) && total=$((total+cnt))
    done
  fi
done
echo "Found $total files."

# Second pass: process files
curr=0
for d in "${valid_sources[@]}"; do
  [[ "$d" = "$destination" ]] && continue

  # build find command
  find_cmd=(find "$d" -type f)
  if ! $use_all_files; then
    find_cmd+=('\(')
    for e in "${extensions[@]}"; do [[ "$e" ]] && find_cmd+=(-name "*${e}" -o); done
    unset 'find_cmd[${#find_cmd[@]}-1]'
    find_cmd+=('\)')
  fi
  find_cmd+=(-print0)

  while IFS= read -r -d '' f; do
    bn=$(basename "$f")
    destf="$destination/$bn"
    [[ -f "$destf" ]] && destf="$destination/$(date +%Y%m%d%H%M%S)_$bn"

    if $move_files; then
      if mv $verbose_flag "$f" "$destf"; then
        file_list+=("$bn")
      else
        errors=$((errors+1)); $detailed && echo "Error moving $f"
      fi
    else
      if cp $verbose_flag "$f" "$destf"; then
        file_list+=("$bn")
      else
        errors=$((errors+1)); $detailed && echo "Error copying $f"
      fi
    fi

    processed=$((processed+1))
    curr=$((curr+1))
    show_progress $curr $total
  done < <("${find_cmd[@]}")
done

echo "\nDone. Processed: $processed, Errors: $errors"

# Prompt to write list
echo -n "Create list-files.txt of processed names? (y/n): "
read save_list
if [[ "$save_list" =~ ^[Yy]$ ]]; then
  printf "%s\n" "${file_list[@]}" > "$destination/list-files.txt"
  echo "Saved list to $destination/list-files.txt"
fi

echo "All finished."
