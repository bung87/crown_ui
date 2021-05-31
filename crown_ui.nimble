# Package

version       = "0.1.0"
author        = "bung87"
description   = "ui system and static site generator"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["crown_ui"]


# Dependencies

requires "nim >= 1.5.1"
requires "https://github.com/karaxnim/karax#master"
requires "yaml"
requires "https://github.com/bung87/web_preprocessor"
requires "dotenv >= 1.1.0"

import strformat,sequtils
task watch,"watch":
  let file = commandLineParams.filterIt( it in ["post","page","index","page","tag","category","archive"])[0]
  echo file
  exec fmt"karun -r -s -w --css=example/themes/default/css.html example/themes/default/{file}.nim"
task preprocess,"preprocess":
  rmFile "manifest.json"
  exec "web_preprocessor -s example/themes/default/assets -d build/assets"
