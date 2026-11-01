--[[______   __
  / ____/ | / / Name: GNUI CANVAS API v1.0.0
 / / __/  |/ /  Desc: the base Canvas, aka the root box
/ /_/ / /|  / Author: GNanimates | https://gnon.top | @gn68s
\____/_/ |_/ License: Mozilla Public License Version 2.0 ]]
---@diagnostic disable: return-type-mismatch, assign-type-mismatch, undefined-field
local BASE = ((...):gsub("/", ".")):match(".+%.GNUI")

local gncommon = require("lib.GNcommon") ---@type GNCommon
local cfg = require(BASE .. ".config") ---@type GNUI.config
local Box = require(cfg.CORE .. ".prims.box") ---@type GNUI.Primitive.BoxAPI
local Render = require(cfg.RENDER .. ".init") ---@type GNUI.RenderAPI
local Event = require(cfg.EVENT) ---@type GN.Event

local Layout = require(cfg.LAYOUT .. ".init") ---@type GNUI.LayoutAPI

--TODO: move this all to the box, and make all of them able to cancel the event.
---@class GNUI.Canvas.Event.CharInput : GN.Event
---@field register fun(self,func:(fun(char: string):boolean?),id:any?)

---@class GNUI.Canvas.Event.KeyInput : GN.Event
---@field register fun(self,func:(fun(scancode:integer, state:integer):boolean?),id:any?)

---@class GNUI.Canvas.Event.MouseInput : GN.Event
---@field register fun(self,func:(fun(button:integer,state:integer):boolean?),id:any?)

---@class GNUI.Canvas.Event.CursorMoved : GN.Event
---@field register fun(self,func:(fun(pos: Vector2, vel: Vector2)),id:any?)



---@alias GNUI.InputButton.Type integer
---| [0]  LEFT
---| [1]  RIGHT
---| [2]  MIDDLE


---@alias GNUI.InputButton.State integer
---| [0]  PRESSED
---| [1]  RELEASED
---| [2]  HOLD


---API for instantiating a Canvas object
---@class GNUI.CanvasAPI
local CanvasAPI = {}

---A root node for boxes,
---this class also exposes all the input methods for the framework to connect to
---@class GNUI.Canvas : GNUI.Box
---@field display GNUI.Render.Display
---@field queueUpdate GNUI.Box[]
---@field hoveredBox GNUI.Box
---@field pressedButtons GNUI.Box[]
---@field nextFrameCallbacks function[]
---
---@field FLUSH_UPDATES GN.Event
---@field POST_FLUSH_UPDATES GN.Event
---
---@field CHAR_INPUT GNUI.Canvas.Event.CharInput
---@field KEY_INPUT GNUI.Canvas.Event.KeyInput
---@field MOUSE_INPUT GNUI.Canvas.Event.MouseInput
---@field CURSOR_MOVED GNUI.Canvas.Event.CursorMoved
---@field HOVERED_BOX_CHANGED GN.Event
local Canvas = {}
Canvas.__index = function(t, i)
	return rawget(t, i) or Canvas[i] or Box.index(t, i)
end


---Creates a new canvas for boxes to attach to, this box is special,
---as it acts as the root node of all boxes
---@return GNUI.Canvas
function CanvasAPI.new()
	---@diagnostic disable-next-line: missing-parameter its literally me!
	local self = Box.new()
	---@cast self GNUI.Canvas
	self.display = Render.newDisplay()
	self.canvas = self
	self.visualID = 1
	self.queueUpdate = {}
	self.pressedButtons = {}
	
	self.nextFrameCallbacks = {}
	
	self.FLUSH_UPDATES = Event.new()
	self.POST_FLUSH_UPDATES = Event.new()
	self.HOVERED_BOX_CHANGED = Event.new()
	
	self.CURSOR_MOVED = Event.new()

	self:setSizing("FIXED", "FIXED")
	setmetatable(self, Canvas)
	return self
end


---Forces an immidiate update to all the boxes in the queue
---@return GNUI.Canvas
function Canvas:flushUpdates()
	self.FLUSH_UPDATES:invoke()
	for key, box in pairs(self.queueUpdate) do
		box:forceUpdate()
		self.queueUpdate[key] = nil
	end
	for index, value in ipairs(self.nextFrameCallbacks) do
		value()
	end
	self.nextFrameCallbacks = {}
	self.POST_FLUSH_UPDATES:invoke()
	return self
end

--TODO: replace with a method that propagates from the root screen to the element, and back to the screen

