---@diagnostic disable: param-type-mismatch
--[[______   __
  / ____/ | / /  by: GNanimates / https://gnon.top / Discord: @gn68s
 / / __/  |/ / name: GNUI Box Widget
/ /_/ / /|  /  desc: The API for instantiating a box
\____/_/ |_/ source: link ]]
---@diagnostic disable: duplicate-doc-field

local BASE = ((...):gsub("/", ".")):match(".+%.GNUI")
local cfg = require(BASE .. ".config") ---@type GNUI.config

local TrueBoxAPI = require(BASE .. ".core.prims.box") ---@type GNUI.Primitive.BoxAPI
local Layout = require(cfg.LAYOUT .. ".init") ---@type GNUI.LayoutAPI
local Theme = require(cfg.THEME .. ".init") ---@type GNUI.ThemeAPI

---@class GNUI.BoxAPI : GNUI.Primitive.BoxAPI
local BoxAPI = {}

setmetatable(BoxAPI, {
	__index = function(t, i)
		return rawget(t, i)
			 or TrueBoxAPI[i]
			 or TrueBoxAPI.index(t, i)
	end,
})

--────────────────────────-< Layout Parser >-────────────────────────--

---@class GNUI.Layout
---@field type nil|"box"
---@field name string?
---@field style string?
---@field pos Vector2?
---@field size Vector2?
---@field minSize Vector2?
---@field sizing ({[1]:GNUI.Box.SizingMode,[2]:GNUI.Box.SizingMode}|GNUI.Box.SizingMode)?
---@field pos Vector2?
---@field gap number?
---@field layout GNUI.Box.LayoutMode?
---@field childAlign Vector2?
---@field text string|table?
---@field textAlign {[1]:(-1|0|1),[2]:(-1|0|1)}?
---@field margin Vector4?
---@field padding Vector4?
---@field color Vector3?
---@field textColor Vector3|string?
---@field textScale number?
---@field wrapText boolean?
---@field captureInput boolean?
---@field textOffset Vector2?


---@param layout GNUI.Layout
---@param canvas GNUI.Canvas
---@param children GNUI.Box|GNUI.Box[]
---@generic box
---@param extraParser fun(box:GNUI.Box,canvas:GNUI.Canvas,children:table) --TODO: annotate this properly
---@return box
function BoxAPI.parse(layout, canvas, children, extraParser)
	local box = TrueBoxAPI.new(canvas)

	local hasSizeX, hasSizeY = false, false
	if layout.size then
		box:setSize(layout.size.x, layout.size.y)
		hasSizeX = layout.size.x ~= -1
		hasSizeY = layout.size.y ~= -1
	end
	if layout.minSize then box:setMinimumSize(layout.minSize.x, layout.minSize.y) end
	if layout.sizing then
		if type(layout.sizing) == "string" then
			---@diagnostic disable-next-line: param-type-mismatch
			box:setSizing(layout.sizing, layout.sizing)
		else
			box:setSizing(layout.sizing[1], layout.sizing[2])
		end
	else
		if box.text and #box.text > 0 then
			box:setSizing("FILL", "FIT")
		else
			box:setSizing(hasSizeX and "FIXED" or "FIT", hasSizeY and "FIXED" or "FIT")
		end
	end
	if layout.pos then box:setPos(layout.pos.x, layout.pos.y) end
	if layout.layout then 
		box:setLayout(layout.layout) 
	end
	if layout.childAlign then box:setChildAlign(layout.childAlign) end
	
	
	
	

	
	
	if layout.name then
		box:setName(layout.name)
	end
	-- only automatically add the children to the box if the box has no extra parser
	if extraParser then
		extraParser(box,canvas,children)
	else
		for index, child in ipairs(children) do
			box:addChild(child)
		end
	end
	
	local t = type(layout.style)
	if t == "string" or t == "nil" then
		box:setStyleVariant(layout.style)
	else
		if layout.style then
			Theme.applyStyle(layout.style,box,1)
		end
	end
	
	
	if layout.text then box:setText(layout.text) end
	if layout.textAlign then box:setTextAlignment(layout.textAlign[1], layout.textAlign[2]) end
	if layout.color then box:setColor(layout.color) end
	if layout.textColor then box:setTextColor(layout.textColor) end
	if layout.textScale then box:setTextScale(layout.textScale) end
	if layout.gap then box:setChildGap(layout.gap) end
	if type(layout.wrapText) == "boolean" then box:setWrapText(layout.wrapText) end
	if type(layout.captureInput) == "boolean" then box:setCaptureInputs(layout.captureInput) end
	if layout.textOffset then box:setTextoffset(layout.textOffset.x,layout.textOffset.y) end
	
	
	box:setPadding(layout.padding or vec(0,0,0,0))
	box:setMargin(layout.margin or vec(0,0,0,0))
	return box
end

Layout.registerType("box", BoxAPI.parse)

return BoxAPI
