--[[______   __
  / ____/ | / /  by: GNanimates / https://gnon.top / Discord: @gn68s
 / / __/  |/ / name: Internal Primitive BoxAPI
/ /_/ / /|  /  desc: meant to be used by widgets, use the Widget Box API for anything else
\____/_/ |_/ source: link ]] ---@diagnostic disable: duplicate-doc-field
local BASE = ((...):gsub("/", ".")):match(".+%.GNUI")
local cfg = require(BASE .. ".config") ---@type GNUI.config

local Style = require(cfg.THEME .. ".init") ---@type GNUI.ThemeAPI

local gncommon = require(cfg.GN_COMMON) ---@type GNCommon
local utils = require(cfg.UTILS) ---@type GNUI.utils
local Event = require(cfg.EVENT) ---@type GN.Event

local Layout = require(cfg.LAYOUT .. ".init") ---@type GNUI.LayoutAPI

local abs = math.abs

---@class GNUI.Primitive.BoxAPI
local BoxAPI = {}

---@alias GNUI.Box.SizingMode string
---| "FIXED"
---| "FIT"
---| "FILL"

---@alias GNUI.Box.LayoutMode string?
---| "VERTICAL"
---| "HORIZONTAL"
---| "VERTICAL_REVERSED"
---| "HORIZONTAL_REVERSED"
---| "VERTICAL_WRAP"
---| "HORIZONTAL_WRAP"
---| "FIXED"
---| {size?:fun(self:GNUI.Box,children:GNUI.Box[],isY:boolean):(Vector2|number)?,pos?:fun(self:GNUI.Box,children:GNUI.Box[],isY:boolean)}

---@class GNUI.Box.Event.CharInput : GN.Event
---@field register fun(self,func:fun(char: string))

---@class GNUI.Box.Event.KeyInput : GN.Event
---@field register fun(self,func:fun(scancode:integer, state:integer))

---@class GNUI.Box.Event.MouseInput : GN.Event
---@field register fun(self,func:fun(button:integer,state:integer))

---@class GNUI.Box.Event.ScrollInput : GN.Event
---@field register fun(self,func:(fun(x:integer,y:integer):boolean?),id:any?)

---@class GNUI.Box.Event.CursorPresenceChanged : GN.Event
---@field register fun(self,func:fun(inside: boolean))

---@alias GNUI.Box.Flags string
---| "dim"
---| "pos"
---| "extents"
---| "color"
---| "text"
---| "visibility"

---@class GNUI.Box
---
---@field offsetPos Vector2
---@field pos Vector2
---@field size Vector2
---@field minSize Vector2
---@field maxSize Vector2
---@field padding Vector4
---@field margin Vector4
---
---@field finalPos Vector2
---@field finalSize Vector2
---@field finalMinSize Vector2
---@field finalMaxSize Vector2
---@field finalPadding Vector4
---@field finalMargin Vector4
---
---@field bounds Vector4
---
---@field SIZE_CHANGED GN.Event # called after size is changed for this element
---@field POSITION_CHANGED GN.Event # called after position is changed for this element
---
---@field sizing {x:GNUI.Box.SizingMode,y:GNUI.Box.SizingMode}
---
---@field childGap number
---
---@field layout GNUI.Box.LayoutMode?
---
---@field parent GNUI.Box?
---@field childIndex integer
---@field children GNUI.Box[]
---@field namedChildren table<string,GNUI.Box>
---@field childAlign Vector2
---@field growDirection Vector2
---@field scroll Vector2
---
---@field visible boolean
---@field color Vector3
---@field id integer
---
---@field absPos Vector2
---@field absSize Vector2
---@field absMinSize Vector2
---@field absMaxSize Vector2
---@field absPadding Vector4
---@field absMargin Vector4
---@field absBounds Vector4
---
---@field text string[]
---@field textColor Vector3
---@field textScale number
---@field textAlignment Vector2
---@field wrapText boolean
---
---@field flaggedUpdate boolean
---@field canvas GNUI.Canvas
---
---@field variant string?
---@field visualID integer
---@field sprites table<any,GNUI.Sprite> # middle man style handling
---
---@field captureInput boolean
---@field isHovered boolean
---
---@field z number
---@field zScale number
---
---@field flags table<GNUI.Box.Flags,boolean?>
---
---@field prevFinalSize Vector2?
---
---@field CURSOR_PRESENCE_CHANGED GNUI.Box.Event.CursorPresenceChanged
---@field KEY_INPUT GNUI.Box.Event.KeyInput
---@field CHAR_INPUT GNUI.Box.Event.CharInput
---@field MOUSE_INPUT GNUI.Box.Event.MouseInput
---@field SCROLL_INPUT GNUI.Box.Event.ScrollInput
---
---@field UNHANDLED_KEY_INPUT GNUI.Box.Event.KeyInput
---@field UNHANDLED_CHAR_INPUT GNUI.Box.Event.CharInput
---@field UNHANDLED_MOUSE_INPUT GNUI.Box.Event.MouseInput
---@field UNHANDLED_SCROLL_INPUT GNUI.Box.Event.ScrollInput
---
---@field CHILD_ADDED GN.Event
---@field CHILD_REMOVED GN.Event
---@field CHILDREN_ORDER_CHANGED GN.Event
local Box = {}
Box.__index = function(t, i)
	return rawget(t, i) or Box[i] or rawget(t, "children")[i] or
		 rawget(t, "namedChildren")[i]
