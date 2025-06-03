#!/bin/bash

# === CONFIGURATION ===

extensions=("tsx")

excluded_files=(
  "package-lock.json" "yarn.lock" "pnpm-lock.yaml"
  ".env" ".env.local" ".env.development" ".env.production" ".env.test"
  "tsconfig.json" "vite.config.js" "vite.config.ts"
  "webpack.config.js" "webpack.config.ts"
  ".gitignore" ".dockerignore" ".npmignore" "README.md"
)

excluded_dirs=(
  "node_modules" ".git" ".github" "dist" "build"
  "out" ".cache" "coverage" "logs" "tmp"
)

excluded_exts=("lock" "pem" "key" "p12" "crt" "cert" "log")

# === FUNCTIONS ===

should_include_file() {
  local file="$1"
  local filename
  filename=$(basename "$file")
  local ext="${filename##*.}"

  for inc_ext in "${extensions[@]}"; do
    if [[ "$filename" == *.$inc_ext ]]; then
      for excl_file in "${excluded_files[@]}"; do
        [[ "$filename" == "$excl_file" ]] && return 1
      done
      for excl_ext in "${excluded_exts[@]}"; do
        [[ "$ext" == "$excl_ext" ]] && return 1
      done
      return 0
    fi
  done
  return 1
}

get_unique_filename() {
  local base="$1"
  local name="${base}.txt"
  local count=1
  while [[ -e "$name" ]]; do
    name="${base}(${count}).txt"
    ((count++))
  done
  echo "$name"
}

collect_files() {
  local dir="$1"
  find "$dir" -type f | while read -r file; do
    local skip=false
    for excl_dir in "${excluded_dirs[@]}"; do
      if [[ "$file" == *"/$excl_dir/"* ]]; then
        skip=true
        break
      fi
    done
    $skip && continue
    should_include_file "$file" && echo "$file"
  done
}

# === MAIN SCRIPT ===

read -rp "📂 Enter the path to the folder you want to scan: " input_dir

# Resolve to absolute path
input_dir=$(realpath "$input_dir" 2>/dev/null)

if [[ ! -d "$input_dir" ]]; then
  echo "❌ Error: Invalid or non-existent folder path."
  exit 1
fi

folder_name=$(basename "$input_dir")
base_output="${folder_name}-merged-text"
output_file=$(get_unique_filename "$base_output")

echo "🔍 Scanning and merging files..."

> "$output_file"  # Clear file
file_count=0

while IFS= read -r file; do
  {
    echo -e "\n\n/* =============================================="
    echo "   FILE: $file"
    echo -e "   ============================================== */"
    echo
    cat "$file"
    echo
  } >> "$output_file"
  ((file_count++))
done < <(collect_files "$input_dir")

echo "✅ Merged $file_count files into \"$output_file\""
