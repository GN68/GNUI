--[[______   __
  / ____/ | / /  by: GNanimates / https://gnon.top / Discord: @gn68s
 / / __/  |/ / name: GNUI SpinBox Class
/ /_/ / /|  /  desc: numeric text field widget with a draggable step knob
\____/_/ |_/ source: link ]]

local BASE = ((...):gsub("/", ".")):match(".+%.GNUI")
local cfg = require(BASE .. ".config") ---@type GNUI.config

local Box = require(cfg.WIDGETS .. ".box") ---@type GNUI.BoxAPI
local Event = require(cfg.EVENT)
local Button = require(cfg.WIDGETS .. ".button") ---@type GNUI.Widget.ButtonAPI
local TextField = require(cfg.WIDGETS .. ".buttons.textField") ---@type GNUI.Widget.TextFieldAPI

local Style = require(cfg.THEME .. ".init") ---@type GNUI.ThemeAPI
local Layout = require(cfg.LAYOUT .. ".init") ---@type GNUI.LayoutAPI

---@class GNUI.Widget.SpinBoxAPI
local SpinBoxAPI = {}

---A numeric input widget that combines a TextField with a draggable right-side knob and scroll wheel stepping.
---@class GNUI.Widget.SpinBox : GNUI.Widget.TextField
---@field isVertical boolean # If true, only vertical dragging on the knob adjusts the value
---@field boxKnob GNUI.Widget.Button # The draggable knob button on the right
---@field value number # Current numeric value
---@field min number # Minimum allowed value
---@field max number # Maximum allowed value
---@field step number # Step increment (0 for continuous)
---@field softBoundary boolean # If true, values are not clamped to [min, max]
---@field loop boolean # If true, values wrap around between min and max
---@field knobLength integer? # Custom width of the right-side knob
---@field pixelsPerStep number # Drag distance in pixels per step (default: 2)
---@field VALUE_CHANGED Event.GNUI.Button.ValueChanged # Triggered when the numeric value changes
local SpinBox = {}
SpinBox.__index = function(t, i)
	return rawget(t, i)
		or SpinBox[i]
		or TextField.index(t, i)
		or Button.index(t, i)
		or Box.index(t, i)
end
SpinBox.__style = "spinBox"
SpinBox.__type = "SpinBox"

function SpinBox.index(t, i)
	return SpinBox.__index(t, i)
end

SpinBoxAPI.index = SpinBox.index

setmetatable(SpinBoxAPI, {
	__index = function(t, i)
		return rawget(t, i)
			or SpinBox[i]
			or TextField.index(t, i)
			or Button.index(t, i)
			or Box.index(t, i)
	end,
})

---@param value number
---@param step number
---@param offset number?
---@return number
local function snap(value, step, offset)
	offset = offset or 0
	if not step or step < 0.0001 then
		return value
	end
	local snapped = math.floor((value + offset) / step + 0.5) * step - offset
	return tonumber(string.format("%.10g", snapped)) or snapped
end

---@param value number
---@return string
local function formatNumber(value)
	if value % 1 == 0 then
		return string.format("%d", value)
	end
	return string.format("%.10g", value)
end

---@param box GNUI.Widget.SpinBox
---@return number
local function getKnobLength(box)
	if box.knobLength then
		return box.knobLength
	end
	local ok, len = pcall(Style.getStyleFromBox, box, "knobLength")
	if ok and type(len) == "number" then
		return len
	end
	return 7
end

---@param box GNUI.Widget.SpinBox
---@return string
local function getKnobStyleVariant(box)
	if box.variant then
		local ok, styleVariant = pcall(Style.getStyle, box, box.variant, "knobStyle")
		if ok and type(styleVariant) == "string" then
			return styleVariant
		end
	end
	return "default"
end

