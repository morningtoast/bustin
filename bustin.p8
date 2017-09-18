pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
--bustin'
--brian vaughn, 2017


-- follow @morningtoast
-- please check out my other Pico-8 games online or on the PocketCHIP:
-- https://www.lexaloffle.com/bbs/?uid=12806&mode=carts
--
-- Bullet Cave
-- Bunyan's Rage
-- Bustin'
-- BuzzKill
-- Invader Overload
-- Mass 360

-- History
-- 1.0 - Initial release (9/17/2017)

version="1.0"
musicon=true
lanes={3,32,61,90}
unlocked=0
charmode=0 --0=girls,1=boys
p_t=0
p_char="holtz"

--#player
function p_update()
    muzzle_x=p_x+16
    muzzle_y=p_y+12
    
    beam_len=muzzle_x+fire_w --x of end of beam

	firing=false
    p_canmove=true
	p_canfire=true

	if p_slimed then p_canmove=false p_canfire=false end
	
	local vert=1

	-- player becomes unslimed
	if p_slimed and p_t>45 then -- time player is disabled by slime
		p_slimed=false
		p_canfire=true
		p_invincible=1
	end
		
	
	
	if btnz then
        firing=true
        p_canmove=false
        fire_speed=8
		
		
        if p_canfire then
			p_power=min(p_power+1.6,100) --speed of overheating
			if p_power>=100 then
				
				--if p_power==100 then sfx(3) end
				
				p_canfire=false
				firing=false 
				fire_w=0
			end
			
            for s in all(slimers) do
                if s.lane==p_lane and s.st!=1 then
                    fire_speed=0
                end
            end
			
			for p in all(portals) do
				if beam_len>=p.x and p.lane==p_lane then 
					p.hit=true 
					fire_speed=0
				end
			end

            
            fire_w+=fire_speed
			if fire_w>110 then fire_w=110 end
            fire_t+=1
        else
            fire_w=0
            fire_t=0
        end
    else
		p_power=max(p_power-3,0) --speed of reducing overheat
		fire_w=0
    end
	
	if btnxp then
		if trap_st<=0 then
			trap_create(p_lane)
		end
	end
	
	--switching lanes up/down
	if (btndp or btnup) and p_canmove then
		if btndp then vert=1 end
		if btnup then vert=-1 end
		
		p_power=0
		p_lane+=1*vert
		if p_lane>#lanes then p_lane=#lanes end
		if p_lane<1 then p_lane=1 end
	end

	p_y=lanes[p_lane]
	
	p_t+=1
end

function p_draw()
	if firing then
		draw_sine(rnd(.2)+.05, fire_t*-3, {muzzle_x,muzzle_y-rnd(5)}, {muzzle_x+fire_w,muzzle_y+rnd(4)}, 11,1)
		draw_sine(rnd(.25)+.05, fire_t*-4, {muzzle_x,muzzle_y-rnd(4)}, {muzzle_x+fire_w,muzzle_y+rnd(3)}, 10,1)
		draw_sine(rnd(.3)+.05, fire_t*-2, {muzzle_x,muzzle_y-rnd(4)}, {muzzle_x+fire_w,muzzle_y+rnd(3)}, 12,1)
	end
	
	if p_invincible<1 then
		draw_char(p_char, p_x,p_y)
	else
		if is_even(p_invincible) then
			draw_char(p_char, p_x,p_y)
		end
		
		p_invincible+=1
		
		if p_invincible>50 then p_invincible=0 end -- time when invicinbiility wears off
	end
	
	-- overheated, draw smoke
	if p_power>=100 then
		expl_create(muzzle_x+2,muzzle_y, 1, {
			dur=18, --30
			decay=-.2,
			den=1, --0
			colors={5,6,1,0},
			smin=.2, --1
			smax=.5, --1
			grav=-.2, --.3
			dir=.25, --0 (all directions)
			range=.05
			
		})
	end
	
	if p_slimed then
		palt(14,true)
		spr(53,p_x,p_y,2,2)
		palt()
	end
	
end

--player sprite
function draw_char(id,x,y)
	palt(0,false)
	palt(14,true)
	
	spr(5,x,y,2,3)
	if id=="holtz" then spr(151,x+1,y+1,2,2) end --holtz
	if id=="abby" then spr(153,x,y,2,2) end --abby
	if id=="erin" then spr(183,x+1,y+1,2,2) end --erin
	if id=="patty" then spr(185,x+2,y+1,2,2) end --patty

	-- boys
	if id=="peter" then spr(155,x+1,y+1,2,2) end --peter
	if id=="ray" then spr(187,x+2,y+1,2,2) end --ray
	if id=="winston" then spr(189,x+3,y+1,2,2) end --zed
	if id=="egon" then spr(157,x+3,y,2,2) end --egon
	
	pal()
end



--#slimers
slimers={}

function slimer_create(lane)
	local from_portal=get_portal(lane)
    
    local obj={
		x=from_portal.x,
		y=lanes[lane]+2,
		lane=lane,
		ang=0,
		speed=level.slimer_speed,
		hp=level.slimer_hp,
		hit=false,
		st=1,
		shrink=0
	}

	add(slimers, obj)
end

function slimer_update()
	for s in all(slimers) do
		if s.st!=3 then
			if beam_len>=s.x and s.lane==p_lane and firing and s.x>muzzle_x then 
				s.st=2
			else
				s.st=1
			end
		end
		
		-- normal moving
		if s.st==1 then
			--check if hit by beam
			s.x-=s.speed
			s.ang+=0.03 --distance between crests
			s.y+=sin(s.ang)*.25 --height of wave

			--caught in trap
			if s.lane==trap_lane and s.x<=trap_x+8 and s.x>= trap_x and trap_st==3 then
				s.st=3
			end

			-- slime player
			if s.lane==p_lane and s.x<muzzle_x-8 and s.x>0 and p_invincible<1 then
				if not p_slimed then sfx(4) end
				p_slimed=true
				p_t=0
				
				
			end

			-- slimer makes it off screen
			if s.x<-16 then
				p_slime=min(p_slime+5,100) -- add to slime meter but not to kill count
				del(slimers,s)
			end
		end
		
		
		--hit by beam
		if s.st==2 then
			s.x+=1
			s.hp-=1
			if s.hp<=0 then
                expl_create(s.x+8,s.y+8, 24, {
                    dur=18,
                    den=4,
                    colors={11,3,10},
                    smin=1,
                    smax=4,
                    grav=1,
                })
				slimer_kill(s)
			end
		end

		--trapped
		if s.st==3 then
			s.shrink+=1.5
			if s.shrink>=14 then
				slimer_kill(s)
			end
		end

	end
end

	
function slimer_draw()
	for s in all(slimers) do
		palt(0,false)
		palt(14,true)

		if s.st==2 then --hit by beam, turn red
			pal(11,8)
			pal(3,2)
			pal(10,9)
		end

		if s.st<3 then
			sspr(56,0,16,24, s.x,s.y, 14,18)
		else
			sspr(56,0,16,24, s.x,s.y, 14-s.shrink,18-s.shrink)
			s.y+=1
		end
		
		pal()	
	end	
end

function slimer_kill(obj)
	-- @sound ghost kill
	sfx(0)
	kills+=1	
	del(slimers,obj)
end




--#portals
--portal_hp=100
portal_explodes={}

function get_portal(lane)
    local pick={}
    for p in all(portals) do
        if p.lane==lane then pick=p end
    end
    return pick
end

function portal_reset()
	portals={}
	for n=1,4 do 
		portal_create(n,level.portal_offset[n]) 
	end
	
	last_portal=0
	portal_spawn=random(15,level.portal_spawn)
	timer_set("portalspawn")
end

function portal_create(lane,xoffset)
    add(portals,{
		x=110-xoffset,
		y=lanes[lane]+10,
		r=5,
		lane=lane,
		hp=level.portal_hp,
		hit=false,t=0,
		jump=false,
		isjumping=false,
		ang=0,
		jt=0
	})
end


