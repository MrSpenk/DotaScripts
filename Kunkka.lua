local Kunkka = {}

KunkkaStaker.optionEnable = Menu.AddOptionBool({ "Hero Specific", "Kunkka", "Auto Stacker"}, "Activation", false)
KunkkaStaker.optionrKey = Menu.AddKeyOption({ "Hero Specific", "Kunkka", "Auto Stacker"}, "Key on/off stack in spot", Enum.ButtonCode.BUTTON_CODE_NONE)

function KunkkaStaker.init()
	KunkkaStaker.sizeBar = 32
	KunkkaStaker.needStacker = false
	KunkkaStaker.AnchentPoint = {
	{Vector(73,-1860,384),false},
	{Vector(476, -4677, 384), false},
	{Vector(2547, 93, 384), false},
	{Vector(3911,-575,256), false},
	{Vector(-2766, 4551, 256), false},
	{Vector(3911,-575,256), false},
	{Vector(-1882, 4191, 256), false},
	{Vector(-4271, 3549, 255), false} }
end

function KunkkaStaker.OnGameStart()
	KunkkaStaker.init()
end

function KunkkaStaker.OnGameEnd()
	KunkkaStaker.init()
end

function KunkkaStaker.OnUpdate()
	if not Menu.IsEnabled( KunkkaStaker.optionEnable ) then return end
	
	local myHero = Heroes.GetLocal()
	if not myHero or NPC.GetUnitName(myHero) ~= "npc_dota_hero_kunkka" then return end

	local Torrent = NPC.GetAbility(myHero, "kunkka_torrent")
	local myMana = NPC.GetMana(myHero)
	
	if Menu.IsEnabled( KunkkaStaker.optionEnable ) then
		if not myHero or not Torrent then return end
	
		KunkkaStaker.needStacker = true
		
		if GameRules.GetGameState() == 5 and (GameRules.GetGameTime()- GameRules.GetGameStartTime()) > 60 then
			if Ability.IsReady( Torrent ) and Ability.IsCastable( Torrent, myMana ) then
				local second = (GameRules.GetGameTime()-GameRules.GetGameStartTime()) % 60
				if second >= 60 - 2.6 - NetChannel.GetAvgLatency(Enum.Flow.MAX_FLOWS) then
					for _,camp in pairs(KunkkaStaker.AnchentPoint) do
						if camp[2] and NPC.IsPositionInRange(myHero, camp[1], Ability.GetCastRange( Torrent )) then
							Ability.CastPosition( Torrent , camp[1] )
						end
					end
				end
			end
		end
	else KunkkaStaker.needStacker = false end
end

function KunkkaStaker.OnDraw()
	if not KunkkaStaker.needStacker then return end
	
	for _,camp in pairs(KunkkaStaker.AnchentPoint) do
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
				if Menu.IsKeyDownOnce(KunkkaStaker.optionrKey) then
					camp[2] = not camp[2]
				end
			end
		end
	end
end

KunkkaStaker.init()

return Kunkka
