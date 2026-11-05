local BASE = ((...):gsub("/", ".")):match(".+%.GNUI")
local cfg = require(BASE .. ".config") ---@type GNUI.config

local Box = require(cfg.WIDGETS .. ".box") ---@type GNUI.BoxAPI
local Event = require(cfg.EVENT)
local Button = require(cfg.WIDGETS .. ".button") ---@type GNUI.Widget.ButtonAPI

local Style = require(cfg.THEME .. ".init") ---@type GNUI.ThemeAPI
local Layout = require(cfg.LAYOUT .. ".init") ---@type GNUI.LayoutAPI

local utils = require(cfg.UTILS) ---@type GNUI.utils

---@class Event.GNUI.Button.ValueChanged : GN.Event
---@field register fun(self,func:fun(value: number))


---@class GNUI.Widget.SliderAPI
local SliderAPI = {}


---A widget that allows users to select a single value or a range of predefined spectrum  by dragging a handle (thumb) along a bar.
---@class GNUI.Widget.Slider : GNUI.Widget.Button
---@field isVertical boolean #Tells if the slider is vertical
---@field boxKnob GNUI.Box
---
---@field value number # The default value
---@field min number # the minimum allowed value
---@field max number # the maximum allowed value
---@field step number # the step size of the slider, 0 for none
---
---@field softBoundary boolean # Tells if the slider is allowed to go out of bounds
---@field softSnapping boolean # Tells if the slider is allowed to have values outside its snap size
---
---@field prefix string # the prefix when the value is displayed
---@field suffix string # the suffix when the value is displayed
---
---@field knobLength integer?
---
---@field VALUE_CHANGED Event.GNUI.Button.ValueChanged # triggered when the value is changed
---@field PRESSED GN.Event # triggered when the slider is pressed
local Slider = {}
Slider.__index = function(t, i)
	return rawget(t, i)
		 or Slider[i]
		 or Button.index(t, i)
		 or Box.index(t, i)
end
Slider.__style = "slider"
Slider.__type = "Slider"

local function snap(value, step, offset)
	offset = offset or 0
	if step < 0.0001 then
		return value
	end
	return math.floor((value + offset) / step + 0.5) * step - offset
end


---@param canvas GNUI.Canvas
---@return GNUI.Widget.Slider
function SliderAPI.new(box,canvas,children)
	local self = Button.new(box,canvas,children)
	---@cast self GNUI.Widget.Slider
	setmetatable(self, Slider)

	self.isVertical = false
	self.value = 0
	self.min = 0
	self.max = 100
	self.step = 10
	self.softBoundary = false
	self.prefix = ""
	self.suffix = ""
	self.VALUE_CHANGED = Event.new()

	self.sizing[self.isVertical and "x" or "y"] = "FIXED"
	self.layout = "FIXED"

	local boxKnob = Box.new(canvas)
	for index, value in ipairs(children) do
		value:setCaptureInputs(false)
		self:addChild(value)
	end
	self.boxKnob = boxKnob
	boxKnob:setSizing("FIXED", "FIXED")
	boxKnob:setCaptureInputs(false)
	self:setSizing("FIXED", "FIT")
	self:addChild(boxKnob)

	self.SIZE_CHANGED:register(function(size)
		self:updateKnob()
	end)

	self.BUTTON_DOWN:register(function()
		local offset = vec(0,0)
		local original = self.value
		self.canvas.CURSOR_MOVED:register(function(pos, vel)
			offset = offset + vel
			self:processSlider(offset,original)
		end, self.id)
	end)

	self.BUTTON_UP:register(function()
		self.canvas.CURSOR_MOVED:remove(self.id)
	end)
	return self
end

local function getKnobLength(box)
	local len = box.knobLength or Style.getStyleFromBox(box, "knobLength")
	if len == -1 then
		return box.isVertical and box.boxKnob.finalSize.x or box.boxKnob.finalSize.y
	end
	return len
end