---TODO: replace with a method that allows selecting boxes outside parent bounds.
---Finds the box being hovered by the cursor
---@param box GNUI.Box
---@param pos Vector2
---@return GNUI.Box
local function findHoveredBox(box, pos)
	for index = #box.children, 1, -1 do
		local childBox = box.children[index]
		if childBox.captureInput and childBox.visible and childBox:isPosInboundingBox(pos) then
			local hoveredBox = findHoveredBox(childBox, pos)
			if hoveredBox and hoveredBox:isPosInBox(pos)
			then
				return hoveredBox
			end
		end
	end
	return box
end


---Sets the position of the cursor in the Canvas.
---@overload fun(self: GNUI.Canvas ,xy: Vector2): GNUI.Canvas
---@param x number
---@param y number
---@return GNUI.Canvas
function Canvas:setCursorPos(x, y)
	local newCursorPos = gncommon.vec2(x, y)
	if self.cursorPos ~= newCursorPos then
		local lastCursorPos = self.cursorPos
		local cursorVel = newCursorPos - (lastCursorPos or newCursorPos)

		self.cursorPos = newCursorPos

		local newHoveredBox = findHoveredBox(self, self.cursorPos)

		self.CURSOR_MOVED:invoke(self.cursorPos, cursorVel)

		if self.hoveredBox ~= newHoveredBox then
			if self.hoveredBox then
				self.hoveredBox.isHovered = false
				self.hoveredBox.CURSOR_PRESENCE_CHANGED:invoke(false)
			end
			local old = self.hoveredBox
			self.hoveredBox = newHoveredBox
			self.HOVERED_BOX_CHANGED:invoke(newHoveredBox,old)
			if newHoveredBox then
				newHoveredBox.isHovered = true
				newHoveredBox.CURSOR_PRESENCE_CHANGED:invoke(true)
			end
		end
	end
	return self
end

-- propagate scroll input from children to its parents, begging for one to capture it lmao.
---@param box GNUI.Box
---@param ... any
---@return boolean
local function processUnhandledInputCapture(box, event, ...)
	local outs = box[event]:invoke(...)
	for index, value in ipairs(outs) do
		if value[1] then return true end
	end
	if box.parent then
		return processUnhandledInputCapture(box.parent, event, ...)
	end
	return false
end

-- propagate scroll input from parent to the given box.
-- while allowing each step of the way to capture the inputs.
---@param box GNUI.Box
---@param ... any
---@return boolean
local function proccessInputCapture(box, event, ...)
	-- prioritize calculating for parent first
	if box.parent then
		if proccessInputCapture(box.parent, event, ...) then
			-- input has been captured by a parent
			return true
		end
	end

	-- check if its been captured
	local outs = box[event]:invoke(...)
	for index, value in ipairs(outs) do
		if value[1] then
			return true
		end
	end
	return false
end


---@param box GNUI.Box
---@param event string
---@param ... any
local function processInput(box, event, ...)
	if not box then return end
	local processed = proccessInputCapture(box, event, ...)
	if processed then return true end
	return processUnhandledInputCapture(box, "UNHANDLED_" .. event, ...)
end


function Canvas:inputScroll(y, x)
	processInput(self.hoveredBox, "SCROLL_INPUT", y, x, 0)
end

---@param scancode integer
---@param state integer
function Canvas:inputKey(scancode, state)
	if self.hoveredBox then
		if state == 1 or state == 2 then
			self.pressedButtons[scancode] = self.hoveredBox
			local capture = processInput(self.hoveredBox, "KEY_INPUT", scancode, state)
			return capture
		elseif state == 0 then
			if self.pressedButtons[scancode] then
				processInput(self.pressedButtons[scancode], "KEY_INPUT", scancode, state)
				self.pressedButtons[scancode] = nil
			end
		end
	end
end

function Canvas:inputChar(char)
	local out = processInput(self.hoveredBox, "CHAR_INPUT", char)
	return out
end

---@param button integer
---@param state integer
function Canvas:inputMouse(button, state)
	if self.hoveredBox then
		if state == 1 then
			self.pressedButtons[button] = self.hoveredBox
			processInput(self.hoveredBox, "MOUSE_INPUT", button, state)
		elseif state == 0 then
			if self.pressedButtons[button] then
				if self.pressedButtons[button].canvas == self then
					processInput(self.pressedButtons[button], "MOUSE_INPUT", button, state)
				end
				self.pressedButtons[button] = nil
			end
		end
	end
end


---calls the given function when all screen requested updates are called.
---
---This is useful for when you want to wait for a layout update before gathering data from them.
---@param callback fun()
function Canvas:callNextFrame(callback)
	self.nextFrameCallbacks[#self.nextFrameCallbacks+1] = callback
end


---Love2D Exclusive
function Canvas:draw(graphics)
	self.display:draw(graphics)
end

return CanvasAPI
