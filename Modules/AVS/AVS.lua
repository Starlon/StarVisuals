local mod = StarVisuals:NewModule("AVS")
mod.name = "AVS"
mod.toggled = true
mod.defaultOff = true
local LibBuffer = LibStub("LibScriptableDisplayBuffer-1.0")
local LibCore = LibStub("LibScriptableDisplayCoreLite-1.0")
local LibTimer = LibStub("LibScriptableDisplayTimer-1.0")
local PluginUtils = LibStub("LibScriptableDisplayPluginUtils-1.0"):New({})
local AVSSuperScope = LibStub("LibScriptableDisplayAVSSuperScope-1.0")
local PluginColor = LibStub("LibScriptableDisplayPluginColor-1.0"):New({})
local _G = _G
local GameTooltip = _G.GameTooltip
local StarVisuals = _G.StarVisuals
local UIParent = _G.UIParent
local textures = {[0] = "Interface\\Addons\\StarVisuals\\Media\\black.blp", [1] = "Interface\\Addons\\StarVisuals\\Media\\white.blp"}
local environment = {_G=_G, coroutine=coroutine}
local update

local options = {}
local optionsDefaults = {
	add = {
		name = "Add Image",
		desc = "Add an image widget",
		type = "input",
		set = function(info, v)
			local widget = {
				name = v,
				height = AVSSuperScope.defaults.height,
				width = AVSSuperScope.defaults.width,
				enabled = true,
				points = {{"CENTER"}},
				parent = "UIParent"
			}
			tinsert(mod.db.profile.images, widget)
			StarVisuals:RebuildOpts()
		end,
		order = 5
	},
	reset = {
		name = "Reset Images",
		desc = "Restart images. Use this after enabling or disabling images.",
		type = "execute",
		func = function()
			mod:ResetImages()
		end,
		order = 6
	},
	defaults = {
		name = "Restore Defaults",
		desc = "Restore Defaults",
		type = "execute",
		func = function()
			mod.db.profile.images = {}
			StarTip:RebuildOpts()
		end,
		order = 7
	},
}

