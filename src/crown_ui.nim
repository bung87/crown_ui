import os
import yaml/serialization, streams
type
  IndexGenerator = object
    path:string
    per_page:int
    order_by: string
  Highlight = object
    enable: bool
    line_number:bool
    auto_detect:bool
    # tab_replace:bool
  Deploy = object
    `type`: string
    repo: string
    branch: string
  Config = ref ConfigObj
  ConfigObj = object
    title: string
    subtitle:string
    description:string
    keywords: seq[string]
    logo:string
    author: string
    language: string
    timezone: string
    url: string
    root: string
    permalink: string
    source_dir: string
    public_dir: string
    tag_dir: string
    archive_dir: string
    category_dir: string
    code_dir: string
    i18n_dir: string
    new_post_name: string
    default_layout: string
    titlecase: bool # Transform title into titlecase
    external_link: bool # Open external links in new tab
    filename_case: int
    render_drafts: bool
    post_asset_folder: bool
    relative_link: bool
    index_generator:IndexGenerator
    default_category: string
    date_format: string
    time_format: string
    skip_render:string
    future: bool # Display future posts?

    # Pagination
    ## Set per_page to 0 to disable pagination
    per_page: int
    pagination_dir: string
    # menu: object
    theme: string
    deploy:Deploy
    highlight:Highlight

    category_map:string
    tag_map:string



when isMainModule:
  const exampleDir = currentSourcePath.parentDir.parentDir / "example"
  echo exampleDir
  var node1: Config

  var s = newFileStream( exampleDir / "config.yml")
  load(s, node1)
  s.close()
  # let themeDir = exampleDir / "themes" / 