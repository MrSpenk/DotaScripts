local KunkkaStaker = {}

KunkkaStaker.Enable = Menu.AddOptionBool({"Utility", "Kunkka Staker"}, "Activation", false)
KunkkaStaker.Key = Menu.AddKeyOption({"Utility", "Kunkka Staker"}, "Key on/off stack in spot", Enum.ButtonCode.BUTTON_CODE_NONE)

function KunkkaStaker.OnUpdate()
	if not Menu.IsEnabled(KunkkaStaker.Enable) then return end
	
	local myHero = Heroes.GetLocal()
	if not myHero then return end
	
	local torrent = NPC.GetAbility(myHero, "kunkka_torrent")
	if not torrent then return end
	
	KunkkaStaker.needStaker = true
	
	if GameRules.GetGameState() == 5 and (GameRules.GetGameTime()- GameRules.GetGameStartTime()) > 60 then
		if Ability.IsReady(torrent) then
			local second = (GameRules.GetGameTime()-GameRules.GetGameStartTime()) % 60
			
			if second >= 60 - 2.6 - NetChannel.GetAvgLatency(Enum.Flow.MAX_FLOWS) then
				for _,camp in pairs(KunkkaStaker.anchentpoint) do
					if camp[2] and NPC.IsPositionInRange(myHero, camp[1], Ability.GetCastRange(torrent)) then
						Ability.CastPosition(torrent,camp[1])
					end
				end
			end
		end
	end
end

function KunkkaStaker.OnDraw()
	if not KunkkaStaker.needStaker then return end
	
	for _,camp in pairs(KunkkaStaker.anchentpoint) do
		if camp then
			local X,Y,vis = Renderer.WorldToScreen(camp[1])
			if vis then
				if camp[2] then
					Renderer.SetDrawColor(0,255,0,150)
				else
					Renderer.SetDrawColor(255,0,0,150)
				end
				Renderer.DrawFilledRect(X - KunkkaStaker.sizeBar / 2, Y - KunkkaStaker.sizeBar / 2, KunkkaStaker.sizeBar, KunkkaStaker.sizeBar)
			end
		
			if Input.IsCursorInRect(X - KunkkaStaker.sizeBar / 2, Y - KunkkaStaker.sizeBar / 2, KunkkaStaker.sizeBar, KunkkaStaker.sizeBar) then
				if Menu.IsKeyDownOnce(KunkkaStaker.Key) then
					camp[2] = not camp[2]
				end
			end
		end
	end
end

function KunkkaStaker.init()
	KunkkaStaker.sizeBar = 32
	KunkkaStaker.needStaker = false
	KunkkaStaker.anchentpoint = {
	{Vector(-2969,-119, 384),false},
	{Vector(69,-1860,384),false},
	{Vector(-851, 2263, 384),false},
	{Vector(3911,-575,256),false} }
end

function KunkkaStaker.OnGameStart()
	KunkkaStaker.init()
end

function KunkkaStaker.OnGameEnd()
	KunkkaStaker.init()
end

KunkkaStaker.init()

return KunkkaStaker