--[[______   __
  / ____/ | / /  by: GNanimates / https://gnon.top / Discord: @gn68s
 / / __/  |/ / name: GNUI Container Widget
/ /_/ / /|  /  desc: A box widget with automatic vertical and horizontal overflow scrollbars
\____/_/ |_/ source: link ]]
---@diagnostic disable: duplicate-doc-field, param-type-mismatch

local BASE = ((...):gsub("/", ".")):match(".+%.GNUI")
local cfg = require(BASE .. ".config") ---@type GNUI.config

local Box = require(cfg.WIDGETS .. ".box") ---@type GNUI.BoxAPI
local Slider = require(cfg.WIDGETS .. ".buttons.slider") ---@type GNUI.Widget.SliderAPI
local Layout = require(cfg.LAYOUT .. ".init") ---@type GNUI.LayoutAPI

---@class GNUI.Widget.ContainerAPI : GNUI.BoxAPI
local ContainerAPI = {}

---A Box that automatically displays vertical (right) and horizontal (bottom) scrollbars when its children overflow.
---@class GNUI.Widget.Container : GNUI.Box
---@field scrollBarV GNUI.Widget.Slider # Vertical scrollbar on the right
---@field scrollBarH GNUI.Widget.Slider # Horizontal scrollbar on the bottom
---@field contentSize Vector2 # Total encapsulated size of all children
---@field contentBounds Vector4 # Encapsulated bounds (minX, minY, maxX, maxY) of all children
---@field scrollSpeed number # Scroll wheel step in pixels (default: 15)
---@field scrollBarThickness number? # Optional custom thickness for the scrollbars
local Container = {}
Container.__index = function(t, i)
	return rawget(t, i)
		or Container[i]
		or Box.index(t, i)
end
Container.__style = "box"
Container.__type = "Container"

function ContainerAPI.index(t, i)
	return Container.__index(t, i)
end

setmetatable(ContainerAPI, {
	__index = function(t, i)
		return rawget(t, i)
			or Container[i]
			or Box.index(t, i)
	end,
})

---@param self GNUI.Widget.Container
---@return boolean
local function popScrollBars(self)
	local n = #self.children
	if n >= 2 and self.children[n - 1] == self.scrollBarV and self.children[n] == self.scrollBarH then
		self.children[n] = nil
		self.children[n - 1] = nil
		return true
	end
	return false
end

---@param self GNUI.Widget.Container
---@param popped boolean
local function pushScrollBars(self, popped)
	if popped then
		local n = #self.children
		self.children[n + 1] = self.scrollBarV
		self.children[n + 2] = self.scrollBarH
		self.scrollBarV.childIndex = n + 1
		self.scrollBarH.childIndex = n + 2
	end
end

---@overload fun(canvas: GNUI.Canvas): GNUI.Widget.Container
---@param box GNUI.Box
---@param canvas GNUI.Canvas
---@param children GNUI.Box[]?
---@return GNUI.Widget.Container
function ContainerAPI.new(box, canvas, children)
	if not canvas and box and box.display then
		canvas = box 
		---@cast canvas GNUI.Canvas
		box = Box.new(canvas)
	end
	local self = box or Box.new(canvas)
	---@cast self GNUI.Widget.Container
	setmetatable(self, Container)

	self.contentSize = vec(0, 0)
	self.contentBounds = vec(0, 0, 0, 0)
	self.scrollSpeed = 15
	self.scrollBarThickness = nil
	self.clipChildren = true

	if children then
		for _, child in ipairs(children) do
			Box.addChild(self, child)
		end
	end

	local scrollBarV = Slider.parse({
		type = "slider",
		isVertical = true,
		min = 0,
		max = 0,
		step = 0,
		value = 0,
		sizing = { "FIXED", "FIXED" },
	}, canvas, {})
	scrollBarV:setVisible(false)

	local scrollBarH = Slider.parse({
		type = "slider",
		isVertical = false,
		min = 0,
		max = 0,
		step = 0,
		value = 0,
		sizing = { "FIXED", "FIXED" },
	}, canvas, {})
	scrollBarH:setVisible(false)

	self.scrollBarV = scrollBarV
	self.scrollBarH = scrollBarH

	Box.addChild(self, scrollBarV)
	Box.addChild(self, scrollBarH)

	scrollBarV.VALUE_CHANGED:register(function(value)
		self:setChildrenOffset(self.childrenOffset.x, -value)
	end, "__container_vscroll")

	scrollBarH.VALUE_CHANGED:register(function(value)
		self:setChildrenOffset(-value, self.childrenOffset.y)
	end, "__container_hscroll")

	local isShiftPressed = false
	self.KEY_INPUT:register(function (scancode, state)
		if scancode == 340 then -- shift
			isShiftPressed = (state == 1)
		end
	end)
	
	self.UNHANDLED_SCROLL_INPUT:register(function(y, x)
		local dir = (y ~= 0) and y or x
		if dir ~= 0 then
			if self.scrollBarV and self.scrollBarV.visible and not isShiftPressed then
				local newVal = math.clamp(self.scrollBarV.value - dir * self.scrollSpeed, self.scrollBarV.min, self.scrollBarV.max)
				if newVal ~= self.scrollBarV.value then
					self.scrollBarV:setValue(newVal)
					return true
				end
			elseif self.scrollBarH and self.scrollBarH.visible then
				local newVal = math.clamp(self.scrollBarH.value - dir * self.scrollSpeed, self.scrollBarH.min, self.scrollBarH.max)
				if newVal ~= self.scrollBarH.value then
					self.scrollBarH:setValue(newVal)
					return true
				end
			end
		end
	end, "__container_scroll")

	return self
