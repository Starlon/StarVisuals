StarVisuals = LibStub("AceAddon-3.0"):NewAddon("StarVisuals: @project-version@", "AceConsole-3.0", "AceHook-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceComm-3.0", "AceSerializer-3.0") 

local LibDBIcon = LibStub("LibDBIcon-1.0")
local LSM = _G.LibStub("LibSharedMedia-3.0")
local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("StarVisuals")
StarVisuals.L = L

local LibCore = LibStub("LibScriptableDisplayCore-1.0")
local LibTimer = LibStub("LibScriptableDisplayTimer-1.0")
local PluginTalents = LibStub("LibScriptableDisplayPluginTalents-1.0")
local WidgetTimer = LibStub("LibScriptableDisplayWidgetTimer-1.0")

local _G = _G
local GameTooltip = _G.GameTooltip
local ipairs, pairs = _G.ipairs, _G.pairs
local timers = {}
local widgets = {}

local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("StarVisuals", {
	type = "data source",
	text = "StarVisuals",
	icon = "Interface\\Icons\\INV_Chest_Cloth_17",
	OnClick = function() StarVisuals:OpenConfig() end
})

StarVisuals.anchors = {
	"CURSOR_TOP",
	"CURSOR_TOPRIGHT",
	"CURSOR_TOPLEFT",
	"CURSOR_BOTTOM",
	"CURSOR_BOTTOMRIGHT",
	"CURSOR_BOTTOMLEFT",
	"CURSOR_LEFT",
	"CURSOR_RIGHT",
	"TOP",
	"TOPRIGHT",
	"TOPLEFT",
	"BOTTOM",
	"BOTTOMRIGHT",
	"BOTTOMLEFT",
	"RIGHT",
	"LEFT",
	"CENTER"
}

StarVisuals.anchorText = {
	"Cursor Top",
	"Cursor Top-right",
	"Cursor Top-left",
	"Cursor Bottom",
	"Cursor Bottom-right",
	"Cursor Bottom-left",
	"Cursor Left",
	"Cursor Right",
	"Screen Top",
	"Screen Top-right",
	"Screen Top-left",
	"Screen Bottom",
	"Screen Bottom-right",
	"Screen Bottom-left",
	"Screen Right",
	"Screen Left",
	"Screen Center"
}

StarVisuals.opposites = {
	TOP = "BOTTOM",
	TOPRIGHT = "BOTTOMLEFT",
	TOPLEFT = "BOTTOMRIGHT",
	BOTTOM = "TOP",
	BOTTOMRIGHT = "TOPLEFT",
	BOTTOMLEFT = "TOPRIGHT",
	LEFT = "RIGHT",
	RIGHT = "LEFT",
}


local defaults = {
	profile = {
		modules = {},
		timers = {},
		minimap = {hide=true},
		modifier = 1,
		unitShow = 1,
		objectShow = 1,
		unitFrameShow = 1,
		otherFrameShow = 1,
		errorLevel = 2,
		throttleVal = 0,
		intersectRate = 200
	}
}
			

local options = {
	type = "group",
	args = {
		modules = {
			name = L["Modules"],
			desc = L["Modules"],
			type = "group",
			args = {}
		},
		settings = {
			name = L["Settings"],
			desc = L["Settings"],
			type = "group",
			args = {
				errorLevel = {
					name = L["Error Level"],
					desc = L["StarVisuals's error level"],
					type = "select",
					values = LibStub("LibScriptableDisplayError-1.0").defaultTexts,
					get = function() return StarVisuals.db.profile.errorLevel end,
					set = function(info, v) StarVisuals.db.profile.errorLevel = v; StarVisuals:Print("Note that changing error verbosity requires a UI reload.") end,
					order = 11
				},
			}
		}
	}
}

local environment = {}
StarVisuals.environment = environment

local function errorhandler(err)
    return geterrorhandler()(err)
end

local function copy(tbl)
	local localCopy = {}
	for k, v in pairs(tbl) do
		if type(v) == "table" then
			localCopy[k] = copy(v)
		elseif type(v) ~= "function" then
			localCopy[k] = v
		end
	end
	return localCopy
end

StarVisuals:SetDefaultModuleState(false)

