local BASE = (...):match(".+[./]GNUI"):gsub("/", ".")

local atlas ---@type string
---@diagnostic disable-next-line: undefined-global
if figuraMetatables then -- is Figura lmao
	atlas = (...):gsub("/", ".") .. ".gnui"
else
	atlas = BASE:gsub("%.", "/") .. "/style/theme/gnui.png"
end

---@type GNUI.Theme
return {
	title = "gnui",
	styles = {
		box = {
			default = "none",
			opaque = {
				normal = {
					type = "nineslice",
					texturePath = atlas,
					uv = vec(5, 10, 7, 12),
					border = vec(2, 2, 2, 2),
					padding = vec(1, 1, 1, 1),
					childGap = 1,
				},
			},
			highlight = {
				normal = {
					type = "nineslice",
					texturePath = atlas,
					uv = vec(13, 1, 15, 3),
					border = vec(1, 1, 1, 1),
					expand = vec(2, 2, 2, 2),
				},
			},
			white = {
				normal = {
					type = "quad",
					texturePath = atlas,
					uv = vec(2,11,2,11),
					sizing="STRETCH"
				},
			},
			none = {
				normal = {
					type = "sprite",
					childGap = 1,
				},
			},
		},
		button = {
			default = {
				normal = {
					type = "nineslice",
					texturePath = atlas,
					uv = vec(0, 0, 4, 4),
					border = vec(2, 2, 2, 2),
					padding = vec(1, 1, 1, 1),
					expand = vec(1, 1, 1, 1),
					textAlignment = vec(0, 0),
					textColor = "#141414",
				},
				hovered = {
					type = "nineslice",
					texturePath = atlas,
					uv = vec(4, 0, 8, 4),
					border = vec(2, 2, 2, 2),
					padding = vec(1, 1, 1, 1),
					expand = vec(1, 1, 1, 1),
					textAlignment = vec(0, 0),
					textColor = "#141414",
				},
				pressed = {
					type = "nineslice",
					texturePath = atlas,
					uv = vec(8, 0, 12, 4),
					border = vec(2, 2, 2, 2),
					padding = vec(1, 1, 1, 1),
					expand = vec(1, 1, 1, 1),
					textAlignment = vec(0, 0),
					textColor = "#141414",
				},
			},
			secondary = {
				normal = {
					type = "nineslice",
					texturePath = atlas,
					uv = vec(21,0,25,4),
					border = vec(2, 2, 2, 2),
					padding = vec(1, 1, 1, 1),
					expand = vec(1, 1, 1, 1),
					textAlignment = vec(0, 0),
					textColor = "#F3F3F3",
				},
				hovered = {
					type = "nineslice",
					texturePath = atlas,
					uv = vec(25,0,29,4),
					border = vec(2, 2, 2, 2),
					padding = vec(1, 1, 1, 1),
					expand = vec(1, 1, 1, 1),
					textAlignment = vec(0, 0),
					textColor = "#ffffff",
				},
				pressed = {
					type = "nineslice",
					texturePath = atlas,
					uv = vec(29,0,33,4),
					border = vec(2, 2, 2, 2),
					padding = vec(1, 1, 1, 1),
					expand = vec(1, 1, 1, 1),
					textAlignment = vec(0, 0),
					textColor = "#C4C4C4",
				},
			},
		},
		slider = {
			default = {
				normal = {
					type = "nineslice",
					texturePath = atlas,
					uv = vec(16, 0, 20, 4),
					border = vec(2, 2, 2, 2),
					expand = vec(1, 1, 1, 1),
					minSize = vec(11, 11),
				},
				hovered = {
					type = "nineslice",
					texturePath = atlas,
					uv = vec(12, 0, 16, 4),
					border = vec(2, 2, 2, 2),
					expand = vec(1, 1, 1, 1),
					minSize = vec(11, 11),
				},
				pressed = {
					type = "nineslice",
					texturePath = atlas,
					uv = vec(16, 0, 20, 4),
					border = vec(2, 2, 2, 2),
					expand = vec(1, 1, 1, 1),
					minSize = vec(11, 11),
				},
				knob = {
					type = "nineslice",
					texturePath = atlas,
					uv = vec(0, 0, 4, 4),

					border = vec(2, 2, 2, 2),
					expand = vec(1, 1, 1, 1),

					textAlignment = vec(0, 0),
					textColor = "#ffffff",
				},
				knobLength = 11,
				knobPressed = {
					type = "nineslice",
					texturePath = atlas,
					uv = vec(4, 0, 6, 2),
					border = vec(1, 1, 1, 1),
				},
			},
		},
		textField = {
			default = {
				empty = {
					type = "nineslice",
					texturePath = atlas,
					uv = vec(1, 5, 3, 8),
					textColor = "#9B9B9B",
					border = vec(1, 1, 1, 2),
					padding = vec(2, 0, 2, -1),
					minSize = vec(9, 0),
					textAlignment = vec(-1, 1),
				},
				normal = {
					type = "nineslice",
					texturePath = atlas,
					uv = vec(1, 5, 3, 8),
					border = vec(1, 1, 1, 2),
					padding = vec(2, 0, 2, -1),
					minSize = vec(9, 0),
					textAlignment = vec(-1, 1),
				},
				active = {
					type = "nineslice",
					texturePath = atlas,
					uv = vec(5, 5, 7, 8),
					border = vec(1, 1, 1, 2),
					padding = vec(2, 0, 2, -1),
					minSize = vec(9, 0),
					textAlignment = vec(-1, 1),
				},
				invalid = {
					type = "nineslice",
					texturePath = atlas,
					uv = vec(9, 5, 11, 8),
					border = vec(1, 1, 1, 2),
					padding = vec(2, 0, 2, -1),
					minSize = vec(9, 0),
					textAlignment = vec(-1, 1),
				},
			},
		},
		dropdown = {
			default = {
				normal = {
					type = "nineslice",
					texturePath = atlas,
					uv = vec(0, 0, 4, 4),
					padding = vec(2, 0, 0, 0),
					border = vec(2, 2, 2, 2),
					expand = vec(1, 1, 1, 1),
					textAlignment = vec(0, 0),
					textColor = "#141414",
				},
				hovered = {
					type = "nineslice",
					texturePath = atlas,
					uv = vec(4, 0, 8, 4),
					padding = vec(2, 0, 0, 0),
					border = vec(2, 2, 2, 2),
					expand = vec(1, 1, 1, 1),
					textAlignment = vec(0, 0),
					textColor = "#141414",
				},
				pressed = {
					type = "nineslice",
					texturePath = atlas,
					uv = vec(8, 0, 12, 4),
					padding = vec(2, 0, 0, 0),
					border = vec(2, 2, 2, 2),
					expand = vec(1, 1, 1, 1),
					textAlignment = vec(0, 0),
					textColor = "#141414",
				},
				entryStyle = "secondary",
			},
		},
		spinBox = {
			default = {
				empty = {
					type = "nineslice",
					texturePath = atlas,
					uv = vec(1, 5, 3, 8),
					textColor = "#9B9B9B",
					border = vec(1, 1, 1, 2),
					padding = vec(2, 0, 9, -1),
					minSize = vec(18, 0),
					textAlignment = vec(-1, 1),
				},
				normal = {
					type = "nineslice",
					texturePath = atlas,
					uv = vec(1, 5, 3, 8),
					border = vec(1, 1, 1, 2),
					padding = vec(2, 0, 9, -1),
					minSize = vec(18, 0),
					textAlignment = vec(-1, 1),
				},
				active = {
					type = "nineslice",
					texturePath = atlas,
					uv = vec(5, 5, 7, 8),
					border = vec(1, 1, 1, 2),
					padding = vec(2, 0, 9, -1),
					minSize = vec(18, 0),
					textAlignment = vec(-1, 1),
				},
				invalid = {
					type = "nineslice",
					texturePath = atlas,
					uv = vec(9, 5, 11, 8),
					border = vec(1, 1, 1, 2),
					padding = vec(2, 0, 9, -1),
					minSize = vec(18, 0),
					textAlignment = vec(-1, 1),
				},
				knobLength = 7,
				knobStyle = "default",
			},
		},
	},
}
