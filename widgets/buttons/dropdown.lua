--[[______   __
  / ____/ | / /  by: GNanimates / https://gnon.top / Discord: @gn68s
 / / __/  |/ / name: GNUI Dropdown Class
/ /_/ / /|  /  desc: the dropdown widget for GNUI
\____/_/ |_/ source: link ]]

local BASE = ((...):gsub("/", ".")):match(".+%.GNUI")
local cfg = require(BASE .. ".config") ---@type GNUI.config

local Box = require(cfg.WIDGETS .. ".box") ---@type GNUI.BoxAPI
local Event = require(cfg.EVENT)
local Button = require(cfg.WIDGETS .. ".button") ---@type GNUI.Widget.ButtonAPI

local Style = require(cfg.THEME .. ".init") ---@type GNUI.ThemeAPI
local Layout = require(cfg.LAYOUT .. ".init") ---@type GNUI.LayoutAPI

local utils = require(cfg.UTILS) ---@type GNUI.utils

---@class Event.GNUI.Dropdown.ValueChanged : GN.Event
---@field register fun(self, func: fun(index: integer, text: string), id: any?)

---@class GNUI.Widget.DropdownAPI
local DropdownAPI = {}

---@class GNUI.Widget.Dropdown : GNUI.Widget.Button
---@field popup GNUI.Box
---@field entries string[]
---@field entryButtons GNUI.Widget.Button[]
---@field value integer
---@field placeholder string
---@field VALUE_CHANGED Event.GNUI.Dropdown.ValueChanged
local Dropdown = {}
Dropdown.__index = function(t, i)
	return rawget(t, i)
		or Dropdown[i]
		or Button.index(t, i)
		or Box.index(t, i)
end
Dropdown.__style = "dropdown"
Dropdown.__type = "Dropdown"

function DropdownAPI.index(t, i)
	return Dropdown.__index(t, i)
end