function StarVisuals:RefreshConfig()
	for k, v in self:IterateModules() do
		if v.ReInit then
			v:ReInit()
		end
	end
	self:RebuildOpts()
	self:Print(L["You may need to reload your UI."])
end

local menuoptions = {
	name = "StarVisuals",
	type = "group",
	args = {
		open = {
			name = "Open Configuration",
			type = "execute",
			func = function() StarVisuals:OpenConfig() end
		}
	}
}
function StarVisuals:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("StarVisualsDB", defaults, "Default")
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
	
	LibStub("AceConfig-3.0"):RegisterOptionsTable("StarVisuals-Addon", options)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("StarVisuals", menuoptions)
	AceConfigDialog:SetDefaultSize("StarVisuals-Addon", 800, 450)
	self:RegisterChatCommand("starvisuals", "OpenConfig")
	AceConfigDialog:AddToBlizOptions("StarVisuals")
	LibDBIcon:Register("StarVisualsLDB", LDB, self.db.profile.minimap)

	if not options.args.Profiles then
 		options.args.Profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
		self.lastConfig = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("StarVisuals-Addon", "Profiles", "StarVisuals-Addon", "Profiles")
	end
		
	self.core = LibCore:New(StarVisuals, environment, "StarVisuals", {["StarVisuals"] = {}}, "text", self.db.profile.errorLevel)		
end

function StarVisuals:OnEnable()
	if self.db.profile.minimap.hide then
		LibDBIcon:Hide("StarVisualsLDB")
	else
		LibDBIcon:Show("StarVisualsLDB")
	end
	
	for k,v in self:IterateModules() do
		if (self.db.profile.modules[k]  == nil and not v.defaultOff) or self.db.profile.modules[k] then
			v:Enable()
		end
	end
	
	local plugin = {}
	LibStub("LibScriptableDisplayPluginColor-1.0"):New(plugin)
	ChatFrame1:AddMessage(plugin.Colorize(L["Welcome to "] .. StarVisuals.name, 0, 1, 1) .. plugin.Colorize(L[" Type /starvisuals to open config. Alternatively you could press escape and choose the addons menu. Or you can choose to show a minimap icon."], 1, 1, 0))
end

function StarVisuals:OnDisable()
	for k,v in self:IterateModules() do
		if (self.db.profile.modules[k]  == nil and not v.defaultOff) or self.db.profile.modules[k] then
			v:Disable()
		end
	end
end

function StarVisuals:RebuildOpts()
	for k, v in self:IterateModules() do
		local t = {}
		if type(v.RebuildOpts) == "function" then v:RebuildOpts() end
		options.args.modules.args[v:GetName()] = {
			name = v.name,
			type = "group",
			args = nil
		}

		if v.GetOptions then
			t = v:GetOptions()
			t.optionsHeader = {
				name = L["Settings"],
				type = "header",
				order = 3
			}
			if v.childGroup then
				options.args.modules.args[v:GetName()].childGroups = "tab"
			end
		else
			t = {}
		end

		if v.toggled then
			t.header = {
				name = v.name,
				type = "header",
				order = 1
			}
			t.toggle = {
				name = L["Enable"],
				desc = L["Enable or disable this module"],
				type = "toggle",
				set = function(info,v)
					self.db.profile.modules[k] = v
					if v then
						self:EnableModule(k)
					else
						self:DisableModule(k)
					end
				end,
				get = function() return (self.db.profile.modules[k]  == nil and not v.defaultOff) or self.db.profile.modules[k] end,
				order = 2
			}
		end
		options.args.modules.args[v:GetName()].args = t
	end
end

function StarVisuals:OpenConfig()
	self:RebuildOpts()
	AceConfigDialog:Open("StarVisuals-Addon")	
end


function StarVisuals:GetLSMIndexByName(category, name)
	for i, v in ipairs(LSM:List(category)) do
		if v == name then
			return i
		end
	end
end

function StarVisuals:SetOptionsDisabled(t, bool)
	for k, v in pairs(t) do
		if not v.args then
			if k ~= "toggle" then v.disabled = bool end
		else
			self:SetOptionsDisabled(v.args, bool)
		end
	end
end

