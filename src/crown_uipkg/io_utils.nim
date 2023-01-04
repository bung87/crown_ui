import os, times, hashes

proc computeDirVersion*(pattern: string): string =
  ## file mtime based
  var h: Hash = 0
  for f in walkFiles(pattern):
    let info = getFileInfo(f)
    h = h !& hash(info.lastWriteTime.toUnix)
  h = !$h
  result = $h

when isMainModule:
  const d = currentSourcePath.parentDir
  echo computeDirVersion(d & "/*.nim")