--TODO: cache the knob length
function Slider:processSlider(offset, original)
	local knobLength = getKnobLength(self)
	local lastValue = self.value
	if self.isVertical then
		local track = self.finalSize.y - knobLength
		self.value = track > 0 and (original + math.map(offset.y, 0, track, 0, self.max - self.min)) or self.min
	else
		local track = self.finalSize.x - knobLength
		self.value = track > 0 and (original + math.map(offset.x, 0, track, 0, self.max - self.min)) or self.min
	end
	self.value = math.clamp(self.value, self.min, self.max)
	self.value = snap(self.value, self.step)
	if lastValue ~= self.value then
		self.VALUE_CHANGED:invoke(self.value)
		self:updateKnob()
	end
end

function Slider:updateKnob()
	local knobLength = getKnobLength(self)
	---@cast knobLength number
	local padding = self:getPadding()
	local hasRange = self.max > self.min
	self.boxKnob
		 :setSize(
			 self.isVertical and (self.finalSize.x - padding.x - padding.z) or knobLength,
			 not self.isVertical and (self.finalSize.y - padding.y - padding.w) or knobLength
		 )
		 :setPos(
			 not self.isVertical and
			 (hasRange and math.map(
				self.value, 
				self.min, self.max, 
				padding.x,
				self.finalSize.x - knobLength - padding.z
			) or padding.x) or padding.x,
			 self.isVertical and
			 (hasRange and math.map(
				self.value,
				self.min,
				self.max,
				-padding.y,
				self.finalSize.y - knobLength
			) or -padding.y) or -padding.y
		 )
	self.boxKnob.finalSize = self.boxKnob.size:copy()
	self.boxKnob.finalPos = self.boxKnob.pos:copy()
end

function Slider:_recalculateValue()
	self.value = math.clamp(self.value, self.min, self.max)
	self:update()
end

---@param vertical boolean
---@generic self
---@param self self
---@return self
function Slider:setVertical(vertical)
	---@cast self GNUI.Widget.Slider
	self.isVertical = vertical
	self.sizing[vertical and "x" or "y"] = "FIT"
	self.sizing[vertical and "y" or "x"] = "FILL"
	self:update()
	return self
end

---@param value number
---@generic self
---@param self self
---@return self
function Slider:setValue(value)
	---@cast self GNUI.Widget.Slider
	self.value = value
	self.VALUE_CHANGED:invoke(value)
	self:updateKnob()
	return self
end


---Sets the value of the slider, as a number between 0 and 1, it automatically maps it to the min and max
---@param value number
---@generic self
---@param self self
---@return self
function Slider:setNormalizedValue(value)
	---@cast self GNUI.Widget.Slider
	self.value = math.map(value, 0, 1, self.min, self.max)
	self.VALUE_CHANGED:invoke(self.value)
	self:updateKnob()
	return self
end


---Sets the value of the slider, as a number between 0 and 1, it automatically maps it to the min and max, and without calling the `VALUE_CHANGED` event
---@param value number
---@generic self
---@param self self
---@return self
function Slider:setNormalizedValueSilent(value)
	---@cast self GNUI.Widget.Slider
	self.value = math.map(value, 0, 1, self.min, self.max)
	self:updateKnob()
	return self
end


---Sets the value of the slider, without calling the `VALUE_CHANGED` event
---@param value number
---@generic self
---@param self self
---@return self
function Slider:setValueSilent(value)
	---@cast self GNUI.Widget.Slider
	self.value = value
	self:updateKnob()
	return self
end

---@param min number
---@generic self
---@param self self
---@return self
function Slider:setMin(min)
	---@cast self GNUI.Widget.Slider
	self.min = min
	self:_recalculateValue()
	self:updateKnob()
	return self
end

---@param max number
---@generic self
---@param self self
---@return self
function Slider:setMax(max)
	---@cast self GNUI.Widget.Slider
	self.max = max
	self:_recalculateValue()
	self:updateKnob()
	return self
end

---@param min number
---@param max number
---@param softBoundary boolean?
---@generic self
---@param self self
---@return self
function Slider:setRange(min, max, softBoundary)
	---@cast self GNUI.Widget.Slider
	self.min = min
	self.max = max
	self.softBoundary = softBoundary or false
	self:_recalculateValue()
	self:updateKnob()
	return self
end

---@param stepSize number
---@generic self
---@param self self
---@return self
function Slider:setStepSize(stepSize)
	---@cast self GNUI.Widget.Slider
	self.step = stepSize
	self:_recalculateValue()
	self:updateKnob()
	return self
end

