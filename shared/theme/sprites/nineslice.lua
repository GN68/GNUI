---@diagnostic disable: param-type-mismatch
--[[______   __
  / ____/ | / /  by: GNanimates / https://gnon.top / Discord: @gn68s
 / / __/  |/ / name: GNUI Nineslice Module
/ /_/ / /|  /  desc: an extension of sprite which can display a texture
\____/_/ |_/ source: link ]]

local BASE = (...):match(".+[./]GNUI"):gsub("/",".")
local cfg = require(BASE..".config") ---@type GNUI.config

local gncommon = require(cfg.GN_COMMON) ---@type GNCommon
local Style = require(BASE..".shared.theme.styles.nineslice") ---@type GNUI.Sprite.Nineslice.StyleAPI

local Sprite = require(BASE..".shared.theme.sprites.sprite") ---@type GNUI.Sprite
local Quad = require(BASE..".shared.theme.sprites.quad") ---@type GNUI.Sprite.Quad

---@class GNUI.Sprite.Nineslice : GNUI.Sprite.Quad
---@field style GNUI.Sprite.Nineslice.Style 
---
---@field idTopLeft integer
---@field idTop integer
---@field idTopRight integer
---
---@field idLeft integer
---@field idCenter integer
---@field idRight integer
---
---@field idBottomRight integer
---@field idBottom integer
---@field idBottomLeft integer
---
---@field ids integer[]
local Nineslice = {}
Nineslice.__index = function (t,i)
	return rawget(t,i) or Nineslice[i] or Quad[i] or Sprite[i]
end


function Nineslice.getIndex() return Nineslice.__index end


---A representation of a quad that will get drawn
---@param box GNUI.Box
---@param slot (integer)?
---@return GNUI.Sprite.Nineslice
function Nineslice.new(box,slot)
	assert(box,"no GNUI.Box given")
	local self = Sprite.new(box,slot)
	---@cast self GNUI.Sprite.Nineslice
	
	local id = box.visualID
	self.idTopLeft = self.taskID
	self.idTop = self.display:newSprite(id)
	self.idTopRight = self.display:newSprite(id)
	
	self.idLeft = self.display:newSprite(id)
	self.idCenter = self.display:newSprite(id)
	self.idRight = self.display:newSprite(id)
	
	self.idBottomRight = self.display:newSprite(id)
	self.idBottom = self.display:newSprite(id)
	self.idBottomLeft = self.display:newSprite(id)
	
	self.ids = {
		self.idTopLeft,
		self.idTop,
		self.idTopRight,
		
		self.idLeft,
		self.idCenter,
		self.idRight,
		
		self.idBottomLeft,
		self.idBottom,
		self.idBottomRight,
	}
	
	self.box = box
	setmetatable(self, Nineslice)
	return self
end


Style.setInstancer(Nineslice.new)
---@return GNUI.Sprite.Nineslice.Style
function Nineslice.newStyle()
	return Style.new()
end


--────────────────────────-< API >-────────────────────────--

---@overload fun(self: GNUI.Sprite.Nineslice)
---@param x number
---@param y number
function Nineslice:setPos(x,y)
	if x then
		local pos = gncommon.vec3(x,y)
		if self.pos == pos then return end
		self.pos = pos
		self:applyDimensions()
	end
end


---@overload fun(self: GNUI.Sprite.Nineslice)
---@param x number
---@param y number
function Nineslice:setSize(x,y)
	if x then
		local size = vec(x,y)
		if size == self.size then return end
		self.size = size
		self:applyDimensions()
	end
	return self
end


function Nineslice:applyDimensions()
	local border = self.style and self.style.border or vec(0,0,0,0)
	local expand = self.style and self.style.expand or vec(0,0,0,0)
	local size = self.size + expand.xy + expand.zw
	local pos = self.pos - expand.xy
	
	local id = self.box.visualID
	self.display:setSpriteSize(id,self.idTopLeft,  border.x, border.y)
	self.display:setSpriteSize(id,self.idTop,      size.x-border.x-border.z, border.y)
	self.display:setSpriteSize(id,self.idTopRight, border.z, border.y)
	self.display:setSpriteSize(id,self.idLeft,  border.x, size.y-border.y-border.w)
	self.display:setSpriteSize(id,self.idCenter,      size.x-border.x-border.z, size.y-border.y-border.w)
	self.display:setSpriteSize(id,self.idRight, border.z, size.y-border.y-border.w)
	self.display:setSpriteSize(id,self.idBottomLeft,  border.x, border.w)
	self.display:setSpriteSize(id,self.idBottom,      size.x-border.x-border.z, border.w)
	self.display:setSpriteSize(id,self.idBottomRight, border.z, border.w)
	
	local l = self.layer
	self.display:setSpritePos(id,self.idTopLeft,  pos.x, pos.y,l)
	self.display:setSpritePos(id,self.idTop,      pos.x+border.x, pos.y,l)
	self.display:setSpritePos(id,self.idTopRight, pos.x+size.x-border.z, pos.y,l)
	self.display:setSpritePos(id,self.idLeft,  pos.x, pos.y+border.y,l)
	self.display:setSpritePos(id,self.idCenter,      pos.x+border.x, pos.y+border.y,l)
	self.display:setSpritePos(id,self.idRight, pos.x+size.x-border.z, pos.y+border.y,l)
	self.display:setSpritePos(id,self.idBottomLeft,  pos.x, pos.y+size.y-border.w,l)
	self.display:setSpritePos(id,self.idBottom,      pos.x+border.x,pos.y+size.y-border.w,l)
	self.display:setSpritePos(id,self.idBottomRight, pos.x+size.x-border.z,pos.y+size.y-border.w,l)