end
Box.__style = "box"

function BoxAPI.index(t, i) return Box.__index(t, i) end

local nextFree = 1

---Creates a new box, the fundemental primitive element of GNUI.
---@param canvas GNUI.Canvas
---@return GNUI.Box
function BoxAPI.new(canvas)
	local self = {

		offsetPos = vec(0,0),
		pos = vec(0, 0),
		size = vec(-1, -1),
		minSize = nil,
		maxSize = vec(math.huge, math.huge),
		padding = nil,
		margin = nil,

		finalPos = vec(0, 0),
		finalSize = vec(0, 0),
		finalMinSize = vec(0, 0),
		finalMaxSize = vec(0, 0),
		finalPadding = vec(0, 0, 0, 0),
		finalMargin = vec(0, 0, 0, 0),
		finalChildGap = 0,

		bounds = vec(0, 0, 0, 0),

		SIZE_CHANGED = Event.new(),
		POSITION_CHANGED = Event.new(),

		sizing = { x = "FIXED", y = "FIXED" },

		childGap = nil,

		layout = "FIXED",

		parent = nil,
		childIndex = 0,
		children = {},
		namedChildren = {},
		childAlign = vec(-1, -1),
		growDirection = vec(1, 1),

		visible = true,
		color = vec(1, 1, 1),
		id = nextFree,

		absPos = vec(0, 0),
		prevFinalSize = vec(0, 0),
		pendingDim = false,
		pendingPos = false,
		pendingVisual = false,

		text = {},
		textScale = 1,
		
		wrapText = true,

		canvas = canvas,
		visualID = canvas and canvas.display:newVisual(),

		sprites = {},
		tasks = {},

		captureInput = true,
		isHovered = false,

		z = 0,
		zScale = 1,

		flags = {},

		CURSOR_PRESENCE_CHANGED = Event.new(),
		KEY_INPUT = Event.new(),
		CHAR_INPUT = Event.new(),
		MOUSE_INPUT = Event.new(),
		SCROLL_INPUT = Event.new(),

		UNHANDLED_KEY_INPUT = Event.new(),
		UNHANDLED_CHAR_INPUT = Event.new(),
		UNHANDLED_MOUSE_INPUT = Event.new(),
		UNHANDLED_SCROLL_INPUT = Event.new(),
		
		CHILD_ADDED = Event.new(),
		CHILD_REMOVED = Event.new(),
		CHILDREN_ORDER_CHANGED = Event.new(),
	}
	nextFree = nextFree + 1

	setmetatable(self, Box)
	return self
end

---@param name string
---@return GNUI.Box
function Box:setName(name)
	if self.parent then self.parent.namedChildren[name] = self end
	self.name = name
	return self
end

---Sets the position of the box,
---note that position only applies if the parent box dosent automatically handle it
---@overload fun(self: GNUI.Box ,pos : Vector2): GNUI.Box
---@param x number?
---@param y number?
---@generic self
---@param self self
---@return self
function Box:setPos(x, y)
	---@cast self GNUI.Box
	local newPos = gncommon.vec2(x, y)
	if newPos ~= self.pos then
		self.pos = newPos
		self:update("pos")
	end
	return self
end

---Sets the offset position of the box,
---@overload fun(self: GNUI.Box ,pos : Vector2): GNUI.Box
---@param x number?
---@param y number?
---@generic self
---@param self self
---@return self
function Box:setOffsetPos(x, y)
	---@cast self GNUI.Box
	local newPos = gncommon.vec2(x, y)
	if newPos ~= self.offsetPos then
		self.offsetPos = newPos
		self.parent:update("pos")
	end
	return self
end

---@return Vector2
function Box:getPos() return self.finalPos end

---@return Vector2
function Box:getGlobalPos()
	return self.absPos
end

local function printTree(box,level)
	print(string.rep("\t",level) .. (box.name or (type(box)..box.id)))
	for key, value in pairs(box.children) do
		printTree(value,level+1)
	end
end

function Box:printTree()
	printTree(self,0)
	print("----------------")
end

---@return Vector4
function Box:getGlobalBounds()
	local pos = self.bounds + self.finalPos.xyxy
	local parent = self.parent
	while parent do
		pos = pos + parent.finalPos.xyxy
		parent = parent.parent
	end
	---@cast pos Vector4
	return pos
end

---@generic self
---@param self self
---@return self
---@overload fun(self: GNUI.Box ,leftTop: Vector2, rightBottom: Vector2): GNUI.Box
---@overload fun(self: GNUI.Box ,leftTopRightBottom: Vector4): GNUI.Box
---@param left number
---@param top number
---@param right number
---@param bottom number
function Box:setMargin(left, top, right, bottom)
	---@cast self GNUI.Box
	self.margin = left and gncommon.vec4(left, top, right, bottom) or nil
	self:recalculateMargin()
	self:recalculateMinimumSize()
	self:update("dim")
	return self
end

