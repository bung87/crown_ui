from crown_ui/generator import generate, build
import scorper except serve
import std / [os, exitprocs]


proc serve(cwd = getCurrentDir(); port = 8080): int =
  ## dev server
  result = 1
  let r = newRouter[ScorperCallback]()
  # Relys on `StaticDir` environment variable
  putEnv("StaticDir", cwd / "build")
  r.addRoute(serveStatic, "get", "/*$")
  let address = "127.0.0.1:" & $port
  let flags = {ReuseAddr}
  var server = newScorper(address, r, flags)
  exitprocs.addExitProc proc() = server.stop(); waitFor server.closeWait()
  server.start()
  waitFor server.join()
  result = 0


when isMainModule:
  import cligen
  from std/tables import toTable
  const
    GenerateHelp = {"tpl": "template"}.toTable()
    BuildHelp = {"cwd": "current working directory"}.toTable()
    ServeHelp = {"cwd": "current working directory", "port": "port"}.toTable()

  dispatchMulti([build, help = BuildHelp],
    [generate, cmdName = "new", help = GenerateHelp],
    [serve, help = ServeHelp]
    )
