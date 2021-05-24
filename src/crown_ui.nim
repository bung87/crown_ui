import os
import yaml, streams
import json
import crown_ui/utils

when isMainModule:
  const exampleDir = currentSourcePath.parentDir.parentDir / "example"
  echo exampleDir

  let configPath = exampleDir / "config.yml"