local foo = 200
local size = 96
local defaults = {
	profile = {
		update = 100,
		images = {
			[1] = {
				name = "Spiral",
				init = [[
n=64
]],
				frame = [[
t=t-5
]],
				beat = [[
]],
				point = [[
d=i+v*0.2; r=t+i*PI*200; x=cos(r)*d; y=sin(r)*d
]],
				width = size,
				height = size,
				pixel = 4,
				drawLayer = "UIParent",
				points = {{"CENTER", "UIParent", "CENTER", 0, 50}},
				enabled = false,
				--next = 2
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
				width = size,
				height = size,
				pixel = 1,
				drawLayer = "UIParent",
				points = {{"CENTER", "UIParent", "CENTER", 0, 100}},
				enabled = false
			},
			[3] = { 
				name = "3D",
				init = [[
-- this doesn't seem to work. Maybe someone else will have better luck. There's a file in StarVisual's top folder that explains this.				
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
			[4] = { 
				name = "3D #2",
				init = [[
rx=random(100)/1000-0.05; ry=random(100)/1000-0.05; rz=random(100)/1000-0.05; 				
zs=sqrt(3)				
]],
				frame = [[
rx=rx+drx; ry=ry+dry; rz=rz+drz; cx=cos(x); sx=sin(x); cy=cos(y); sy=sin(y); cz=cos(z); sz=sin(z);				
]],
				beat = [[
rx=random(100)/1000-0.05; ry=random(100)/1000-0.05; rz=random(100)/1000-0.05; 				
]],
				point = [[
x2=x1*sz+y1*cz; y2=x1*cz-y1*sz;
x3=x2*sy+z1*cy; z2=x2*cy-z1*sy;
y3=y2*sx+z2*cx; z3=1/(y2*cx-z2*sx+zs);
x=x3*z3; y=y3*z3;				
]],
				width = 32,
				height = 32,
				pixel = 4,
				drawLayer = "UIParent",
				points = {{"CENTER", "UIParent", "CENTER", 0, -300}},
				enabled = false
			},
			[5] = {
				name = "Gradient",
				init = [[
n=100
]],
				frame = [[
]],
				beat = [[
]],
				point = [[
x=i*2-1 ;
y=0 ;
col=i * 255 ;
blue=col ; red=col ; green=col
]],
				width = 24,
				height = 24,
				pixel = 4,
				drawLayer = "UIParent",
				points = {{"CENTER", "UIParent", "CENTER", 0, -300}},
				enabled = false,
				--next = 2
			},	
			[6] = {
				name = "Scope Trick",
				init = [[
pi=acos(-1); sp=0.1;siz=0.7;vi=0; sn=25;cn=6;
tx = 0
ty = 0
tz = 0
ex = 0
ey = 0
ez = 0
tb = 2
u = 1
count = 0
]],
				frame = [[				
n=sqrt(w*w+h*h)*pi*sn/30*siz*cn; 
ex=ex+tx*sp;
ey=ey+ty*sp;
ez=ez+tz*sp; 
if vi == 0 then
	kx=sin(ex)*pi/8
	ky=sin(ey)*pi/8
	kz=ez
else
    kx=-pi/2+sin(ex)*pi/8;
    ky=ey;
    kz=sin(ez)*pi/8; 
end
sx=sin(kx);
sy=sin(ky);
sz=sin(kz); 
cx=cos(kx);
cy=cos(ky);
cz=cos(kz);
count = count + 1
if count % random(20) == 0 then
    tx = 0
    ty = 0
    tz = 0
    ex = 0
    ey = 0
    ez = 0
    tb = 2
    u = 1
end
]],
				beat = [[
tx = random(w)
ty = random(h)
tz = random(100)
ex = random(w)
ey = random(h)
ez = random(100)
tb = tb + 2
u = u + 1
count = 0
]],
				point = [[
r=i*pi*2*sn;
d=((i*sn)%sn+1)/sn*1.2;
if tb == 2 then
	u = 1-u
else
	u = tb
end
x1=sin(r)*d*siz;
y1=cos(r)*d*siz;
--z1=(1-getspec(d,0.5/sn,0))*siz*(u*2-1);
z1=(1-v)*siz*(u*2-1);
y2=y1*cx-z1*sx;
z2=y1*sx+z1*cx; 
x2=z2*sy+x1*cy;
z3=z2*cy-x1*sy; 
x3=x2*cz-y2*sz;
y3=y2*cz+x2*sz; 
x=x3/(1+z3/3);
y=y3/(1+z3/3);
cl=sqrt(2)/4*3-z3; 
red=cl*(sin(d/1.2*pi*2)/2+0.5) * 255;
green=cl*(sin(d/1.2*pi*2+pi*2/3)/2+0.5) * 255;
blue=cl*(sin(d/1.2*pi*2+pi*4/3)/2+0.5) * 255;
]],
				width = 16,
				height = 16,
				pixel = 8,
				drawLayer = "UIParent",
				points = {{"CENTER", "UIParent", "CENTER", 0, -300}},
				enabled = true,
				--next = 2
			},				
		}
	}
}

function mod:OnInitialize()
	self.db = StarVisuals.db:RegisterNamespace(self:GetName(), defaults)
	StarVisuals:SetOptionsDisabled(options, true)

	self.timer = LibTimer:New("Images", self.db.profile.update, true, update)
	self.images = {}
	
	self.core = LibCore:New(self, environment, "StarVisuals.AVS", {}, nil, errorLevel)
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
	for i, imagedb in ipairs(mod.db.profile.images) do
		if imagedb.enabled then
			local image = AVSSuperScope:New(imagedb.name or "avs", copy(imagedb), draw)
			image.framebuffer = LibBuffer:New("framebuffer", image.width * image.height)
			local frame = CreateFrame("Frame")
			frame:SetParent(UIParent)
			frame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				tile = true,
				tileSize = 1,
				edgeSize=1,
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
			mod.images[imagedb] = image
		end
	end
	for i, image in pairs(mod.images) do
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
	for k, image in pairs(self.images or {}) do
		image.canvas:Hide()
	end
	wipe(self.images)
end

function mod:CreateImages()
	createImages()
end

function mod:ClearImages()
	for k, widget in pairs(mod.images or {}) do
		widget:Del()
		widget.canvas:Hide()
	end
	wipe(mod.images or {})
end

function mod:ResetImages()
	self:ClearImages()
	self:CreateImages()
end

function update()
	for i, widget in pairs(mod.images or {}) do
		widget.buffer:Clear()
		local fbout = {}
		local total = 0
		for i = 0, 1024 do
			mod.visdata[i] = random(100) / 100
			total = total + mod.visdata[i]
		end
		local isBeat
		if total * 100 / 1024 * 10 > 520 then
			isBeat = true
		end
		--widget.framebuffer = widget.framebuffer or LibBuffer:New("framebuffer", widget.width * widget.height)
		widget:Render(mod.visdata, isBeat, widget.framebuffer, fbout, widget.width, widget.height)
		for row = 0, widget.height - 1 do
		for col = 0, widget.width - 1 do
		--for n = 0, widget.height * widget.width - 1 do
			local n = row * widget.width + col
			local n2 = (widget.height - row - 1) * widget.width + col
			local color = widget.buffer.buffer[n]
			local test = widget.textures[n2]
			if not test then
				StarTip:Print(n, n2, "test")
			end
			widget.textures[n2]:SetVertexColor(PluginColor.Color2RGBA(color))
		--end
		end
		end
	end
end

function mod:GetOptions()
	return options
end

function mod:RebuildOpts()
	local defaults = AVSSuperScope.defaults
	self:ResetImages()
	wipe(options)
	for k, v in pairs(optionsDefaults) do
		options[k] = v
	end
	for i, db in ipairs(self.db.profile.images) do
		options[db.name:gsub(" ", "_")] = {
			name = db.name,
			type="group",
			order = i,
			args=AVSSuperScope:GetOptions(db, StarVisuals.RebuildOpts, StarVisuals)
		}
		options[db.name:gsub(" ", "_")].args.delete = {
			name = "Delete",
			desc = "Delete this widget",
			type = "execute",
			func = function()
				self.db.profile.images[i] = nil
				self:ResetImages()
				StarVisuals:RebuildOpts()
			end,
			order = 13
		}
	end
end
