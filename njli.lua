-- Copyright 2011-12 Paul Kulchenko, ZeroBrane LLC

local macOS
local win = ide.osname == "Windows"
local mac = ide.osname == "Macintosh"

return {
  name = "NJLI",
  description = "NJLI game engine",
  api = {"baselib", "macOS"},
  frun = function(self,wfilename,rundebug)
    macOS = macOS or ide.config.path.macOS -- check if the path is configured
    if not macOS then
      local sep = win and ';' or ':'
      local default =
           win and (GenerateProgramFilesPath('macOS', sep)..sep)
        or mac and ('/Applications/macOS.app/Contents/MacOS'..sep)
        or ''
      local path = default
                 ..(os.getenv('PATH') or '')..sep
                 ..(GetPathWithSep(self:fworkdir(wfilename)))..sep
                 ..(os.getenv('HOME') and GetPathWithSep(os.getenv('HOME'))..'bin' or '')
      local paths = {}
      for p in path:gmatch("[^"..sep.."]+") do
        macOS = macOS or GetFullPathIfExists(p, win and 'macOS.exe' or 'macOS')
        table.insert(paths, p)
      end
      if not macOS then
        DisplayOutputLn("Can't find njli executable in any of the following folders: "
          ..table.concat(paths, ", "))
        return
      else
        DisplayOutputLn("Found njli executable in any of the following folders: "
          ..table.concat(paths, ", "))
      end
    end

    if not GetFullPathIfExists(self:fworkdir(wfilename), 'main.lua') then
      DisplayOutputLn(("Can't find 'main.lua' file in the current project folder: '%s'.")
        :format(self:fworkdir(wfilename)))
      return
    end

    if rundebug then
      DebuggerAttachDefault({runstart = ide.config.debugger.runonstart == true})
    end

    -- suppress hiding ConsoleWindowClass as this is used by Love console
    local uhw = ide.config.unhidewindow
    local cwc = uhw and uhw.ConsoleWindowClass
    if uhw then uhw.ConsoleWindowClass = 0 end

    local params = ide.config.arg.any or ide.config.arg.macOS
    local cmd = ('"%s" "%s"%s%s'):format(macOS, self:fworkdir(wfilename),
      params and " "..params or "", rundebug and ' -debug' or '')
    DisplayOutputLn('This is the command: ' .. cmd )
    -- CommandLineRun(cmd,wdir,tooutput,nohide,stringcallback,uid,endcallback)
    return CommandLineRun(cmd,self:fworkdir(wfilename),true,true,nil,nil,
      function() if uhw then uhw.ConsoleWindowClass = cwc end end)
  end,
  hasdebugger = true,
  fattachdebug = function(self) DebuggerAttachDefault() end,
  scratchextloop = true,
  takeparameters = true,
}