---@param prefix string
---@generic self
---@param self self
---@return self
function Slider:setPrefix(prefix)
	---@cast self GNUI.Widget.Slider
	self.prefix = prefix
	self:update()
	return self
end

---@param suffix string
---@generic self
---@param self self
---@return self
function Slider:setSuffix(suffix)
	---@cast self GNUI.Widget.Slider
	self.suffix = suffix
	self:update()
	return self
end


---@param length integer?
---@generic self
---@param self self
---@return self
function Slider:setKnobLength(length)
	---@cast self GNUI.Widget.Slider
	self.knobLength = length
	self:updateKnob()
	self:update()
	return self
end

---@param softBoundary boolean
---@return GNUI.Widget.Slider
function Slider:setSoftBoundary(softBoundary)
	---@cast self GNUI.Widget.Slider
	self.softBoundary = softBoundary
	self:updateKnob()
	self:update()
	return self
end


---Returns the value of the slider
---@return number
function Slider:getValue()
	return self.value
end


--Returns the value of the slider as a number between 0 and 1.
---@return number
function Slider:getNormalizedValue()
	return math.map(self.value, self.min, self.max, 0, 1)
end


---Applies the appropriate style to the button, based on its state.
---
---this is called automatically by built in events
---@generic self
---@param self self
---@return self
function Slider:applyApropriateStyle()
	---@cast self GNUI.Widget.Slider
	if self.sprites[2] then
		self.sprites[2]:setVisible(self.isHovered)
	end
	if self.down then
		self.sprites[1]:setStyle(Style.getStyleFromBox(self, "pressed"))
	else
		self.sprites[1]:setStyle(Style.getStyleFromBox(self, "normal"))
	end
	return self
end

---Sets the style of the sprite of this box, if no sprite exists, it will create one for that given style
---
---@generic self
---@param self self
---@return self
---@param variant string?
function Slider:setStyleVariant(variant)
	variant = variant or "default"
	---@cast self GNUI.Widget.Slider

	self.variant = variant
	local style = Style.getStyle(self, variant, "normal")
	style:newInstance(self,1)

	--TODO: replace styling method with a cleaner one
	self.boxKnob.variant = variant

	Style.getStyle("box", "highlight", "normal")
		 :newInstance(self, 2)
		 :setVisible(false)

	Style.getStyleFromBox(self, "knob")
		 :newInstance(self.boxKnob)

	self:recalculateMargin()
	self:recalculatePadding()
	self:recalculateMinimumSize()
	self:update()
	return self
end

--────────────────────────-< Layout Parser >-────────────────────────--


---@diagnostic disable: duplicate-doc-field
---@class GNUI.Layout
---@field type "slider"?
---
---@field isVertical boolean?
---@field value number?
---@field min number?
---@field max number?
---@field step number?
---
---@field softBoundary boolean?
---
---@field prefix string?
---@field suffix string?
---@field knobLength integer?

---@param layout any
---@param canvas GNUI.Canvas
---@param button GNUI.Widget.Button?
---@return GNUI.Widget.Slider
function SliderAPI.parse(layout, canvas, children, button)
	local self = button or Box.parse(layout, canvas, children, SliderAPI.new)
	---@cast self GNUI.Widget.Slider

	self:setToggle(false) -- force sliders to be non-toggleable

	local isVertical = layout.isVertical
	self:setVertical(isVertical) 
	if layout.sizing then
		if type(layout.sizing) == "string" then
			---@diagnostic disable-next-line: param-type-mismatch
			self:setSizing(layout.sizing, layout.sizing)
		else
			self:setSizing(layout.sizing[1], layout.sizing[2])
		end
	else
		self:setSizing(isVertical and "FIT" or "FILL", isVertical and "FILL" or "FIT")
	end
	if layout.value then self.value = layout.value end
	if layout.min then self:setMin(layout.min) end
	if layout.max then self:setMax(layout.max) end
	if layout.step then self:setStepSize(layout.step) end
	if layout.softBoundary then self:setSoftBoundary(layout.softBoundary) end
	if layout.prefix then self:setPrefix(layout.prefix) end
	if layout.suffix then self:setSuffix(layout.suffix) end
	if layout.knobLength then  self:setKnobLength(layout.knobLength) end
	return self
end

Layout.registerType("slider", SliderAPI.parse)

return SliderAPI
