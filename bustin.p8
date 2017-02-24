pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
version="1.0"
screen_x,screen_y,screen_w,screen_h=0,0,127,127
ef=function() end
cart_update,cart_draw=ef,ef
cart_control=function(u,d)
	u=u or ef
	d=d or ef
	cart_update,cart_draw=u,d
	t=0
end
--score,lives=0,3
pi=3.14159265359
musicon=off
-- returns random pos value from provided table

meter_x=8
meter_y=116
meter_w=110
meter_h=7
meter_vmax=100
meter_vnow=0
meter_color=11

lanes={3,32,61,90}
kills=0
nofail=false

p_t=0
p_char="holtz"

--#player

function p_reset()
	p_lane=2
	p_x,p_y,p_dir=2,lanes[p_lane],1
	p_power=meter_vmax
	p_cooldown=0
	p_slimed=false
	p_canmove=true
	p_canfire=true
	meter_vnow=0
	
	fire_w=0
	fire_t=0 --needed for sine wave
end

function p_update()
    muzzle_x=p_x+16
    muzzle_y=p_y+12
    
    beam_len=muzzle_x+fire_w --x of end of beam

	firing=false
    p_canmove=true
	p_canfire=true

	if p_slimed then p_canmove=false p_canfire=false end
	
	local vert=1

	if p_slimed and p_t>45 then
		p_slimed=false
		p_canfire=true
	end
		
	
	
	if btnz then
        firing=true
        p_canmove=false
        fire_speed=8
		
        if p_canfire then
			
            for s in all(slimers) do
                if s.lane==p_lane and s.st!=1 then
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
	
	draw_char(p_char, p_x,p_y)
	
	if p_slimed then
		palt(14,true)
		spr(53,p_x,p_y,2,2)
		palt()
	end
	
end

function draw_char(id,x,y)
	--player sprite
	palt(0,false)
	palt(14,true)
	
	spr(5,x,y,2,3)
	if id=="holtz" then spr(151,x+1,y+1,2,2) end --holtz
	if id=="abby" then spr(153,x,y,2,2) end --abby
	if id=="erin" then spr(183,x+1,y+1,2,2) end --erin
	if id=="patty" then spr(185,x+2,y+1,2,2) end --patty
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
			if s.lane==p_lane and s.x<muzzle_x-8 and s.x>0 then
				p_slimed=true
				p_t=0
			end

			if s.x<-16 then
				meter_inc(5)
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
				del(slimers,s)
                kills+=1
			end
		end

		--trapped
		if s.st==3 then
			s.shrink+=1.5
			if s.shrink>=14 then
				del(slimers,s)
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
	for n=1,4 do portal_create(n) end
	
	last_portal=0
	portal_spawn=random(level.portal_spawn,50)
	timer_set("portalspawn")
end

function portal_create(lane)
    add(portals,{
		x=115,
		y=lanes[lane]+10,
		r=5,
		lane=lane,
		hp=level.portal_hp,
		hit=false,t=0,
		spawn=random(30,level.portal_spawn)
	})
end


function portal_update()
	
    for p in all(portals) do
		p.hit=false
		if beam_len>=p.x and p.lane==p_lane then p.hit=true end
		
		
        if p.hit then 
            p.hp-=1
            
            if p.hp<=0 and p.r>0 then
				p.r-=1
				shake=1
				
				--portal is dead
                if p.r<=0 then
					
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
					expl_create(p.x,p.y, 48,{
						dur=15,
						den=5,
						colors={7},
						smin=3,
						smax=8,
						grav=0,
					})
                
                	p.hp=level.portal_hp
                end
            end
            
        else
            p.hit=false 
        end
    
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
			portal_spawn=random(level.portal_spawn,50)

			if not spawnfrom.hit and #slimers<level.slimer_max then
				slimer_create(spawnfrom.lane)
			end
		end
	end
end


