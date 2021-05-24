import os
import yaml, streams
import json
import ./utils

when isMainModule:
  const exampleDir = currentSourcePath.parentDir.parentDir / "example"
  echo exampleDir

  let configPath = exampleDir / "config.yml"
  var s = newFileStream(configPath)
  let res = parseYaml(s)
  let config = if res.len > 1: res[0] else: newJNull()
  if config.kind != JNull:
    discard
