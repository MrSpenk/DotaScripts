local KunkkaStacker = {}

KunkkaStacker.Enable = Menu.AddOptionBool({"Utility", "Kunkka Stacker"}, "Activation", false)
KunkkaStacker.Key = Menu.AddKeyOption({"Utility", "Kunkka Stacker"}, "Key on/off stack in spot", Enum.ButtonCode.BUTTON_CODE_NONE)

function KunkkaStacker.OnUpdate()
	if not Menu.IsEnabled(KunkkaStacker.Enable) then return end
	
	local myHero = Heroes.GetLocal()
	if not myHero then return end
	
	local torrent = NPC.GetAbility(myHero, "kunkka_torrent")
	if not torrent then return end
	
	KunkkaStacker.needStacker = true
	
	if GameRules.GetGameState() == 5 and (GameRules.GetGameTime()- GameRules.GetGameStartTime()) > 60 then
		if Ability.IsReady(torrent) then
			local second = (GameRules.GetGameTime()-GameRules.GetGameStartTime()) % 60
			
			if second >= 60 - 2.6 - NetChannel.GetAvgLatency(Enum.Flow.MAX_FLOWS) then
				for _,camp in pairs(KunkkaStacker.anchentpoint) do
					if camp[2] and NPC.IsPositionInRange(myHero, camp[1], Ability.GetCastRange(torrent)) then
						Ability.CastPosition(torrent,camp[1])
					end
				end
			end
		end
	end
end

function KunkkaStacker.OnDraw()
	if not KunkkaStacker.needStacker then return end
	
	for _,camp in pairs(KunkkaStacker.anchentpoint) do
		if camp then
			local X,Y,vis = Renderer.WorldToScreen(camp[1])
			if vis then
				if camp[2] then
					Renderer.SetDrawColor(0,255,0,150)
				else
					Renderer.SetDrawColor(255,0,0,150)
				end
				Renderer.DrawFilledRect(X - KunkkaStacker.sizeBar / 2, Y - KunkkaStacker.sizeBar / 2, KunkkaStacker.sizeBar, KunkkaStacker.sizeBar)
			end
		
			if Input.IsCursorInRect(X - KunkkaStacker.sizeBar / 2, Y - KunkkaStacker.sizeBar / 2, KunkkaStacker.sizeBar, KunkkaStacker.sizeBar) then
				if Menu.IsKeyDownOnce(KunkkaStacker.Key) then
					camp[2] = not camp[2]
				end
			end
		end
	end
end

function KunkkaStacker.init()
	KunkkaStacker.sizeBar = 32
	KunkkaStacker.needStacker = false
	KunkkaStacker.anchentpoint = {
	{Vector(73,-1860,384),false},
	{Vector(3911,-575,256),false} }
end

function KunkkaStacker.OnGameStart()
	KunkkaStacker.init()
end

function KunkkaStacker.OnGameEnd()
	KunkkaStacker.init()
end

KunkkaStacker.init()

return KunkkaStacker