function portal_draw()
    for p in all(portals) do
        if p.hit then p.c=rnd_table({8,7,10}) else p.c=0 end
    
		local c=rnd_table({7,10,11,8,9})
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
		
		spr(3,p.x-6,p.y-8,2,2)
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
			if trap_x>40 then trap_st=2 end
		end
		
		if trap_st==2 then
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
		spr(35,puft_x,puft_y,2,3)
		palt()
	end
end








--#meter
meter_bar=0
function meter_update()
	if meter_vnow>0 then
		meter_per=meter_vnow/meter_vmax
		meter_bar=flr(meter_w*meter_per)
	else
		meter_bar=0
	end
	
	if meter_vnow>=meter_vmax then meter_vnow=meter_vmax end
	if meter_vnow<1 then meter_vnow=0 end
end

function meter_full()
	if meter_vnow>=meter_vmax then return true else return false end
end

function meter_percent()
	if meter_vnow>0 then
		return flr((meter_vnow/meter_vmax)*100)
	else
		return 0
	end
end

function meter_inc(v) meter_vnow+=v end
function meter_dec(v) meter_vnow-=v end

function meter_draw()
	palt(0,false)
	rectfill(meter_x,meter_y, meter_x+meter_w,meter_y+meter_h, 0) --progress bar
	rectfill(meter_x,meter_y, meter_x+meter_bar,meter_y+meter_h, meter_color) --progress bar
	rect(meter_x,meter_y, meter_x+meter_w,meter_y+meter_h, 6) --border
	palt()
end








--#charselect

selects={"holtz","erin","abby","patty"}
function charselect_init()
	select_pos=1
	cart_control(charselect_update,charselect_draw)
end

function charselect_update()
	if btnp(1) then select_pos+=1 end
	if btnp(0) then select_pos-=1 end
	if btndp then select_pos+=2 end
	if btnup then select_pos-=2 end
	
	if select_pos<1 then select_pos=1 end
	if select_pos>4 then select_pos=4 end
	
	p_char=selects[select_pos]
	
	if btnzp then scene1_init() end
end

function charselect_draw()
	rectfill(0,0,127,127,1)
	
	center_text("select your ghostbuster",5,7)
	
	draw_char("holtz",30,30)
	print("holtzmann",20,55,7)
	if select_pos==1 then rect(15,20, 60,65, 10) end
	
	draw_char("erin",80,30)
	print("erin",80,55,7)
	if select_pos==2 then rect(65,20, 110,65, 10) end
	
	
	draw_char("abby",30,80)
	print("abby",30,105,7)
	if select_pos==3 then rect(15,70, 60,115, 10) end
	
	draw_char("patty",80,80)
	print("patty",78,105,7)
	if select_pos==4 then rect(65,70, 110,115, 10) end
end



--#game
function game_init()
	slimers={}

	puft_init()

	cart_control(game_update,game_draw)
end

function game_update()
	meter_update()
	p_update()
	slimer_update()
	expl_update()
	portal_update()
	trap_update()
	puft_update()

	if meter_percent()>70 and puft_st<1 then
		puft_st=1
	end
	
	if meter_percent()>100 then
		gameover_init()
	end
	
	if #portals<=0 then
		current_level+=1
		if current_level>4 then
			--rowan_death() --end scene
		else
			scene_init() --continue	
		end
		
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
	meter_draw()
end


function game_drawbg() 
	rectfill(0,0,127,127,0)

	puft_draw(1)
	palt(0,false)
	palt(14,true)
	map(0,0, -60,-2, 16,3) --grey city
	map(0,0, 44,-2, 16,3) --grey city
	rectfill(0,20,127,60, 5)
	skyfade(47,4)
	palt()
	
	
	puft_draw(2)
	palt(0,false)
	palt(14,true)
	pal(5,2) --red city
	map(0,0, 0,25, 16,3) --grey city
	rectfill(0,48,127,127, 2)
	skyfade(73,8)
	palt()
	
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
	map(0,3, 0,lanes[1]+layer_h, 16,1) --1
	map(0,3, 0,lanes[2]+layer_h, 16,1) --2
	map(0,3, 0,lanes[3]+layer_h, 16,1) --3
	map(0,3, 0,lanes[4]+layer_h, 16,1) --4
	
	
	map(0,4, 0,117, 16,1) --4
	map(0,4, 0,125, 16,1) --4
	pal()	
	
