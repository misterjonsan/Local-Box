EFFECT.beam=Material("cable/xbeam")

function EFFECT:Init(data)
    self.life=0
    
    local origin=data:GetOrigin()
    local startPos=data:GetStart()
    local flags = data:GetFlags() or 0
    local silent = (bit and bit.band(flags, 1) ~= 0) or flags == 1
    self.points={startPos}
	self.strands={}
	
    local dist=startPos:Distance(origin)
	local segments=math.max(math.floor(dist/100),1)
	local length=dist/segments
    local dir=(startPos-origin):GetNormalized()*length
	
	local rand=Vector(0,0,0)
	local lastPoint=self.points[1]
	for k=1,segments-1 do
		rand:Random(-100,100)
		local p=math.min(math.abs(k-segments)/12,1)--math.abs((k-segments)/segments)
        local point=startPos-dir*k-rand*p
		table.insert(self.points,point)
		
		if math.Rand(0,1)>.7 then
			table.insert(self.strands,{point,point-(lastPoint-point):GetNormalized()*200*p,p})
		end
		
		lastPoint=point
	end
    table.insert(self.points,origin)
	
    local far=math.min(1,origin:DistToSqr(EyePos())/33333333)
    if not silent then
        timer.Simple(far/2,function()
            EmitSound("ambient/explosions/explode_9.wav",origin,1,CHAN_AUTO,1-far*.9,140)
        end)
    end
	
    util.ScreenShake(origin,5,40,.4,1000,true)
	
    for k,p in pairs({startPos,origin}) do
		local d=dir*(k>1 and -1 or 1)
		local trace=util.QuickTrace(p,d)
        if trace.Hit and !trace.HitSky then
            util.Decal("Scorch",trace.HitPos+trace.HitNormal,trace.HitPos-trace.HitNormal)
            if not silent then
                local effect=EffectData()
                effect:SetOrigin(trace.HitPos)
                effect:SetNormal(trace.HitNormal)
                util.Effect("cball_explode",effect,true,true)
            end
        end
	
		local dlight=DynamicLight(self:EntIndex()+k)
		if dlight then
			dlight.pos=p
			dlight.r=255
			dlight.g=255
			dlight.b=255
			dlight.brightness=2
			dlight.decay=1000
			dlight.size=256
			dlight.dietime=CurTime()+1
		end
	end
	
    self:SetRenderBoundsWS(startPos,origin)
end

function EFFECT:Think()
	self.life=self.life+FrameTime()
	
	cam.Start3D()
	self:Render()
	cam.End3D()
	
	return self.life<.2
end

function EFFECT:Render()
	local width=math.min(.3-self.life*1.5,.2)*80
	
	render.SetMaterial(self.beam)
	for k=1,#self.points-1 do
		render.DrawBeam(self.points[k],self.points[k+1],width*math.max(k/#self.points-1,.5),0,2)
	end
	
	for _,s in pairs(self.strands) do
		render.DrawBeam(s[1],s[2],width*s[3],0,2)
	end
end
