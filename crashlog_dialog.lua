local Screen = require("device").screen
local Blitbuffer = require("ffi/blitbuffer")

local Font = require("ui/font")
local Geom = require("ui/geometry")
local UIManager = require("ui/uimanager")

local ButtonDialog = require("ui/widget/buttondialog")
local ConfirmBox = require("ui/widget/confirmbox")
local ScrollTextWidget = require("ui/widget/scrolltextwidget")
local TitleBar = require("ui/widget/titlebar")
local ToggleSwitch = require("ui/widget/toggleswitch")
local VerticalGroup = require("ui/widget/verticalgroup")

local FrameContainer = require("ui/widget/container/framecontainer")
local RightContainer = require("ui/widget/container/rightcontainer")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local CrashlogDialog = WidgetContainer:extend {
  width = Screen:getWidth(),
  height = Screen:getHeight(),
  padding = Screen:scaleBySize(5),
  title = nil,
  text = nil,
  log_level = 1
}

local LOG_LEVELS = {
  "ALL",
  "DEBUG",
  "INFO",
  "WARN",
  "ERROR"
}

local LOG_LEVEL_INDEX = {
  ALL = 1,
  DEBUG = 2,
  INFO = 3,
  WARN = 4,
  ERROR = 5,
}

function CrashlogDialog:init()
  local titlebar = TitleBar:new {
    title = self.title,
    with_bottom_line = true,
    left_icon = "appbar.menu",
    left_icon_tap_callback = function()
      self:showTitlebarDialog()
    end,
    close_callback = function()
      UIManager:close(self)
    end
  }
  local titlebar_size = titlebar:getSize()

  local filter = ToggleSwitch:new {
    width = self.width,
    toggle = {
      "All", "Debug", "Info", "Warn", "Error"
    },
    values = LOG_LEVELS,
    config = self,
    alternate = false,
  }
  filter:setPosition(1)

  local filter_size = filter:getSize()

  local text_container_height = self.height - titlebar_size.h - filter_size.h
  self.text_container = self:buildTextContainer(self:filterText(self.text), text_container_height)

  self.container_parent = RightContainer:new {
    dimen = Geom:new {
      w = self.width,
      h = text_container_height,
    },
    self.text_container
  }

  local frame = FrameContainer:new {
    width = self.width,
    height = self.height,
    background = Blitbuffer.COLOR_WHITE,
    bordersize = 0,
    padding = 0,
    VerticalGroup:new {
      align = "left",
      titlebar,
      filter,
      self.container_parent,
    }
  }

  self[1] = frame
end

function CrashlogDialog:getText()
  self.text = self.refresh_func()
  return self:filterText(self.text)
end

function CrashlogDialog:filterText(text)
  if self.log_level == 1 then
    return text
  end

  local output_t = {}
  local i = 1
  for line in text:gmatch("[^\n]*\n?") do
    local level = line:match("^[%d-/:]+ ([A-Z]+)")
    if LOG_LEVEL_INDEX[level] and LOG_LEVEL_INDEX[level] >= self.log_level then
      output_t[i] = line
      i = i + 1
    end
  end

  return table.concat(output_t, "")
end

function CrashlogDialog:onConfigChoose(_values, _name, _event, _args, position)
  if self.log_level ~= position then
    self.log_level = position
  end

  local filtered_text = self:filterText(self.text)
  self:refreshContainer(filtered_text)
end

function CrashlogDialog:refreshContainer(text)
  local old_height = self.text_container.height
  self.text_container:free()

  self.text_container = self:buildTextContainer(text, old_height)
  self.container_parent[1] = self.text_container

  UIManager:nextTick(function()
    UIManager:setDirty(self, "ui", self.text_container.dimen)
  end)
end

function CrashlogDialog:buildTextContainer(text, height)
  local text_widget = ScrollTextWidget:new {
    face = Font:getFace("infont", 14),
    text = text,
    width = self.width - Screen:scaleBySize(6),
    height = height,
    dialog = self,
    show_parent = self,
  }
  text_widget:scrollToBottom()

  return text_widget
end

function CrashlogDialog:showTitlebarDialog()
  local dialog
  dialog = ButtonDialog:new {
    buttons = {
      { {
        text = "Refresh logs",
        callback = function()
          local new_text = self:getText()
          UIManager:close(dialog)
          self:refreshContainer(new_text)
        end
      } },
      { {
        text = "Clear log file",
        callback = function()
          UIManager:show(ConfirmBox:new {
            text = "Are you sure you want to clear the log file?",
            ok_callback = function()
              self:clearLog()
              UIManager:close(dialog)
            end,
          })
        end
      } }
    }

  }
  UIManager:show(dialog)
end

function CrashlogDialog:clearLog()
  local result = self.clear_log_func()
  if result then
    self.text = ""
    self:refreshContainer(self.text)
  end
end

return CrashlogDialog
