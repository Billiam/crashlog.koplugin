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
    title = _("Show crash.log"),
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

function Crashlog:getLogPath()
  local DataStorage = require("datastorage")
  local log_path = string.format("%s/%s", DataStorage:getDataDir(), "crash.log")
  return log_path
end

function Crashlog:_loadCrashLog()
  local file, error = io.open(self:getLogPath(), "r")
  if file then
    local body = file:read("*a")
    file:close()
    return body
  else
    logger.err(error)
  end
end

function Crashlog:_clearCrashLog()
  local file, err = io.open(self:getLogPath(), "w")
  if file then
    file:close()

    return true
  else
    logger.err(err)
  end
end

function Crashlog:onShowCrashlog()
  local CrashlogDialog = require("crashlog_dialog")
  local data = self:_loadCrashLog()
  local dialog = CrashlogDialog:new {
    text = data,
    title = "crash.log",
    refresh_func = function()
      return self:_loadCrashLog()
    end,
    clear_log_func = function()
      return self:_clearCrashLog()
    end
  }

  UIManager:show(dialog)
  UIManager:nextTick(function()
    UIManager:setDirty(dialog, "ui")
  end)
end

return Crashlog
