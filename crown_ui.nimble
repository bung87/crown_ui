# Package

version       = "0.1.1"
author        = "bung87"
description   = "ui system and static site generator"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
namedBin = {"crown_ui": "crown_ui"}.toTable()

# Dependencies

requires "nim >= 1.6.0"
requires "karax"
requires "yaml"
requires "https://github.com/bung87/web_preprocessor"
requires "nmark >= 0.1.9"
requires "dotenv >= 1.1.0"
requires "cligen > 1.3.2"
requires "npeg"
requires "chronicles"
requires "fusion"
requires "scorper >= 1.1.0"
requires "https://github.com/beef331/oopsie"
requires "https://github.com/bung87/nimscripter"
requires "https://github.com/bung87/nyml"
requires "slugify"

task buildAssets,"build assets":
  rmFile "manifest.json"
  exec "web_preprocessor -s example/themes/default/assets -d example/build"

task serve,"serve":
  exec "nim c -r src/crown_ui.nim serve --cwd ./example/"

task buildSite,"build" :
  exec "nim c -r src/crown_ui.nim build --cwd ./example/"
