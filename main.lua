local _ = require("gettext")
local Dispatcher = require("dispatcher")
local logger = require("logger")

local UIManager = require("ui/uimanager")

local WidgetContainer = require("ui/widget/container/widgetcontainer")

local VERSION = { 0, 0, 1 }

local Crashlog = WidgetContainer:extend {
  name = "crashlog",
  is_doc_only = false,
}

function Crashlog:init()
  self:onDispatcherRegisterActions()
  self.ui.menu:registerToMainMenu(self)
end

function Crashlog:onDispatcherRegisterActions()
  Dispatcher:registerAction("show_crashlog", {
    category = "none",
    event = "ShowCrashlog",
    title = _("Hardcover: Link book"),
    general = true,
  })
end

function Crashlog:addToMainMenu(menu_items)
  menu_items.crashlog = {
    text = _("Crash Log Viewer"),
    sorting_hint = "more_tools",
    callback = function()
      self:onShowCrashlog()
    end,
  }
end

function Crashlog:_loadCrashLog(force)
  if force then
    self.crashlog_data = nil
  end

  if not self.crashlog_data then
    local DataStorage = require("datastorage")
    local log_path = string.format("%s/%s", DataStorage:getDataDir(), "crash.log")
    local file, error = io.open(log_path, "r")
    if file then
      local body = file:read("*a")
      file:close()
      self.crashlog_data = body
    else
      logger.err(error)
    end
  end

  return self.crashlog_data
end

function Crashlog:onShowCrashlog()
  local CrashlogDialog = require("crashlog_dialog")
  local data = self:_loadCrashLog()
  UIManager:show(CrashlogDialog:new {
    text = data,
    title = "crash.log",
    refresh_func = function()
      return self:_loadCrashLog(true)
    end
  })
end

return Crashlog
