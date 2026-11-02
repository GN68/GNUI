--[[______   __
  / ____/ | / /  by: GNanimates / https://gnon.top / Discord: @gn68s
 / / __/  |/ / name: GNUI Sprite Module
/ /_/ / /|  /  desc: base class for all sprites
\____/_/ |_/ source: link ]]
local BASE = (...):match(".+[./]GNUI"):gsub("/", ".")
local cfg = require(BASE .. ".config") ---@type GNUI.config

local SpriteStyle = require(BASE .. ".shared.theme.styles.sprite") ---@type GNUI.Sprite.StyleAPI
local gncommon = require(cfg.GN_COMMON) ---@type GNCommon


---A base class for all sprites for boxes
---@class GNUI.Sprite
---@field style GNUI.Sprite.Style
---@field box GNUI.Box?
---@field index (integer|string)? # index of the sprite to the box it is attached to
---@field parentID integer
---@field boxColor Vector3
---
---@field flagApply boolean
---@field padding Vector4
---@field textColor Vector3
---@field textAlignment Vector2
---@field textOffset Vector2
---
---@field pos Vector2
---@field layer number
---@field size Vector2
---@field minSize Vector2
---
---@field display GNUI.Render.Display
---@field taskID integer # Task ID
---@field labelID integer # Task ID
local Sprite = {}
Sprite.__index = Sprite


---@param box GNUI.Box
---@param layer (integer)?
---@return GNUI.Sprite
function Sprite.new(box, layer)
	assert(box, "no GNUI.Box given")
	layer = layer or 1
	local self = {
		pos = vec(0, 0),
		size = vec(0, 0),
		padding = vec(0, 0, 0, 0),
		layer = layer,

		minSize = vec(0,0),
		childIndex = 1,

		textColor = vec(1, 1, 1),
		textAlignment = vec(0, 0),
		textOffset = vec(0, 0),

		boxColor = vec(1, 1, 1),
		flagApply = false,

	}
	setmetatable(self, Sprite)
	self:setBox(box, layer)
	return self
end

SpriteStyle.setInstancer(Sprite.new)
---@return GNUI.Sprite.Style
function Sprite.newStyle()
	return SpriteStyle.new()
end

--────────────────────────-< API >-────────────────────────--


---@param box GNUI.Box
---@param layer (integer)?
function Sprite:setBox(box, layer)
	if self.taskID then
		self.display:removeSprite(box.visualID,self.taskID)
	end
	self.layer = layer
	self.display = box.canvas.display
	self.taskID = box.canvas.display:newSprite(box.visualID)
	self.labelID = box.canvas.display:newLabel(box.visualID)
	self.box = box

	self.index = layer or #box.sprites + 1

	box.sprites[self.index] = self
	box:recalculateMargin()
	box:recalculatePadding()
	box:recalculateMinimumSize()

	if self.box then
		self:applyAll()
	end
end

---@overload fun(self: GNUI.Sprite)
---@param x number
---@param y number
function Sprite:setPos(x, y)
	if x then
		local pos = gncommon.vec2(x, y)
		local expand = self.style and self.style.expand.xy or vec(0, 0)

		if self.pos == pos then return end
		self.pos = pos - expand
	end
	self.display:setPos(self.box.visualID, self.pos.x, self.pos.y)
end


---@overload fun(self: GNUI.Sprite)
---@param x number
---@param y number
function Sprite:setSize(x, y)
	---@cast self GNUI.Sprite
	if x then
		local size = vec(x, y)
		if self.style then size = size + self.style.expand.xy end

		if size == self.size then return end
		self.size = size
	end
	self.display:setSpriteSize(self.box.visualID, self.taskID, self.size.x, self.size.y)
	return self
end

---@overload fun(self: GNUI.Sprite)
---@param text string
function Sprite:setText(text)
	---@cast self GNUI.Sprite
	if text then
		if self.text == text then return end
		self.text = text
	end
	self.display:setLabelText(self.box.visualID, self.labelID, self.text)
end

---@overload fun(self: GNUI.Sprite)
---@overload fun(self: GNUI.Sprite, rgb: Vector3)
---@param r number
---@param g number
---@param b number
function Sprite:setTextColor(r, g, b)
	if r then
		local color = gncommon.color(r, g, b).xyz
		if self.style and self.style.textColor then
			color = color * self.style.textColor
		end
		if self.textColor == color then return end
		self.textColor = color
	end
	if self.textColor then
		self.display:setLabelColor(self.box.visualID, self.labelID, self.textColor.x, self.textColor.y, self.textColor.z)
	end
end

---@overload fun(self: GNUI.Sprite)
---@param l number
---@param t number
---@param r number
---@param b number
---@return GNUI.Sprite
function Sprite:setPadding(l, t, r, b)
	---@cast self GNUI.Sprite
	if l then
		local padding = vec(l, t, r, b)
		if padding == self.padding then return end
		self.padding = padding
	end

	local expand = self.style and self.style.expand or vec(0, 0, 0, 0)

	self.display:setLabelPadding(self.box.visualID, self.labelID,
		self.padding.x + expand.x,
		self.padding.y + expand.y,
		self.padding.z + expand.z,
		self.padding.w + expand.w
	)
	return self
end

---@param h (-1|0|1)?
---@param v (-1|0|1)?
function Sprite:setTextAlignment(h, v)
	---@cast self GNUI.Sprite
	local changed = false
	if h then
		self.textAlignment.x = h
		changed = true
	end
	if v then
		self.textAlignment.y = v
		changed = true
	end
	if changed then
		self.display:setLabelAlignment(self.box.visualID, self.labelID, self.textAlignment.x,
			self.textAlignment.y or 0)
	end
	return self
end


function Sprite:setTextScale(s)
	self.display:setLabelScale(self.box.visualID, self.labelID,s)
end


---@param x number
---@param y number
function Sprite:setTextOffset(x, y)
	self.display:setLabelOffset(self.box.visualID, self.labelID, x, y)
end


function Sprite:setVisible(visible)
	self.visible = visible
	self.display:setSpriteVisible(self.box.visualID, self.taskID, visible)
end

function Sprite:setWrapText(wrap)
	self.display:setLabelWrapText(self.box.visualID, self.labelID, wrap)
end

---@overload fun(self: GNUI.Sprite)
---@param style GNUI.Sprite.Style
function Sprite:setStyle(style)
	---@cast self GNUI.Sprite
	if style then
		if self.style == style then return end
		self.style = style
	end
	self:applyAll(style)
	if self.box then
		self.box:recalculateMargin()
		self.box:recalculatePadding()
		self.box:recalculateMinimumSize()
		self.box:update()
	end
	return self
end

--TODO: make reactive and only apply when a property is changed
---@param style GNUI.Sprite.Style?
function Sprite:applyAll(style)
	style = style or self.style
	self:setPos()
	self:setSize()
	self:setText()
	self:setPadding()

	if style then
		self:setTextColor(self.box.textColor or (style.textColor and gncommon.color(style.textColor).xyz) or self.textColor)
		self:setTextAlignment(self.box.textAlignment and self.box.textAlignment:unpack() or style.textAlignment:unpack())
		self.box:setChildGap(style.childGap)
	else
		self:setTextColor(self.box.textColor or self.textColor)
		self:setTextAlignment(self.box.textAlignment and self.box.textAlignment:unpack())
	end
end

function Sprite:free()
	self.display:removeSprite(self.box.visualID, self.taskID)
	self.display:removeLabel(self.box.visualID, self.labelID)
end

return Sprite
