local mod = StarVisuals:NewModule("AVS")
mod.name = "AVS"
mod.desc = "Enabling and disabling this module or its images will require a UI reload due to a bug."
mod.toggled = true
mod.defaultOff = false
local LibBuffer = LibStub("LibScriptableDisplayBuffer-1.0")
local LibCore = LibStub("LibScriptableDisplayCoreLite-1.0")
local LibTimer = LibStub("LibScriptableDisplayTimer-1.0")
local PluginUtils = LibStub("LibScriptableDisplayPluginUtils-1.0"):New({})
local AVSSuperScope = LibStub("LibScriptableDisplayAVSSuperScope-1.0")
local PluginColor = LibStub("LibScriptableDisplayPluginColor-1.0"):New({})
local PluginNoise, NoiseObj = LibStub("LibScriptableDisplayPluginNoise-1.0"):New({})
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
			StarVisuals:RebuildOpts()
		end,
		order = 7
	},
}

local foo = 200
local size = 32
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
				width = 96,
				height = 96,
				pixel = 4,
				drawLayer = "UIParent",
				points = {{"CENTER", UIParent, "CENTER", 0, 300}},
				enabled = true,
				drawMode = 1
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
				pixel = 3,
				drawLayer = "UIParent",
				points = {{"CENTER", "UIParent", "CENTER", 0, 100}},
				drawMode = 0,
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
fr = fr or 0
fr=fr+0.01;mz=1+sin(fr)
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
				enabled = false,
				drawMode = 1
			},
			[4] = { 
				name = "3D #2",
				init = [[
n=12; r=.5;  --Just for this scope, which is a simple circle with a radius of 0.5 done in 7 steps.
mx=0;my=0;mz=0; --Use these to move the center/base of your scope along the axes.
dst=2; -- Normally you don't need to change this. It's the distance for the 3D/2D-Translation.
--IMPORTANT: If you create, rotate or move a scope its z-values must not become lower 
--than -dst => !!! z >= -dst for all z !!! 
  
rx=0;ry=0;rz=0; --Initrotation around x,y and z-axis in degrees.

rdx=1;rdy=1;rdz=1; -- Permanent rotation around axes in degrees/frame. Set these to zero to stop rotation.

p=3.14159265;p2=2.0*p;p3=180/p -- You'll never need to change these

]],
				frame = [[
-- This is a good place to setup additional movement for your scope. For Example:
fr=(fr or 0)+0.01;mz=1+sin(fr) --will move the scope back and forward along the z-axis.

-- Do not change these and add your input in front of them:

rx=rx+rdx;ry=ry+rdy;rz=rz+rdz; --Rotation per Frame

xs=sin(rx/p3);ys=sin(ry/p3);zs=sin(rz/p3);xc=cos(rx/p3);yc=cos(ry/p3);zc=cos(rz/p3) -- Sinuses and cosinuses for rotation in point-section (to save space and increase performance).

]],
				beat = [[
-- Setup the beat reaction of your scope. For example change the rotation speed by random like this:				
rdx=random(3)+1;rdy=random(3)+1;rdz=random(3)+1				
]],
				point = [[
d=i+v*0.2; r=t+i*PI*200; x1=cos(r)*d; y1=sin(r)*d; z1 = 0

--This is the 3D-Scope. Add your own scopes here by setting x1,y1 and z1. 
--(Do not use x and y. They are generated in this section)

--(In fact the example is not really 3D because of y1=0, but as you see,it can be nicely rotated anyway) 

--IMPORTANT!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--The length of input in all of the sections is limited. So keep your scope as
--short as possible. If the scope suddenly dissapears after a regular input you're
--F***ed!
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

--Do not change anything else in this section:

y2=y1*xc-z1*xs;z2=y1*xs+z1*xc; --Rotation around x-axis

x2=z2*ys+x1*yc;z3=z2*yc-x1*ys; --Rotation around y-axis

x3=x2*zc-y2*zs;y3=y2*zc+x2*zs; --Rotation around z-axis

x4=mx+x3;y4=my+y3;z4=mz+z3; --Movement of center/base

x=x4/(1+z4/dst);y=y4/(1+z4/dst); --3D/2D-Translation

]],
				width = 32,
				height = 32,
				pixel = 4,
				drawLayer = "UIParent",
				points = {{"CENTER", "UIParent", "CENTER", 0, -300}},
				enabled = false,
				drawMode = 1
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
				name = "3D Scope Trick",
				init = [[
pi=acos(-1); 
sp=3; -- speed
siz=.3; -- size
vi=0; 
sn=2;
cn=3;

tx = 100
ty = 10
tz = 1
tb = 1
u = 1
count = 0
]],
				frame = [[				
n=sqrt(w*w+h*h)*pi*sn/5*siz*cn; 
ex=(ex or 0)+tx*sp;
ey=(ey or 0)+ty*sp;
ez=(ez or 0)+tz*sp; 
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
]],
				beat = [[
do return end
mx=v
my=v
mz=v
local sign = 1

if mx ~= 0 then
	if mx < 0 then
		sign = -1
	else
		sign = 1
	end
end
tx=(1-abs(mx))*sign;

sign = 1
if my ~= 0 then
	if my < 0 then
		sign = -1
	else
		sign = 1
	end
end
ty=(1-abs(my))*sign;

sign = 1
if mz ~= 0 then
	if mz < 0 then
		sign = -1
	else
		sign = 1
	end
else
	sign = 1
end
tz=(1-abs(mz))*sign;
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
red=cl*(sin(d/1.2*pi*2)/2+0.5);
green=cl*(sin(d/1.2*pi*2+pi*2/3)/2+0.5);
blue=cl*(sin(d/1.2*pi*2+pi*4/3)/2+0.5);
]],
				width = 64,
				height = 64,
				pixel = 1,
				drawLayer = "UIParent",
				points = {{"CENTER"}},
				enabled = false,
				drawMode = 1
				--next = 2
			},				
			[7] = {
				name = "Simple Example",
				init = [[
k0, k1, kx, ky, x0, y0 = 1, 1, 1, 1, 0, 0
n=k0*600; tpi=2*acos(-1);
]],
				frame = [[
]],
				beat = [[
]],
				point = [[
d=k1*v+i*tpi; x=x0+pow(cos(d),3)*kx; y=y0+pow(sin(d),3)*ky;
]],
				width = 24,
				height = 24,
				pixel = 4,
				drawLayer = "UIParent",
				points = {{"CENTER", "UIParent", "CENTER", 0, 0}},
				enabled = false,
				drawMode = 1
				--next = 2
			},	
			[8] = {
				name = "Z",
				init = [[
n=4;
halfx=10; halfy=5;
]],
				frame = [[
asp=h/w;
rlw=halfx/w;
rlh=halfy/h;
c=0;
]],
				beat = [[
]],
				point = [[
x=if2(c%2,rlw,-rlw);
y=if2(above(c,1),rlh,-rlh);
c=c+1; 
]],
				width = 24,
				height = 24,
				pixel = 4,
				drawLayer = "UIParent",
				points = {{"CENTER", "UIParent", "CENTER", 0, 0}},
				enabled = false,
				drawMode = 1
				--next = 2
			},	
			[9] = {
				name = "Starfield",
				init = [[
n = 64
zo = 0
]],
				frame = [[
r1=1/7;r2=4/9;r3=5/3;
zo=_G.GetTime()*.1;
]],
				beat = [[
--zo = zo * 1.2
]],
				point = [[
r1=r2*9333.2312311+r3*33222.93329; r1=r1-floor(r1);
r2=r3*6233.73553+r1*9423.1323219; r2=r2-floor(r2);
r3=r1*373.871324+r2*43322.4323441; r3=r3-floor(r3);
z1=r3-zo;z1=.5/(z1-floor(z1)+.2);
x=(r2*2-1)*z1;
y=(r1*2-1)*z1;
red=(1-exp(-z1*z1)) * 255; green=red; blue=red;
]],
				width = 94,
				height = 94,
				pixel = 3,
				drawLayer = "UIParent",
				points = {{"CENTER", "UIParent", "CENTER", 0, 0}},
				enabled = false,
				drawMode = 0
				--next = 2
			},	
			[10] = {
				name = "Vertical Scope",
				init = [[
n=50; t=0; tv=0.1;dt=1;
tv=((random(50.0)/50.0))*dt; 
]],
				frame = [[
t=t*0.9+tv*0.1
]],
				beat = [[
tv=((random(50.0)/50.0))*dt; dt=-dt;
]],
				point = [[
x=t+v*pow(sin(i*PI),0); y=i*2-1.0;
]],
				width = 94,
				height = 94,
				pixel = 1,
				drawLayer = "UIParent",
				points = {{"CENTER", "UIParent", "CENTER", 0, 0}},
				enabled = false,
				drawMode = 1
				--next = 2
			},	
			[11] = {
				name = "Spiral Graph",
				init = [[
n=10;t=0;
]],
				frame = [[
t=t+0.1;				
]],
				beat = [[
n=10+rand(8)
]],
				point = [[
j = 0.001
size = 0.5
r=i*PI*128+t; 
x=cos(r/j)*size+sin(r)*0.3; 
y=sin(r/j)*size+cos(r)*0.3
]],
				width = 94,
				height = 94,
				pixel = 1,
				drawLayer = "UIParent",
				points = {{"CENTER", "UIParent", "CENTER", 0, 0}},
				enabled = false,
				drawMode = 1
				--next = 2
			},	
			[12] = {
				name = "Vibrating Worm",
				init = [[
n=w; dt=0.1; t=0; sc=1000;
]],
				frame = [[
t=t+dt;
dt=0.2*dt+0.001 + 2; 
t=if2(above(t,PI*2),t-PI*2,t);
]],
				beat = [[
dt=sc;sc=-sc;
]],
				point = [[
x=cos(2*i+t)*0.9*(v*0.5+0.5); 
y=sin(i*2+t)*0.9*(v*0.5+0.5);
]],
				width = 94,
				height = 94,
				pixel = 1,
				drawLayer = "UIParent",
				points = {{"CENTER", "UIParent", "CENTER", 0, 0}},
				enabled = false,
				drawMode = 1
				--next = 2
			},	
			[13] = {
				name = "Test",
				init = [[
n = 500 ; k = 0.0; l = 0.0; m = ( rand( 10 ) + 2 ) * .5; c = 0; f = 0
]],
				frame = [[
a = (a or 0) + 0.002 ; k = k + 0.04 ; l = l + 0.03
]],
				beat = [[
bb = (bb or 0) + 1;
beatdiv = 16;
n=if2(equal(bb%beatdiv,0),380 + rand(200),n);
t=if2(equal(bb%beatdiv,0),0.0,t);
a=if2(equal(bb%beatdiv,0),0.0,a);
k=if2(equal(bb%beatdiv,0),0.0,k);
l=if2(equal(bb%beatdiv,0),0.0,l);
m=if2(equal(bb%beatdiv,0),(( rand( 100  ) + 2 ) * .1) + 2,m);
]],
				point = [[
r=(i*3.14159*2)+(a * 3.1415);
d=sin(r*m)*0.3;
x=cos(k+r)*d*2;y=(  (sin(k-r)*d) + ( sin(l*(i-.5) ) ) ) * .7;
do return end
red=abs(x);
green=abs(y);
blue=d
]],
				width = 94,
				height = 94,
				pixel = 4,
				drawLayer = "UIParent",
				points = {{"CENTER", "UIParent", "CENTER", 0, 0}},
				enabled = false,
				drawMode = 0
				--next = 2
			},	
			
		},
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

local MAXRECORDS = 32

function update()
	for i, widget in pairs(mod.images or {}) do
		widget.buffer:Clear()
		local visdata, isBeat, maxhit = PluginNoise.UnitNoise(widget.unit or "player")
		
		local fbout = {}
		local total = 0
		for i = 0, MAXRECORDS - 1 do
			total = total + visdata.buffer[i]
		end
		--widget.framebuffer = widget.framebuffer or LibBuffer:New("framebuffer", widget.width * widget.height)
		widget:Render(visdata.buffer, isBeat, widget.framebuffer, fbout, widget.width, widget.height)
		for row = 0, widget.height - 1 do
		for col = 0, widget.width - 1 do
		--for n = 0, widget.height * widget.width - 1 do
			local n = row * widget.width + col
			local n2 = (widget.height - row - 1) * widget.width + col
			local color = widget.buffer.buffer[n]
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
	if self:IsEnabled() then
		self:ResetImages()
	end
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