function Box:recalculateMargin()
	if self.margin then
		self.finalMargin = self.margin:copy()
	else
		local margin = vec(0, 0, 0, 0)
		for key, sprite in pairs(self.sprites) do
			if sprite.style and sprite.style.margin then
				local styleMargin = sprite.style.margin
				margin.x = (abs(margin.x) <= abs(styleMargin.x)) and styleMargin.x or margin.x
				margin.y = (abs(margin.y) <= abs(styleMargin.y)) and styleMargin.y or margin.y
				margin.z = (abs(margin.z) <= abs(styleMargin.z)) and styleMargin.z or margin.z
				margin.w = (abs(margin.w) <= abs(styleMargin.w)) and styleMargin.w or margin.w
			end
		end
		self.finalMargin = margin
	end
end

---@return Vector4
function Box:getMargin() return self.finalMargin end

---@generic self
---@param self self
---@return self
---@overload fun(self: GNUI.Box ,leftTop: Vector2, rightBottom: Vector2): GNUI.Box
---@overload fun(self: GNUI.Box ,leftTopRightBottom: Vector4): GNUI.Box
---@param left number
---@param top number
---@param right number
---@param bottom number
function Box:setPadding(left, top, right, bottom)
	---@cast self GNUI.Box
	self.padding = left and gncommon.vec4(left, top, right, bottom) or nil
	self:recalculatePadding()
	self:recalculateMinimumSize()
	self:update("dim")
	return self
end

---@return Vector4
function Box:getPadding() return self.finalPadding end

function Box:recalculatePadding()
	if self.padding then
		self.finalPadding = self.padding:copy()
	else
		local padding = vec(0, 0, 0, 0)
		for key, sprite in pairs(self.sprites) do
			if sprite.style and sprite.style.padding then
				local p = sprite.style.padding
				padding.x = math.max(padding.x, p.x)
				padding.y = math.max(padding.y, p.y)
				padding.z = math.max(padding.z, p.z)
				padding.w = math.max(padding.w, p.w)
			end
		end
		self.finalPadding = padding
	end
	for key, value in pairs(self.sprites) do
		if value.labelID then
			value:setPadding(self.finalPadding:unpack())
		end
	end
end

---@generic self
---@param self self
---@return self
---@param gap number
function Box:setChildGap(gap)
	---@cast self GNUI.Box
	self.childGap = gap
	self:recalculateChildGap()
	self:update("dim")
	return self
end

function Box:recalculateChildGap()
	if self.childGap ~= nil then
		self.finalChildGap = self.childGap
	else
		local gap = 0
		for key, sprite in pairs(self.sprites) do
			if sprite.style and sprite.style.childGap then
				gap = sprite.style.childGap
			end
		end
		self.finalChildGap = gap
	end
end

---@return number
function Box:getChildGap() return self.finalChildGap end

---Sets the size of the box
---NOTE: setting an axis to -1 will make it automatically fit that given axis.
---@overload fun(self: GNUI.Box ,size : Vector2): GNUI.Box
---@param x number?
---@param y number?
---@generic self
---@param self self
---@return self
function Box:setSize(x, y)
	---@cast self GNUI.Box
	local newSize = gncommon.vec2(x, y, self.size)
	if newSize ~= self.size then
		self.size = newSize
		self:update("dim")
	end
	return self
end

---@overload fun(self: GNUI.Box ,size : Vector2): GNUI.Box
---@param x number?
---@param y number?
---@generic self
---@param self self
---@return self
function Box:setMinimumSize(x, y)
	---@cast self GNUI.Box
	self.minSize = (x or y) and gncommon.vec2(x, y, self.minSize or vec(0, 0)) or nil
	self:recalculateMinimumSize()
	self:update("dim")
	return self
end

---@return Vector2
function Box:getMinimumSize() return self.finalMinSize end

function Box:recalculateMinimumSize()
	if self.minSize then
		self.finalMinSize = self.minSize:copy()
	else
		local minSize = vec(0, 0)
		for key, sprite in pairs(self.sprites) do
			if sprite.style then
				local style = sprite.style
				minSize.x = math.max(minSize.x, self.finalPadding.x + self.finalPadding.z,
					style.minSize.x)
				minSize.y = math.max(minSize.y, self.finalPadding.y + self.finalPadding.w,
					style.minSize.y)
			end
		end
		self.finalMinSize = minSize
	end
end

---@overload fun(self: GNUI.Box ,size : Vector2): GNUI.Box
---@param x number?
---@param y number?
---@generic self
---@param self self
---@return self
function Box:setMaximumSize(x, y)
	---@cast self GNUI.Box
	self.maxSize = gncommon.vec2(x, y)
	self.finalMaxSize = self.maxSize -- lmao
	self:update("dim")
	return self
end

---@return Vector2
function Box:getMaximumSize() return self.finalMaxSize end

---@generic self
---@param self self
---@return self
---@param x GNUI.Box.SizingMode?
---@param y GNUI.Box.SizingMode?
function Box:setSizing(x, y)
	---@cast self GNUI.Box
	self.sizing = { x = x or self.sizing.x, y = y or self.sizing.y }
	self:update("dim")
	return self
end

---Gets the stored size for this box, for the actual size used for displaying, use `Box:getFinalSize()`
---@return Vector2
function Box:getSize()
	local minSize = self:getMinimumSize()
	---@diagnostic disable-next-line: return-type-mismatch, param-type-mismatch
	return math.clamp(self.size, minSize, self.maxSize)