function portal_update()
	
    for p in all(portals) do
        if p.hit then 
            p.hp-=1
            
            if p.hp<=0 and p.r>0 then
				p.r-=1
				shake=1
				
				sfx(1)
				
				--portal is dead
                if p.r<=0 then
					-- @sound portal dead
                    expl_create(p.x,p.y, 48,{
                        dur=40,
                        den=5,
                        colors={8,7,10,9,12},
                        smin=3,
                        smax=6,
                        grav=0,
                    })
                    
                    del(portals,p)
                    
				else
					--portal shatters once
					-- @sound portal hit
					expl_create(p.x,p.y, 48,{
						dur=15,
						den=5,
						colors={7},
						smin=3,
						smax=8,
						grav=0,
					})
                
                	p.hp=level.portal_hp
					
					if p.jump then -- pick new portal for jumping
						p.jump=false
						portal_jump_pick(p.lane)
					end
                end
            end
            
        else
            p.hit=false 
			
			if p.jump then
				
				if p.x>50 then
					if p.jt==0 then 
						-- @sound of jumping portal
						
					end
					
					if p.jt>45 and p.jt<60 then --
						p.x-=1
						p.ang+=.16 --distance between crests
						p.y+=sin(p.ang)*1 --height of wave
						p.isjumping=true
						
						if p.jt==46 or p.jt==55 then sfx(5) end
					end

					if p.jt==210 then
						p.isjumping=false
						p.jt=0
						p.ang=0
						
					end

					p.jt+=1
				end
			end
			
			
        end
    
		p.hit=false
        p.t+=1
    end
	
	-- portal spawn; randomize from available
	if #portals>0 then
		if timer("portalspawn",portal_spawn,true) then
			local spawnfrom=rnd_table(portals)

			while last_portal==spawnfrom.lane and #portals>1 do
				spawnfrom=rnd_table(portals)
			end

			last_portal=spawnfrom.lane
			portal_spawn=random(15,level.portal_spawn)
			
			if #portals==1 then
				portal_spawn=60
			end

			if not spawnfrom.hit and #slimers<level.slimer_max then
				slimer_create(spawnfrom.lane)
			end
		end
	end
end

function portal_jump_pick(lastlane)
	if #portals>1 then
		local pick={lane=lastlane}
		
		while pick.lane==lastlane do
			pick=rnd_table(portals)
		end
		
		pick.jump=true
		pick.jt=0
	else
		local pick=rnd_table(portals)
		pick.jump=true
		pick.jt=0
	end
end


function portal_draw()
    for p in all(portals) do
        if p.hit then p.c=rnd_table({8,7,10}) else p.c=0 end
    
		local c=rnd_table({3,11})
		palt(14,true)
		palt(0,false)
		pal(0,c)
		pal(8,c)
		pal(12,c)
		pal(9,c)
		pal(15,c)
		
		if p.r<5 then pal(8,0) end
		if p.r<4 then pal(12,0) end
		if p.r<3 then pal(9,0) end
		if p.r<2 then pal(15,0) end
		
		spr(3,p.x,p.y-8,2,2)
		pal()
        
		if p.hit then
			expl_create(p.x,p.y, 8,{
				dur=8,
				den=2,
				colors={10,7,9,8},
				smin=1,
				smax=4,
				grav=0,
			})
		end
    end 
	
	for e in all(portal_explodes) do
		for n=0,e.q do
			circ(e.x,e.y,e.r-n*2,7)
			
			if e.r>200 then del(portal_explodes,e) end
		end
		e.r+=8
	end

end



--#trap
trap_lane=0
trap_x=-100
trap_y=-100
trap_t=0
trap_st=0
function trap_create(lane)
	trap_st=1
	trap_ps={}
	trap_lane=lane
	trap_x=p_x
	trap_y=lanes[lane]
	trap_t=0
end

function trap_update()
		if trap_st==1 then
			trap_x+=2
			if trap_x>30 then trap_st=2 end
		end
		
		if trap_st==2 then
			-- @sound of trap opening, one-timer
			sfx(2)
			for n=0,48 do
				local obj={
					ox=random(trap_x-6,trap_x+16),
					oy=random(trap_y,trap_y+16),
					c=10
				}
				obj.x=obj.ox
				obj.y=obj.oy
				local ang = atan2(trap_x+6-obj.x, trap_y+14-obj.y)	
				obj.dx,obj.dy=dir_calc(ang,1.25)
				
				add(trap_ps,obj)
			end
			
			trap_st=3
		end
		
		if trap_st==3 then
			trap_t+=1
			if trap_t>210 then trap_st=4 end --time to end
			
			for p in all(trap_ps) do
				p.x+=p.dx
				p.y+=p.dy
				p.c=rnd_table({10,7,9,12})
				
				if p.y>trap_y+16 or p.x<trap_x-6 or p.x>trap_x+16 or p.y<trap_y then 
					p.x=p.ox
					p.y=p.oy
				end
				
				
			end
		end
		
		if trap_st==4 then
			trap_x-=2
			if trap_x<-16 then trap_st=0 end
		end
	
end


function trap_draw()
	palt(0,false)
	palt(14,true)
	if trap_st>0 then
		if trap_st<3 or trap_st==4 then spr(57,trap_x,trap_y+13,2,1) end
		if trap_st==3 then
			spr(43,trap_x,trap_y+10,2,2)
		
			for p in all(trap_ps) do
				pset(p.x,p.y, p.c)
			end
		end
	end
	
end



--#puft
function puft_init()
	puft_x=130
	puft_dir=-1
	puft_ang=0
	puft_st=0
	puft_y=lanes[1]
	puft_bottom=lanes[1]+1.8
end


function puft_update()
	if puft_st>0 then
		puft_x+=.15*puft_dir
		puft_ang+=0.01 --distance between crests, higher=closer
		puft_y = lanes[puft_st]+sin(puft_ang)*2
		
		if puft_x<-40 then 
			puft_dir=1
			puft_st+=1
			if puft_st>3 then puft_st=1 end
			puft_bottom=lanes[puft_st]+1.8
		end

		if puft_x>150 then 
			puft_st+=1
			puft_x=130
			if puft_st>3 then puft_st=1 end
			puft_y=lanes[puft_st]
			puft_bottom=lanes[puft_st]+1.8
			
			puft_dir=-1
		end

		if puft_y>puft_bottom and puft_x>0 and puft_x<128 and shake<1 then shake=1 end
	end
end

function puft_draw(s)
	if puft_st==s then
		palt(14,true)
		palt(0,false)
		spr(35,puft_x,puft_y,2,3)
		palt()
	end
end








--#meter
function meter_draw()
		local hpbarx1,hpbarx2=4,46
		local hpbary1,hpbary2=116,124
		local hpbarw=flr((hpbarx2-hpbarx1)*(p_power/100))
		
		rectfill(hpbarx1,hpbary1, hpbarx2,hpbary2, 0)
		rectfill(hpbarx1,hpbary1, hpbarx1+hpbarw,hpbary2, 8)
		rect(hpbarx1,hpbary1, hpbarx2,hpbary2, 7)
		print("overheated",hpbarx1+2,hpbary1+2, 0)
		
		
		local hpbarx1,hpbarx2=50,120
		local hpbary1,hpbary2=116,124
		local hpbarw=flr((hpbarx2-hpbarx1)*(p_slime/100))
		
		rectfill(hpbarx1,hpbary1, hpbarx2,hpbary2, 0)
		rectfill(hpbarx1,hpbary1, hpbarx1+hpbarw,hpbary2, 11)
		rect(hpbarx1,hpbary1, hpbarx2,hpbary2, 7)
		print("slime",hpbarx1+2,hpbary1+2, 0)

end








--#charselect



function charselect_init()
	local select_pos=1
	
	if charmode>0 then
		selects={"peter","ray","egon","winston"}
	else
		selects={"holtz","erin","abby","patty"}
	end
	
	
	function charselect_update()
		if btnp(1) then select_pos+=1 end
		if btnp(0) then select_pos-=1 end
		if btndp then select_pos+=2 end
		if btnup then select_pos-=2 end
		
		if select_pos<1 then select_pos=1 end
		if select_pos>4 then select_pos=4 end
		
		p_char=selects[select_pos]
		
		if btnzp then scene_init() end
	end

	function charselect_draw()
		rectfill(0,0,127,127,1)
		
		center_text("select your ghostbuster",5,7)
		
		if charmode>0 then
			draw_char("peter",30,30)
			print("peter",28,55,7)
			
			draw_char("ray",80,30)
			print("ray",82,55,7)
			
			draw_char("egon",30,80)
			print("egon",30,105,7)
			
			draw_char("winston",80,80)
			print("winston",74,105,7)
		else
			draw_char("holtz",30,30)
			print("holtzmann",20,55,7)
			
			draw_char("erin",80,30)
			print("erin",80,55,7)
			
			draw_char("abby",30,80)
			print("abby",30,105,7)
			
			draw_char("patty",80,80)
			print("patty",78,105,7)
			
		end
		
		
		if select_pos==1 then rect(15,20, 60,65, 10) end
		if select_pos==2 then rect(65,20, 110,65, 10) end
		if select_pos==3 then rect(15,70, 60,115, 10) end
		if select_pos==4 then rect(65,70, 110,115, 10) end
	end
	
	
	
	cart_control(charselect_update,charselect_draw)