end



--#victory screen, you win!
function victory_init()
	camera()
	camera_y=0
	state_ch(1)
	cart_control(victory_update,victory_draw)
end



function victory_update()
	expl_update()
	
	-- intro wait
	if st_is(1) and t>60 then
		st_ch(2)
	end
	
	-- fireworks
	if st_is(2) then
		if timer(1,random(30,60),true) then
			expl_create(rnd(115)+15,rnd(60)+15, 24, {
				dur=30,
				den=1,
				colors={rnd(15)},
				smin=1,
				smax=3,
			})
		end
	
		if t>150 then
			st_add(3)
		end
	end
	
	-- pan camera down to show city and character
	if st_is(3) then
		camera_y+=1
		if camera_y>100 then
			st_rm(3)
			st_add(4)
		end
	end

	-- state4 is in draw(), text timer
	
end



function victory_draw()
	expl_draw()
	
	camera(0,camera_y)

	
	pal(5,2) --red city
	palt(14,true)
	rectfill(0,144+18,127,144+18+80, 2)
	map(0,0, -20,144, 16,3)
	map(0,0, 80,144, 16,3)
	pal()
	
	
	
	pal(5,1) --blue city
	palt(14,true)
	rectfill(0,130+22,127,130+22+127, 1)
	map(0,0, -30,130, 16,3)
	map(0,0, 40,130, 16,3)
	pal()
	
	skyfade(130+95,0)
	
	
	draw_char(p_char, 10,187)
	
	
	if st_is(4) then
		if timer(2,90) then
			center_text("thank you ghostbusters",200, 7)
		end
	end
end





--#over, game over screen
function gameover_init()
	slimedrop={}
	
	cart_control(gameover_update,gameover_draw)
	
	for n=0,16 do
		add(slimedrop,{r=rnd(5)+5,x=8*n,y=rnd(6)*-1})
	end
	
	slimedrop_min=0
end

function gameover_update()
	
	meter_update()
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
	meter_draw()
	
	
	for s in all(slimedrop) do
		circfill(s.x,s.y,s.r,11)
	end

	rectfill(-8,0, 130,slimedrop_min+3, 11)
	
	if slimedrop_min>130 then
		center_text("game over",60,3)
		center_text("press \142 to play again",85,3)
	end
end



--#rowan
function rowan_draw(x,y)
	x=x or rowan_x
	y=y or rowan_y
	
	palt(0,false)
	palt(14,true)
	spr(147, x,y, 4,4)
	palt()
end

function rowan_reset(fn)
	rowan_y=-50
	rowan_x=50
	rowan_a=0
	rowan_next=fn
	
	st_clear(90)
	st_add(90)
end

function rowan_entrance_update()
	tbx_update()
	
	--rowan comes down
	if st_is(90) then
		if rowan_y<35 then rowan_y+=1 else st_chg(91) end
	end
	
	--rowan text, wait for player to continue
	if st_is(91) then
		rowan_a+=0.02
		rowan_y = 35+sin(rowan_a)*4
		
		if not st_is(91.1) then
			if wait(60,true) then
				st_add(91.1)
			end
		else
			if st_is(91.2) then
				if btnzp then st_chg(92) end
			else
				textbox(rowan_text,14,68,7)
				st_add(91.2)
			end
		end
		
	end
	
	--rowan leaves after player continues from textbox (92)
	if st_is(92) then
		-- Levels 1 and 2; Normal up and out exit
		if current_level<=2 then
			if wait(60) then
				if rowan_y>-50 then
					rowan_y-=1
				else
					rowan_next()
				end
			else
				rowan_a+=0.02
				rowan_y = 35+sin(rowan_a)*4
			end
		end
	
		-- Level 3, jumps into frames
		if current_level==3 then
			
		end
		
		-- Level 4...grows? 
		if current_level==4 then
			
		end
			
	end