---@param box GNUI.Box
---@param canvas GNUI.Canvas
---@param children GNUI.Box[]?
---@return GNUI.Widget.Dropdown
function DropdownAPI.new(box, canvas, children)
	local self = Button.new(box, canvas, children)
	---@cast self GNUI.Widget.Dropdown
	setmetatable(self, Dropdown)

	self:setMinimumSize(0, 11)
	self.toggle = true
	self.value = 0
	self.entries = {}
	self.entryButtons = {}
	self.placeholder = ""
	self.VALUE_CHANGED = Event.new()

	local popup = canvas:parse({
		style = "opaque",
		layout = "VERTICAL",
		sizing = { "FIXED", "FIT" },
	})
	popup:setVisible(false)
	self.popup = popup

	local function syncPopupTransform()
		popup:setPos(self.absPos.x, self.absPos.y + self.finalSize.y)
		popup:setSize(self.finalSize.x, -1)
	end

	self.SIZE_CHANGED:register(syncPopupTransform)
	self.POSITION_CHANGED:register(syncPopupTransform)

	self.BUTTON_DOWN:register(function()
		syncPopupTransform()
		popup:setVisible(true)
		popup:setChildIndex(#self.canvas.children)

		self.canvas.MOUSE_INPUT:register(function(button, state)
			if state == 1 then
				local cursorPos = self.canvas.cursorPos
				if not self:isPosInboundingBox(cursorPos) and not self.popup:isPosInboundingBox(cursorPos) then
					self:release()
				end
			end
		end, self.id)
	end, "__core")

	self.BUTTON_UP:register(function()
		popup:setVisible(false)
		if self.canvas then
			self.canvas.MOUSE_INPUT:remove(self.id)
		end
	end, "__core")

	if children then
		for _, child in ipairs(children) do
			if child.text and child.text[1] then
				self:addEntry(child.text[1])
				child:free()
			end
		end
	end

	return self
end

---@private
function Dropdown:_getEntryStyleVariant()
	if self.variant then
		local ok, styleVariant = pcall(Style.getStyle, self, self.variant, "entryStyle")
		if ok and type(styleVariant) == "string" then
			return styleVariant
		end
	end
	return "secondary"
end

---@private
function Dropdown:_reindexEntries()
	for i, btn in ipairs(self.entryButtons) do
		btn.entryIndex = i
		btn:setChildIndex(i)
	end
end

---@private
function Dropdown:_updateMinimumWidth()
	local maxW = 0
	for _, entry in ipairs(self.entries) do
		local w = utils.getTextSize(entry, math.huge, false).x * self.textScale.x
		if w > maxW then
			maxW = w
		end
	end
	local pad = self:getPadding()
	local popPad = self.popup and self.popup:getPadding() or vec(0, 0, 0, 0)
	local minW = maxW > 0 and (maxW + pad.x + pad.z + popPad.x + popPad.z + 4) or 0
	self:setMinimumSize(minW, math.max(self.minSize.y, 11))
end

---@private
function Dropdown:_updateDisplayText()
	local entryText = self.entries[self.value]
	if entryText ~= nil then
		Box.setText(self, entryText)
	else
		Box.setText(self, self.placeholder or "")
	end
end

---Adds an entry to the dropdown. If `index` is omitted, appends to the end; otherwise inserts at `index`.
---@param text string
---@param index integer?
---@generic self
---@param self self
---@return self
function Dropdown:addEntry(text, index)
	---@cast self GNUI.Widget.Dropdown
	text = tostring(text)
	local count = #self.entries
	local insertIdx = index and math.clamp(index, 1, count + 1) or (count + 1)

	table.insert(self.entries, insertIdx, text)

	local entryButton = self.popup:parse({
		type = "button",
		style = self:_getEntryStyleVariant(),
		text = text,
		wrapText = false,
		sizing = { "FILL", "FIT" },
	})
	---@cast entryButton GNUI.Widget.Button

	table.insert(self.entryButtons, insertIdx, entryButton)
	self:_reindexEntries()

	entryButton.PRESSED:register(function()
		self:setValue(entryButton.entryIndex)
		self:release()
	end)

	if self.value == 0 then
		self.value = 1
	elseif index and insertIdx <= self.value then
		self.value = self.value + 1
	end
	self:_updateMinimumWidth()
	self:_updateDisplayText()

	return self
end

---Removes the entry at the given index.
---@param index integer
---@generic self
---@param self self
---@return self
function Dropdown:removeEntry(index)
	---@cast self GNUI.Widget.Dropdown
	if not self.entries[index] then return self end

	table.remove(self.entries, index)
	local btn = table.remove(self.entryButtons, index)
	if btn then
		btn:free()
	end
	self:_reindexEntries()

	if #self.entries == 0 then
		self.value = 0
	elseif self.value > #self.entries then
		self.value = #self.entries
	elseif index < self.value then
		self.value = self.value - 1
	end
	self:_updateMinimumWidth()
	self:_updateDisplayText()

	return self
end

---Replaces the text of the entry at the given index, if it exists.
---@param index integer
---@param text string
---@generic self
---@param self self
---@return self
function Dropdown:setEntry(index, text)
	---@cast self GNUI.Widget.Dropdown
	if self.entries[index] then
		text = tostring(text)
		self.entries[index] = text
		if self.entryButtons[index] then
			self.entryButtons[index]:setText(text)
		end
		self:_updateMinimumWidth()
		if self.value == index then
			self:_updateDisplayText()
		end
	end
	return self
end

---Clears all entries from the dropdown.
---@generic self
---@param self self
---@return self
function Dropdown:clear()
	---@cast self GNUI.Widget.Dropdown
	for _, btn in ipairs(self.entryButtons) do
		btn:free()
	end
	self.entries = {}
	self.entryButtons = {}
	self.value = 0
	self:_updateMinimumWidth()
	self:_updateDisplayText()
	return self
end

---Sets the selected entry index and triggers `VALUE_CHANGED` if changed.
---@param index integer
---@generic self
---@param self self
---@return self
function Dropdown:setValue(index)
	---@cast self GNUI.Widget.Dropdown
	if self.entries[index] then
		local changed = (self.value ~= index)
		self.value = index
		self:_updateDisplayText()
		if changed then
			self.VALUE_CHANGED:invoke(self.value, self.entries[self.value])
		end
	end
	return self
end

---Sets the selected entry index without triggering `VALUE_CHANGED`.
---@param index integer
---@generic self
---@param self self
---@return self
function Dropdown:setValueSilent(index)
	---@cast self GNUI.Widget.Dropdown
	if self.entries[index] then
		self.value = index
		self:_updateDisplayText()
	end
	return self
end

---Returns the currently selected entry index and its text.
---@return integer, string?
function Dropdown:getValue()
	return self.value, self.entries[self.value]
end

---Sets the fallback text displayed when the dropdown has no entries.
---@param text string
---@param slot (integer|string)?
---@generic self
---@param self self
---@return self
function Dropdown:setText(text, slot)
	---@cast self GNUI.Widget.Dropdown
	if not slot or slot == 1 then
		self.placeholder = text
		if not self.entries[self.value] then
			Box.setText(self, text, slot)
		end
	else
		Box.setText(self, text, slot)
	end
	return self
end

---@param variant string?
---@generic self
---@param self self
---@return self
function Dropdown:setStyleVariant(variant)
	---@cast self GNUI.Widget.Dropdown
	Button.index(self, "setStyleVariant")(self, variant)
	if self.entryButtons then
		local entryStyle = self:_getEntryStyleVariant()
		for _, btn in ipairs(self.entryButtons) do
			btn:setStyleVariant(entryStyle)
		end
	end
	return self
end

---@param visible boolean
---@generic self
---@param self self
---@return self
function Dropdown:setVisible(visible)
	---@cast self GNUI.Widget.Dropdown
	if not visible and self.down then
		self:release()
	end
	return Box.setVisible(self, visible)
end

function Dropdown:free()
	if self.canvas then
		self.canvas.MOUSE_INPUT:remove(self.id)
	end
	if self.popup then
		self.popup:free()
		self.popup = nil
	end
	Box.free(self)
end

--────────────────────────-< Layout Parser >-────────────────────────--

---@diagnostic disable: duplicate-doc-field
---@class GNUI.Layout
---@field type "dropdown"?
---@field entries string[]?
---@field value integer?
---@field placeholder string?

---@param layout any
---@param canvas GNUI.Canvas
---@param children GNUI.Box[]
---@param button GNUI.Widget.Dropdown?
---@return GNUI.Widget.Dropdown
function DropdownAPI.parse(layout, canvas, children, button)
	local self = button or Box.parse(layout, canvas, children, DropdownAPI.new)
	---@cast self GNUI.Widget.Dropdown

	if layout.placeholder then
		self:setText(layout.placeholder)
	end
	if layout.entries then
		for _, entry in ipairs(layout.entries) do
			self:addEntry(entry)
		end
	end
	if layout.value then
		self:setValueSilent(layout.value)
	end

	return self
end

Layout.registerType("dropdown", DropdownAPI.parse)

return DropdownAPI
