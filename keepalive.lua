-- title:  KeepAlive
-- author: @DrEvilBrain
-- desc:   Made for Ludum Dare 46 (Keep it alive)
-- script: lua

COLS=30
ROWS=17
LIFE=5 --how many dropped packets allowed
SPAWN_T=60 --default time between obj spawns
SPEEDUP=25 --how many pkts per speedup
DIFFUP=25 --how many pkts per diffup

t=0 --time
x=22 --player x pos
y=64 -- player y pos
received=0 --score
dropped=0 --packets dropped
mwDropped=0 --malware dropped
speed=1 --game speed
diff=SPAWN_T --game difficulty
toNextSpeed=SPEEDUP --how many more pkts needed to next speedup
toNextDiff=DIFFUP --how many more pkts needed to next diffup

menu=true --main menu boolean
tutorial=false --tutorial boolean
gameover=false --game over boolean
spawnT=60 --time between obj spawns
objs={} --onscreen objects table

SPAWN={ --object spawner locations
	drop=24,
 x=210,
	y1=24,
	y2=48,
	y3=72,
	y4=96,
	y5=120
}

OBJ={ --table of possible objects
	pkt0=256,
	pkt1=257,
	pktBad=258,
	xmark=272,
	checkmark=273,
	question=274
}

function mainMenu()
	local text="KEEPALIVE"..
 "                                     "..
	"                                     "..
	"                         "
	cls()
	if btnp(4) then
		menu=false
		tutorial=true
	end
	local color=1
 for x=0,29 do
  for y=0,16 do
   color=(color+1)%#text
   l=(color-math.floor(t))%#text
   print(text:sub(l,l),x*8,y*8,3)
  end
 end
	print("KEEPALIVE",68,52,15,false,2)
	print("PRESS Z TO START",77,72,15)
	print("@",0,130,14)
	print("DrEvilBrain, made for LD46",6,130,14,false,1,true)
 t=t+0.2
end

function playTutorial()
	map(30,0,30,17,0,0)
	print("How To Play",53,8,15,true,2)
	print("Move with the arrow keys.",47,106,15,true,1)
	print("Pick up packets, avoid malware.",24,116,15,true,1)
	print("Drop 5 packets and the connection dies!",4,126,15,true,1)
	if btnp(4)==true then
		tutorial=false
		resetGame()
	end
end

function gameManager()
	if gameover==false then
		rendGame()
		
		if spawnT==0 then
			spawnObj()
			spawnT=diff
		end
		spawnT=spawnT-1
		updateObjs()
		
		playerController()
		
		speedUp()
		diffUp()
		t=t+1
	end
end

function TIC()
	if menu==true then
		mainMenu()
	elseif tutorial==true then
		playTutorial()
	else
		gameManager()
		if btnp(4) then
			resetGame()
		end
	end
end

function resetGame()
	t=0
	objs={}
	rendGame()
	sfx(16,0,0,0) --empty sound channels
	sfx(16,0,0,1)
	sfx(16,0,0,2)
	sfx(16,0,0,3)
	music(0) --play canyon.mid
	received=0
	dropped=0
	mwDropped=0
	speed=1
	diff=SPAWN_T
	toNextSpeed=SPEEDUP
	toNextDiff=DIFFUP
	gameover=false
end

function rendGame()
	map(0,0,30,17,0,0)
	renderUI()
	spr(480,x,y,0,1,0,0,2,2) --player
end

