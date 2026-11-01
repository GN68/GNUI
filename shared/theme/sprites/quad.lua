--[[______   __
  / ____/ | / /  by: GNanimates / https://gnon.top / Discord: @gn68s
 / / __/  |/ / name: GNUI Quad Module
/ /_/ / /|  /  desc: an extension of sprite which can display a texture
\____/_/ |_/ source: link ]]

local BASE = (...):match(".+[./]GNUI"):gsub("/",".")
local cfg = require(BASE..".config") ---@type GNUI.config
local gncommon = require(cfg.GN_COMMON) ---@type GNCommon

local Sprite = require(cfg.THEME..".sprites.sprite") ---@type GNUI.Sprite
local Style = require(cfg.THEME..".styles.quad") ---@type GNUI.Sprite.Quad.StyleAPI

---@alias GNUI.Sprite.Quad.SizingMode string
---| "STRETCH"
---| "FIXED"

---@class GNUI.Sprite.Quad : GNUI.Sprite
---@field style GNUI.Sprite.Quad.Style
---@field uv Vector4
---@field color Vector3
---@field sizing GNUI.Sprite.Quad.SizingMode
---@field texturePath string
local Quad = {}
Quad.__index = function (t,i)
	return rawget(t,i) or Quad[i] or Sprite[i]
end



---A representation of a quad that will get drawn
---@param box GNUI.Box
---@param slot (integer)?
---@return GNUI.Sprite.Quad
function Quad.new(box,slot)
	assert(box,"no GNUI.Box given")
	local self = Sprite.new(box,slot)
	---@cast self GNUI.Sprite.Quad
	
	setmetatable(self, Quad)
	return self
end
Style.setInstancer(Quad.new)


---@return GNUI.Sprite.Quad.Style
function Quad.newStyle()
	return Style.new()
end


--────────────────────────-< API >-────────────────────────--


---@overload fun(self: GNUI.Sprite.Quad)
---@param path string
function Quad:setTexture(path)
	---@cast self GNUI.Sprite.Quad
	if path then
		if self.texturePath == path then return end
		self.texturePath = path
	end
	
	self.display:setSpriteTexture(self.box.visualID, self.taskID, self.texturePath)
	return self
end


---@overload fun(self: GNUI.Sprite.Quad)
---@overload fun(self: GNUI.Sprite.Quad, rgb: Vector3)
---@param r number
---@param g number
---@param b number
---@return GNUI.Sprite.Quad
function Quad:setColor(r,g,b)
	if r then
		local color = gncommon.color(r,g,b).xyz
		if self.style and self.style.color then color = color * self.style.color end
		if self.color == color then return end
		self.color = color
	end
	-- TODO: implement method to display
	self.display:setSpriteColor(self.box.visualID, self.taskID, self.color.x, self.color.y, self.color.z)
end


---@overload fun(self: GNUI.Sprite.Quad)
---@param u1 number
---@param v1 number
---@param u2 number
---@param v2 number
---@return GNUI.Sprite.Quad
function Quad:setUV(u1,v1,u2,v2)
	if u1 then
		local uv = vec(u1,v1,u2,v2)
		if self.uv == uv then return end
		self.uv = uv
	end
	self.display:setSpriteUV(self.box.visualID, self.taskID, self.uv.x, self.uv.y, self.uv.z, self.uv.w)
	return self
end


---@param style GNUI.Sprite.Quad.Style?
function Quad:applyAll(style)
	self:setText()
	self:setPos()
	self:setSize()
	
	if style.texturePath then self:setTexture(style and style.texturePath) end
	if style.uv then self:setUV(style.uv:unpack())end
	if style.color then self:setColor(self.box.color and self.box.color or style.color) end
	if style.childGap then self.box:setChildGap(self.box.childGap and self.box.childGap or style.childGap) end
	
	if style then
		self:setTextColor(self.box.textColor or (style.textColor and gncommon.color(style.textColor).xyz) or self.textColor)
		self:setTextAlignment(self.box.textAlignment and self.box.textAlignment:unpack() or style.textAlignment:unpack())
	else
		self:setTextColor(self.box.textColor or self.textColor)
		self:setTextAlignment(self.box.textAlignment and self.box.textAlignment:unpack())
	end
end


function Quad:free()
	self.display:removeSprite(self.box.visualID, self.taskID)
	self.display:removeLabel(self.box.visualID, self.labelID)
end


return Quad
