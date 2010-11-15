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
n=32
]],
				frame = [[
t=t-5
]],
				beat = [[
]],
				point = [[
d=i+v*0.2; r=t+i*PI*200; x=cos(r)*d*.8; y=sin(r)*d*.8
]],
				width = 88,
				height = 88,
				pixel = 1,
				drawLayer = "UIParent",
				points = {{"CENTER", "UIParent", "CENTER", 0, 255}},
				enabled = true,
				drawMode = 1,
				unit = "local"
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
				points = {{"CENTER", "UIParent", "CENTER", 0, 0}},
				enabled = false,
				drawMode = 1
			},
			[4] = { 
				name = "3D #2",
				init = [[
--if you can figure this out, more power to you
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
				points = {{"CENTER", "UIParent", "CENTER", 0, 0}},
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
				points = {{"CENTER", "UIParent", "CENTER", 0, 0}},
				enabled = false,
				--next = 2
			},	
			[6] = {
				name = "Scope Trick",
				init = [[
pi=acos(-1); 
sp=10; -- speed
siz=.5; -- size
vi=0; 
sn=10
tb = 1

cn=0.05;
tx = 100
ty = 100
tz = 50
u = 1
count = 0
]],
				frame = [[				
n=sqrt(w*w+h*h)*pi*sn*siz/8*(1+equal(tb,2)); 
ex=(ex or 0)+tx*sp;ey=(ey or 0)+ty*sp;ez=(ez or 0)+tz*sp; 
kx=if2(vi,sin(ex)*pi/8,-pi/2+sin(ex)*pi/8);
ky=if2(vi,sin(ey)*pi/8,ey);
kz=if2(vi,ez,sin(ez)*pi/8); 
sx=sin(kx);
sy=sin(ky);
sz=sin(kz); 
cx=cos(kx);
cy=cos(ky);
cz=cos(kz);
]],
				beat = [[
mx=v
my=(random(100) - 50) / 50
mz=(random(100) - 50) / 50
tx=(1-abs(mx))*if2(mx,sign(mx),1);ty=(1-abs(my))*if2(my,sign(my),1);tz=(1-abs(mz))*if2(mz,sign(mz),1); 
]],
				point = [[
r=i*pi*2*sn;d=((i*sn)%sn+1)/sn*1.2;u=if2(equal(tb,2),1-u,tb);
x1=sin(r)*d*siz;y1=cos(r)*d*siz;z1=(1-v)*siz*(u*2-1);
y2=y1*cx-z1*sx;z2=y1*sx+z1*cx; x2=z2*sy+x1*cy;z3=z2*cy-x1*sy; x3=x2*cz-y2*sz;y3=y2*cz+x2*sz; x=x3/(1+z3/3);y=y3/(1+z3/3);
cl=sqrt(2)/4*3-z3; red=cl*(sin(d/1.2*pi*2)/2+0.5);green=cl*(sin(d/1.2*pi*2+pi*2/3)/2+0.5);blue=cl*(sin(d/1.2*pi*2+pi*4/3)/2+0.5);
]],
				width = 94,
				height = 84,
				pixel = 3,
				drawLayer = "UIParent",
				points = {{"CENTER"}},
				enabled = false,
				drawMode = 0
				--next = 2
			},				
			[7] = {
				name = "3d Fearn",
				init = [[
n=1000; zs=sqrt(2); izs=5.893/2; iys=1.385/2
zt = 50; yt = 25; xt = rand(100)
]],
				frame = [[
rx1=0; ry1=0; rz1=0; rx2=0; ry2=0; zt=zt+izt; yt=yt+iyt; xt=xt+ixt; cz=cos(zt); sz=sin(zt); cy=cos(yt); sy=sin(yt); cx=cos(xt); sx=sin(xt);
red = 15 / 255; green = 63 / 255; blue = 31 / 255
xt = xt + 10
]],
				beat = [[
local val = 20.05
izt=rand(100)/1000-val; iyt=rand(100)/1000-val; ixt=rand(100)/1000-val;
]],
				point = [[
random=rand(100);
t1=if2(equal(random,0),0,t1);
t1=if2(below(random,86)*above(random,0),1,t1);
t1=if2(below(random,93)*above(random,86),2,t1);
t1=if2(below(random,99)*above(random,92),3,t1);
rx2=rx1; ry2=ry1;
rx1=if2(equal(t1,0),0,rx1);
ry1=if2(equal(t1,0),ry1*0.18,ry1);
rz1=if2(equal(t1,0),0,rz1);
rx2=rx1; ry2=ry1;
rx1=if2(equal(t1,1),rx1*0.85,rx1);
ry1=if2(equal(t1,1),ry1*0.85+rz1*0.1+1.6,ry1);
rz1=if2(equal(t1,1),ry2*-0.1+rz1*0.85,rz1);
rx2=rx1; ry2=ry1;
rx1=if2(equal(t1,2),rx1*0.2+ry1*-0.2,rx1);
ry1=if2(equal(t1,2),rx2*0.2+ry1*0.2+0.8,ry1);
rz1=if2(equal(t1,2),rz1*0.3,rz1);
rx2=rx1; ry2=ry1;
rx1=if2(equal(t1,3),rx1*-0.2+ry1*0.2,rx1);
ry1=if2(equal(t1,3),rx2*0.2+ry1*0.2+0.8,ry1);
rz1=if2(equal(t1,3),rz1*0.3,rz1);
x1=rx1; y1=ry1; z1=rz1;
x2=x1*cz+y1*sz; y2=x1*sz-y1*cz;
x3=x2*cy+z1*sy; z2=x2*sy-z1*cy;
y3=y2*cx+z2*sx; z3=y2*sx-z2*cx+10;
x=x3/z3; y=y3/z3;
x = x / 1.5; y = y / 1.5;
]],
				width = 94,
				height = 94,
				pixel = 2,
				drawLayer = "UIParent",
				points = {{"CENTER", "UIParent", "CENTER", 0, 0}},
				enabled = false,
				drawMode = 0,
				line_blend_mode=2
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
n=32; t=0; tv=0.1;dt=1;
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
x = x - .6
]],
				width = 94,
				height = 94,
				pixel = 1,
				drawLayer = "UIParent",
				points = {{"CENTER", "UIParent", "CENTER", 0, 255}},
				enabled = false,
				drawMode = 1,
				unit = "local"
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
	PluginNoise.StartNoise()
end

function mod:OnDisable()
	StarVisuals:SetOptionsDisabled(options, true)
	self.timer:Stop()
	for k, image in pairs(self.images or {}) do
		image.canvas:Hide()
	end
	wipe(self.images)
	PluginNoise.StopNoise()
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
		local visdata, isBeat = PluginNoise.UnitNoise(widget.config.unit or "local")

		local fbout = {}
		local total = 0
		
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
