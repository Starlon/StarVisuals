local mod = StarVisuals:NewModule("PNM")
mod.name = "PNM"
mod.toggled = true
mod.defaultOff = true
local LibBuffer = LibStub("LibScriptableDisplayBuffer-1.0")
local LibCore = LibStub("LibScriptableDisplayCore-1.0")
local LibTimer = LibStub("LibScriptableDisplayTimer-1.0")
local PluginUtils = LibStub("LibScriptableDisplayPluginUtils-1.0")
local AVSSuperScope = LibStub("LibScriptableDisplayAVSSuperScope-1.0")
local PluginColor = LibStub("LibScriptableDisplayPluginColor-1.0"):New({})
local LibPNM = LibStub("LibScriptableDisplayPNM-1.0")
local _G = _G
local GameTooltip = _G.GameTooltip
local StarVisuals = _G.StarVisuals
local UIParent = _G.UIParent
local textures = {[0] = "Interface\\Addons\\StarVisuals\\Media\\black.blp", [1] = "Interface\\Addons\\StarVisuals\\Media\\white.blp"}
local environment = {}
local update

local options = {
}

local foo = 200
local defaults = {
	profile = {
		update = 100,
		images = {
			[1] = {
				name = "Tiger",
				pnm = StarVisualsTiger,
				pixel = 1,
				points = {{"CENTER", "UIParent", "CENTER", 0, 64 * 2 + 20}},
				enabled = 1
			},
			[2] = {
				name = "Readhead",
				pnm = StarVisualsReadhead,
				pixel = 1,
				points = {{"CENTER", "UIParent", "CENTER", 0, 64}},
				enabled = true
			},		
			[3] = {
				name = "Snail",
				pnm = StarVisualsSnail,
				pixel = 1,
				points = {{"CENTER", "UIParent", "CENTER", 0, -64}},
				enabled = true
			},
			[4] = {
				name = "Rays",
				pnm = StarVisualsRays,
				pixel = 1,
				points = {{"CENTER", "UIParent", "CENTER", 0, -64 * 2 - 20}},
				enabled = true
			},
		}
	}
}

local buildImages
function mod:OnInitialize()
	self.db = StarVisuals.db:RegisterNamespace(self:GetName(), defaults)
	StarVisuals:SetOptionsDisabled(options, true)
		
	self.timer = LibTimer:New("PNM build", self.db.profile.update, true, buildImages)	
end

local function copy(tbl)
	local newTbl = {}
	for k, v in pairs(tbl) do
		if type(v) == "table" then
			v = copy(v)
		end
		newTbl[k] = v
	end
	return newTbl
end

local co = coroutine.create(function()
	if type(mod.images) ~= "table" then mod.images = {} end

	for k, image in pairs(mod.db.profile.images) do
		if image.enabled then
			local image = LibPNM:New("image", copy(image), draw)
			local frame = CreateFrame("Frame")
			frame:SetParent(UIParent, "StarVisuals_" .. image.config.name:gsub(" ", "_"))
			
			frame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				tile = true,
				tileSize = 4,
				edgeSize=4, 
				insets = { left = 0, right = 0, top = 0, bottom = 0}})
			frame:ClearAllPoints()
			
			frame:SetAlpha(1)
			frame:SetBackdropColor(0, 0, 0)
			
			frame:SetWidth(image.w * image.pixel)
			frame:SetHeight(image.h * image.pixel)
			
			for _, point in ipairs(image.config.points or {{"CENTER", "UIParent", "CENTER"}}) do
				frame:SetPoint(unpack(point))
			end
			
			frame:Show()
			image.textures = {}
			for row = 0, image.h - 1 do
				for col = 0, image.w - 1 do
				--for n = 0, image.height * image.width - 1 do
					--local row, col = PluginUtils.GetCoords(n, image.width)
					local n = row * image.w + col
					image.textures[n] = frame:CreateTexture()
					image.textures[n]:SetHeight(image.pixel)
					image.textures[n]:SetWidth(image.pixel)
					image.textures[n]:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", col * image.pixel, (image.h - row + 1) * image.pixel)
					image.textures[n]:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
					image.textures[n]:Show()
					if image.bitmap then
					elseif image.grayimage then
						local blue = image.grayimage[n] / 100 * image.n
						local green = bit.lshift(image.grayimage[n] / 100 * image.n, 8)
						local red = bit.lshift(image.grayimage[n] / 100 * image.n, 16)
						local color = bit.bor(bit.bor(red, green), blue)
						image.textures[n]:SetVertexColor(PluginColor.Color2RGBA(color))
					elseif image.colorimage then
						local color = image.colorimage[n]
						local red = color.r / image.n
						local green = color.g / image.n
						local blue = color.b / image.n
						image.textures[n]:SetVertexColor(red, green, blue)
					end					
				end
				coroutine.yield(false)
			end
			image.canvas = frame
			tinsert(mod.images, image)
		end
		coroutine.yield(true)
	end
end)

function buildImages()
	if coroutine.status(co) == 'dead' then
		mod.timer:Stop()
		update()
	else
		local ret, ret2 = coroutine.resume(co)
		if ret2 then error(ret2) end
	end
end

function mod:OnEnable()
	StarVisuals:SetOptionsDisabled(options, false)
	self.timer:Start()
	update()
end

function mod:OnDisable()
	StarVisuals:SetOptionsDisabled(options, true)
	for k, image in pairs(self.images or {}) do
		image.canvas:Hide()
	end
	wipe(self.images)
end

function mod:GetOptionsbleh()
	for i, image in ipairs(self.db.profile.images) do
		options.images.args["Icon"..i] = {
			enabled = {
				name = "Enabled",
				type = "toggle",
				get = function() return image.enabled end,
				set = function(info, val) image.enabled = val end,
				order = 1
			},
			speed = {
				name = "Speed",
				type = "input",
				pattern = "%d",
				get = function() return image.speed end,
				set = function(info, val) image.speed = val end,
				order = 2
			},
			bitmap = {
				name = "Bitmap",
				type = "input",
				multiline = true,
				width = "full",
				get = function() return image.bitmap end,
				set = function(info, val) image.bitmap = val end,
				order = 3
			}
		}
	end
	return options
end

function mod:ClearImages()
do return end
	for k, widget in pairs(mod.images) do
		widget:Del()
	end
	wipe(mod.images)
end

function update()
	for i, pnm in ipairs(mod.images or {}) do
		if pnm.bitmap then
		elseif pnm.grayimage then
			for n = 0, pnm.h * pnm.w - 1 do
				local color = 0
				blue = pnm.grayimage[n] / 100 * pnm.n
				green = bit.lshift(pnm.grayimage[n] / 100 * pnm.n, 8)
				red = bit.lshift(pnm.grayimage[n] / 100 * pnm.n, 16)
				local color = bit.bor(blue, bit.bor(green, red))
				pnm.textures[n]:SetVertexColor(PluginColor.Color2RGBA(color))
			end
		elseif pnm.colorimage then
			for n = 0, pnm.h * pnm.w - 1 do
				local red, green, blue = PluginColor.Color2RGBA(pnm.colorimage[n])
				pnm.textures[n]:SetVertexColor(red, green, blue)
			end		
		end
		--[[
		for n = 0, widget.height * widget.width - 1 do
			local color = widget.buffer.buffer[n]
			widget.textures[n]:SetVertexColor(PluginColor.Color2RGBA(color))
		end]]
	end
end