end





--#game
function game_init()
	slimers={}

	--puft_init()
	rowan_st=1
	foo=0
	foox=130
	fool=p_lane
	fooy=lanes[fool]
	fooang=0
	footrig=-30
	
	function game_update()
		
		
		portal_update()
		p_update()
		slimer_update()
		expl_update()
		
		trap_update()
		puft_update()
		
		if current_level==4 then --rowan scales into mirror
			rowan_jump_update()
		end

		if p_slime>=40 and puft_st<1 then
			puft_st=1
		end
		
		if p_slime>=100 then
			gameover_init()
		end
		
		if #portals<=0 then
			p_canfire=false
			
			if wait(45) then
				current_level+=1
				
				if current_level<6 then
					scene_init() --continue	
				else
					victory_init()
				end
				
			end
		end
		
		if current_level==5 then
			if foo>=90 then
				
				foox-=3.5
				fooang+=0.1 --distance between crests
				fooy+=sin(fooang)*1 --height of wave
				
				if fool==p_lane and foox<muzzle_x-8 and foox>0 and p_invincible<1 then
					p_slimed=true
					p_t=0
				end
				
				
				if foox<=footrig then
					foox=130
					
					if rnd()<.4 then
						fool=p_lane
					else
						fool=random(1,4)
					end
					
					fooy=lanes[fool]
					footrig=flr(rnd(90)+60)*-1
				end
			end
			
			foo+=1
		end

	end

	
	

	function game_draw()
		screenshake()
		game_drawbg()
		p_draw()
		trap_draw()
		portal_draw()
		expl_draw()
		slimer_draw()
		
		
		if current_level==4 then
			rowan_jump_draw()
		end
		
		if current_level==5 then
			if foo>=90 then
				palt(0,false)
				palt(14,true)
				zspr(147,4,4,foox,fooy,.9)
				palt()
			end
		end
	end
	
	

	
	cart_control(game_update,game_draw)
end




function game_drawbg() 
		camera(0+cam_x,bglayer1_cy+cam_y)
		puft_draw(1)
		palt(0,false)
		palt(14,true)
		map(0,0, -60,-2, 16,3) --grey city
		map(0,0, 44,-2, 16,3) --grey city
		rectfill(0,20,127,60, 5)
		skyfade(47,4)
		palt()
		
		camera(0+cam_x,bglayer2_cy+cam_y)
		puft_draw(2)
		palt(0,false)
		palt(14,true)
		pal(5,2) --red city
		map(0,0, 0,25, 16,3) --grey city
		rectfill(0,48,127,127, 2)
		skyfade(73,8)
		palt()
		
		camera(0+cam_x,0+cam_y)
		puft_draw(3)
		palt(0,false)
		palt(14,true)
		pal(5,1) --blue city
		rectfill(0,75,127,127, 1)
		map(0,0, -30,56, 16,3)
		map(0,0, 70,53, 16,3)
		
		skyfade(110,0)
		
		
		--layers
		local layer_h=20
		pal(5,5) 
		camera(0+cam_x,bglayer1_cy+cam_y)
		map(0,3, layer1_x,lanes[1]+layer_h, 16,1) --1
		camera(0+cam_x,bglayer2_cy+cam_y)
		
		map(0,3, layer2_x,lanes[2]+layer_h, 16,1) --2
		camera(0+cam_x,0+cam_y)
		map(0,3, 0,lanes[3]+layer_h, 16,1) --3
		map(0,3, 0,lanes[4]+layer_h, 16,1) --4
		
		
		map(0,4, 0,117, 16,1) --4
		map(0,4, 0,125, 16,1) --4
		pal()	
		
		meter_draw()
		
	end




--#victory screen, you win!
function victory_init()
	
	--p_lane=4
	vic_st=1
	rowan_x,rowan_y,rowan_a=130,p_y,0
	
	function bobbing()
		rowan_a+=0.02
		rowan_y=p_y+sin(rowan_a)*4
	end
	

	function victory_update()
		p_y=lanes[p_lane]
		trap_update()
		expl_update()
		
		if vic_st==1 then
			if t==20 then
				if p_lane==3 then
					rowan_y=p_y
					vic_st=2
				else
					if p_lane==4 then
						p_lane=3
					else
						p_lane+=1
					end
					t=0
				end
			end
		end
		
		if vic_st==2 then
			bobbing()
			rowan_x=max(70,rowan_x-1)
			if rowan_x==70 then
				vic_st=3
				t=0
			end
		end
		
		if vic_st==3 then
			bobbing()
			if t>30 then vic_st=4 end
		end
		
		
		if vic_st==4 then
			trap_create(p_lane)
			vic_st=5 t=0
			rowan_scale=1
			
		end
		
		if vic_st==5 then
			bobbing()
			if t>30 then
				vic_st=6
				t=0
			end
		end
		
		if vic_st==6 then
			if t<30 then
				rowan_x+=1
				rowan_y-=2
				rowan_ang = atan2(trap_x+2-rowan_x, trap_y+12-rowan_y)
				rowan_dx,rowan_dy=dir_calc(rowan_ang,1.5)
			else
				rowan_scale=max(0,rowan_scale-.014)
				rowan_x+=rowan_dx
				rowan_y+=rowan_dy
				
				if t>250 then
					vic_st=7
				end
			end
		end
		
		
		if vic_st==7 then
			if layer1_x>-128 then layer1_x-=5 end
			if layer2_x<128 then layer2_x+=5 end
			
			if layer2_x>=128 then
				if bglayer1_cy>-129 then 
					bglayer1_cy=min(128,bglayer1_cy-1.6)
					bglayer2_cy=min(128,bglayer2_cy-1)
				else 
					vic_st=8
					t=50
					intro_text(";_;thank you ghostbusters!;")
					intro_text(";_;the city is once again safe...;")
					intro_text(";_;...for now;")
					intro_text("design+code;@morningtoast;")
					intro_text("music+sounds;@gnarcade_vgm;")
					intro_text("character art;hal laboratory, 1990;;additional art;@morningtoast;@beetleinthebox;")
					intro_text(";_;you busted "..kills.." ghosts;")
					
					if unlocked<1 then
						intro_text(";_;special characters unlocked;please play again;")
					else
						intro_text(";_;thanks for playing;")
						intro_text(";_;please try other games;from @morningtoast;")
					end
					
					intro_init(ef)
				end
			end
		end
		
		if vic_st==8 then
			if t==50 then
				expl_create(rnd(100)+10,rnd(40)+10, 64, {
					colors={2,3,4,7,8,9,10,11,12,13,14,15},
					grav=.2,
					dur=35, --30
					den=2, --0
					smin=1, --1
					smax=2 --1
				})
				t=0
			end
			
			if btnxp or btnzp then 
				if unlocked>0 then
					title_init() 
				else
					unlock_init()
				end
			end
			
		end

	end


	function victory_draw()
		
		rectfill(0,0,128,128,0)
		skyfade(63,2)
		rectfill(0,61,128,128,12)
		skyfade(77,11)
		skyfade(79,3)
		
		pal(5,1)
		spr(80, 31,40, 1,3) --liberty
		pal()
		
		game_drawbg()
		camera(0,0)
		p_draw()
		trap_draw()
		expl_draw()
		
		if vic_st<6 then
			rowan_draw(rowan_x,rowan_y)
		end
		
		if vic_st==6 then
			zspr(147,4,4,rowan_x,rowan_y,rowan_scale)
		end
		
		if vic_st==8 then
			intro_draw()
		end
	end

	cart_control(victory_update,victory_draw)
end




-- #unlock - unlock bonus characters
function unlock_init()
	t=0
	unlocked=1
	dset(0,1)

	cart_control(ef,unlock_draw)
end

