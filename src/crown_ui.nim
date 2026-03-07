from crown_uipkg/generator import generate, build
import std / [os, exitprocs, asynchttpserver, asyncdispatch, mimetypes, strutils]


proc serveCmd(cwd = getCurrentDir(); port = 8080): int =
  ## dev server
  result = 1
  # Use StaticDir environment variable if set, otherwise use cwd/build
  let staticDir = getEnv("StaticDir", cwd / "build")
  let mimes = newMimeTypes()

  proc handler(req: Request) {.async.} =
    var path = req.url.path
    if path == "/":
      path = "/index.html"

    # Security: prevent directory traversal
    if ".." in path:
      await req.respond(Http400, "Bad Request")
      return

    let filePath = staticDir / path

    if not fileExists(filePath):
      await req.respond(Http404, "Not Found: " & path)
      return

    let ext = splitFile(filePath).ext
    let contentType = mimes.getMimeType(ext.strip(chars = {'.'}))

    try:
      let content = readFile(filePath)
      let headers = newHttpHeaders([("Content-Type", contentType)])
      await req.respond(Http200, content, headers)
    except:
      await req.respond(Http500, "Internal Server Error")

  let server = newAsyncHttpServer()
  let address = "127.0.0.1:" & $port

  echo "Serving " & staticDir & " at http://" & address

  exitprocs.addExitProc proc() =
    server.close()

  result = 0
  waitFor server.serve(Port(port), handler)


when isMainModule:
  import cligen
  from std/tables import toTable
  const
    GenerateHelp = {"tpl": "<post|page> <title>"}.toTable()
    BuildHelp = {"cwd": "current working directory"}.toTable()
    ServeHelp = {"cwd": "current working directory", "port": "port"}.toTable()

  dispatchMulti([build, help = BuildHelp],
    [generate, cmdName = "new", help = GenerateHelp],
    [serveCmd, cmdName = "serve", help = ServeHelp]
    )