end

---@overload fun(self: GNUI.Sprite.Nineslice)
---@param path string
function Nineslice:setTexture(path)
	---@cast self GNUI.Sprite.Nineslice
	if path then
		if self.texturePath == path then return end
		self.texturePath = path
	end
	
	local id = self.box.visualID
	if self.texturePath then
		self.display:setSpriteTexture(id,self.idTopLeft,self.texturePath)
		self.display:setSpriteTexture(id,self.idTop,self.texturePath)
		self.display:setSpriteTexture(id,self.idTopRight,self.texturePath)
		
		self.display:setSpriteTexture(id,self.idLeft,self.texturePath)
		self.display:setSpriteTexture(id,self.idCenter,self.texturePath)
		self.display:setSpriteTexture(id,self.idRight,self.texturePath)
		
		self.display:setSpriteTexture(id,self.idBottomLeft,self.texturePath)
		self.display:setSpriteTexture(id,self.idBottom,self.texturePath)
		self.display:setSpriteTexture(id,self.idBottomRight,self.texturePath)
	end
end


function Nineslice:setUV(u1,v1,u2,v2)
	if u1 then
		local uv = vec(u1,v1,u2,v2)
		if uv == self.uv then return end
		uv = uv
		:copy()
		:add(0,0,1,1)
		self.uv = uv
	end
	
	local id = self.box.visualID
	
	if self.uv then
		local uv = self.uv
		local border = self.style and self.style.border or vec(0,0,0,0)
		self.display:setSpriteUV(id,self.idTopLeft,  uv.x,             uv.y,      uv.x+border.x,       uv.y+border.y)
		self.display:setSpriteUV(id,self.idTop,      uv.x+border.x,    uv.y,      uv.z-border.z,       uv.y+border.y)
		self.display:setSpriteUV(id,self.idTopRight, uv.z-border.z,    uv.y,      uv.z,                uv.y+border.y)
		
		self.display:setSpriteUV(id,self.idLeft,  uv.x,                uv.y+border.y,       uv.x+border.x,   uv.w-border.w)
		self.display:setSpriteUV(id,self.idCenter,      uv.x+border.x, uv.y+border.y,       uv.z-border.z,   uv.w-border.w)
		self.display:setSpriteUV(id,self.idRight, uv.z-border.z,       uv.y+border.y,       uv.z,            uv.w-border.w)
		
		self.display:setSpriteUV(id,self.idBottomLeft,  uv.x,          uv.w-border.w, uv.x+border.x, uv.w)
		self.display:setSpriteUV(id,self.idBottom,      uv.x+border.x, uv.w-border.w, uv.z-border.z, uv.w)
		self.display:setSpriteUV(id,self.idBottomRight, uv.z-border.z, uv.w-border.w, uv.z, uv.w)
	end
end


---@overload fun(self: GNUI.Sprite.Quad)
---@param r number
---@param g number
---@param b number
---@return GNUI.Sprite.Quad
function Nineslice:setColor(r,g,b)
	if r then
		local color = vec(r,g,b)
		if self.style then color = color * self.style.color end
		if self.color == color then return end
		self.color = color
	end
	if self.color then
		for index, id in ipairs(self.ids) do
			self.display:setSpriteColor(self.box.visualID, id,self.color.x,self.color.y,self.color.z)
		end
	end
end


function Nineslice:setVisible(visible)
	self.visible = visible
	for index, id in ipairs(self.ids) do
		self.display:setSpriteVisible(self.box.visualID, id,visible)
	end
end


---@param style GNUI.Sprite.Nineslice.Style
function Nineslice:applyAll(style)
	self:setText()
	self:setPos()
	self:setSize()
	
	if style then
		self:setTexture(style.texturePath)
		self:setUV(style.uv:unpack())
		self:setColor((self.box.color and self.box.color or style.color):unpack())
		self:setPadding((self.box.padding and self.box.padding or style.padding):unpack())
		if style.childGap then self.box:setChildGap(style.childGap) end
		
	end
	if style then
		self:setTextColor(self.box.textColor  or (style.textColor and gncommon.color(style.textColor).xyz) or self.textColor)
		self:setTextAlignment(self.box.textAlignment and self.box.textAlignment:unpack() or style.textAlignment:unpack())
	else
		self:setTextColor(self.box.textColor or self.textColor)
		self:setTextAlignment(self.box.textAlignment and self.box.textAlignment:unpack())
	end
	
	self:applyDimensions()
end

function Nineslice:free()
	for index, id in ipairs(self.ids) do
		self.display:removeSprite(self.box.visualID, id)
	end
	
	self.display:removeLabel(self.box.visualID, self.labelID)
end

return Nineslice
