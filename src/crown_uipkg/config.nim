
import json

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
    keywords*: JsonNode
    logo*: JsonNode
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
    dateTimeFormat*: string
    # footer_links*: seq[Link]


