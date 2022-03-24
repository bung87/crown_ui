# crown_ui  [![GitHub Pages](https://github.com/bung87/crown_ui/actions/workflows/pages.yml/badge.svg?branch=devel)](https://github.com/bung87/crown_ui/actions/workflows/pages.yml)

`crown_ui` is a static site generator written in [Nim](https://nim-lang.org) language. 

## Installation  

`nimble install crown_ui`  

## Usage  

generate new post or page in markdown

`crown_ui new post <title>`
`crown_ui new page <title>`  

generated page or post will under ./source/drafts when ready for publish, move to ./source/<pages|posts> directory  

## Contribution  

check issues first  
### code formatting  
clone this repository, run `nimble install stage` , if you already have `stage` installed, run `stage init`  
`stage` is used for integrating with git commit hook, doing checking and code formatting.  

### Precompile assets  
for styles,images  

`nimble buildAssets`

### Build site  

`nimble buildSite`  

### Serve locally  

`nimble serve`  

## License  

MIT License