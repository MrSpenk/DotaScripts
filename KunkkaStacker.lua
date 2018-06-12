local KunkkaStacker = {}

KunkkaStacker.optionStakerEnable = Menu.AddOptionBool({ "Hero Specific", "Kunkka", "Auto Stacker"}, "Activation", false)
KunkkaStacker.optionStakerKey = Menu.AddKeyOption({ "Hero Specific", "Kunkka", "Auto Stacker"}, "Key on/off stack in spot", Enum.ButtonCode.BUTTON_CODE_NONE)

function KunkkaStacker.init()
	KunkkaStacker.sizeBar = 32
	KunkkaStacker.needStacker = false
	KunkkaStacker.AnchentPoint = {
	{Vector(73,-1860,384),false},
	{Vector(476, -4677, 384), false},
	{Vector(2547, 93, 384), false},
	{Vector(3911,-575,256), false},
	{Vector(-2766, 4551, 256), false},
	{Vector(3911,-575,256), false},
	{Vector(-1882, 4191, 256), false},
	{Vector(-4271, 3549, 255), false} }
end

function KunkkaStacker.OnGameStart()
	KunkkaStacker.init()
end

function KunkkaStacker.OnGameEnd()
	KunkkaStacker.init()
end

KunkkaStacker.init()

function KunkkaStacker.OnUpdate()
	if not Menu.IsEnabled( KunkkaStacker.optionStakerEnable ) then 
		KunkkaStacker.needStacker = false
	return end
	
	local myHero = Heroes.GetLocal()
	if not myHero or NPC.GetUnitName(myHero) ~= "npc_dota_hero_kunkka" then return end

	local Torrent = NPC.GetAbility(myHero, "kunkka_torrent")
	if not Torrent then return end
	
	KunkkaStacker.needStacker = true
		
	if GameRules.GetGameState() == 5 and (GameRules.GetGameTime()- GameRules.GetGameStartTime()) > 60 then
		if Ability.IsReady( Torrent ) and Ability.IsCastable( Torrent, NPC.GetMana(myHero) ) then
			local second = (GameRules.GetGameTime()-GameRules.GetGameStartTime()) % 60
			if second >= 60 - 2.6 - NetChannel.GetAvgLatency(Enum.Flow.MAX_FLOWS) then
				for _,camp in pairs(KunkkaStacker.AnchentPoint) do
					if camp[2] and NPC.IsPositionInRange(myHero, camp[1], Ability.GetCastRange( Torrent )) then
						Ability.CastPosition( Torrent , camp[1] )
					end
				end
			end
		end
	end
end

function KunkkaStacker.OnDraw()
	if not KunkkaStacker.needStacker then return end
	
	for _,camp in pairs(KunkkaStacker.AnchentPoint) do
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
				if Menu.IsKeyDownOnce(KunkkaStacker.optionStakerKey) then
					camp[2] = not camp[2]
				end
			end
		end
	end
end

return KunkkaStacker