function unlock_draw()
	rectfill(0,0,128,128,1)
	center_text("who you gonna call?",15,8)
	center_text("classic characters unlocked",30,10)
	center_text("use \131\148 to switch modes",50,7)
	center_text("at the title screen",58,7)
	
	center_text("press \142 to continue",80,6)
	
	draw_char("peter", 10,100)
	draw_char("ray", 40,100)
	draw_char("egon", 70,100)
	draw_char("winston", 100,100)
	
	if t>30 then
		if btnzp or btnxp then title_init() end
	end
end


--#over, game over screen
function gameover_init()
	slimedrop={}
	
	
	function gameover_update()
		slimer_update()
		expl_update()
		trap_update()
		puft_update()
		
		slimedrop_min=999
		for s in all(slimedrop) do
			s.y+=rnd(1)+1
			
			if s.y<slimedrop_min then slimedrop_min=s.y end
			
			if s.y>130 then s.y=130 end
		end
		
		if slimedrop_min>130 then
			if btnzp or btnxp then title_init() end
		end
		
	end


	function gameover_draw()
		game_drawbg()
		p_draw()
		trap_draw()
		portal_draw()
		expl_draw()
		slimer_draw()

		for s in all(slimedrop) do
			circfill(s.x,s.y,s.r,11)
		end

		rectfill(-8,0, 130,slimedrop_min+3, 11)
		
		if slimedrop_min>130 then
			center_text("game over",30,3)
			center_text("you busted "..kills.." ghosts",50,3)
			center_text("press \142 to play again",85,3)
		end
	end
	
	
	cart_control(gameover_update,gameover_draw)
	
	for n=0,16 do
		add(slimedrop,{r=rnd(5)+5,x=8*n,y=rnd(6)*-1})
	end
	
	slimedrop_min=0
end





--#rowan
function rowan_reset()
	rowan_y=-50
	rowan_x=50
	rowan_a=0
	rowan_next=fn	
	rowan_st=1
	rowan_scale=32
end

function rowan_draw(x,y)
	x=x or rowan_x
	y=y or rowan_y
	
	palt(0,false)
	palt(14,true)
	spr(147, x,y, 4,4)
	palt()
end

function rowan_bob()
	rowan_a+=0.02
	rowan_y = 35+sin(rowan_a)*4
end

-- level 3 jump into mirrors
function rowan_jump_update()

	if rowan_st==1 then
		rowan_pick=rnd_table(portals)
		rowan_stopmin=lanes[rowan_pick.lane]-5
		rowan_stopmax=lanes[rowan_pick.lane]+5
		
		local ang = atan2(rowan_pick.x+8-rowan_x, rowan_pick.y+4-rowan_y)
		rowan_dx,rowan_dy=dir_calc(ang,2.25)
		rowan_scale=32
		
		rowan_st=2
	end
	
	if rowan_st==2 then
	
		rowan_y+=rowan_dy
		rowan_x+=rowan_dx
		rowan_scale-=1
		
		if rowan_scale<=0 then
			rowan_st=2.1
			portals[rowan_pick.lane].jump=true
		end
	end
	
	if rowan_st==3 then
		rowan_bob()
	end
	
	
	
end


function rowan_jump_draw()
	if rowan_scale>0 then
		palt(0,false)
		palt(14,true)
		sspr(24,72, 32,32, rowan_x,rowan_y, rowan_scale,rowan_scale)
		palt()
	end

end


-- scene entrance
function rowan_entrance_update()
	tbx_update()
	
	--rowan comes down
	if rowan_st==1 then
		if rowan_y<35 then rowan_y+=1 else rowan_st=2 end
	end
	
	--bob when it reaches the bottom, wait a bit then talk
	if rowan_st==2 then
		rowan_bob()
		if wait(40,true) then
			rowan_st=3
			textbox(level.rowan_text,14,68,7)
		end
	end
	
	--talk while bobbing
	if rowan_st==3 then
		rowan_bob()
		
		if btnzp then rowan_st=4 end
	end
	
	if rowan_st==4 then
		rowan_bob()
		if wait(25,true) then
			rowan_st=5
		end
	end
	
	if rowan_st==5 then
		if current_level!=4 then --float up out of screen to start play
			if rowan_y>-50 then
				rowan_y-=2
			else
				if current_level==5 then
					portal_jump_pick(99)
				end
			
				game_init()
			end
		else
			game_init()
		end

	end
end

function rowan_entrance_draw()
	rowan_draw()
	
	if rowan_st==3 then
		draw_textbox()
		tbx_draw()
		
		if tbx_finish() then
			print("\142",107,97,7) 
		end
	end
end

function draw_textbox()
	rectfill(10,65, 117,105, 0)
	rect(10,65, 117,105, 7)
end




--#scenes
function scene_reset()
	p_canfire=false
	p_slimed=false
	firing=false
end

--#levels
levels={
	{ -- level 1
		portal_hp=50,
		portal_spawn=60, -- spawn of next slimer is between 30f and this number
		portal_offset={36,24,12,0},
		slimer_hp=10,
		slimer_speed=.5,
		slimer_max=7,
		rowan_text="these portals will let my ghost army enter your world. the city shall be ours!"
	},
	{ -- level 2
		portal_hp=50,
		portal_spawn=50,
		portal_offset={0,12,24,36},
		slimer_hp=10,
		slimer_speed=.6,
		slimer_max=10,
		rowan_text="think that's all? there's more where that came from. this is the end, ghostbusters!"
	},
	{ -- level 3
		portal_hp=50,
		portal_spawn=50,
		portal_offset={36,12,36,12},
		slimer_hp=10,
		slimer_speed=.7,
		slimer_max=8,
		rowan_text="impressive. but i have more portals and evil spirits. prepare to meet your doom!"
	},
	{ -- level 4, jumping mirrrs
		portal_hp=50,
		portal_spawn=50,
		portal_offset={0,0,0,0},
		slimer_hp=10,
		slimer_speed=.8,
		slimer_max=10,
		rowan_text="i must help my ghost army. the end is near, ghostbusters. you can't stop us all!"
	},
	{ -- level 5, boss fight
		portal_hp=40,
		portal_spawn=50,
		portal_offset={0,0,0,0},
		slimer_hp=6,
		slimer_speed=.8,
		slimer_max=15,
		rowan_text="i guess if you want to take over the world, you have to do it yourself."
	}
}

function scene_init()
	level=levels[current_level]
	
	wait_reset()
	scene_reset()
	portal_reset()
	rowan_reset(game_init)

	function scene_update()
		rowan_entrance_update()
		expl_update()
	end

	function scene_draw()
		game_drawbg()
		p_draw()
		
		portal_draw()
		expl_draw()
		
		rowan_entrance_draw()
		rowan_draw()
	end

	cart_control(scene_update,scene_draw)
end













-- #intro
function boot_init()
	play_music(0)
	intro_text("bustin' v"..version..";(c)brian vaughn, 2017;_;_;design+code;brian vaughn;@morningtoast;_;music+sound;brian follick;@gnarcade_vgm;")
	intro_text("_;_;_;for penny;")
	intro_init(title_init)

	cart_control(ef,intro_draw)
end




--#title
function title_init()
	t=0
	sspr_wh=12
	logo_xy=60
	
	city1_y=144
	city1_ystop=24
	city2_y=130
	city2_ystop=30
	
	bglayer1_cy=0
	bglayer2_cy=0

	layer1_x=0
	layer2_x=0	
	
	cam_x,cam_y=0,0
	
	cart_control(title_update,title_draw)
	
	p_lane=2
	p_x,p_y,p_dir=2,lanes[p_lane],1
	p_power=0
	p_slime=0
	p_cooldown=0
	p_slimed=false
	p_canmove=true
	p_canfire=true
	p_invincible=0
	kills=0

	fire_w=0
	fire_t=0 --needed for sine wave	
	
	puft_init()
	puft_y=25
	
	current_level=1 --debug
end

function title_update() 
	logo_xy-=2
	sspr_wh+=3
	
	if sspr_wh>64 then sspr_wh=64 end
	if logo_xy<26 then logo_xy=26 end
	
	if btnzp then 
		puft_st=0
		charselect_init() 
		--victory_init()
	end
	
	if t>20 then
		if city1_y>city1_ystop then city1_y-=1 end
		if city2_y>city2_ystop then city2_y-=1 end
	end
	
	if t>400 and puft_st==0 then puft_st=1 end
	
	if puft_st==1 then
		puft_x+=.15*puft_dir
		puft_ang+=0.01
		puft_y = 25+sin(puft_ang)*2
		
		if puft_x<-40 then puft_dir=1 end
		if puft_x>140 then puft_st=2 end
	end
	
	if t<1000 then t+=1 end
	
	if (btnup or btndp) and unlocked>0 then
		charmode+=1
		if charmode>1 then charmode=0 end
	end
