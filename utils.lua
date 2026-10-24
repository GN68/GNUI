--[[______   __
  / ____/ | / /  by: GNanimates / https://gnon.top / Discord: @gn68s
 / / __/  |/ / name: GNUI Utility Module
/ /_/ / /|  /  desc: meant to be refactored to the existing framework/library
\____/_/ |_/ source: link ]]

--- fixes emoji width to be 8 pixels wide
local EMOJI_WIDTH_PATCH = false

---@class GNUI.utils
local util = {}



local NEXTLINE_PLACEHOLDER = "!b4z1n6@"
---converts json text into normal string
---@param text string
---@return string
local function getWidthAccurateText(text)
	local jsonText = text
	if type(text) == "string" then
		jsonText = {text=jsonText}
	end
	local name = (toJson(jsonText):gsub("\\n",NEXTLINE_PLACEHOLDER))
	local ok, item = pcall(world.newItem,"egg[item_name='"..name.."']")
	if ok then
		local out = item:getName():gsub(NEXTLINE_PLACEHOLDER,"\n")
		return out
	else
		return toJson(text)
	end
end


---@return Vector2
function util.getScreenSize()
	return client:getWindowSize()/client:getGuiScale()
end


function util.getTextureSize(path)
	return textures[path]:getDimensions()
end


---@param path string
---@return string[]
function util.listFiles(path)
	return listFiles(path,true)
end


---@return string
function util.getClipboard()
	return host:getClipboard()
end


---@param content string
---@param maxWidth any
---@param wrap any
---@return Vector2
function util.getTextSize(content, maxWidth, wrap)
	content = getWidthAccurateText(content)
	
	return client.getTextDimensions(content, maxWidth+1, wrap):sub(1,1)
end

---@param text string
---@return integer
function util.getTextWidth(text)
	content = getWidthAccurateText(content)
	return client.getTextWidth(text)
end

-- Thankyou 4P5!
local clampCache = setmetatable({}, { mode = "v" })
---@param text string
---@param length number
---@return number
function util.LengthToCharCount(text, length)
	if not clampCache[length] then clampCache[length] = {} end
	if clampCache[length][text] then return clampCache[length][text][1] end

	local width = client.getTextWidth(text)

	local i = 0
	if width > length then
		local low, high = 0, #text
		while low < high do
			i = i + 1
			local mid = math.floor((low + high) / 2)
			local test_text = text:sub(1, mid)
			local test_width = client.getTextWidth(test_text)

			if test_width > length then
				high = mid
			else
				low = mid + 1
			end
		end

		local left = text:sub(1, low - 1)
		text = left
	end

	return #text
end


return util