function renderUI()
	print("Packets Received: "..received,0,0)
	print("Packets Dropped: "..dropped.."/"..mwDropped,0,8)
	print("Uptime: "..t//60,0,130)
end

local function gameOverMalware()
	music()
	sfx(03,"C#3",180,0)
	rendGame() --refresh score
	spr(482,x,y,0,1,0,0,2,2) --player
	spr(238,8,16,0,1,0,0,2,2) --servers
	spr(238,8,40,0,1,0,0,2,2)
	spr(238,8,64,0,1,0,0,2,2)
	spr(238,8,88,0,1,0,0,2,2)
	spr(238,8,112,0,1,0,0,2,2)
	spr(226,216,16,0,1,0,0,2,2) --computers
	spr(226,216,40,0,1,0,0,2,2)
	spr(226,216,64,0,1,0,0,2,2)
	spr(226,216,88,0,1,0,0,2,2)
	spr(226,216,112,0,1,0,0,2,2)
	gameover=true
	print("GAME OVER",64,63,8,true,2)
	print("PRESS Z TO RESTART",71,84,8)
end

local function gameOverPktLoss()
	music()
	sfx(02,"C#3",180,0)
	rendGame() --refresh score
	spr(486,x,y,0,1,0,0,2,2) --player
	spr(206,8,16,0,1,0,0,2,2) --servers
	spr(206,8,40,0,1,0,0,2,2)
	spr(206,8,64,0,1,0,0,2,2)
	spr(206,8,88,0,1,0,0,2,2)
	spr(206,8,112,0,1,0,0,2,2)
	spr(228,216,16,0,1,0,0,2,2) --computers
	spr(228,216,40,0,1,0,0,2,2)
	spr(228,216,64,0,1,0,0,2,2)
	spr(228,216,88,0,1,0,0,2,2)
	spr(228,216,112,0,1,0,0,2,2)
	gameover=true
	print("GAME OVER",64,63,14,true,2)
	print("PRESS Z TO RESTART",71,84,14)
end

local function isCollision()
	for i=1,#objs do
		local o=objs[i]
		if y+8==o.y and x+8>o.x and x<o.x+2 then
			if o.name==OBJ.pktBad then
				gameOverMalware()
				return
			else
				sfx(00,"C#6",20,1)
			end
			table.remove(objs,i)
			return true
		end
	end 
	return false
end

function playerController()
	if btnp(0,10,5) then y=y-24 end
	if btnp(1,10,5) then y=y+24 end
	if btn(2) then x=x-1.5 end
	if btn(3) then x=x+1.5 end
	
	if y<16 then y=112 end
	if y>112 then y=16 end
	if x<22 then x=22 end
	if x>110 then x=110 end
	
	if isCollision() then
		received=received+1
		toNextSpeed=toNextSpeed-1
		toNextDiff=toNextDiff-1
	end
end

function spawnObj()
	local xPos=SPAWN.x
	local row=math.random(1,5)
	local num=math.random(1,3)
	local obj=math.random(1,3)
	
	if row==1 then row=SPAWN.y1
	elseif row==2 then row=SPAWN.y2
	elseif row==3 then row=SPAWN.y3
	elseif row==4 then row=SPAWN.y4
	elseif row==5 then row=SPAWN.y5 end
	
	if obj==3 then o=OBJ.pktBad end
	
	for i=1,num do
		if obj==1 or obj==2 then obj=math.random(1,2) end
		if obj==1 then o=OBJ.pkt0
		elseif obj==2 then o=OBJ.pkt1 end
		makeObj(o,xPos,row,1)
		xPos=xPos-8
	end
end

function makeObj(objName,xPos,yPos,moveT)
	local o={name=objName,x=xPos,y=yPos,t=moveT}
	table.insert(objs,o)
end

local function moveObj(obj)
	local xVel=speed
	if obj.t==0 then
		obj.x=obj.x-xVel
		obj.t=1
	else
		obj.t=obj.t-1
	end
end

local function rendObjs()
	for i=1,#objs do
		local o=objs[i]
		spr(o.name,o.x,o.y,0,1,0,0,1,1)
	end
end

function updateObjs()
	for i=#objs,1,-1 do
		local o=objs[i]
		moveObj(o)
		
		--obj goes past player
		if o.x<SPAWN.drop then
			if o.name==OBJ.pktBad then mwDropped=mwDropped+1
			elseif o.name==OBJ.pkt0 or o.name==OBJ.pkt1 then
				dropped=dropped+1
				if dropped >= LIFE then
					gameOverPktLoss()
					return
				end
				sfx(01,"C#2",30,3)
			end
			table.remove(objs,i)
		end
	end
	rendObjs()
end

function speedUp()
	if toNextSpeed==0 then
		speed=speed+0.5
		toNextSpeed=SPEEDUP
	end
end

function diffUp()
	if toNextDiff==0 then
		diff=diff-10
		toNextDiff=DIFFUP
	end
	if diff<10 then diff=10 end
end 