end

---@param child GNUI.Box
---@generic self
---@param self self
---@return GNUI.Box
function Container:addChild(child)
	---@cast self GNUI.Widget.Container
	Box.addChild(self, child)
	if child ~= self.scrollBarV and child ~= self.scrollBarH
		and self.scrollBarV and self.scrollBarH
		and self.scrollBarV.parent == self and self.scrollBarH.parent == self
	then
		local count = #self.children
		self.scrollBarV:setChildIndex(count)
		self.scrollBarH:setChildIndex(count)
	end
	return child
end

---@return Vector2
function Container:getContentSize()
	return self.contentSize
end

---@return GNUI.Widget.Slider, GNUI.Widget.Slider
function Container:getScrollBars()
	return self.scrollBarV, self.scrollBarH
end

---@param speed number
---@generic self
---@param self self
---@return self
function Container:setScrollSpeed(speed)
	---@cast self GNUI.Widget.Container
	self.scrollSpeed = speed
	return self
end

---@return number
function Container:getScrollSpeed()
	return self.scrollSpeed
end

---@param thickness number?
---@generic self
---@param self self
---@return self
function Container:setScrollBarThickness(thickness)
	---@cast self GNUI.Widget.Container
	if self.scrollBarThickness ~= thickness then
		self.scrollBarThickness = thickness
		self:update("dim")
	end
	return self
end

---@return number?
function Container:getScrollBarThickness()
	return self.scrollBarThickness
end

---@param isY boolean
function Container:_solveFit(isY)
	local popped = popScrollBars(self)
	Box.index(self, "_solveFit")(self, isY)
	pushScrollBars(self, popped)
	if self.scrollBarV then self.scrollBarV:_solveFit(isY) end
	if self.scrollBarH then self.scrollBarH:_solveFit(isY) end
end

---@param isY boolean
function Container:_solveFill(isY)
	local popped = popScrollBars(self)
	Box.index(self, "_solveFill")(self, isY)
	pushScrollBars(self, popped)
end

---@param isY boolean
function Container:_solveLayout(isY)
	local popped = popScrollBars(self)
	Box.index(self, "_solveLayout")(self, isY)
	if isY then
		self:_updateScrollBars()
	end
	pushScrollBars(self, popped)
end

