import json
import tables
import jsony
import oopsie
import ./config
import ./datetime_utils
import ./utils

proc getDateTimeFormat*(config: JsonNode): string =
  result = toNimFormat(config{"date_format"}.getStr("YYYY-MM-DD") & " " & config{"time_format"}.getStr("HH:mm:ss"))

proc parseConfig*(configPath: string): Config =
  let configJson = parseYamlConfig(configPath)
  let baseConfig = ($configJson).fromJson(BaseConfig)
  copy(result, baseConfig)
  result.menuLinks = newSeq[Link]()
  let menuNode = configJson["menu"].getFields
  for k, v in menuNode.pairs:
    result.menuLinks.add Link(href: v.getStr(""), title: k)
  result.dateTimeFormat = configJson.getDateTimeFormat
  return result


when isMainModule:
  import times
  const exampleDir = currentSourcePath.parentDir.parentDir.parentDir / "example"

  const configPath = exampleDir / "config.yml"
  echo configPath
  let conf = parseYamlConfig(configPath)
  echo conf.getDateTimeFormat

  echo parse("2021-06-11 15:04:29", conf.getDateTimeFormat)