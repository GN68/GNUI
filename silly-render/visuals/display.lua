--[[______   __
  / ____/ | / /  by: GNanimates / https://gnon.top / Discord: @gn68s
 / / __/  |/ / name: Display API
/ /_/ / /|  /  desc: handles all the updating for all visuals
\____/_/ |_/ source: link ]]

---@class GNUI.Render.Visual.Task
---@field visible boolean
---@field pos Vector2
---@field size Vector2
---@field [any] any


---@class GNUI.Render.Visual
---@field id integer
---@field visible boolean
---@field index integer
---@field children GNUI.Render.Visual[]
---@field parent GNUI.Render.Visual?
---
---@field pos Vector2
---@field size Vector2
---
---@field tasks GNUI.Render.Visual.Task[]


---@class GNUI.Render.Display
---@field visuals GNUI.Render.Visual[]
local Display = {}
Display.__index = Display


function Display.newDisplay()
	local self = {}
	setmetatable(self,Display)
	---@cast self GNUI.Render.Display
	
	self.visuals = {}
	self:newVisual()
	
	return self
end


---@return integer
function Display:newVisual()
	local id = #self.visuals+1
	local visual = {
		id = id,
		
		index = 1,
		children = {},
		
		visible = true,
		pos = vec(0,0),
		size = vec(0,0),
		
		tasks = {},
	}
	
	self.visuals[id] = visual
	return id
end


---@param visualID integer
function Display:flash(visualID)
	--TODO: implement flashing for debugging
end

---NOTE: INTERNAL USE ONLY
---@param visualID integer
---@param spriteID integer
---@return GNUI.Render.Visual.Task?
function Display:getTask(visualID,spriteID)
	local visual = self.visuals[visualID]
	if visual then
		local task = visual.tasks[spriteID]
		return task
	end
end


---@param vis GNUI.Render.Visual
local function updateChildrenIndexes(vis)
	for i, child in ipairs(vis.children) do
		vis.index = i
		updateChildrenIndexes(child)
	end
end


---Updates the dimensions of the visual
---@param visualID integer
function Display:updateDimensions(visualID)
	local vis = self.visuals[visualID]
	-- useless for immidiate renderer
end


---@param id integer
---@param childID integer
---@return GNUI.Render.Visual
function Display:addChild(id,childID)
	local vis = self.visuals[id]
	local child = self.visuals[childID]
	assert(vis,"Visual Quad "..tostring(id).." not found")
	assert(child,"Visual Quad "..tostring(childID).." not found")
	
	child.parent = vis
	local id = #vis.children + 1
	vis.children[id] = child
	child.index = id
	
	self:updateDimensions(child.id)
	self:updateDimensions(vis.id)
	return vis
end


function Display:setVisualChildIndex(visualID,index)
	local vis = self.visuals[visualID]
	if not vis then return end
	local parent = vis.parent
	if parent then
		index = math.clamp(index, 1, #parent.children)
		local ogIndex = vis.index
		if index ~= ogIndex then
			local temp = parent.children[index]
			parent.children[index] = vis
			parent.children[ogIndex] = temp
			
			vis.index = index
			
			if temp then
				temp.index = ogIndex
			end
			
			self:updateDimensions(parent.id)
			if parent.children[index] then
				self:updateDimensions(parent.id)
			end
		end
	end
end


---Removes a child from the box
---@param visualID integer
---@param childVisualID integer
function Display:removeChild(visualID,childVisualID)
	local vis = self.visuals[visualID]
	if not vis then return end
	
	local child = self.visuals[childVisualID]
	assert(child,"Visual Quad "..visualID.." not found")
	
	if vis.children[child.id] == child then
		table.remove(vis.children, childVisualID)
		
		updateChildrenIndexes(vis)
		child.parent = nil
		self:updateDimensions(child.id)
		self:updateDimensions(vis.id)
	end
	return self
end


---Removes the parent of the box
---@param id integer
function Display:removeParent(id)
	local vis = self.visuals[id]
	if not vis then return end
	
	if vis.parent then
		self:removeChild(vis.parent.id,vis.id)
	end
	return self
end


function Display:removeVisual(visualID)
	local vis = self.visuals[visualID]
	if not vis then return end
	self.visuals[visualID] = nil
end



---Sets the parent of the box
---@param id integer
---@param parentID integer
function Display:setParent(id,parentID)
	local vis = self.visuals[id]
	local parent = self.visuals[parentID]
	if not vis then return end
	assert(parent,"Visual Quad "..parentID.." not found")
	
	self:removeParent(id)
	self:addChild(parentID,id)
end


function Display:free(id)
	local vis = self.visuals[id]
	if not vis then return end
	
	self.visuals[id] = nil
end


function Display:setPos(id,x,y)
	local vis = self.visuals[id]
	if not vis then return end
	vis.pos = vec(x,y)
end


function Display:setSize(id,x,y)
	local vis = self.visuals[id]
	if not vis then return end
	vis.size = vec(x,y)
	for key, task in pairs(vis.tasks) do
		task:setSize(x,y)
	end
end


function Display:setVisible(id,visible)
	local vis = self.visuals[id]
	if not vis then return end
	
	vis.visible = visible
	
end


function Display:setColor(id,r,g,b)
	local vis = self.visuals[id]
	if not vis then return end
	
	for key, task in pairs(vis.tasks) do
		task:setColor(r,g,b)
	end
end
local e = 0

local function drawTasks(graphics,visual,offset)
	for key, task in pairs(visual.tasks) do
		if task.visible then
			task:draw(graphics,offset + visual.pos,visual)
		end
	end
	for vi, childVis in pairs(visual.children) do
		if childVis.visible then
			drawTasks(graphics,childVis,offset + visual.pos)
		end
	end
end

---@param graphics LuaGraphicsAPI
function Display:draw(graphics)
	drawTasks(graphics,self.visuals[1],vec(0,0))
end

return Display
