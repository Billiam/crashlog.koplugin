local Screen = require("device").screen
local Blitbuffer = require("ffi/blitbuffer")

local Font = require("ui/font")
local Geom = require("ui/geometry")
local UIManager = require("ui/uimanager")

local ScrollTextWidget = require("ui/widget/scrolltextwidget")
local TitleBar = require("ui/widget/titlebar")
local VerticalGroup = require("ui/widget/verticalgroup")

local FrameContainer = require("ui/widget/container/framecontainer")
local RightContainer = require("ui/widget/container/rightcontainer")
local WidgetContainer = require("ui/widget/container/widgetcontainer")

local CrashlogDialog = WidgetContainer:extend {
  width = Screen:getWidth(),
  height = Screen:getHeight(),
  padding = Screen:scaleBySize(5),
  title = nil,
  text = nil
}

function CrashlogDialog:init()
  local titlebar = TitleBar:new {
    title = self.title,
    with_bottom_line = true,
    left_icon = "cre.render.reload",
    left_icon_tap_callback = function()
      local new_text = self.refresh_func()
      local old_height = self.text_container.height
      self.text_container:free()

      self.text_container = self:buildTextContainer(new_text, old_height)
      self.container_parent[1] = self.text_container
      UIManager:nextTick(function()
        UIManager:setDirty(self, "ui", self.text_container.dimen)
      end)
    end,
    close_callback = function()
      UIManager:close(self)
    end
  }
  local titlebar_size = titlebar:getSize()
  local text_container_height = self.height - titlebar_size.h
  self.text_container = self:buildTextContainer(self.text, text_container_height)

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
      self.container_parent,
    }
  }

  self[1] = frame
end

function CrashlogDialog:buildTextContainer(text, height)
  local text_widget = ScrollTextWidget:new {
    face = Font:getFace("cfont", 14),
    text = text,
    width = self.width - Screen:scaleBySize(6),
    height = height,
    dialog = self,
    show_parent = self,
  }
  text_widget:scrollToBottom()

  return text_widget
end

return CrashlogDialog
