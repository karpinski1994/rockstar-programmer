# Prompt user for input directory
$inputDir = Read-Host "Enter the path to the folder you want to scan"

# Resolve full absolute path or exit on error
try {
    $resolvedPath = Resolve-Path -Path $inputDir -ErrorAction Stop
} catch {
    Write-Host " Error: Invalid or non-existent folder path." -ForegroundColor Red
    exit 1
}
$resolvedPath = $resolvedPath.Path

# Lists of files, folders, and extensions to exclude
$excludedFiles = @(
    "package-lock.json", "yarn.lock", "pnpm-lock.yaml",
    ".env", ".env.local", ".env.development", ".env.production", ".env.test",
    "tsconfig.json", "vite.config.js", "vite.config.ts",
    "webpack.config.js", "webpack.config.ts",
    ".gitignore", ".dockerignore", ".npmignore", "README.md"
)

$excludedFolders = @(
    "node_modules", ".git", ".github", "dist", "build",
    "out", ".cache", "coverage", "logs", "tmp"
)

$extensions = @(
    ".js", ".ts", ".tsx", ".jsx", ".json", ".html", ".css",
    ".scss", ".sass", ".less", ".vue", ".svelte", ".md",
    ".yml", ".yaml", ".cjs", ".mjs", ".graphql", ".ng"
)

# Prepare output file name - avoid overwriting existing files
$baseOutputName = "$(Split-Path $resolvedPath -Leaf)-merged-text"
$outputFile = "$baseOutputName.txt"
$counter = 1
while (Test-Path $outputFile) {
    $outputFile = "$baseOutputName($counter).txt"
    $counter++
}

Write-Host "🔍 Scanning and merging files..." -ForegroundColor Cyan

# Clear/create output file with UTF8 encoding
"" | Set-Content -Path $outputFile -Encoding UTF8

# Iterate files recursively
Get-ChildItem -Path $resolvedPath -Recurse -File | ForEach-Object {
    $file = $_.FullName
    $fileName = $_.Name
    $ext = $_.Extension.ToLower()

    # Skip files in excluded folders (case-insensitive)
    foreach ($folder in $excludedFolders) {
        # Fix path matching to Windows style and ignore case
        if ($file.ToLower() -like "*\$folder*") {
            return
        }
    }

    # Skip excluded files (exact name match)
    if ($excludedFiles -contains $fileName) {
        return
    }

    # Skip files with extensions not in the allowed list
    if ($extensions -notcontains $ext) {
        return
    }

    # Append file name as comment and file contents (re-typed for cleanliness)
    Add-Content -Path $outputFile -Value "`n`n// File: $file" -Encoding UTF8
    Get-Content -Path $file | Add-Content -Path $outputFile -Encoding UTF8
}

# Add back the completion message, re-typed for cleanliness
Write-Host "Merging complete. Output file: '$outputFile'" -ForegroundColor Green