end

---Returns the final size used to display this box.
---
---NOTE: this gets the final size from the last frame.
---@return Vector2
function Box:getFinalSize()
	---@diagnostic disable-next-line: return-type-mismatch, param-type-mismatch
	return self.finalSize
end

---Sets the layout to use for its children,
---@generic self
---@param self self
---@return self
---@param layout GNUI.Box.LayoutMode?
function Box:setLayout(layout)
	---@cast self GNUI.Box
	self.layout = layout
	self:update("dim")
	return self
end

---@overload fun(self: GNUI.Box ,hv: Vector2): GNUI.Box
---@param h number
---@param v number
---@generic self
---@param self self
---@return self
function Box:setChildAlign(h, v)
	---@cast self GNUI.Box
	self.childAlign = gncommon.vec2(h, v)
	self:update("dim")
	return self
end

---@overload fun(self: GNUI.Box, hv: Vector2): GNUI.Box
---@param h number?
---@param v number?
---@generic self
---@param self self
---@return self
function Box:setGrowDirection(h, v)
	---@cast self GNUI.Box
	local newDir = gncommon.vec2(h, v, self.growDirection)
	if newDir ~= self.growDirection then
		self.growDirection = newDir
		self:update("pos")
	end
	return self
end

---@return Vector2
function Box:getGrowDirection()
	return self.growDirection
end

---@generic self
---@param self self
---@return self
---@param sprite GNUI.Sprite
---@param layer (integer)?
function Box:setSprite(sprite, layer)
	---@cast self GNUI.Box

	sprite:setBox(self, layer)
	self:recalculateMargin()
	self:recalculatePadding()
	self:recalculateChildGap()
	self:recalculateMinimumSize()
	self:update("dim")
	return self
end

---Sets the style of the sprite of this box, if no sprite exists, it will create one for that given style
---
---@generic self
---@param self self
---@return self
---@param variant string?
function Box:setStyleVariant(variant)
	variant = variant or "default"
	---@cast self GNUI.Box

	self.variant = variant
	local style = Style.getStyle(self, variant, "normal")
	local layer = #self.sprites + 1
	style:newInstance(self, layer)

	self:recalculateMargin()
	self:recalculatePadding()
	self:recalculateChildGap()
	self:recalculateMinimumSize()
	self:update("dim")
	return self
end

---Returns the model part of the box
---
---NOTE: this is Figura exclusive
function Box:getModelPart() self.canvas.display:getModelPart(self.visualID) end

--────  Children Management  ────────────────────────────────────────────────────────--

---@param box GNUI.Box
local function recalculateChildrenIndexes(box)
	for id, child in ipairs(box.children) do
		child.childIndex = id
	end
	box.CHILDREN_ORDER_CHANGED:invoke(box)
end

---@param child GNUI.Box
---@generic self
---@param self self
---@return self
function Box:addChild(child)
	---@cast self GNUI.Box
	if child.parent then
		child.parent:removeChild(child)
	end
	
	child.parent = self
	local id = #self.children + 1
	self.children[id] = child
	child.childIndex = id
	if child.name then self.namedChildren[child.name] = child end
	self.canvas.display:addChild(self.visualID, child.visualID)
	
	self.CHILD_ADDED:invoke(child)
	self.CHILDREN_ORDER_CHANGED:invoke(child)
	self:recalculateMinimumSize()
	self:update("dim")
	return child
end

---Removes a child from the box
---@param box GNUI.Box
---@generic self
---@param self self
---@return self
function Box:removeChild(box)
	---@cast self GNUI.Box
	local childIndex = box.childIndex
	if self.children[childIndex] == box then
		
		table.remove(self.children, childIndex)
		self.CHILD_REMOVED:invoke(box)
		
		if box.name then box.namedChildren[box.name] = nil end
		self.canvas.display:removeChild(self.visualID, box.visualID)
		
		recalculateChildrenIndexes(self)
		box.parent = nil
		self.CHILDREN_ORDER_CHANGED:invoke()
	end
	self:recalculateMinimumSize()
	self:update("dim")
	return self
end

---@param box GNUI.Box
---@param name string
local function searchChild(box, name)
	if box == nil then return nil end
	if box.name == name then return box end
	for index, value in ipairs(box.children) do
		local result = searchChild(value, name)
		if result then return result end
	end
end

