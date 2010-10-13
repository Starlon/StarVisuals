local mod = StarVisuals:NewModule("AVS")
mod.name = "AVS"
mod.toggled = true
mod.defaultOff = true
local LibBuffer = LibStub("LibScriptableDisplayBuffer-1.0")
local LibCore = LibStub("LibScriptableDisplayCore-1.0")
local LibTimer = LibStub("LibScriptableDisplayTimer-1.0")
local PluginUtils = LibStub("LibScriptableDisplayPluginUtils-1.0"):New({})
local AVSSuperScope = LibStub("LibScriptableDisplayAVSSuperScope-1.0")
local PluginColor = LibStub("LibScriptableDisplayPluginColor-1.0"):New({})
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
				name = "Spiral",
				init = [[
n=32
]],
				frame = [[
t=t-5				
]],
				beat = [[
]],
				point = [[
d=i+v*0.2; r=t+i*PI*200; x=cos(r)*d; y=sin(r)*d				
]],
				width = 32,
				height = 32,
				pixel = 4,
				drawLayer = "UIParent",
				points = {{"CENTER", "UIParent", "CENTER", 0, -100}},
				enabled = true,
				next = 2
			},
			[2] = {
				name = "Swirlie Dots",
				init = [[
n=32;
t=random(100);
u=random(100)
]],
				frame = [[
t = t + 150; u = u + 50
]],
				beat = [[
bb = (bb or 0) + 1;
beatdiv = 16;
if bb%beatdiv == 0 then
    n = 32 + random( 30 )
end
]],
				point = [[
di = ( i - .5) * 2;
x = di;
y = cos(u*di) * .6;
x = x + ( cos(t) * .005 );
y = y + ( sin(t) * .005 );
]],
				width = 32,
				height = 32,
				pixel = 4,
				drawLayer = "UIParent",
				points = {{"CENTER", "UIParent", "CENTER", 0, 100}},
				enabled = false
			},
			[3] = { -- this doesn't seem to work. Maybe someone else will have better luck. There's a file in StarVisual's top folder that explains this.
				name = "3D",
				init = [[
n=7; r=5
mx=0;my=0;mz=0
dst=10
rx=0;ry=0;rz=0
rdx=1;rdy=1;rdz=1
p=PI;p2=15.0*p;p3=180/p
]],
				frame = [[
fr=(fr or 0)+0.01;mz=1+sin(fr)
rx=rx+rdx;ry=ry+rdy;rz=rz+rdz
xs=sin(rx/p3);ys=sin(ry/p3);zs=sin(rz/p3);xc=cos(rx/p3);yc=cos(ry/p3);zc=cos(rz/p3)
]],
				beat = [[
rdx=random(3)+1;rdy=random(3)+1;rdz=random(3)+1
]],
				point = [[
x1=r*sin(p2*i);y1=0;z1=r*cos(p2*i);
y2=y1*xc-z1*xs;z2=y1*xs+z1*xc
x2=z2*ys+x1*yc;z3=z2*yc-x1*ys
x3=x2*zc-y2*zs;y3=y2*zc+x2*zs
x4=mx+x3;y4=my+y3; z4=mz+z3
x=x4/(1+z4/dst);y=y4/(1+z4/dst)
]],
				width = 32,
				height = 32,
				pixel = 4,
				drawLayer = "UIParent",
				points = {{"CENTER", "UIParent", "CENTER", 0, -300}},
				enabled = false
			},			
		}
	}
}

function mod:OnInitialize()
	self.db = StarVisuals.db:RegisterNamespace(self:GetName(), defaults)
	StarVisuals:SetOptionsDisabled(options, true)
		
	self.timer = LibTimer:New("Images", self.db.profile.update, true, update)	
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

	mod.visdata = LibBuffer:New("Superscope visdata", 576, 0)
	for i, image in ipairs(mod.db.profile.images) do
		if image.enabled then
			local image = AVSSuperScope:New("image", copy(image), draw)
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
			for _, point in ipairs(image.config.points or {{"CENTER", "UIParent", "CENTER"}}) do
				frame:SetPoint(unpack(point))
			end
			frame:Show()
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
			image.canvas = frame
			tinsert(mod.images, image)
		end
	end
	for i, image in ipairs(mod.images) do
		image.next = mod.images[image.config.next or -1]
	end
end

function mod:OnEnable()
	StarVisuals:SetOptionsDisabled(options, false)
	createImages()
	self.timer:Start()
end

function mod:OnDisable()
	StarVisuals:SetOptionsDisabled(options, true)
	self.timer:Stop()
	for k, image in pairs(self.images) do
		image.canvas:Hide()
	end
	wipe(self.images)
end

function mod:ClearImages()
do return end
	for k, widget in pairs(mod.images) do
		widget:Del()
	end
	wipe(mod.images)
end

function update()
	for i, widget in ipairs(mod.images or {}) do
		widget.buffer:Clear()
		local fbout = {}
		for i = 0, 1024 do
			mod.visdata[i] = random(100) / 100
		end
		widget.framebuffer = widget.framebuffer or LibBuffer:New("framebuffer", widget.width * widget.height)
		widget:Render(mod.visdata, isBeat, widget.framebuffer, fbout, widget.width, widget.height)
		for n = 0, widget.height * widget.width - 1 do
			local color = widget.buffer.buffer[n]
			widget.textures[n]:SetVertexColor(PluginColor.Color2RGBA(color))
		end
	end
end
