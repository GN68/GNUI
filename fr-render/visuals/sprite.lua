---@diagnostic disable: param-type-mismatch

---@class GNUI.Render.Display
local Display = require("./display") ---@type GNUI.Render.Display

---@class GNUI.Render.VisualTask.Sprite : GNUI.Render.Visual
---@field texturePath string
---@field textureSize Vector2
---@field uv Vector4
---@field pos Vector2
---@field layer number
---@field size Vector2
---@field crop Vector4
---@field hasCustomUV boolean
---
---@field quad SpriteTask
local Sprite = {}
Sprite.__index = Sprite


---Creates a new sprite
---@param visualID integer
---@return integer
function Display:newSprite(visualID)
	local vis = self.visuals[visualID]
	assert(vis,"Visual Quad "..visualID.." not found")
	
	local taskID = #vis.tasks+1
	
	local quad = vis.model:newSprite("task"..taskID)
	local self = {
		pos = vec(0, 0),
		layer = 1,
		size = vec(0, 0),
		crop = vec(0, 0, 0, 0),
		uv = vec(0, 0, 1, 1),
		hasCustomUV = false,
		textureSize = vec(1,1),
		quad = quad
	}
	
	setmetatable(self,Sprite)
	
	vis.tasks[taskID] = self
	return taskID
end

---@param task GNUI.Render.VisualTask.Sprite
local function updateSprite(task)
	local w, h = task.size.x, task.size.y
	local crop = task.crop
	local cL = math.clamp(crop.x, 0, w)
	local cT = math.clamp(crop.y, 0, h)
	local cR = math.clamp(crop.z, 0, w - cL)
	local cB = math.clamp(crop.w, 0, h - cT)

	local visW = w - cL - cR
	local visH = h - cT - cB
	local visX = task.pos.x + cL
	local visY = task.pos.y + cT

	local texW, texH = task.textureSize.x, task.textureSize.y
	local uv = task.uv
	local du = uv.z - uv.x
	local dv = uv.w - uv.y

	local u1 = (w > 0) and math.floor(uv.x + du * (cL / w) + 0.5) or uv.x
	local u2 = (w > 0) and math.floor(uv.z - du * (cR / w) + 0.5) or uv.z
	local rw = math.max(1, u2 - u1)
	u1 = math.clamp(u1, uv.x, math.max(uv.x, uv.z - rw))

	local v1 = (h > 0) and math.floor(uv.y + dv * (cT / h) + 0.5) or uv.y
	local v2 = (h > 0) and math.floor(uv.w - dv * (cB / h) + 0.5) or uv.w
	local rh = math.max(1, v2 - v1)
	v1 = math.clamp(v1, uv.y, math.max(uv.y, uv.w - rh))

	task.quad
		:pos(-visX, -visY, -(task.layer - 1) * 1.001)
		:scale(visW / texW, visH / texH, 0)
		:setUV(u1 / texW, v1 / texH)
		:setRegion(rw, rh)
end

--────────────────────────-< Callbacks for general display calls >-────────────────────────--

---@param x number
---@param y number
function Sprite:setSize(x,y)
	local size = self.textureSize
	--self.quad:scale(x/size.x,y/size.y,1)
end


---Sets this given task visibility.
---@param visible boolean
function Sprite:setVisible(visible)
	self.quad:setVisible(visible)
end


---Sets the color of this task.
---@param r number
---@param g number
---@param b number
function Sprite:setColor(r,g,b)
	self.quad:color(r,g,b)
end


--────────────────────────-< Injected APIs >-────────────────────────--


---Sets the size of the given task.
---@param x number
---@param y number
function Display:setSpriteSize(visualID,taskID,x,y)
	local task = self:getTask(visualID,taskID)
	if task then
		task.size = vec(x, y)
		updateSprite(task)
	end
	self:flash(visualID)
end


---Sets the crop (left, up, right, down) of the given task.
---@param visualID integer
---@param taskID integer
---@param l number
---@param t number
---@param r number
---@param b number
function Display:setSpriteCrop(visualID,taskID,l,t,r,b)
	local task = self:getTask(visualID,taskID)
	if task then
		l = l or 0
		t = t or 0
		r = r or 0
		b = b or 0
		if task.crop.x == l and task.crop.y == t and task.crop.z == r and task.crop.w == b then
			return
		end
		task.crop = vec(l, t, r, b)
		updateSprite(task)
	end
end


---Sets the visibility of the given task
---@param visualID integer
---@param taskID integer
---@param visible boolean
function Display:setSpriteVisible(visualID,taskID,visible)
	local task = self:getTask(visualID,taskID)
	if task then
		task.quad:setVisible(visible)
		self:flash(visualID)
	end
end


---Sets the color of the given task
---
---The difference between this and `Display:setColor(r,g,bar)` is that
---this sets the color for the given task only, not for the entire display.
---@param visualID integer
---@param taskID integer
---@param r number
---@param g number
---@param b number
function Display:setSpriteColor(visualID,taskID,r,g,b)
	local task = self:getTask(visualID,taskID)
	if not task then return end
	task.quad:color(r,g,b)
	self:flash(visualID)
end


---Sets the position of the given task
---@param x number
---@param y number
function Display:setSpritePos(visualID,taskID,x,y,layer)
	local task = self:getTask(visualID,taskID)
	if task then
		task.pos = vec(x, y)
		task.layer = layer or task.layer or 1
		updateSprite(task)
	end
end


---Sets the texture of the given task
---@param visualID integer
---@param taskID integer
---@param path string
function Display:setSpriteTexture(visualID,taskID,path)
	local task = self:getTask(visualID,taskID)
	if path then
		local texture = textures[path]
		assert(texture,'texture "'..path..'" not found')
		local textureSize = texture:getDimensions()
		task.texturePath = path
		task.textureSize = textureSize
		if not task.hasCustomUV then
			task.uv = vec(0, 0, textureSize.x, textureSize.y)
		end
		task.quad
		:texture(textures[path],textureSize.x,textureSize.y)
		:setVisible(true)
		updateSprite(task)
	else
		task:setVisible(false)
	end
	self:flash(visualID)
end



---Sets the UV of the given task
---@param visualID integer
---@param u1 number
---@param v1 number
---@param u2 number
---@param v2 number
function Display:setSpriteUV(visualID,taskID,u1,v1,u2,v2)
	local task = self:getTask(visualID,taskID)
	if not task then return end
	local uv = vec(u1,v1,u2,v2)
	task.uv = uv
	task.hasCustomUV = true
	updateSprite(task)
	self:flash(visualID)
end


---Removes the given task
---@param visualID integer
---@param taskID integer
function Display:removeSprite(visualID,taskID)
	local task = self:getTask(visualID,taskID)
	if task then
		task.quad:remove()
		self.visuals[visualID].tasks[taskID] = nil
	end
	self:flash(visualID)
end