---@generic self
---@param self self
---@return self
function Box:setChildIndex(index)
	---@cast self GNUI.Box
	local parent = self.parent
	if parent then
		index = math.clamp(index, 1, #self.parent.children)
		local ogIndex = self.childIndex
		if index ~= ogIndex then
			local temp = parent.children[index]
			parent.children[index] = self
			parent.children[ogIndex] = temp
			
			self.childIndex = index

			if temp then
				temp.childIndex = ogIndex
			end
			parent.CHILDREN_ORDER_CHANGED:invoke(index,ogIndex)
			local vis = self.visualID
			self.canvas.display:setVisualChildIndex(vis, index)
			self.parent:update("dim")
		end -- TODO: figure out why this isnt reordering the input handler AND renderer
	end
	
	
	return self
end

---Returns the first box with that given name, through its entirey hierarchy.
---@param name string
---@return GNUI.Box?
function Box:getChild(name) 
	return searchChild(self, name)
end

---Removes the parent of the box
---@generic self
---@param self self
---@return self
function Box:removeParent()
	---@cast self GNUI.Box
	if self.parent then 
		self.parent:removeChild(self)
		self:update("dim")
	end
	return self
end

---Sets the parent of the box
---@param parent GNUI.Box
---@return GNUI.Box
function Box:setParent(parent)
	if parent ~= self.parent then
		self:removeParent()
		parent:addChild(self)
		self:update("dim")
	end
	return self
end

---Returns the parent of the box
---@return GNUI.Box?
function Box:getParent() return self.parent end

---@generic self
---@param self self
---@return self
---@param text string
---@param slot (integer|string)?
function Box:setText(text, slot)
	---@cast self GNUI.Box
	slot = slot or 1
	if self.text[slot] ~= text then
		self.text[slot] = text
		self:update("text")
	end
	return self
end

---@generic self
---@param self self
---@return self
function Box:setTextScale(scale)
	---@cast self GNUI.Box
	if scale ~= self.textScale then
		self.textScale = scale
		self:update("text")
		for key, value in pairs(self.sprites) do value:setTextScale(scale) end
	end
	
	return self
end

---@generic self
---@param self self
---@return self
---@param h -1|0|1
---@param v -1|0|1
function Box:setTextAlignment(h, v)
	---@cast self GNUI.Box
	local newAlignment = gncommon.vec2(h, v)
	if newAlignment ~= self.textAlignment then
		self.textAlignment = newAlignment
		self:update("text")
		for key, value in pairs(self.sprites) do value:setTextAlignment(h, v) end
	end
	return self
end

---@generic self
---@param self self
---@return self
---@param r number
---@param g number
---@param b number
---@overload fun(self: self,rgb: Vector3): self
function Box:setTextColor(r, g, b)
	---@cast self GNUI.Box
	local newColor = gncommon.vec3(r, g, b)
	if newColor ~= self.textColor then
		self.textColor = newColor
		self:update("text")
		for key, value in pairs(self.sprites) do value:setTextColor(newColor) end
	end
	return self
end


---@generic self
---@param self self
---@return self
---@param x -1|0|1
---@param y -1|0|1
function Box:setTextoffset(x, y)
	---@cast self GNUI.Box
	local newOffset = gncommon.vec2(x, y)
	if newOffset ~= self.textOffset then
		self.textOffset = newOffset
		self:update("text")
		for key, value in pairs(self.sprites) do value:setTextOffset(x, y) end
	end
	return self
end


---sets if the text should wrap around or not
---@generic self
---@param self self
---@return self
---@param wrap boolean
function Box:setWrapText(wrap)
	---@cast self GNUI.Box
	if self.wrapText ~= wrap then
		self.wrapText = wrap
		for index, value in ipairs(self.sprites) do
			value:setWrapText(self.wrapText)
		end
		self:update("text")
	end
	return self
end

function Box:setColor(r, g, b)
	local clr = gncommon.vec3(r, g, b)
	if self.color ~= clr then
		self.color = clr
		self:update("color")
	end
	return self
end

---@generic self
---@param self self
---@return self
---@param visible boolean
function Box:setVisible(visible)
	---@cast self GNUI.Box
	if visible ~= self.visible then
		self.visible = visible
		self:update("visibility")
	end
	return self
end

---@overload fun(self: GNUI.Box ,pos : Vector2): Vector2
---@param x number
---@param y number
---@return Vector2
function Box:toLocal(x, y)
	return gncommon.vec2(x, y) - self.absPos
end

-- ────────────────────────-<  >-────────────────────────--

---@param pos Vector2
---@return boolean
function Box:isPosInboundingBox(pos)
	local bounds = self:getGlobalBounds()

	local globalPos = bounds.xy
	local otherEnd = bounds.zw

	if pos.x > globalPos.x and pos.x < otherEnd.x and pos.y > globalPos.y and
		 pos.y < otherEnd.y then
		return true
	end
	return false
end


---@param pos Vector2
---@return boolean
function Box:isPosInBox(pos)
	local gpos = self:getGlobalPos()

	local start = gpos.xy
	local otherEnd = gpos.xy + self.finalSize

	if pos.x > start.x and pos.x < otherEnd.x and pos.y > start.y and
		 pos.y < otherEnd.y then
		return true
	end
	return false
end



---@param captureInput boolean
---@generic self
---@param self self
---@return self
function Box:setCaptureInputs(captureInput)
	---@cast self GNUI.Box
	self.captureInput = captureInput
	return self
end

---Deletes this box and its children
function Box:free()
	self:removeParent()
	if self.canvas then
		self.canvas.queueUpdate[self.flaggedUpdate] = nil
		self.flaggedUpdate = nil
		for index, sprite in pairs(self.sprites) do sprite:free() end
		self.canvas.display:removeVisual(self.visualID)
		self.canvas = nil
	end
end

---@param self GNUI.Box
---@return Vector4
local function calculateBounds(self)
	local size = self.finalSize
	local finalBounds = vec(0, 0, size.x, size.y)
	for index, value in ipairs(self.children) do
		local childBounds = calculateBounds(value)
		finalBounds.x = math.min(finalBounds.x, childBounds.x)
		finalBounds.y = math.min(finalBounds.y, childBounds.y)
		finalBounds.z = math.max(finalBounds.z, childBounds.z)
		finalBounds.w = math.max(finalBounds.w, childBounds.w)
	end
	self.bounds = finalBounds
	---@diagnostic disable-next-line: return-type-mismatch
	return self.bounds + self.finalPos.xyxy
end

function Box:calculateBounds()
	calculateBounds(self.canvas)
	return self
end


---Parses the given layout data and parents it to this box, while returning the new box
---@param data GNUI.Layout
---@return GNUI.Box
function Box:parse(data)
	local box = Layout.parse(self.canvas,data)
	--self:forceUpdate() -- TODO: figure out why this is required
	self:addChild(box)
	return box
end


-- ────────────────────────-< UPDATERS >-────────────────────────--

---@param box    GNUI.Box
---@param hasDim boolean   true when sizes / content changed
---@return GNUI.Box
local function findUpdateRoot(box, hasDim)
	if not hasDim then
		return box
	end
	local root = box
	local p = box.parent
	while p do
		if (p.sizing.x == "FIXED" and p.sizing.y == "FIXED") then
			break
		end
		root = p
		p = p.parent
	end
	return root
end

--- Queue a box for an update, merging flags if it was already queued.
--- This is the only place boxes are added to the canvas update queue.
---@param box GNUI.Box
---@param dim boolean
---@param pos boolean
---@param visual boolean
local function queueBox(box, dim, pos, visual)
	-- Merge so multiple changes before the flush are batched together
	box.pendingDim = box.pendingDim or dim
	box.pendingPos = box.pendingPos or pos
	box.pendingVisual = box.pendingVisual or visual

	if not box.flaggedUpdate and box.canvas then
		local q = box.canvas.queueUpdate
		local id = #q + 1
		q[id] = box
		box.flaggedUpdate = id
	end
end

---@param ... GNUI.Box.Flags
function Box:update(...)
	local hasDim = false
	local hasPos = false
	local hasVisual = false


	for _, flag in ipairs({ ... }) do
		if flag == "dim" then
			hasDim = true
		elseif flag == "text" then
			if self.sizing.x == "FIT" or self.sizing.y == "FIT" then
				hasDim = true
			else
				hasVisual = true
			end
		elseif flag == "pos" then
			hasPos = true
		elseif flag == "color" then
			hasVisual = true
		elseif flag == "visibility" then
			hasDim = true
			hasPos = true
		end
	end

	-- A dimension change always forces a position re-solve too,
	-- because new sizes shift where everything sits.
	if hasDim then hasPos = true end

	if hasDim or hasPos then
		local root = findUpdateRoot(self, hasDim)
		queueBox(root, hasDim, hasPos, false)
	end

	-- Visual-only change: no layout propagation needed, just re-push this node.
	if hasVisual and not hasDim and not hasPos then
		queueBox(self, false, false, true)
	end
end

--- Runs the full layout pipeline on this subtree, then clears dirty state.
--- The canvas flush loop should call this, don't call it directly. unless you know what youre doing.
---
---@generic self
---@param self self
---@return self
function Box:forceUpdate()
	---@cast self GNUI.Box
	local doDim    = self.pendingDim
	local doPos    = self.pendingPos or doDim
	local doVisual = self.pendingVisual
	
	
	if doDim then
		self:_updateTexts()
		self:_solveFit(false)
		self:_solveFill(false)
		self:_solveFit(true)
		self:_solveFill(true)
		self:_solveLayout(false)
		self:_solveLayout(true)
	end

	if doPos then
		if self.parent and self.parent.layout == "FIXED" then
			local minX = self.minSize and self.minSize.x or 0
			local minY = self.minSize and self.minSize.y or 0
			local growX = math.max(0, self.finalSize.x - minX) * (self.growDirection.x - 1) * 0.5
			local growY = math.max(0, self.finalSize.y - minY) * (self.growDirection.y - 1) * 0.5
			self.finalPos.x = self.pos.x + self.offsetPos.x + growX
			self.finalPos.y = self.pos.y + self.offsetPos.y + growY
		end
		local parentAbs = (self.parent and self.parent.absPos) or vec(0, 0)
		self:_calcAbsPos(parentAbs)
	end
	
	if doDim or doVisual then
		self:_updateSprites()
	elseif doPos then
		if self.canvas then
			self.canvas.display:setPos(self.visualID, self.finalPos.x, self.finalPos.y)
		end
	end

	
	if doDim then
		self:calculateBounds()
	end
	self.flaggedUpdate = false
	self.pendingDim    = false
	self.pendingPos    = false
	self.pendingVisual = false
	return self
end

---@param isY boolean
function Box:_solveFit(isY)
	local x = isY and "y" or "x"
	local z = isY and "w" or "z"
	for _, child in ipairs(self.children) do child:_solveFit(isY) end
	if not self.visible then
		self.finalSize[x] = 0
		return
	end
	local sz = self.sizing[x]

	if sz == "FIXED" then
		self.finalSize[x] = math.max(self.finalMinSize[x], self.size[x])
	elseif sz == "FIT" then
		local padding = self:getPadding()
		local textComp = 0

		if self.text then
			local availW = isY and ((self.finalSize.x - padding.x - padding.z) / self.textScale) or math.huge
			local ts = utils.getTextSize(self.text[next(self.text)] or "", availW, self.wrapText) * self.textScale
			textComp = isY and ts.y or ts.x
		end

		local parallel = (self.layout == (isY and "VERTICAL" or "HORIZONTAL"))
			or (self.layout == (isY and "VERTICAL_REVERSED" or "HORIZONTAL_REVERSED"))
			or (self.layout == (isY and "VERTICAL_WRAP" or "HORIZONTAL_WRAP"))
		local crossWrap = (self.layout == (isY and "HORIZONTAL_WRAP" or "VERTICAL_WRAP"))
		local inner = 0

		if parallel then
			for _, child in ipairs(self.children) do
				if child.visible and child.sizing[x] ~= "FILL" then
					local m = child:getMargin()
					inner = inner + child.finalSize[x] + m[x] + m[z]
				end
			end
			
			local visibleChildCount = 0
			for index, value in ipairs(self.children) do
				if value.visible then
					visibleChildCount = visibleChildCount + 1
				end
			end
			
			inner = inner + self.finalChildGap * math.max(visibleChildCount - 1, 0)
		elseif crossWrap then
			local p = isY and "x" or "y"
			local pEnd = isY and "z" or "w"
			local availPrimary = (self.finalSize[p] > 0 and self.finalSize[p] or self.size[p]) - padding[p] - padding[pEnd]
			local cursorP = 0
			local lineMaxCross = 0
			local hasItem = false
			for _, child in ipairs(self.children) do
				if child.visible and child.sizing[x] ~= "FILL" then
					local m = child:getMargin()
					local childP = child.finalSize[p] + m[p] + m[pEnd]
					local childC = child.finalSize[x] + m[x] + m[z]
					if hasItem and availPrimary > 0 and (cursorP + childP > availPrimary) then
						inner = inner + lineMaxCross + self.finalChildGap
						cursorP = 0
						lineMaxCross = 0
					end
					cursorP = cursorP + childP + self.finalChildGap
					lineMaxCross = math.max(lineMaxCross, childC)
					hasItem = true
				end
			end
			inner = inner + lineMaxCross
		else
			for _, child in ipairs(self.children) do
				if child.visible and child.sizing[x] ~= "FILL" then
					local m = child:getMargin()
					inner = math.max(inner, child.finalSize[x] + m[x] + m[z])
				end
			end
		end

		self.finalSize[x] = math.max(self.finalMinSize[x], inner, textComp) +
			 padding[x] + padding[z]
	end
	if type(self.layout) == "table" and self.layout.size and sz == "FIT" then
		local res = self.layout.size(self, self.children, isY)
		if type(res) == "number" then
			self.finalSize[x] = math.max(self.finalMinSize[x], res)
		elseif res then
			self.finalSize[x] = math.max(self.finalMinSize[x], res[x])
		end
	end
end

---@param isY boolean
function Box:_solveFill(isY)
	local x = isY and "y" or "x"
	local z = isY and "w" or "z"
	local padding = self:getPadding()
	local parallel = (self.layout == (isY and "VERTICAL" or "HORIZONTAL"))
		or (self.layout == (isY and "VERTICAL_REVERSED" or "HORIZONTAL_REVERSED"))
		or (self.layout == (isY and "VERTICAL_WRAP" or "HORIZONTAL_WRAP"))
	if not self.visible then
		self.finalSize[x] = 0
		return
	end
	if parallel then
		local remaining = self.finalSize[x] - padding[x] - padding[z]
		local fillers = {}

		for _, child in ipairs(self.children) do
			if child.visible then
				local m = child:getMargin()
				if child.sizing[x] == "FILL" then
					fillers[#fillers + 1] = child
					child.finalSize[x] = 0 -- reset; will be set below
				end
				remaining = remaining - child.finalSize[x] - m[x] - m[z]
			end
		end
		
		local visibleChildCount = 0
		for index, value in ipairs(self.children) do
			if value.visible then
				visibleChildCount = visibleChildCount + 1
			end
		end
		
		remaining = remaining - self.finalChildGap * math.max(visibleChildCount - 1, 0)

		if #fillers > 0 then
			local share = math.max(0, remaining) / #fillers
			for _, child in ipairs(fillers) do
				child.finalSize[x] = math.max(child.finalMinSize[x] or 0, share)
			end
		end
	else
		for _, child in ipairs(self.children) do
			if child.visible and child.sizing[x] == "FILL" then
				local m = child:getMargin()
				child.finalSize[x] = math.max(child.finalMinSize[x] or 0,
					self.finalSize[x] - padding[x] -
					padding[z] - m[x] - m[z])
			end
		end
	end
	if type(self.layout) == "table" and self.layout.size and self.sizing[x] ~= "FIT" then
		self.layout.size(self, self.children, isY)
	end
	for _, child in ipairs(self.children) do child:_solveFill(isY) end
	if isY and self.layout == "VERTICAL_WRAP" and self.sizing.x == "FIT" then
		self:_solveFit(false)
	end
end

---@param isY boolean
function Box:_solveLayout(isY)
	local x = isY and "y" or "x"
	local z = isY and "w" or "z"
	local padding = self:getPadding()
	if not self.visible then
		return
	end
	
	if type(self.layout) == "table" then
		for _, child in ipairs(self.children) do
			if child.visible then
				local m = child:getMargin()
				child.finalPos[x] = math.lerp(
					padding[x] + m[x],
					self.finalSize[x] - child.finalSize[x] - padding[z] - m[z],
					self.childAlign[x] * 0.5 + 0.5)
					+ child.offsetPos[x]
			end
		end
		if isY and self.layout.pos then
			self.layout.pos(self, self.children, isY)
		end
	elseif self.layout == "FIXED" then
		for _, child in ipairs(self.children) do
			local minVal = child.minSize and child.minSize[x] or 0
			local growOffset = math.max(0, child.finalSize[x] - minVal) * (child.growDirection[x] - 1) * 0.5
			child.finalPos[x] = child.pos[x] + child.offsetPos[x] + growOffset
		end
	elseif self.layout == (isY and "VERTICAL" or "HORIZONTAL") then
		local cursor = padding[x]
		for _, child in ipairs(self.children) do
			if child.visible then
				local m = child:getMargin()
				child.finalPos[x] = cursor + m[x] + child.offsetPos[x]
				cursor = cursor + child.finalSize[x] + m[x] + m[z] + self.finalChildGap
			end
		end
	elseif self.layout == (isY and "VERTICAL_REVERSED" or "HORIZONTAL_REVERSED") then
		local cursor = self.finalSize[x] - padding[z]
		for _, child in ipairs(self.children) do
			if child.visible then
				local m = child:getMargin()
				child.finalPos[x] = cursor - m[z] - child.finalSize[x] + child.offsetPos[x]
				cursor = cursor - child.finalSize[x] - m[x] - m[z] - self.finalChildGap
			end
		end
	elseif self.layout == "HORIZONTAL_WRAP" or self.layout == "VERTICAL_WRAP" then
		if isY then
			local isVert = (self.layout == "VERTICAL_WRAP")
			local p = isVert and "y" or "x"
			local pEnd = isVert and "w" or "z"
			local c = isVert and "x" or "y"
			local cEnd = isVert and "z" or "w"
			local maxPrimary = self.finalSize[p] - padding[pEnd]
			local cursorP = padding[p]
			local cursorC = padding[c]
			local lineMaxCross = 0
			local hasItem = false
			for _, child in ipairs(self.children) do
				if child.visible then
					local m = child:getMargin()
					local childP = child.finalSize[p] + m[p] + m[pEnd]
					local childC = child.finalSize[c] + m[c] + m[cEnd]
					if hasItem and (cursorP + childP > maxPrimary) then
						cursorP = padding[p]
						cursorC = cursorC + lineMaxCross + self.finalChildGap
						lineMaxCross = 0
					end
					child.finalPos[p] = cursorP + m[p] + child.offsetPos[p]
					child.finalPos[c] = cursorC + m[c] + child.offsetPos[c]
					cursorP = cursorP + childP + self.finalChildGap
					lineMaxCross = math.max(lineMaxCross, childC)
					hasItem = true
				end
			end
		end
	else
		for _, child in ipairs(self.children) do
			if child.visible then
				local m = child:getMargin()
				child.finalPos[x] = math.lerp(
				padding[x] + m[x],
					self.finalSize[x] - child.finalSize[x] - padding[z] - m[z],
					self.childAlign[x] * 0.5 + 0.5)
					+ child.offsetPos[x]
			end
		end
	end
	for _, child in ipairs(self.children) do child:_solveLayout(isY) end
end


---@param parentAbs Vector2   absolute screen position of the parent
function Box:_calcAbsPos(parentAbs)
	local newX = parentAbs.x + self.finalPos.x
	local newY = parentAbs.y + self.finalPos.y

	if self.finalSize.x ~= self.prevFinalSize.x or self.finalSize.y ~=
		 self.prevFinalSize.y then
		self.prevFinalSize.x = self.finalSize.x
		self.prevFinalSize.y = self.finalSize.y
		self.SIZE_CHANGED:invoke(self.finalSize:copy())
	end

	if newX ~= self.absPos.x or newY ~= self.absPos.y then
		self.absPos.x = newX
		self.absPos.y = newY
		self.POSITION_CHANGED:invoke(self.absPos:copy())
	end

	for _, child in ipairs(self.children) do child:_calcAbsPos(self.absPos) end
end

function Box:_updateSprites()
	if not self.canvas then return end
	local d = self.canvas.display

	-- TODO: split to only update ones that are requireed
	d:setPos(self.visualID, self.finalPos.x, self.finalPos.y)
	d:setSize(self.visualID, self.finalSize.x, self.finalSize.y)
	
	d:setColor(self.visualID, self.color.x, self.color.y, self.color.z)
	d:setVisible(self.visualID, self.visible)
	
	d:setVisualChildIndex(self.visualID, self.childIndex)

	
	self:_updateTexts()
	for _, sprite in pairs(self.sprites) do
		sprite:setSize(self.finalSize.x, self.finalSize.y)
	end
	for _, child in ipairs(self.children) do child:_updateSprites() end
end

function Box:_updateTexts()
	for key, value in pairs(self.text) do
		if self.sprites[key] then
			self.sprites[key]:setText(value)
		end
	end
end


return BoxAPI
