# Package

version       = "0.1.1"
author        = "bung87"
description   = "ui system and static site generator"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
namedBin = {"crown_ui": "crown_ui"}.toTable()

# Dependencies

requires "nim >= 2.0.16"
requires "karax"

requires "nmark >= 0.1.9"
requires "dotenv >= 1.1.0"
requires "cligen > 1.3.2"
requires "npeg"
requires "fusion"
requires "https://github.com/beef331/oopsie"
requires "nimscripter"
requires "nyml"
requires "slugify"
requires "nregex"

task buildAssets,"build assets":
  rmFile "manifest.json"
  # Build all assets (SCSS compilation + static file copying)
  # Use global sass if available, otherwise use local node_modules
  var sassPath = "sass"
  if fileExists("./node_modules/.bin/sass"):
    sassPath = "./node_modules/.bin/sass"
  # Use the built-in theme assets from src/crown_uipkg/themes/default/assets
  exec "nim c -r src/crown_uipkg/assets_builder.nim -s:src/crown_uipkg/themes/default/assets -d:example/build --sass-path:" & sassPath

task serve,"serve":
  exec "nim c -r src/crown_ui.nim serve --cwd ./example/"

task buildSite,"build" :
  # First compile assets (SCSS -> CSS)
  exec "nimble buildAssets"
  # Then build the site (generates HTML)
  exec "nim c -r src/crown_ui.nim build --cwd ./example/"