function Container:_updateScrollBars()
	if not self.visible then return end
	local vBar = self.scrollBarV
	local hBar = self.scrollBarH
	if not vBar or not hBar then return end

	local padding = self:getPadding()
	local minX, minY = 0, 0
	local maxX, maxY = 0, 0
	local hasVisibleChild = false

	for _, child in ipairs(self.children) do
		if child.visible and child ~= vBar and child ~= hBar then
			local m = child:getMargin()
			local childX = child.finalPos.x - self.childrenOffset.x
			local childY = child.finalPos.y - self.childrenOffset.y
			if not hasVisibleChild then
				minX = math.min(0, childX - m.x - padding.x)
				minY = math.min(0, childY - m.y - padding.y)
				hasVisibleChild = true
			else
				minX = math.min(minX, childX - m.x - padding.x)
				minY = math.min(minY, childY - m.y - padding.y)
			end
			maxX = math.max(maxX, childX + child.finalSize.x + m.z + padding.z)
			maxY = math.max(maxY, childY + child.finalSize.y + m.w + padding.w)
		end
	end

	self.contentBounds = vec(minX, minY, maxX, maxY)
	self.contentSize = vec(maxX - minX, maxY - minY)

	local overflowX = (minX < -0.001) or (maxX > self.finalSize.x + 0.001)
	local overflowY = (minY < -0.001) or (maxY > self.finalSize.y + 0.001)

	vBar.visible = overflowY
	hBar.visible = overflowX

	local barW = self.scrollBarThickness or math.max(vBar.finalMinSize.x, 7)
	local barH = self.scrollBarThickness or math.max(hBar.finalMinSize.y, 7)

	if overflowY then
		local vW = barW
		local vH = math.max(0, self.finalSize.y - (overflowX and barH or 0))
		vBar.size = vec(vW, vH)
		vBar.finalSize = vec(vW, vH)
		vBar.pos = vec(self.finalSize.x - vW, 0)
		vBar.finalPos = vec(self.finalSize.x - vW, 0)

		vBar.min = minY
		vBar.max = math.max(0, maxY - self.finalSize.y)

		local totalH = maxY - minY
		local vPad = vBar:getPadding()
		local availTrackH = math.max(0, vH - vPad.y - vPad.w)
		local minKnobH = math.min(11, availTrackH)
		if totalH > 0 then
			vBar.knobLength = math.clamp(math.floor(availTrackH * (self.finalSize.y / totalH) + 0.5), minKnobH, availTrackH)
		else
			vBar.knobLength = availTrackH
		end

		vBar.value = math.clamp(-self.childrenOffset.y, vBar.min, vBar.max)
		vBar:updateKnob()
	else
		vBar.finalPos = vec(0, 0)
		vBar.finalSize = vec(0, 0)
	end

	if overflowX then
		local hW = math.max(0, self.finalSize.x - (overflowY and barW or 0))
		local hH = barH
		hBar.size = vec(hW, hH)
		hBar.finalSize = vec(hW, hH)
		hBar.pos = vec(0, self.finalSize.y - hH)
		hBar.finalPos = vec(0, self.finalSize.y - hH)

		hBar.min = minX
		hBar.max = math.max(0, maxX - self.finalSize.x)

		local totalW = maxX - minX
		local hPad = hBar:getPadding()
		local availTrackW = math.max(0, hW - hPad.x - hPad.z)
		local minKnobW = math.min(11, availTrackW)
		if totalW > 0 then
			hBar.knobLength = math.clamp(math.floor(availTrackW * (self.finalSize.x / totalW) + 0.5), minKnobW, availTrackW)
		else
			hBar.knobLength = availTrackW
		end

		hBar.value = math.clamp(-self.childrenOffset.x, hBar.min, hBar.max)
		hBar:updateKnob()
	else
		hBar.finalPos = vec(0, 0)
		hBar.finalSize = vec(0, 0)
	end

	vBar.prevFinalSize = vBar.finalSize:copy()
	hBar.prevFinalSize = hBar.finalSize:copy()
	for _, b in ipairs({ vBar, vBar.boxKnob, hBar, hBar.boxKnob }) do
		if b.flaggedUpdate and b.canvas then
			b.canvas.queueUpdate[b.flaggedUpdate] = nil
		end
		b.flaggedUpdate = false
		b.pendingDim = false
		b.pendingPos = false
		b.pendingVisual = false
	end

	vBar:_updateSprites()
	hBar:_updateSprites()
end

--────────────────────────-< Layout Parser >-────────────────────────--

---@class GNUI.Layout
---@field type "container"?
---@field scrollSpeed number?
---@field scrollBarThickness number?

---@param layout GNUI.Layout
---@param canvas GNUI.Canvas
---@param children GNUI.Box[]
---@param container GNUI.Widget.Container?
---@return GNUI.Widget.Container
function ContainerAPI.parse(layout, canvas, children, container)
	local self = container or Box.parse(layout, canvas, children, ContainerAPI.new)
	---@cast self GNUI.Widget.Container

	if layout.scrollSpeed ~= nil then
		self:setScrollSpeed(layout.scrollSpeed)
	end
	if layout.scrollBarThickness ~= nil then
		self:setScrollBarThickness(layout.scrollBarThickness)
	end

	return self
end

Layout.registerType("container", ContainerAPI.parse)

return ContainerAPI
