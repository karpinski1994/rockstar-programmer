$inputDir = Read-Host "📂 Enter the path to the folder you want to scan"

# Resolve to full absolute path
try {
  $resolvedPath = Resolve-Path -Path $inputDir -ErrorAction Stop
} catch {
  Write-Error "❌ Error: Invalid or non-existent folder path."
  exit
}

$resolvedPath = $resolvedPath.Path

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

$baseOutputName = "$(Split-Path $resolvedPath -Leaf)-merged-text"
$outputFile = "$baseOutputName.txt"
$counter = 1

while (Test-Path $outputFile) {
  $outputFile = "$baseOutputName($counter).txt"
  $counter++
}

Write-Output "🔍 Scanning and merging files..."
"" | Set-Content $outputFile

Get-ChildItem -Path $resolvedPath -Recurse -File | ForEach-Object {
  $file = $_.FullName
  $fileName = $_.Name
  $ext = $_.Extension

  # Skip files in excluded folders
  foreach ($folder in $excludedFolders) {
    if ($file -match "\\$folder(\\|$)") {
      return
    }
  }

  if ($excludedFiles -contains $fileName) {
    return
  }

  if ($extensions -notcontains $ext) {
    return
  }

  "`n`n// File: $file" | Add-Content $outputFile
  Get-Content $file | Add-Content $outputFile
}

Write-Output "✅ Merged files into `"$outputFile`""
