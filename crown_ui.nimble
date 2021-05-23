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
requires "karax"
requires "yaml"
requires "https://github.com/bung87/web_preprocessor"
requires "dotenv >= 1.1.0"

task watch,"watch":
  exec "karun -r -w --css:src/css.html src/nimhub.nim"
task preprocess,"preprocess":
  exec "web_preprocessor -s src/assets -d dest/assets"
