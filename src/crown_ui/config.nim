import ./utils
import os
import json
import jsony
import tables
import macros
import ./datetime_utils

type Link* = object
  href*: string
  title*: string
type
  IndexGenerator = object
    path*: string
    per_page*: int
    order_by*: string
    pagination_dir*: string
  Highlight = object
    enable*: bool
    line_number*: bool
    auto_detect*: bool
    # tab_replace:bool
  Deploy = object
    `type`*: string
    repo*: string
    branch*: string
  BaseConfig* = ref BaseConfigObj
  BaseConfigObj = object of RootObj
    title*: string
    subtitle*: string
    description*: string
    keywords*: seq[string]
    logo*: string
    author*: string
    language*: string
    timezone*: string
    url*: string
    root*: string
    permalink*: string
    source_dir*: string
    public_dir*: string
    tag_dir*: string
    archive_dir*: string
    category_dir*: string
    code_dir*: string
    i18n_dir*: string
    new_post_name*: string
    default_layout*: string
    titlecase*: bool     # Transform title into titlecase
    external_link*: bool # Open external links in new tab
    filename_case*: int
    render_drafts*: bool
    post_asset_folder*: bool
    relative_link*: bool
    index_generator*: IndexGenerator
    default_category*: string
    date_format*: string
    time_format*: string
    skip_render*: string
    future*: bool        # Display future posts?

    # # Pagination
    # ## Set per_page to 0 to disable pagination
    # per_page*: int
    # pagination_dir*: string

    theme*: string
    deploy*: Deploy
    highlight*: Highlight

    category_map*: string
    tag_map*: string
    theme_config*: JsonNode
    menu*: JsonNode
  Config* = ref ConfigObj
  ConfigObj = object of BaseConfigObj
    menuLinks*: seq[Link]
    # footer_links*: seq[Link]

func getFields(child: NimNode): seq[NimNode] =
  let impl = child.getType[^1].getImpl
  for identDef in impl[^1][^1]:
    result.add identDef[0..^3]
  if not impl[^1][1][0].eqIdent("RootObj"):
    result.add getFields(impl[^1][1][0])

macro assign*(child: ref object, parent: ref object): untyped =
  let fields = getFields(parent)
  result = newStmtList()
  result.add quote do:
    if `child`.isNil:
      new `child`
  for field in fields:
    let field = field.baseName
    result.add quote do:
      `child`.`field` = `parent`.`field`

proc parseConfig*(configPath: string): Config =
  # result = Config()
  let configJson = parseYamlConfig(configPath)
  let baseConfig = ($configJson).fromJson(BaseConfig)
  # copyMem(cast[pointer](result),cast[pointer](baseConfig),sizeof(baseConfig))
  # result = cast[Config](baseConfig)
  assign(result, baseConfig)
  result.menuLinks = newSeq[Link]()
  let menuNode = configJson["menu"].getFields
  for k, v in menuNode.pairs:
    result.menuLinks.add Link(href: v.getStr(), title: k)
  return result

proc dateTimeFormat*(config: Config): string =
  result = toNimFormat(config.date_format & " " & config.time_format)

when isMainModule:
  const exampleDir = currentSourcePath.parentDir.parentDir.parentDir / "example"

  const configPath = exampleDir / "config.yml"
  echo configPath
  let config = parseConfig(configPath)
  echo repr config