end

function rowan_entrance_draw()
	rowan_draw()
	
	if st_is(91.1) then
		draw_textbox()
		tbx_draw()
	end
	
	if st_is(91.2) then
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
	meter_vnow=0 --reset slime meter for each level
end


levels={
	{ -- Level 1
		portal_hp=30,
		portal_spawn=15,
		slimer_hp=7,
		slimer_speed=.5,
		slimer_max=7,
		rowan_text="these frames will allow ghosts to enter and take over the world. you won't stop me!"
	},
	{ -- Level 2
		portal_hp=30,
		portal_spawn=15,
		slimer_hp=7,
		slimer_speed=.5,
		slimer_max=7,
		rowan_text="impressive. but i have more frames and stronger ghosts. the end is near!"
	},
	{ -- Level 3
		portal_hp=30,
		portal_spawn=15,
		slimer_hp=7,
		slimer_speed=.5,
		slimer_max=7,
		rowan_text="arg! i must help my ghost army. you can't stop us all!"
	},
	{ -- Level 4
		portal_hp=30,
		portal_spawn=15,
		slimer_hp=7,
		slimer_speed=.5,
		slimer_max=7,
		rowan_text="what?! no! i'll stop you myself, ghostbusters!"
	}
}

function scene_init()
	level=levels[current_level]

	scene_reset()
	portal_reset()
	rowan_reset(game_init)

	cart_control(scene_update,scene_draw)
end

function scene_update()
	rowan_entrance_update()
end

function scene_draw()
	game_drawbg()
	p_draw()
	meter_draw()
	portal_draw()
	
	rowan_entrance_draw()
end











-- #intro
function boot_init()
	play_music(0)
	intro_text("bustin' v"..version..";(c)brian vaughn, 2017;_;_;design+code+art;brian vaughn;_;music+sound;brian follick;_;additional art;unofficial sources;")
	intro_text("_;_;_;for penelope;")
	intro_init(title_init)

	cart_update,cart_draw=ef,intro_draw
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
	
	cart_control(title_update,title_draw)
	
	p_reset()
	puft_init()
	puft_y=25
	
	current_level=1
end

function title_update() 
	logo_xy-=2
	sspr_wh+=3
	
	if sspr_wh>64 then sspr_wh=64 end
	if logo_xy<26 then logo_xy=26 end
	
	if btnzp then charselect_init() end
	
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
	sspr(24,40, 32,32, logo_xy+4,logo_xy-15, sspr_wh,sspr_wh)
	pal()
	
	if sspr_wh>=64 then
		spr(87, 30,logo_xy+38, 9,3)
		center_text("makes me feel good",90,11)
		center_text("press \142 to start",108,7)
	end
end






-- #loop
menuitem(1, "toggle music", function() 
	if musicon then musicon=false music(-1) else musicon=true play_music(0) end
end)	


function _init()
	tbx_init()
	
	--charselect_init()
	--boot_init()
	title_init()
	--game_init()
	--scene1_init()
	--gameover_init()
end

function _update()
	btnl=btn(0)
	btnr=btn(1)
	btnup=btnp(2)
	btndp=btnp(3)
	btnz=btn(4)
	btnx=btn(5)
	btnzp=btnp(4)
	btnxp=btnp(5)
	
	cart_update()
	
	
end


b=0
function _draw()
	cls()

	cart_draw()
	
	--rect(0,0,127,127,5)
	print(debug,1,100,10)
end







