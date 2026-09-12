local BASE = ((...):gsub("/", ".")):match(".+%.GNUI")
local cfg = require(BASE .. ".config") ---@type GNUI.config

local utils = require(cfg.UTILS) ---@type GNUI.utils
local Display = require(cfg.RENDER..".visuals.display") ---@type GNUI.Render.Display

---@class GNUI.RenderAPI
local RenderAPI = {}
for _, visualClass in ipairs(utils.listFiles(cfg.RENDER..".visuals")) do
	require(visualClass)
end

---@return GNUI.Render.Display
function RenderAPI.newDisplay()
	return Display.newDisplay()
end


return RenderAPI