end

function title_draw()
	puft_draw(1)
	
	pal(5,2) --red city
	palt(14,true)
	rectfill(0,city1_y+18,127,city1_y+18+80, 2)
	map(0,0, -20,city1_y, 16,3)
	map(0,0, 80,city1_y, 16,3)
	pal()
	
	
	
	pal(5,1) --blue city
	palt(14,true)
	rectfill(0,city2_y+22,127,city2_y+22+127, 1)
	map(0,0, -30,city2_y, 16,3)
	map(0,0, 40,city2_y, 16,3)
	pal()
	
	skyfade(city2_y+95,0)
	
	
	
	palt(14,true)
	palt(0,false)
	sspr(24,40, 32,32, logo_xy+4,logo_xy-15, sspr_wh,sspr_wh)
	pal()
	
	if sspr_wh>=64 then
		spr(87, 30,logo_xy+38, 9,3)
		
		if charmode>0 then
			center_text("who you gonna call?",90,8)
		else
			center_text("makes me feel good",90,11)	
		end

		center_text("press \142 to start",108,7)
	end
end



-- #loop

 --load savedata
cartdata("bustin2017")

-- Pause menu options
menuitem(1, "toggle music", function() 
	if musicon then musicon=false music(-1) else musicon=true play_music(0) end
end)

menuitem(2, "clear save data", function()
	dset(0,0)
	unlocked=0
	charmode=0
	title_init()
end)


function _init()
	unlocked=dget(0)
	
	tbx_init()
	boot_init()
end

function _update()
	btnup=btnp(2)
	btndp=btnp(3)
	btnz=btn(4)
	btnzp=btnp(4)
	btnxp=btnp(5)
	
	cart_update()

	t=min(32000,t+1)
end


b=0
function _draw()
	cls()

	cart_draw()

	if debug then print(debug,1,100,10) end
end







-- #utilities and helpers
ef=function() end
cart_control=function(u,d)
	cart_update,cart_draw=u,d
	t=0
end


function zspr(n,w,h,dx,dy,dz)
  sx = 8 * (n % 16)
  sy = 8 * flr(n / 16)
  sw = 8 * w
  sh = 8 * h
  dw = sw * dz
  dh = sh * dz

  sspr(sx,sy,sw,sh, dx,dy,dw,dh)
end


shake,shake_t=0,0
cam_x=0 cam_y=0
function screenshake()
	cam_x=0 cam_y=0
	if shake>0 then
		
		local shaker=1
		if rnd()<.5 then shaker=-random(1,2) end
		
		cam_x+=shaker*rnd_table({-1,1,-1,1})
		cam_y+=shaker*rnd_table({-1,1,-1,1})

		shake_t+=1
		if shake_t>3 then 
			shake=0
			shake_t=0 
		end
	end
end


function play_music(track)
	if musicon then music(track) end	
end

	
--[[#state
states={}
function st_add(st) add(states,st) end
function st_rm(st) del(states,st) end
function st_chg(st) st_reset() st_add(st) end
function st_reset() states={} end
function st_clear(st)
	local nextst=st+1
	for n in all(states) do
		if n>=st and n<nextst then st_rm(n) end
	end
end
function st_is(st) 
	if in_table(states, st) then return true else return false end
end
function st_debug()
	local t=""
	for n in all(states) do
		t=n.."-"..t
	end
	return t
end
]]

timers={}
function timer_set(t) timers[t]=0 end
function timer_get(t) return timers[t] end
--function timer_rm(t) timers[t]=false end
--[[
function timer_is(t,limit)
	limit=limit or 32000
	
	if timers[t] then
		if timer_get(t)>limit then return true end
	end
	return false
end
]]

function timer(t,limit,reset)
	reset=reset or true
	limit=limit or 32000
	
	if not timers[t] then
		timer_set(t)
	else
		timers[t]+=1
	end
	
	if timer_get(t)>limit then 
		if reset then timer_set(t) end
		return true 
	end
	return false
end
	
	
wait_t=0
function wait(max,reset)
	reset=reset or false
	
	if wait_t<max then 
		wait_t+=1 	
		return false
	else
		if reset then wait_t=0 end
		return true
	end
end
function wait_reset() wait_t=0 end


--text drawing
function tbx_init()
	tbx_counter=1
	tbx_width=26 --characters not pixels
	tbx_lines={}
	tbx_cur_line=1
	tbx_com_line=0
	tbx_text=nil
	tbx_x=nil
	tbx_y=nil
end


function tbx_finish()
	if tbx_com_line+1==#tbx_lines then return true else return false end
end

