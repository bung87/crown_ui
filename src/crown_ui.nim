import os

when isMainModule:
  const exampleDir = currentSourcePath.parentDir.parentDir / "example"
  echo exampleDir

  let configPath = exampleDir / "config.yml"
