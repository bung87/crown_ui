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
requires "https://github.com/karaxnim/karax#master"
requires "yaml"
requires "https://github.com/bung87/web_preprocessor"
requires "nmark >= 0.1.9"
requires "dotenv >= 1.1.0"
requires "cligen > 1.3.2"
requires "npeg"
requires "chronicles"
requires "fusion"
requires "scorper >= 1.0.25"
requires "https://github.com/beef331/oopsie"
requires "nimscripter >= 1.0.13"
requires "https://github.com/openpeep/nyml"

task ghpage,"gh page":
  withDir "example/build": 
    exec "git init"
    writeFile("CNAME", "crown_ui.bungos.me")
    exec "git add ."
    exec "git config user.name \"bung87\""
    exec "git config user.email \"crc32@qq.com\""
    exec "git commit -m \"docs(docs): update gh-pages\""
    let url = "\"https://bung87@github.com/bung87/crown_ui.git\""
    exec "git push --force --quiet " & url & " master:ghpages"


import strformat,sequtils
task watch,"watch":
  let file = commandLineParams.filterIt( it in ["post","page","index","page","tag","category","archive"])[0]
  exec fmt"karun -r -s -w --css=example/themes/default/css.html example/themes/default/{file}.nim"
task preprocess,"preprocess":
  rmFile "manifest.json"
  exec "web_preprocessor -s example/themes/default/assets -d build/assets"

task buildStatic,"build static":
  exec "web_preprocessor -s example/themes/default/assets -d example/build"

task serve,"serve":
  exec "nim c -r src/crown_ui.nim serve --cwd ./example/"

task buildSite,"build" :
  exec "nim c -r src/crown_ui.nim build --cwd ./example/"
