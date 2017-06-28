-- Copyright 2011-12 Paul Kulchenko, ZeroBrane LLC

local njli
local win = ide.osname == "Windows"
local mac = ide.osname == "Macintosh"

return {
  name = "NJLIGameEngine",
  description = "NJLI game engine",
  api = {"baselib", "njli"},
  frun = function(self,wfilename,rundebug)
    njli = njli or ide.config.path.njli -- check if the path is configured
    if not njli then
      local sep = win and ';' or ':'
      local default =
           win and (GenerateProgramFilesPath('NJLIGameEngine', sep)..sep)
        or mac and ('/Applications/NJLIGameEngine.app/Contents/MacOS'..sep)
        or ''
      local path = default
                 ..(os.getenv('PATH') or '')..sep
                 ..(GetPathWithSep(self:fworkdir(wfilename)))..sep
                 ..(os.getenv('HOME') and GetPathWithSep(os.getenv('HOME'))..'bin' or '')
      local paths = {}
      for p in path:gmatch("[^"..sep.."]+") do
        njli = njli or GetFullPathIfExists(p, win and 'NJLIGameEngine.exe' or 'NJLIGameEngine')
        table.insert(paths, p)
      end
      if not njli then
        DisplayOutputLn("Can't find njli executable in any of the following folders: "
          ..table.concat(paths, ", "))
        return
      else
        DisplayOutputLn("Found njli executable in any of the following folders: "
          ..table.concat(paths, ", "))
      end
    end

--    if not GetFullPathIfExists(self:fworkdir(wfilename), 'main.lua') then
--      DisplayOutputLn(("Can't find 'main.lua' file in the current project folder: '%s'.")
--        :format(self:fworkdir(wfilename)))
--      return
--    end

    local file
    local epoints = ide.config.njli and ide.config.njli.entrypoints
    if epoints then
      epoints = type(epoints) == 'table' and epoints or {epoints}
      for _,entry in pairs(epoints) do
        file = GetFullPathIfExists(self:fworkdir(wfilename), entry)
        if file then break end
      end
      if not file then
        DisplayOutputLn("Can't find any of the specified entry points ("
          ..table.concat(epoints, ", ")
          ..") in the current project; continuing with the current file...")
      end
    end

    if rundebug then
      DebuggerAttachDefault({rstartwith = file,
        unstart = ide.config.debugger.runonstart == true})
    end

    -- suppress hiding ConsoleWindowClass as this is used by Love console
    local uhw = ide.config.unhidewindow
    local cwc = uhw and uhw.ConsoleWindowClass
    if uhw then uhw.ConsoleWindowClass = 0 end

    local params = ide.config.arg.any or ide.config.arg.njli
    local cmd = ('"%s" "%s"%s%s'):format(njli, self:fworkdir(wfilename),
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