function tbx_update()
 if tbx_text!=nil then 
 local first=nil
 local last=nil
 local rows=flr(#tbx_text/tbx_width)+2
 
 --split text into lines
 for i=1,rows do
  first =first or 1+i*tbx_width-tbx_width
  last = last or i*tbx_width
			
  --cut off incomplete words
  if sub(tbx_text,last+1,last+1)!="" or sub(tbx_text,last,last)!=" " and sub(tbx_text,last+1,last+1)!=" " then
   for j=1,tbx_width/3 do
    if sub(tbx_text,last-j,last-j)==" " and i<rows then
     last=last-j
     break
    end
   end
  end
  
  --create line
  --if first char is a space, remove the space
  if sub(tbx_text,first,first)==" " then
   tbx_lines[i]=sub(tbx_text,first+1,last)
  else
   tbx_lines[i]=sub(tbx_text,first,last)
  end
   first=last
   last=last+tbx_width
 end
 
 --lines are now made
 
 
 --change lines after printing
 if tbx_counter%tbx_width==0 and tbx_cur_line<#tbx_lines then
  tbx_com_line+=1
  tbx_cur_line+=1
  tbx_counter=1  
 end
 --update text counter
 tbx_counter+=1
 if (sub(tbx_text,tbx_counter,tbx_counter)=="") tbx_counter+=1
 end
end


function tbx_draw()
 if #tbx_lines>0 then
  --print current line one char at a time
  print(sub(tbx_lines[tbx_cur_line],1,tbx_counter),tbx_x,tbx_y+tbx_cur_line*6-6,tbx_col)

 
  --print complete lines
  for i=0,tbx_com_line do
   if i>0 then
    print(tbx_lines[i],tbx_x,tbx_y+i*6-6,tbx_col)
   end
  end
 end 
end


function textbox(text,x,y,col)
	tbx_init()
	tbx_x=x or 4
	tbx_y=y or 4
	tbx_col=col or 7
	tbx_text=text
end

	
--#intro scenes
intro_all={}
function intro_text(txt) add(intro_all, txt) end

function intro_complete()
	if not intro_st then intro_st=1 else intro_st+=1 end
	intro_t=0
	intro_color=0
	
	if intro_st>#intro_all then
		intro_st=0
		intro_all={}
		return true
	else return false end
end

function intro_init(oncomplete)
	
	intro_complete()
	intro_func=oncomplete
	
	for k,txt in pairs(intro_all) do intro_all[k]=split(txt) end
end

function intro_draw()
	intro_y=10
	
	for line in all(intro_all[intro_st]) do
		if line!="_" then
			print(line, 64-(#line*2),intro_y, intro_color) --centers text
		end
		
		intro_y+=7
	end
	
	-- fadein
	if intro_t>3 then intro_color=1 end
	if intro_t>6 then intro_color=5 end
	if intro_t>9 then intro_color=13 end
	if intro_t>12 then intro_color=6 end
	if intro_t>15 then intro_color=7 end
	
	--display as white for ~3s
	
	--fadeout
	if intro_t>100 then intro_color=6 end
	if intro_t>103 then intro_color=13 end
	if intro_t>106 then intro_color=5 end
	if intro_t>109 then intro_color=1 end
	if intro_t>112 then intro_color=0 end
	
	--faded out + wait, load next
	if intro_t>120 then 
		if intro_complete() then intro_func() end
	end
	
	intro_t+=1
	
end


-- split(string, delimter)
function split(s,dc)
	dc=dc or ";"
	local a={}
	local ns=""
	
	
	while #s>0 do
		local d=sub(s,1,1)
		if d==dc then
			add(a,ns)
			ns=""
		else
			ns=ns..d
		end
	
		s=sub(s,2)
	end
	
	return a
end	
	
	

--[[ checks to see if value is in a table
function in_table(tbl, element)
  for _, value in pairs(tbl) do
    if value == element then
      return true
    end
  end
  return false
end
]]
	
function center_text(s,y,c) print(s,64-(#s*2),y,c) end

function skyfade(y,c,inv,rows)
	rows=rows or {0,1,2,4,5,7,10,15}
	inv=inv or -1

	for b in all(rows) do
		line(0,y+b*inv, 127,y+b*inv, c)
	end
end


	
--sine boxrender
--by lumiette

--game
pi=3.14159265359
function sine(amplitude, speed, phase)
  phase=phase or 1
  return amplitude * (sin((t+phase/pi)*speed))
end

function draw_sine(spd,phs,tl,br,colour,thickness, border, bg)
-- params: speed, phase, 
--         top-left xy, bottom-right xy,
--         wave colour, border colour, background colour 
 bg=bg or false  border=border or false  colour=colour or 7  thickness=thickness or 2
 tl=tl or {64-32,64-16} br=br or {64+32, 64+16}
 tx=tl[1] ty=tl[2] bx=br[1] by=br[2]
 x=bx-tx y=by-ty-1+thickness


 for j=1,thickness do
   for i=0,x-2 do
    wave=sine(y/2,spd,phs+i)
    pset(i+tx+1,ty+(y-1)/2-(j/2)+j+wave+1,colour)
   end
  end
end



function dir_calc(angle,speed)
	local dx=cos(angle)*speed
	local dy=sin(angle)*speed
	
	return dx,dy
end

--[[
function distance(ox,oy, px,py)
  local a = ox-px
  local b = oy-py
  return pythag(a,b)
end
]]

function random(min,max)
	n=round(rnd(max-min))+min
	return n
end

-- round number to the nearest whole
function round(num, idp)
  local mult = 10^(idp or 0)
  return flr(num * mult + 0.5) / mult
end


function rnd_table(t)
	local r=flr(rnd(#t))+1
	return(t[r])
end

function is_even(n) 
	if (n%2==0) then return true else return false end
end


--[[
function offscreen(x,y)
	if (x<screen_x or x>screen_w or y<screen_y or y>screen_h) then 
		return true
	else
		return false
	end
end
]]

--[[ returns true if hitbox collision 
function collide(ax,ay,ahb, bx,by,bhb)

    -- get the intersection of p and af
	  local l = max(ax+ahb.x,        bx+bhb.x)
	  local r = min(ax+ahb.x+ahb.w,  bx+bhb.x+bhb.w)
	  local t = max(ay+ahb.y,        by+bhb.y)
	  local b = min(ay+ahb.y+ahb.h,  by+bhb.y+bhb.h)

	  -- they overlapped if the area of intersection is greater than 0
	  if l < r and t < b then
		return true
	  end
					
	return false
end	
]]




--[[
	basic explosion particle library

	in-game use:
	expl_create(x,y, numberofparticles, optoinstable)
	
	optionstable
	{
		dur=durationinframes, --30
		den=startingsizeofparticle, --0
		decay=rateofsizereduction, --.25
		colors=tableofcolors, --{7,10,9}
		smin=minspeedofparticles, --1
		smax=maxspedofparticles, --1
		grav=maxgravity, --.3
		dir=directionofforce, --0 (all directions)
		range=distributionanglearounddirection --0
	}
	
	
	add these functions to your system loops:
	expl_update()
	expl_draw()
		
]]



expl_all={}
function expl_create(x,y, size, options)
	for n=1,size do
		local obj={
			x=x,y=y,
			t=0,
			dur=30,
			den=0,
			decay=.25,
			dia=0,
			colors={7,10,9},
			smin=.25,
			smax=1,
			grav=.3,
			dir=0,
			range=0
		}
		
		if options then
			for k,v in pairs(options) do obj[k] = v end
		end
		
		local c=flr(rnd(#obj.colors))+1
		local sp=rnd(obj.smax-obj.smin)+obj.smin

		if obj.dir>0 then
			if obj.range>0 then
				local dirh=obj.range/2
				local dira=obj.dir-dirh
				local dirb=obj.dir+dirh

				obj.dir=rnd(dirb-dira)+dira
			end
		else
			obj.dir=rnd()	
		end
	
		obj.c=obj.colors[c]
		obj.g=rnd(abs(obj.grav))
		obj.dx=cos(obj.dir)*sp
		obj.dy=sin(obj.dir)*sp
		
		if obj.grav<0 then obj.g*=-1 end
		
		add(expl_all,obj)
	end
end

function expl_update()
	foreach(expl_all, function(o)
		o.dy+=o.g
		o.y+=o.dy
		o.x+=o.dx
		o.t+=1
		o.den-=o.decay
		o.dia=max(o.den,0)

		if o.t>o.dur then del(expl_all, o) end
	end)
end

function expl_draw()
	foreach(expl_all, function(e)
		circfill(e.x,e.y, e.dia, e.c)
	end)
end


__gfx__
0000000000000000000000004444444444445eeeeeeeeeeeeeeeeeeeeeeee33333eeeeee555555550000000055555555eeeeeeeeeeeeeeee0000000000000000
0000000000000000000000004222222222215eeeeeeeeeeeeeeeeeeeeeee33bbb33eeeee525252526666666659595555eeeeeeeeeeeeeeee0000000000000000
00700700000000000000000042ddddddddd15eeeeeeeeeeeeeeeeeeeeee33bbabb33eeee222222224444444454545555eeeeeeeeeeeeeeee0000000000000000
00077000000000000000000042d9990fffd15eeeeeeeeeeeeeeeeeeee333bbaabbb33eee44444444000000005555555555555555eee55eee0000000000000000
00077000000000000000000042d09900ffd15eeeeeeeeeeeeeeeeeeee3baabbbbbbb3eee44444444444404445555595955595955ee5555ee0000000000000000
00700700000000000000000042d009900fd15eee000eeeeeeeeeeeee3337bbbbbbbb33eed4d4d4d4888808885555545455545455e555555e0000000000000000
00000000000000000000000042d0009900d15eee050eeeeeeeeeeeee333773bb3bbbb3eedddddddd000000005555555555555555555555550000000000000000
00000000000000000000000042d0c00000d15eee05000eeeeeeeeeee33b07bbbb3bbb3ee55555555eeeeeeee5555555555555555555555550000000000000000
00000000000000000000000042d00ccc00d15eee050000eeeeeeeeeee3bbbb3bb3bbb3eeeeeeeeee440444445555555500000000333333330000000000000000
00000000000000000000000042d800ccc0d15eee055000eeeeeeeeeee333333bbbbbb33eeeeeeeee440444445555555500000000333333330000000000000000
00000000000000000000000042d808ccccd15eee05000000eeeeee0ee3b33bbbbbbbbb33eeeeeeee880888885555555500000000333333330000000000000000
00000000000000000000000042d8800cccd15eee0005000000000060e3bbab33b3bbb3b3eeeeeeee000000005555555500000000333333330000000000000000
eeeeeeeeeeeeeeee0000000042d8800cccd15eee0500000000000000e33333bab3bbbbb3eeeeeeee444440445555555500000000333333330000000000000000
eeeee000000e00ee0000000042ddddddddd15eee000000660000000ee3bbaaab3bbbbbb3eeeeeeee444440445555555500000000333333330000000000000000
eeee0aaaaaa55a0e000000004211111111115eee00000909990900eee33bbbbb3bbb3bb3eeeeeeee888880885555555500000000333333330000000000000000
eee05aaaaa5575a0000000004555555555555eeee0e00006666660eeee33bb33abb3bbb3eeeeeeee000000005555555500000000333333330000000000000000
e00aa5aa55575a0e00000000eeee111eeeeeeeeee0e0000006660eeeee3baababb3abb33eeeeeeeeeeeeeeeeee666666eeeeeeee333333330000000000000000
00aaaa55a00000ee00000000ee11671eeeeeeeeeee00006666600eeeee33bbbb33ab3b33eeeeeeeeeeeeeeeee67a7a7a6eeeeeee333333330000000000000000
050aaaaa0ffff0ee00000000e1c6771eeeeeeeeeeeeee0066600eeeeeee3333333a3b33eeeeeeeeeeeeeeeeee5a7a7a75eeeeeee333333330000000000000000
050aaaaa0f0000ee00000000e16771c111111eeeeeeeee00000eeeeeeeee33bbb3b333eeeeeeeeeeeeeeeeeee555555555eeeeee333333330000000000000000
0500aa0a0ffcf0ee0000000016771c17777771eeeeeeee000000eeeeeeeee33333333eeeeeeeeeeeeeeeeeeee5aaaaaaa50eeeee333333330000000000000000
055000f0fff0f0ee000000001661c1577755771eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee09999999050eeee333333330000000000000000
050000fffffff00e00000000111c16757577771eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000b00eeee333333330000000000000000
00050000ffff006000000000ee1167077707771eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee005550a0500eeeee333333330000000000000000
050000000000000000000000e8e167777777771eeeee3e33eeeee3ee0000000000000000eee000000eeeeeee00550a055000eeee333333330000000000000000
000000660000000e00000000e8e167000007771eeee3b3bb333e333e0000000000000000e0055555500eeeeeee0000000eeeeeee333333330000000000000000
0000090999090000000000008ee167700077771eee3bbbbbbbb3bbb30000000000000000e06666666000eeeeeeeeeeeeeeeeeeee333333330000000000000000
e0e00006666660ee00000000eeee1666666771eee3bbbbbb33bbb3b30000000000000000000000000800eeeeeeeeeeeeeeeeeeee333333330000000000000000
e0e0000006660eee00000000eeee1111111111eee3b3b3b3bbbb3bb30000000000000000005550a0500eeeeeeeeeeeeeeeeeeeee333333330000000000000000
ee00006666600eee00000000eee17c6ccc7c71ee3bbbbb3bbb33bb3e000000000000000000550a055000eeeeeeeeeeeeeeeeeeee333333330000000000000000
eeeee0066600eeee00000000ee177c66777c771e3bbb3bbbb3ee3b3e0000000000000000ee0000000eeeeeeeeeeeeeeeeeeeeeee333333330000000000000000
eeeeee00000eeeee00000000e1777ccccccc77713bb3e3bbb3eee3ee0000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee333333330000000000000000
eeeeee000000eeee00000000e1677ccccccc7761e3b3e3bbb3eee3ee000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000e176777787777671e3b3e3bb3eeeeeee000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000e177777878777771e3b3e3bb3eeeeeee000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000e177177777771771ee3eee3b3eeeeeee000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000e166167777771661eeeeeee3eeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000ee1116777777111eeeebeeeeeeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000eeee167777771eeeeee3beebeeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000eeee166666771eeeeeee3ee3eeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000
9eeeeeee0000000000000000eeeeeeeeeeeeeeeee77eeeeeeeeeeeee000000000000003333000330300000033000000030000300000000033000033000033330
5e5e5eee0000000000000000eeeeeeeeeeeeeeee7777eeeeeeeeeeee00033333333000b33300033b30003333333003333333330333300033330033330003b3b0
5ee555ee0000000000000000eeeeeeeeeeeee77776777eeeeeeeeeee0003bb333bb300b3bb000bb3b0033b3b33330bb33bb33b03b3b000b3bb00bb3b0000b300
5ee55eee0000000000000000eeeeeeeeeeee777777622222eeeeeeee000bb0bbb3bb00bb3b000bbbb00b3bbbbb3b0bbbbbbb3b0bbb0000bbbb00b3bb0000bb00
e5ee5eee0000000000000000eeeeeeeeeee277070778888822eeeeee000bb000bbbb00bbbb000bbbb00bbbbb0bbb00b0bbb0b00bbbb000bbbb00bbbb000bb000
e55555ee0000000000000000eeeeeeeee228770707788888882eeeee00bbb00bbbbb00bbbb000bbbb00bbbbb0b0b00b0bbb000b0bbb000bbbbb0bbbb000bb000
ee5555550000000000000000eeeeeeee28877777777228888882eeee00bbb000bbbb00bbbb000bbbb00bbbb00b0b0000bbb00000bbb000bbbbb0bbbb000b0000
ee55555e0000000000000000eeeeeeee288777707777e28888882eee00bbb000bbbb00bbbb000bbbb00bbbb0000b00b0bbb00000bbb000bbbbb0bbbb000b0000
ee5555ee0000000000000000eeeeeee2888777777777ee22888882ee000bb000bbbb00bbb0000bbbb000bbb0000b0000bbb00000bb0000bbbbb0bbbb00000000
ee5555ee0000000000000000eeeeee2888887700777677ee288882ee000bbbbbbbb000bbb0000bbb0000bbbb00000000bbb00000bb0000bbbbb00bbb00000000
ee5555ee0000000000000000eeeeee2888887770776777722888882e000bbbbbbb0000bbb0000bbb000000bbbb000000bbb0000bbb0000bbb0b0bbbb00000000
ee55555e0000000000000000eeeee28888776777777772288888882e000bbbbbbbb000bbb0000bbb0000000bbbb00000bbb0000bbb0000bbb0bbbbbb00000000
ee55555e0000000000000000e7eee28887777777777228888888882e000bbb0bbbbb00bbb0000bbb0000000bbbbb0000bbb0000bbb0000bbb0bbbbbb00000000
ee55555e0000000000000000ee7ee288777777777228888822288827000bbb00bbbb00bbb0000bbb0000000bbbbb0000bbb00000bb000bbbb0bbbbbb00000000
ee55555e0000000000000000e767e77777777772288888827778877e000bbb00bbbb00bbbb000bbb00000000bbbb0000bbb00000bb000bbbb0bbbbbb00000000
e55555550000000000000000ee77776777777228888882276777772e000bb000bbbb00bbbb000bbb000bbb000bbbb000bbb0000bbb000bbbb0bbbbbb00000000
555555550000000000000000e7e7767777722888888227777677777700bbb0000bbb00bbbb000bbb00bbbb000bbbb000bbb0000bbb000bbbb00bbbbb00000000
e555555e0000000000000000eeee728882288888822777776777772e000bbb00bbbb00bbbbb00bbb00bbbbb0bbbb0000bb00000bbb000bbbb00bbbbb00000000
e555555e0000000000000000eeeee28888888882277777777628887e000bbbbbbbbb000bbbbbbbbb00bbbbbbbbbb0000bb00000bbb000bbbb000bbbb00000000
e555555e0000000000000000eeeee28888888227777777777728882e00bbbbbbbbb000b0bbbbbbb0000b0bbbbbbb0000bb00000bbb0000bbb000bbbb00000000
e555555e0000000000000000eeeeee2888882777777777777288882e000bb0000000000b0bbbbb00000000bbb0bb0000bb000000bb00000b00000bb000000000
e555555e0000000000000000eeeeee2888882e76667777772888882e0000b000000000000b000b000000000b000b0000b000000bbb000b00b00000b000000000
e555555e0000000000000000eeeeeee288882e7777667772888882ee000000000000000000000b0000000000000b000000000000b0000b00000000b000000000
555555550000000000000000eeeeeee2888882777777772888882eee00000000000000000b0000000000000b00000000b0000000b00000000000000000000000
000000000000000000000000eeeeeeee28888822222222888882eeeeee0000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000eeeeeeeee288888888888888882eeeeeee0000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeee2288888888888822eeeeeeee0000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeee228888888822eeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeeeee22222222eeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeeeeeee000eeeeeeeeeeeeeeeee000000e00eeeee000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000
000000000000000000000000eeeeeeeeeeeeee0077700eeeeeeeeeeeeee0aaaaaa55a0eee04440e0000000eeeeee000000000eeeee0000000000eeee00000000
000000000000000000000000eeeeeeeeeeeee0777777700eeeeeeeeeee05aaaaa5575a0ee04444044444440eeee04404444000eee00000001100eeee00000000
000000000000000000000000eeeeeeeeeeee077776677770eeeeeeee00aa5aa55575a0eee04442444444440eee0440f0440ff0eee0000001000eeeee00000000
000000000000000000000000eeeeeeeeeee07777777600770eeeeeee0aaaa55a00000eeeee042444400000eeee040fff00fff0ee00000000000eeeee00000000
000000000000000000000000eeeeeeeeeee070777070ee00eeeeeeeee0aaaaa0ffff0eeeeee044400ffff0eeee0440fffffff0ee0010000fff0eeeee00000000
000000000000000000000000ee0eeeeeeee077070770eeeeeeee0eeee0aaaaa0f0000eeeeee0440ffff000eeee04440ffff000ee01000fffff0eeeee00000000
000000000000000000000000e070ee0eeee077878770eeee0ee070eeee0aa0a0ffcf0eeeeee04000000f30eeee04200ffffcf0ee01000000000eeeee00000000
000000000000000000000000ee070070eee077777770eee070070eeeeee00f0fff7f0eeeeee00f0fff0f70eeee020f0ffff7f0ee000f0fff0f00eeee00000000
000000000000000000000000e000770eee07707070770eee077000eeeeee0fffffff0eeeeeee0ffffff000eeeee00ffffffff0ee00ffffff00f00eee00000000
0000000000000000000000000777770eee07770707770eee0777770eeeeee00ffff00eeeeeee00fffffff0eeeeeee00ffff00eeee00fffffffff0eee00000000
000000000000000000000000e00777700076777777767000777700eeeeeeeee0000eeeeeeeeeee0ffff00eeeeeeeeee0000eeeeeeee00fffff00eeee00000000
000000000000000000000000ee066777777767877877777777660eeeeeeeeeeeeeeeeeeeeeeeeee0000eeeeeeeeeeeeeeeeeeeeeeeeee00000eeeeee00000000
000000000000000000000000e06006777777777887777777660060eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000
000000000000000000000000ee0ee000666777877877766000ee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000
000000000000000000000000eeeeeeee000677777777700eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000
000000000000000000000000eeeeeeeeee077777777760eeeeeeeeeeee000e00000eeeeeeeeeeeee000eeeeeeeee00000000eeeeee000000000eeeee00000000
000000000000000000000000eeeeeeeeee067777777770eeeeeeeeeee044404444400eeeeeeee0002020eeeeeee04444445500eee0000000000eeeee00000000
000000000000000000000000eeeeeeeeee0677777777770eeeeeeeee04442444444440eeeee0020200000eeeee054444455750ee00000000000eeeee00000000
000000000000000000000000eeeeeeeeee0677777777770eeeeeeeee044244444444440eee02000020000eeee04255455575f0ee00000000440eeeee00000000
000000000000000000000000eeeeeeeeee0677677777770eeeeeeeee020444440000440eee00200000000eeee044225000555eee00004444440eeeee00000000
000000000000000000000000eeeeeeeeeee067767777770eeeeeeeee04042420ffff040ee02000044440eeeee044440fffff0eee00004444440eeeee00000000
000000000000000000000000eeeeeeeeeee067767767770eeeeeeeee02024240f00000eee00000040000eeeee044400ff0000eee00000440000eeeee00000000
000000000000000000000000eeeeeeeeeeee07777776770eeeeeeeeee0402020ffdf0eeeee0400044140eeeee0440f0fffcf0eee00440444140eeeee00000000
000000000000000000000000eeeeeeeeeeee067677777770eeeeeeeee0200f0fff7f0eeeeee040444f40eeeeee00ff0fff7f0eee00440444f40eeeee00000000
000000000000000000000000eeeeeeeeeeee067767767770eeeeeeeee0200fffffff0eeeeee044444440eeeeeee0ffffffff0eeee0004444440eeeee00000000
000000000000000000000000eeeeeeeeeeee0677767677770eeeeeeeee0ee00ffff00eeeeeee00444400eeeeeeee000ffff00eeeeeee0444400eeeee00000000
000000000000000000000000eeeeeeeeeeeee0667777677770000eeeeeeeeee0000eeeeeeeeeee0000eeeeeeeeeeeee0000eeeeeeeeee0000eeeeeee00000000
000000000000000000000000eeeeeeeeeeeeee0066777677777770eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000
000000000000000000000000eeeeeeeeeeeeeeee0077776677700eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000
000000000000000000000000eeeeeeeeeeeeeeeeee007777700eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000
000000000000000000000000eeeeeeeeeeeeeeeeeeee00000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b000000000b1b00000d0000001b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1b0c0b0c0b1b1b0c1b0b0c0c1b0b0d0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0002000017160121600d160091600516001160137001470014700296002c600276001f60023600146000a600076000b60008600076000a6000760005600026000c60008600026000b60005600016000060000600
00080000326653266526655266551a6451a6450e6350e63532605266051a6050e60532605266051a6050e6052b1002b1002b1022b1022b1022b1022b1022b1022b1022b102261002610026100001000010000100
00050000026000260003601056010c6210663108621096350f6300b6350c64010645016401264514640166401a6401a6551c6502065521650236552565027650086502b6552e6603066535660396653b6603f675
01050000042300d23517230242302e230362353c23001205042300d23517230242352e230362353c23013200042300d23517230242352e230362353c23007200042300d23517230242352e230362353c2300d205
000800001c15016150101500c15009150051500314001130011200120001200012000120001200012000320001200012000320003200032000220002200012000220001200000000000000000000000000000000
000500001225013250182501c2501e250202500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010f00000b3500b3350b3500b3350b3550e355123501233515350153301535015335103501033010350103350b3500b3350b3500b3350b3550e35512350123351535015330153501533510350103301035010335
010f00000b3500b3500b3500b3500b3500b3500b3500b3500b3500b3500b3500b3550935009350093500935009350093500935009350093500935009350093500935009350093500935009350093500935009352
010f00000835008350083500835008350083500835008350083500835008350083550435004350043500435004350043500435004350043500435004350043500435004350043500435004350043500435004352
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010f00002330023300233022330223302233022330223302263002630026302263022630226302263022630218733187231873318723187431873318743187331875318743187531874318763187531877318763
010f00000b7730b7003c6452d60021650216351c6053c6450b7730b7003c6450b7032d650216350b6013c6550b7730b6003c6450b6012d650216350b6013c6550b7730b6003c6450b7002d65021635006003c665
010f00000b7730b7003c6452d60021650216353c6453c6050b7730b7003c6450b7032d650216353c6453c6250b7730b6003c6450b6012d650216350b6013c6550b7730b6002d650216350b773216002d65021635
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010f00002747027470234702347527470274522744227432234001d40021400214050040000400234751e47523470254751e4701e475234702345023432234222140021400214001e4021e4001e4050040000400
010f0000234701e4711e4751e4751e4701e4521e4421e432234001d400214002140536661126612a4001e4011e6601e6651e6601e665234002340023402234022140021400214001e4021e4001e4050040000400
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010f00002f3002f300233752337527370273522337023355253702535221370213550000000000000000000000000000002131023331233752337523375233752137021355233702335500000000000000000000
010f00002f3002f300233752337527370273522337023355253702535221370213550000000000000000000000000000002130023301233752337523375233752137021355253702535223370233550000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010f00002637026370263702337023375273022637026370263702337023375213052637026370263702337023375000002637026370263702337023375233052637026375233702337521375223752337023375
010f00002a3502a3502a3502635026355273022a3502a3502a3502635026355213052a3502a3502a3502635026355003002a3502a3502a3502635026355233052a3502a355263502635525355253552635026355
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010f00000b4600b4600b4500b4500b4400b4400b4300b420134601346013450134501344013440134301342012460124601245012450124401244012430124201146011460114501145011440114401143011420
010f000010460104601045010450104401044010430104201a4601a4601a4501a4501a4401a4401a4301a42016460164601645016450164401644016430164201642016420164301643016440164401645016460
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010f00002334023340233322333223322233222331223312263402634026332263322632226322263122631225340253402533225332253222532225312253122134021340213322133221322213222131221312
010f00001a3401a3401a3321a3321a3221a3221a3121a3122a3402a3402a3322a3322a3222a3222a3122a31225340253402534225342253322533225332253322532225322253222532225312253122531225312
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010f00002740027400234002340527400274022740227402234001d40021400214053b661236612a4051e40123663236652366323665234002340023402234022140021400214001e4021e4001e4050040000400
010f00002747027470234702347527470274522744227432234001d40021400214050040000400234751e47523470254751e4701e475234702345023432234222140021400214001e4021e4001e4050040000400
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 32395444
00 333a1444
00 0a154344
00 0a155e68
01 0a155e28
00 0a165e29
00 0a155e1e
00 0a153c1f
00 0a155e1e
00 0a163c1f
00 0b2c4316
00 0c2c4316
00 0b2c2d16
02 0c2c2d16
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