---@param box GNUI.Box
---@param canvas GNUI.Canvas
---@param children GNUI.Box[]?
---@return GNUI.Widget.SpinBox
function SpinBoxAPI.new(box, canvas, children)
	local self = TextField.new(box, canvas, children)
	---@cast self GNUI.Widget.SpinBox
	setmetatable(self, SpinBox)

	self.isVertical = false
	self.value = 0
	self.min = 0
	self.max = 100
	self.step = 1
	self.softBoundary = false
	self.loop = false
	self.pixelsPerStep = 2
	self.prefix = ""
	self.suffix = ""
	self.VALUE_CHANGED = Event.new()
	self.layout = "FIXED"

	self.validator = function(field)
		return tonumber(field) ~= nil
	end

	local knob = Button.new(Box.new(canvas), canvas, {})
	knob:setToggle(false)
	knob:setSizing("FIXED", "FIXED")
	knob:setStyleVariant("default")
	self.boxKnob = knob
	self:addChild(knob)

	self.SIZE_CHANGED:register(function()
		self:updateKnob()
	end)

	knob.BUTTON_DOWN:register(function()
		if self.down then
			self:confirm()
		end
		local dragOffset = vec(0, 0)
		local startValue = self.value
		self.canvas.CURSOR_MOVED:register(function(_, vel)
			dragOffset = dragOffset + vel
			self:_processKnobDrag(dragOffset, startValue)
		end, knob.id)
	end, "__core")

	knob.BUTTON_UP:register(function()
		if self.canvas then
			self.canvas.CURSOR_MOVED:remove(knob.id)
		end
	end, "__core")

	local function onScroll(x, y)
		local dir = (y ~= 0) and y or x
		if dir ~= 0 then
			if self.down then
				self:confirm()
			end
			self:setValue(self.value + dir * self:getEffectiveStep())
			return true
		end
	end

	self.SCROLL_INPUT:register(onScroll, "__spinbox_scroll")
	knob.SCROLL_INPUT:register(onScroll, "__spinbox_scroll")

	self.field = formatNumber(self.value)
	self.editingField = self.field
	self:setText(self.field)
	self:updateKnob()

	return self
end

---@return number
function SpinBox:getEffectiveStep()
	if self.step and self.step > 0 then
		return self.step
	end
	if self.max > self.min and self.max < math.huge and self.min > -math.huge then
		return (self.max - self.min) / 100
	end
	return 0.1
end

---@private
---@param offset Vector2
---@param startValue number
function SpinBox:_processKnobDrag(offset, startValue)
	local deltaPixels = self.isVertical and -offset.y or (offset.x - offset.y)
	local pxPerStep = (self.pixelsPerStep and self.pixelsPerStep > 0) and self.pixelsPerStep or 2
	local steps = deltaPixels / pxPerStep
	local rawValue = startValue + steps * self:getEffectiveStep()
	self:setValue(rawValue)
end

---@private
---@param value number?
---@return number
function SpinBox:_sanitizeValue(value)
	value = tonumber(value) or self.value or 0
	value = snap(value, self.step)
	if self.loop and self.max > self.min and self.max < math.huge and self.min > -math.huge then
		local span = self.max - self.min
		if span > 0 then
			value = self.min + ((value - self.min) % span)
		end
	elseif not self.softBoundary then
		value = math.clamp(value, self.min, self.max)
	end
	return value
end

function SpinBox:updateKnob()
	if not self.boxKnob then return end
	local knobLen = getKnobLength(self)
	local w = self.finalSize.x
	local h = self.finalSize.y
	self.boxKnob
		:setSize(knobLen, h)
		:setPos(math.max(0, w - knobLen), 0)
	return self
end

---@generic self
---@param self self
---@return self
function SpinBox:confirm()
	---@cast self GNUI.Widget.SpinBox
	if self.down then
		local num = tonumber(self.editingField)
		if num and (not self.validator or self.validator(self.editingField)) then
			self:release()
			self:setValue(num)
			self.FIELD_CONFIRMED:invoke(self.field)
		else
			self:discard()
		end
	end
	return self
end

---@generic self
---@param self self
---@return self
function SpinBox:discard()
	---@cast self GNUI.Widget.SpinBox
	if self.down then
		self.FIELD_DISCARDED:invoke(self.editingField)
		self.editingField = self.field
		self.cursor = #self.field
		self:release()
	end
	return self
end

---@param value number?
---@generic self
---@param self self
---@return self
function SpinBox:setValue(value)
	---@cast self GNUI.Widget.SpinBox
	local newValue = self:_sanitizeValue(value)
	local formatted = formatNumber(newValue)
	local changed = (self.value ~= newValue)
	self.value = newValue
	self:setField(formatted)
	if self.down then
		self:setEditingField(formatted)
	end
	if changed then
		self.VALUE_CHANGED:invoke(newValue)
	end
	return self
end

---@param value number?
---@generic self
---@param self self
---@return self
function SpinBox:setValueSilent(value)
	---@cast self GNUI.Widget.SpinBox
	local newValue = self:_sanitizeValue(value)
	local formatted = formatNumber(newValue)
	self.value = newValue
	self:setField(formatted)
	if self.down then
		self:setEditingField(formatted)
	end
	return self
end

---@return number
function SpinBox:getValue()
	return self.value
end

---@param min number
---@generic self
---@param self self
---@return self
function SpinBox:setMin(min)
	---@cast self GNUI.Widget.SpinBox
	self.min = min
	self:setValue(self.value)
	return self
end

