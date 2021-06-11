import scorper
import std / [os, exitprocs]
when isMainModule:
  let r = newRouter[ScorperCallback]()
  # Relys on `StaticDir` environment variable
  putEnv("StaticDir", "example"/"build")
  r.addRoute(serveStatic, "get", "/*$")
  let address = "127.0.0.1:8888"
  let flags = {ReuseAddr}
  var server = newScorper(address, r, flags)
  exitprocs.addExitProc proc() = server.stop(); waitFor server.closeWait()
  server.start()
  waitFor server.join()
