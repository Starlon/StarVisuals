local mod = StarVisuals:NewModule("Images")
mod.name = "Images"
mod.toggled = true
mod.defaultOff = true
local LibBuffer = LibStub("LibScriptableDisplayBuffer-1.0")
local LibCore = LibStub("LibScriptableDisplayCore-1.0")
local LibTimer = LibStub("LibScriptableDisplayTimer-1.0")
local PluginUtils = LibStub("LibScriptableDisplayPluginUtils-1.0"):New({})
local WidgetImage = LibStub("LibScriptableDisplayWidgetImage-1.0")
local PluginColor = LibStub("LibScriptableDisplayPluginColor-1.0"):New({})
local _G = _G
local GameTooltip = _G.GameTooltip
local StarVisuals = _G.StarVisuals
local UIParent = _G.UIParent
local textures = {[0] = "Interface\\Addons\\StarVisuals\\Media\\black.blp", [1] = "Interface\\Addons\\StarVisuals\\Media\\white.blp"}
local environment = {}
local draw

local function copy(tbl)
	if type(tbl) ~= "table" then return tbl end
	local new = {}
	for k, v in pairs(tbl) do
		new[k] = copy(v)
	end
	return new
end

local foo = 200
local defaults = {
	profile = {
		cols = 2,
		rows = 1,
		yres = 8,
		xres = 7,
		size = 15,
		update = 500,
		images = nil
	}
}

local defaultWidgets = {
	[1] = {
		name = "Analyzer",
		prescript = [[
]],
		script = [[
self:Clear()
y_old = floor(self.height / 2);
for i = 0, self.width - 1 do
	y = (self.height / 2) + (noise[rshift(i, 1) % #noise] * (self.height / 4));
	y = floor(y)
	if (y > y_old) then
		for j = y_old, y do
			self.image[self.index].buffer[j * self.width + i] = 0xffffffff;
		end
	else
		for j = y, y_old - 1 do
			self.image[self.index].buffer[j * self.width + i] = 0xffffffff;
		end
	end
end

]],
		update = 100,
		width = 64,
		height = 64,
		pixel = 1,
		--drawLayer = "UIParent",
		enabled = true,
		points = {{"CENTER", "UIParent", "CENTER"}},
	}
}

defaults.profile.images = copy(defaultWidgets)

local options = {}
local optionsDefaults = {
	add = {
		name = "Add Image",
		desc = "Add an image widget",
		type = "input",
		set = function(info, v)
			local widget = {
				name = v,
				height = WidgetImage.defaults.height,
				width = WidgetImage.defaults.width,
				enabled = true,
				points = {{"CENTER"}},
			}
			tinsert(mod.db.profile.images, widget)
			StarVisuals:RebuildOpts()

		end,
		order = 5
	},
	defaults = {
		name = "Restore Defaults",
		desc = "Restore Defaults",
		type = "execute",
		func = function()
			mod.db.profile.images = copy(defaultWidgets);
			StarTip:RebuildOpts()
		end,
		order = 6
	},
}

function mod:OnInitialize()
	self.db = StarVisuals.db:RegisterNamespace(self:GetName(), defaults)
	StarVisuals:SetOptionsDisabled(options, true)
	
	self.core = LibCore:New(mod, environment, "StarVisuals.Images", {["StarVisuals.Images"] = {}}, nil, StarVisuals.db.profile.errorLevel)
	self.core.lcd = {LCOLS=self.db.profile.cols, LROWS=self.db.profile.rows, LAYERS=self.db.profile.layers}
	
	self.buffer = LibBuffer:New("StarVisuals.Images", self.core.lcd.LCOLS * self.core.lcd.LROWS, 0, StarVisuals.db.profile.errorLevel)
	
	if self.db.profile.update > 0 then
		self.timer = LibTimer:New("Images", 100, true, update)
	end
	
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

local function createImages()
	if type(mod.images) ~= "table" then mod.images = {} end

	for k, image in pairs(mod.db.profile.images) do
		if image.enabled then
			local image = WidgetImage:New(mod.core, "image", copy(image), image.row or 0, image.col or 0, image.layer or 0, StarVisuals.db.profile.errorLevel, draw)
			local frame = CreateFrame("Frame")
			frame:SetParent(UIParent)
			frame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				tile = true,
				tileSize = 4,
				edgeSize=4, 
				insets = { left = 0, right = 0, top = 0, bottom = 0}})
			frame:ClearAllPoints()
			frame:SetAlpha(1)
			frame:SetWidth(image.width * image.pixel)
			frame:SetHeight(image.height * image.pixel)
			frame:SetPoint("CENTER", UIParent, "CENTER")
			image.frame = frame
			image.textures = {}
			for row = 0, image.height - 1 do
			for col = 0, image.width - 1 do
			--for n = 0, image.height * image.width - 1 do
				--local row, col = PluginUtils.GetCoords(n, image.width)
				local n = row * image.width + col
				image.textures[n] = frame:CreateTexture()
				image.textures[n]:SetHeight(image.pixel)
				image.textures[n]:SetWidth(image.pixel)
				image.textures[n]:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", col * image.pixel, (row + 1) * image.pixel)
				image.textures[n]:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
				image.textures[n]:Show()
			end
			end
			frame:ClearAllPoints()
			frame:SetPoint("CENTER")
			tinsert(mod.images, image)
		end
	end
end

function mod:OnEnable()
	StarVisuals:SetOptionsDisabled(options, false)
	createImages()
	for i, v in pairs(mod.images) do
		v:Start()
	end
	if self.timer then
		self.timer:Start()
	end
	for k, image in pairs(self.images or {}) do
		image:Start()
		image.frame:Show()
	end
end

function mod:OnDisable()
	StarVisuals:SetOptionsDisabled(options, true)
	if self.timer then 
		self.timer:Stop()
	end
	for k, image in pairs(self.images or {}) do
		image:Stop()
		image.frame:Hide()
	end
end

function mod:RebuildOpts()
	local defaults = WidgetImage.defaults
	self:ClearImages()
	wipe(options)
	for k, v in pairs(optionsDefaults) do
		options[k] = v
	end
	for i, db in ipairs(self.db.profile.images) do
		options[db.name:gsub(" ", "_")] = {
			name = db.name,
			type="group",
			order = i,
			args=WidgetImage:GetOptions(db, StarVisuals.RebuildOpts, StarVisuals)
		}
		options[db.name:gsub(" ", "_")].args.delete = {
			name = "Delete",
			desc = "Delete this widget",
			type = "execute",
			func = function()
				self.db.profile.images[i] = nil
				self:ClearImages()
				StarVisuals:RebuildOpts()
			end,
			order = 13
		}
	end
end

function mod:GetOptions()
	return options
end

function mod:ClearImages()
do return end
	for k, widget in pairs(mod.images) do
		widget:Del()
	end
	wipe(mod.images)
end

function draw(widget)

	local size = 64
	widget.noise = widget.noise or LibBuffer:New("widget.noise", size, 0)
	
	for i = 0, size - 1 do
		widget.noise.buffer[i] = random(100) / 100
	end
	
	widget.environment.noise = widget.environment.noise or {}
	
	local noise = widget.noise:MovingAverageExp(0.2)
	
	for i = 0, noise:Size() - 1 do
		widget.environment.noise[i] = noise.buffer[i]
	end
			
	noise:Del()
	
	for n = 0, widget.height * widget.width - 1 do
		local color = widget.image[widget.index].buffer[n]
		widget.textures[n]:SetVertexColor(PluginColor.Color2RGBA(color, true))
	end
end