---@param max number
---@generic self
---@param self self
---@return self
function SpinBox:setMax(max)
	---@cast self GNUI.Widget.SpinBox
	self.max = max
	self:setValue(self.value)
	return self
end

---@param min number
---@param max number
---@param softBoundary boolean?
---@generic self
---@param self self
---@return self
function SpinBox:setRange(min, max, softBoundary)
	---@cast self GNUI.Widget.SpinBox
	self.min = min
	self.max = max
	if softBoundary ~= nil then
		self.softBoundary = softBoundary
	end
	self:setValue(self.value)
	return self
end

---@param stepSize number
---@generic self
---@param self self
---@return self
function SpinBox:setStepSize(stepSize)
	---@cast self GNUI.Widget.SpinBox
	self.step = stepSize
	self:setValue(self.value)
	return self
end

SpinBox.setStep = SpinBox.setStepSize

---@param loop boolean
---@generic self
---@param self self
---@return self
function SpinBox:setLoop(loop)
	---@cast self GNUI.Widget.SpinBox
	self.loop = loop
	self:setValue(self.value)
	return self
end

---@param softBoundary boolean
---@generic self
---@param self self
---@return self
function SpinBox:setSoftBoundary(softBoundary)
	---@cast self GNUI.Widget.SpinBox
	self.softBoundary = softBoundary
	self:setValue(self.value)
	return self
end

---@param vertical boolean
---@generic self
---@param self self
---@return self
function SpinBox:setVertical(vertical)
	---@cast self GNUI.Widget.SpinBox
	self.isVertical = vertical
	return self
end

---@param length integer?
---@generic self
---@param self self
---@return self
function SpinBox:setKnobLength(length)
	---@cast self GNUI.Widget.SpinBox
	self.knobLength = length
	self:updateKnob()
	return self
end

---@param pixels number
---@generic self
---@param self self
---@return self
function SpinBox:setPixelsPerStep(pixels)
	---@cast self GNUI.Widget.SpinBox
	self.pixelsPerStep = pixels
	return self
end

---@generic self
---@param self self
---@param variant string?
---@return self
function SpinBox:setStyleVariant(variant)
	variant = variant or "default"
	---@cast self GNUI.Widget.SpinBox

	self.variant = variant
	local style = Style.getStyle(self, variant, "normal")
	style:newInstance(self, 1)

	if self.boxKnob then
		self.boxKnob:setStyleVariant(getKnobStyleVariant(self))
	end

	self:recalculateMargin()
	self:recalculatePadding()
	self:recalculateMinimumSize()
	self:applyApropriateStyle()
	self:updateKnob()
	self:update("dim")
	return self
end

--────────────────────────-< Layout Parser >-────────────────────────--

---@diagnostic disable: duplicate-doc-field
---@class GNUI.Layout
---@field type "spinBox"?
---@field value number?
---@field min number?
---@field max number?
---@field step number?
---@field softBoundary boolean?
---@field loop boolean?
---@field isVertical boolean?
---@field knobLength integer?
---@field pixelsPerStep number?
---@field prefix string?
---@field suffix string?
---@field placeholder string?

---@param layout GNUI.Layout
---@param canvas GNUI.Canvas
---@param children GNUI.Box[]?
---@param spinBox GNUI.Widget.SpinBox?
---@return GNUI.Widget.SpinBox
function SpinBoxAPI.parse(layout, canvas, children, spinBox)
	local box = spinBox or Box.parse(layout, canvas, children, SpinBoxAPI.new)
	---@cast box GNUI.Widget.SpinBox

	if layout.min ~= nil then box.min = layout.min end
	if layout.max ~= nil then box.max = layout.max end
	if layout.step ~= nil then box.step = layout.step end
	if layout.softBoundary ~= nil then box.softBoundary = layout.softBoundary end
	if layout.loop ~= nil then box.loop = layout.loop end
	if layout.isVertical ~= nil then box:setVertical(layout.isVertical) end
	if layout.knobLength ~= nil then box:setKnobLength(layout.knobLength) end
	if layout.pixelsPerStep ~= nil then box:setPixelsPerStep(layout.pixelsPerStep) end
	if layout.prefix then box:setPrefix(layout.prefix) end
	if layout.suffix then box:setSuffix(layout.suffix) end
	if layout.placeholder then box:setPlaceholder(layout.placeholder) end

	if layout.value ~= nil then
		box:setValueSilent(layout.value)
	elseif layout.field ~= nil and tonumber(layout.field) then
		box:setValueSilent(tonumber(layout.field))
	else
		box:setValueSilent(box.value)
	end

	box:applyApropriateStyle()
	box:updateKnob()
	return box
end

Layout.registerType("spinBox", SpinBoxAPI.parse)

return SpinBoxAPI
