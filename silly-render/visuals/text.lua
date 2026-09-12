---@diagnostic disable: param-type-mismatch
local BASE = ((...):gsub("/", ".")):match(".+%.GNUI")
local cfg = require(BASE .. ".config") ---@type GNUI.config

local utils = require(BASE..".utils") ---@type GNUI.utils

---@class GNUI.Render.Display
local Display = require(cfg.RENDER..".visuals.display") ---@type GNUI.Render.Display


---@class GNUI.Text
---@field text string
---@field color string


---@class GNUI.Render.VisualTask.Label : GNUI.Render.Visual
---@field padding Vector4
---@field text string|GNUI.Text[]
---@field jsonText string
---@field textColor Vector3
---@field textAlignment Vector2
---@field wrapText boolean
local Label = {}
Label.__index = Label


local function parseText(text,defaultColor)
	local tableText
	if type(text) == "string" then
		tableText = {{text=text,color="#"..defaultColor}}
	else
		if type(text) == "table" then
			for index, value in ipairs(text) do
				if not value.color then
					value.color = defaultColor
				end
			end
			tableText = text
		end
	end
	-- TODO: implement coloring
	return tableText
end


---@param visualID integer
---@return integer
function Display:newLabel(visualID)
	local vis = self.visuals[visualID]
	assert(vis,"Visual Quad "..visualID.." not found")
	
	local taskID = #vis.tasks+1
	local self = {
		
		size = vec(0,0),
		padding = vec(0,0,0,0),
		visible = true,
		textAlignment = vec(-1,1),
		textColor = vec(1,1,1),
		wrapText = true,
	}
	
	setmetatable(self,Label)
	
	vis.tasks[taskID] = self
	return taskID
end


---@param task GNUI.Render.VisualTask.Label
local function updateLabelText(task)
	if task.text then
		task.jsonText = tostring(task.text) --parseText(task.text,task.textColor)
	end
end

---@param task GNUI.Render.VisualTask.Label
local function updateLabelPos(task)
	if task.text then
		--task.label:alignment(task.textAlignment.x == -1 and "LEFT" or task.textAlignment.x == 0 and "CENTER" or "RIGHT")
		local fineWidth = task.size.x-task.padding.x-task.padding.z
		--task.label:setWidth(fineWidth)
		--local textDim = client.getTextDimensions(task.jsonText, fineWidth, task.wrapText)
		--local align = task.textAlignment*0.5+0.5
		--task.label:setPos(
		--	math.floor(math.lerp(-task.padding.x,task.padding.z,align.x) - task.size.x * (align.x)+0.5),
		--	math.floor(math.lerp(
		--		-task.padding.y,
		--		-task.size.y+task.padding.w+textDim.y,
		--		align.y
		--	)+0.5)
		--)
	end
end


---INTERNAL CALLBACK for Display
---@param x number
---@param y number
function Label:setSize(x,y)
	self.size = vec(x,y)
	updateLabelPos(self)
end


---INTERNAL CALLBACK for Display
function Label:setVisible(visible)
	self.visible = visible
end


function Label:setColor(r,g,b)
end


--────────────────────────-< Injected APIs >-────────────────────────--

---TODO: implement a caller in the GNUI core
---Sets the wrap text of the given label
---@param visualID integer
---@param taskID integer
---@param wrapText boolean
function Display:setLabelWrapText(visualID,taskID,wrapText)
	local task = self:getTask(visualID,taskID)
	if not task then return end
	task.wrapText = wrapText
	updateLabelPos(task)
end


---@param visualID integer
---@param taskID integer
---@param left number
---@param top number
---@param right number
---@param bottom number
function Display:setLabelPadding(visualID,taskID,left,top,right,bottom)
	local task = self:getTask(visualID,taskID)
	task.padding = vec(left,top,right,bottom)
	updateLabelPos(task)
end


function Display:setLabelVisible(visualID,taskID,visible)
	local task = self:getTask(visualID,taskID)
	task.visible = visible
end


---@param visualID integer
---@param taskID integer
---@param r number
---@param g number
---@param b number
function Display:setLabelColor(visualID,taskID,r,g,b)
	local task = self:getTask(visualID,taskID)
	task.textColor = vec(r,g,b)
	task.jsonText = parseText(task.text,vectors.rgbToHex(task.textColor))
	updateLabelText(task)
	updateLabelPos(task)
end


---@param visualID integer
---@param taskID integer
---@param text string|GNUI.Text[]
function Display:setLabelText(visualID,taskID,text)
	local task = self:getTask(visualID,taskID)
	task.text = text
	
	updateLabelText(task)
	updateLabelPos(task)
end


---@param visualID integer
---@param taskID integer
---@param h -1|0|1
---@param v -1|0|1
function Display:setLabelAlignment(visualID,taskID,h,v)
	local task = self:getTask(visualID,taskID)
	task.textAlignment = vec(h,v)
	updateLabelPos(task)
end


---Sets the alignment of the given label
---@param visualID integer
---@param taskID integer
---@param h number
---@param v number
function Display:setLabelOffset(visualID,taskID,h,v)
	local task = self:getTask(visualID,taskID)
	if not task then return end
	task.textOffset = vec(h,v)
	updateLabelPos(task)
end


---Removes the given label
---@param visualID integer
---@param taskID integer
function Display:removeLabel(visualID,taskID)
	local task = self:getTask(visualID,taskID)
	if task then
		self.visuals[visualID].tasks[taskID] = nil
	end
end

---@param graphics LuaGraphicsAPI
---@param pos Vector2
---@param visual GNUI.Render.VisualTask.Label
function Label:draw(graphics,pos,visual)
	if self.jsonText then
		local padding = self.padding
		local finalWidth = self.size.x-padding.x-padding.z
		local size = utils.getTextSize(self.text, self.size.x, self.wrapText and finalWidth > 20)
		graphics:blitString(
		self.jsonText,
		pos.x+padding.x,
		math.lerp(pos.y, pos.y + self.size.y - size.y+1, self.textAlignment.y*0.5+0.5),
		finalWidth
		)
	--	love.graphics.printf({{self.textColor:unpack()},self.text},
	--	pos.x+padding.x,
	--	math.lerp(pos.y+size.y*0.5, pos.y + self.size.y - size.y+1, self.textAlignment.y*0.5+0.5),
	--	finalWidth,
	--	self.textAlignment.x == -1 and "left" or self.textAlignment.x == 0 and "center" or "right"
	--)
	end
end
