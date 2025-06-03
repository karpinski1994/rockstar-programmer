const fs = require('fs');
const path = require('path');
const readline = require('readline');

// Extensions to include
const extensions = [
  '.tsx',
];

// Filenames to exclude (case-sensitive)
const excludedFiles = [
  'package-lock.json',
  'yarn.lock',
  'pnpm-lock.yaml',
  '.env',
  '.env.local',
  '.env.development',
  '.env.production',
  '.env.test',
  'tsconfig.json',
  'vite.config.js',
  'vite.config.ts',
  'webpack.config.js',
  'webpack.config.ts',
  '.gitignore',
  '.dockerignore',
  '.npmignore',
  'README.md',
];

// Folders to skip
const excludedFolders = [
  'node_modules',
  '.git',
  '.github',
  'dist',
  'build',
  'out',
  '.cache',
  'coverage',
  'logs',
  'tmp',
];

const excludedExtensions = [
  '.lock',
  '.pem',
  '.key',
  '.p12',
  '.crt',
  '.cert',
  '.log',
];

function collectFiles(dir) {
  let allFiles = [];

  try {
    const entries = fs.readdirSync(dir, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);

      if (entry.isDirectory()) {
        if (excludedFolders.includes(entry.name) || entry.name.startsWith('.') || excludedExtensions.includes(entry.name)) continue;
        allFiles = allFiles.concat(collectFiles(fullPath));
      } else {
        const ext = path.extname(entry.name);
        const fileName = entry.name;

        if (
          extensions.includes(ext) &&
          !excludedFiles.includes(fileName)
        ) {
          allFiles.push(fullPath);
        }
      }
    }
  } catch (err) {
    console.error(`Error reading directory ${dir}:`, err);
  }

  return allFiles;
}

// Generate unique output file name
function getUniqueOutputFileName(baseName) {
  let fileName = `${baseName}.txt`;
  let counter = 1;

  while (fs.existsSync(fileName)) {
    fileName = `${baseName}(${counter}).txt`;
    counter++;
  }

  return fileName;
}

function mergeFiles(inputDir, outputFile) {
  const files = collectFiles(inputDir);
  let mergedContent = '';

  for (const file of files) {
    try {
      const content = fs.readFileSync(file, 'utf-8');
      mergedContent += `\n\n// File: ${file}\n${content}\n`;
    } catch (err) {
      console.error(`Failed to read ${file}:`, err);
    }
  }

  fs.writeFileSync(outputFile, mergedContent);
  console.log(`✅ Merged ${files.length} files into "${outputFile}"`);
}

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

rl.question('📂 Enter the path to the folder you want to scan: ', (inputDir) => {
  const resolvedPath = path.resolve(inputDir); // <--- this resolves ../ to an absolute path

  if (!fs.existsSync(resolvedPath) || !fs.lstatSync(resolvedPath).isDirectory()) {
    console.error('❌ Error: Invalid or non-existent folder path.');
    rl.close();
    return;
  }

  const folderName = path.basename(resolvedPath);
  const baseOutputName = `${folderName}-merged-text`;
  const outputFile = getUniqueOutputFileName(baseOutputName);

  console.log('🔍 Scanning and merging files...');
  mergeFiles(resolvedPath, outputFile); // <--- use resolved path here
  rl.close();
});

