## Assets Builder - Replacement for web_preprocessor
## Compiles SCSS and copies static assets

import std/[os, osproc, strutils, paths]

type
  AssetsBuilder* = object
    sourceDir*: string
    destDir*: string
    sassPath*: string

proc newAssetsBuilder*(sourceDir, destDir, sassPath: string): AssetsBuilder =
  result.sourceDir = sourceDir
  result.destDir = destDir
  result.sassPath = sassPath

proc ensureDir*(path: string) =
  if not dirExists(path):
    createDir(path)

proc relativePath*(path, base: string): string =
  ## Get relative path from base
  let absPath = absolutePath(path)
  let absBase = absolutePath(base)
  result = absPath.replace(absBase, "").strip(chars = {'/'})

proc compileScss*(builder: AssetsBuilder, inputFile, outputFile: string) =
  ## Compile a single SCSS file
  ensureDir(parentDir(outputFile))
  let cmd = builder.sassPath & " " & inputFile & " " & outputFile
  echo "Compiling: ", relativePath(inputFile, builder.sourceDir), " -> ", relativePath(outputFile, builder.destDir)
  let (output, exitCode) = execCmdEx(cmd)
  if exitCode != 0:
    stderr.writeLine "Error compiling ", inputFile, ":"
    stderr.writeLine output
    quit(1)

proc copyFile*(builder: AssetsBuilder, inputFile, outputFile: string) =
  ## Copy a static file
  ensureDir(parentDir(outputFile))
  copyFile(inputFile, outputFile)
  echo "Copied: ", relativePath(inputFile, builder.sourceDir)

proc shouldCompile*(file: string): bool =
  ## Check if file should be compiled (SCSS but not partial)
  let name = extractFilename(file)
  file.endsWith(".scss") and not name.startsWith("_")

proc shouldCopy*(file: string): bool =
  ## Check if file should be copied (not SCSS source)
  not file.endsWith(".scss") and not file.endsWith(".sass")

proc shouldSkipDirectory*(dir: string): bool =
  ## Skip directories that contain only SCSS partials (like pure/)
  let name = extractFilename(dir)
  name == "pure" or name.startsWith("_")

proc processDirectory*(builder: AssetsBuilder, subdir: string = "") =
  ## Process a directory recursively
  let currentSource = if subdir.len == 0: builder.sourceDir else: builder.sourceDir / subdir
  let currentDest = if subdir.len == 0: builder.destDir else: builder.destDir / subdir
  
  ensureDir(currentDest)
  
  for kind, path in walkDir(currentSource):
    let relPath = relativePath(path, currentSource)
    let destPath = currentDest / relPath
    
    case kind
    of pcFile:
      if shouldCompile(path):
        # Compile SCSS to CSS
        let cssPath = destPath.changeFileExt(".css")
        builder.compileScss(path, cssPath)
      elif shouldCopy(path):
        # Copy static file
        builder.copyFile(path, destPath)
    of pcDir:
      # Skip directories that contain only partials
      if shouldSkipDirectory(path):
        echo "Skipping: ", relativePath(path, builder.sourceDir)
      else:
        # Recurse into subdirectory
        let newSubdir = if subdir.len == 0: relPath else: subdir / relPath
        builder.processDirectory(newSubdir)
    else:
      discard

proc build*(builder: AssetsBuilder) =
  ## Build all assets
  echo "Building assets from ", builder.sourceDir, " to ", builder.destDir
  ensureDir(builder.destDir)
  builder.processDirectory()
  echo "Build complete!"

when isMainModule:
  import std/parseopt
  
  var sourceDir = ""
  var destDir = ""
  var sassPath = "sass"
  
  var opt = initOptParser()
  for kind, key, val in opt.getopt():
    case kind
    of cmdArgument:
      discard
    of cmdShortOption, cmdLongOption:
      case key
      of "s", "source": sourceDir = val
      of "d", "dest": destDir = val
      of "sass-path": sassPath = val
      else: discard
    of cmdEnd:
      discard
  
  if sourceDir.len == 0 or destDir.len == 0:
    echo "Usage: assets_builder -s:<source_dir> -d:<dest_dir> [--sass-path:<path>]"
    quit(1)
  
  let builder = newAssetsBuilder(sourceDir, destDir, sassPath)
  builder.build()