-- #utilities and helpers
shake,shake_t=0,0
function screenshake()
	cam_x=0 cam_y=0
	if shake>0 then
		local shaker=1
		if rnd()<.5 then shaker=-random(1,2) end
		
		cam_x+=shaker*rnd_table({-1,1,-1,1})
		cam_y+=shaker*rnd_table({-1,1,-1,1})

		shake_t+=1
		if shake_t>3 then shake=0 shake_t=0 end
	end
	
	camera(cam_x,cam_y)
end


function play_music(track)
	if musicon then music(track) end	
end

	
--#state
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

timers={}
function timer_set(t) timers[t]=0 end
function timer_get(t) return timers[t] end
function timer_rm(t) timers[t]=false end
function timer_is(t,limit)
	limit=limit or 32000
	
	if timers[t] then
		if timer_get(t)>limit then return true end
	end
	return false
end

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
	
	if intro_st>#intro_all then return true else return false end
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
	
	

-- checks to see if value is in a table
function in_table(tbl, element)
  for _, value in pairs(tbl) do
    if value == element then
      return true
    end
  end
  return false
end
	
	
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


function distance(ox,oy, px,py)
  local a = ox-px
  local b = oy-py
  return pythag(a,b)
end

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



function offscreen(x,y)
	if (x<screen_x or x>screen_w or y<screen_y or y>screen_h) then 
		return true
	else
		return false
	end
end

-- returns true if hitbox collision 
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
000000000000000000000000eee4444444444444eeeeeeeeeeeeeeeeeeeee33333eeeeee555555550000000055555555eeeeeeeeeeeeeeee0000000000000000
000000000000000000000000eee4222222222225eeeeeeeeeeeeeeeeeeee33bbb33eeeee525252526666666659595555eeeeeeeeeeeeeeee0000000000000000
007007000000000000000000eee42ddddddddd15eeeeeeeeeeeeeeeeeee33bbabb33eeee222222224444444454545555eeeeeeeeeeeeeeee0000000000000000
000770000000000000000000eee42d9990fffd15eeeeeeeeeeeeeeeee333bbaabbb33eee44444444000000005555555555555555eee55eee0000000000000000
000770000000000000000000eee42d09900ffd15eeeeeeeeeeeeeeeee3baabbbbbbb3eee44444444444404445555595955595955ee5555ee0000000000000000
007007000000000000000000eee42d009900fd15000eeeeeeeeeeeee3337bbbbbbbb33eed4d4d4d4888808885555545455545455e555555e0000000000000000
000000000000000000000000eee42d0009900d15050eeeeeeeeeeeee333773bb3bbbb3eedddddddd000000005555555555555555555555550000000000000000
000000000000000000000000eee42d0c00000d1505000eeeeeeeeeee33b07bbbb3bbb3ee55555555eeeeeeee5555555555555555555555550000000000000000
000000000000000000000000eee42d00ccc00d15050000eeeeeeeeeee3bbbb3bb3bbb3eeeeeeeeee440444445555555500000000333333330000000000000000
000000000000000000000000eee42d800ccc0d15055000eeeeeeeeeee333333bbbbbb33eeeeeeeee440444445555555500000000333333330000000000000000
000000000000000000000000eee42d808ccccd1505000000eeeeee0ee3b33bbbbbbbbb33eeeeeeee880888885555555500000000333333330000000000000000
000000000000000000000000eee42d8800cccd150005000000000060e3bbab33b3bbb3b3eeeeeeee000000005555555500000000333333330000000000000000
eeeeeeeeeeeeeeee00000000eee42d8800cccd150500000000000000e33333bab3bbbbb3eeeeeeee444440445555555500000000333333330000000000000000
eeeee000000e00ee00000000eee42ddddddddd15000000660000000ee3bbaaab3bbbbbb3eeeeeeee444440445555555500000000333333330000000000000000
eeee0aaaaaa55a0e00000000eee411111111111500000909990900eee33bbbbb3bbb3bb3eeeeeeee888880885555555500000000333333330000000000000000
eee05aaaaa5575a000000000eee4555555555555e0e00006666660eeee33bb33abb3bbb3eeeeeeee000000005555555500000000333333330000000000000000
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
000000000000000000000000eeeeeeeeeeeeeeeee77eeeeeeeeeeeee000000000000003333000330300000033000000030000300000000033000033000033330
000000000000000000000000eeeeeeeeeeeeeeee7777eeeeeeeeeeee00033333333000b33300033b30003333333003333333330333300033330033330003b3b0
000000000000000000000000eeeeeeeeeeeee77776777eeeeeeeeeee0003bb333bb300b3bb000bb3b0033b3b33330bb33bb33b03b3b000b3bb00bb3b0000b300
000000000000000000000000eeeeeeeeeeee777777622222eeeeeeee000bb0bbb3bb00bb3b000bbbb00b3bbbbb3b0bbbbbbb3b0bbb0000bbbb00b3bb0000bb00
000000000000000000000000eeeeeeeeeee277070778888822eeeeee000bb000bbbb00bbbb000bbbb00bbbbb0bbb00b0bbb0b00bbbb000bbbb00bbbb000bb000
000000000000000000000000eeeeeeeee228770707788888882eeeee00bbb00bbbbb00bbbb000bbbb00bbbbb0b0b00b0bbb000b0bbb000bbbbb0bbbb000bb000
000000000000000000000000eeeeeeee28877777777228888882eeee00bbb000bbbb00bbbb000bbbb00bbbb00b0b0000bbb00000bbb000bbbbb0bbbb000b0000
000000000000000000000000eeeeeeee288777707777e28888882eee00bbb000bbbb00bbbb000bbbb00bbbb0000b00b0bbb00000bbb000bbbbb0bbbb000b0000
000000000000000000000000eeeeeee2888777777777ee22888882ee000bb000bbbb00bbb0000bbbb000bbb0000b0000bbb00000bb0000bbbbb0bbbb00000000
000000000000000000000000eeeeee2888887700777677ee288882ee000bbbbbbbb000bbb0000bbb0000bbbb00000000bbb00000bb0000bbbbb00bbb00000000
000000000000000000000000eeeeee2888887770776777722888882e000bbbbbbb0000bbb0000bbb000000bbbb000000bbb0000bbb0000bbb0b0bbbb00000000
000000000000000000000000eeeee28888776777777772288888882e000bbbbbbbb000bbb0000bbb0000000bbbb00000bbb0000bbb0000bbb0bbbbbb00000000
000000000000000000000000e7eee28887777777777228888888882e000bbb0bbbbb00bbb0000bbb0000000bbbbb0000bbb0000bbb0000bbb0bbbbbb00000000
000000000000000000000000ee7ee288777777777228888822288827000bbb00bbbb00bbb0000bbb0000000bbbbb0000bbb00000bb000bbbb0bbbbbb00000000
000000000000000000000000e767e77777777772288888827778877e000bbb00bbbb00bbbb000bbb00000000bbbb0000bbb00000bb000bbbb0bbbbbb00000000
000000000000000000000000ee77776777777228888882276777772e000bb000bbbb00bbbb000bbb000bbb000bbbb000bbb0000bbb000bbbb0bbbbbb00000000
000000000000000000000000e7e7767777722888888227777677777700bbb0000bbb00bbbb000bbb00bbbb000bbbb000bbb0000bbb000bbbb00bbbbb00000000
000000000000000000000000eeee728882288888822777776777772e000bbb00bbbb00bbbbb00bbb00bbbbb0bbbb0000bb00000bbb000bbbb00bbbbb00000000
000000000000000000000000eeeee28888888882277777777628887e000bbbbbbbbb000bbbbbbbbb00bbbbbbbbbb0000bb00000bbb000bbbb000bbbb00000000
000000000000000000000000eeeee28888888227777777777728882e00bbbbbbbbb000b0bbbbbbb0000b0bbbbbbb0000bb00000bbb0000bbb000bbbb00000000
000000000000000000000000eeeeee2888882777777777777288882e000bb0000000000b0bbbbb00000000bbb0bb0000bb000000bb00000b00000bb000000000
000000000000000000000000eeeeee2888882e76667777772888882e0000b000000000000b000b000000000b000b0000b000000bbb000b00b00000b000000000
000000000000000000000000eeeeeee288882e7777667772888882ee000000000000000000000b0000000000000b000000000000b0000b00000000b000000000
000000000000000000000000eeeeeee2888882777777772888882eee00000000000000000b0000000000000b00000000b0000000b00000000000000000000000
000000000000000000000000eeeeeeee28888822222222888882eeeeee0000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000eeeeeeeee288888888888888882eeeeeee0000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeee2288888888888822eeeeeeee0000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeee228888888822eeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeeeee22222222eeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeeeeeee000eeeeeeeeeeeeeeeee000000e00eeeee000eeeeeeeeeee0000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeeeee0077700eeeeeeeeeeeeee0aaaaaa55a0eee04440e0000000ee0000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeeee0777777700eeeeeeeeeee05aaaaa5575a0ee04444044444440e0000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeee077776677770eeeeeeee00aa5aa55575a0eee04442444444440e0000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeee07777777600770eeeeeee0aaaa55a00000eeeee042444400000ee0000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeee070777070ee00eeeeeeeee0aaaaa0ffff0eeeeee044400ffff0ee0000000000000000000000000000000000000000
000000000000000000000000ee0eeeeeeee077070770eeeeeeee0eeee0aaaaa0f0000eeeeee0440ffff000ee0000000000000000000000000000000000000000
000000000000000000000000e070ee0eeee077878770eeee0ee070eeee0aa0a0ffcf0eeeeee04000000f30ee0000000000000000000000000000000000000000
000000000000000000000000ee070070eee077777770eee070070eeeeee00f0fff7f0eeeeee00f0fff0f70ee0000000000000000000000000000000000000000
000000000000000000000000e000770eee07707070770eee077000eeeeee0fffffff0eeeeeee0ffffff000ee0000000000000000000000000000000000000000
0000000000000000000000000777770eee07770707770eee0777770eeeeee00ffff00eeeeeee00fffffff0ee0000000000000000000000000000000000000000
000000000000000000000000e00777700076777777767000777700eeeeeeeee0000eeeeeeeeeee0ffff00eee0000000000000000000000000000000000000000
000000000000000000000000ee066777777767877877777777660eeeeeeeeeeeeeeeeeeeeeeeeee0000eeeee0000000000000000000000000000000000000000
000000000000000000000000e06006777777777887777777660060eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000
000000000000000000000000ee0ee000666777877877766000ee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000
000000000000000000000000eeeeeeee000677777777700eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeee077777777760eeeeeeeeeeee000e00000eeeeeeeeeeeee000eeeee0000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeee067777777770eeeeeeeeeee044404444400eeeeeeee0002020eeee0000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeee0677777777770eeeeeeeee04442444444440eeeee0020200000eee0000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeee0677777777770eeeeeeeee044244444444440eee02000020000eee0000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeee0677677777770eeeeeeeee020444440000440eee00200000000eee0000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeee067767777770eeeeeeeee04042420ffff040ee02000044440eeee0000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeee067767767770eeeeeeeee02024240f00000eee00000040000eeee0000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeee07777776770eeeeeeeeee0402020ffdf0eeeee0400044140eeee0000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeee067677777770eeeeeeeee0200f0fff7f0eeeeee040444f40eeee0000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeee067767767770eeeeeeeee0200fffffff0eeeeee044444440eeee0000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeee0677767677770eeeeeeeee0ee00ffff00eeeeeee00444400eeee0000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeeee0667777677770000eeeeeeeeee0000eeeeeeeeeee0000eeeeee0000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeeeee0066777677777770eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeeeeeee0077776677700eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeeeeeeeee007777700eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeeeeeeeeeee00000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000
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
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

