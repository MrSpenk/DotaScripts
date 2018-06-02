local Kunkka = {}

Kunkka.optionEnable = Menu.AddOptionBool({ "Hero Specific", "Kunkka" }, "Activation", false)
Kunkka.optionComboKey = Menu.AddKeyOption({ "Hero Specific", "Kunkka" }, "Combo Key", Enum.ButtonCode.BUTTON_CODE_NONE)
Kunkka.optionAttack = Menu.AddOptionBool({ "Hero Specific", "Kunkka" }, "Attack during combo", true)
Kunkka.optionComboType = Menu.AddOptionCombo({ "Hero Specific", "Kunkka" }, "Combo Type", {" X-Mark + Torrent", " X-Mark + GhostShip", " X-Mark + Torrent + GhostShip"}, 0)

Kunkka.optionStakerEnable = Menu.AddOptionBool({ "Hero Specific", "Kunkka", "Auto Stacker"}, "Activation", false)
Kunkka.optionStakerKey = Menu.AddKeyOption({ "Hero Specific", "Kunkka", "Auto Stacker"}, "Key on/off stack in spot", Enum.ButtonCode.BUTTON_CODE_NONE)

function Kunkka.init()
	Kunkka.Hero = nil
	Kunkka.Mana = nil
	Kunkka.Target = nil

	Kunkka.Torrent = nil
	Kunkka.XMark = nil
	Kunkka.Ship = nil

	Kunkka.MarkPos = Vector()
	Kunkka.ComboType = 0

	Kunkka.sizeBar = 32
	Kunkka.needStacker = false
	Kunkka.AnchentPoint = {
	{Vector(73,-1860,384),false},
	{Vector(476, -4677, 384), false},
	{Vector(2547, 93, 384), false},
	{Vector(3911,-575,256), false},
	{Vector(-2766, 4551, 256), false},
	{Vector(3911,-575,256), false},
	{Vector(-1882, 4191, 256), false},
	{Vector(-4271, 3549, 255), false} }
end

function Kunkka.OnGameStart()
	Kunkka.init()
end

function Kunkka.OnGameEnd()
	Kunkka.init()
end

Kunkka.init()

function Kunkka.OnUpdate()
	if not Menu.IsEnabled( Kunkka.optionEnable ) then return end
	
	Kunkka.Hero = Heroes.GetLocal()
	if not Kunkka.Hero or NPC.GetUnitName(Kunkka.Hero) ~= "npc_dota_hero_kunkka" then return end
		
	Kunkka.Mana = NPC.GetMana(Kunkka.Hero)

	Kunkka.ComboType = Menu.GetValue( Kunkka.optionComboType )
	
	Kunkka.Torrent = NPC.GetAbility(Kunkka.Hero, "kunkka_torrent")
	Kunkka.Splash = NPC.GetAbility(Kunkka.Hero, "kunkka_tidebringer")
	Kunkka.XMark = NPC.GetAbility(Kunkka.Hero, "kunkka_x_marks_the_spot")
	Kunkka.Ship = NPC.GetAbility(Kunkka.Hero, "kunkka_ghostship")
	

	if Menu.IsKeyDown( Kunkka.optionComboKey ) then	
		local enemy = Kunkka.getComboTarget()
		if enemy and Kunkka.heroCanCast( Kunkka.Hero ) and NPC.IsEntityInRange(Kunkka.Hero, enemy, Ability.GetCastRange(Kunkka.XMark)) then
			Kunkka.LockTarget(enemy)
			if Kunkka.Target == nil then return end
			
			if Kunkka.ComboType == 0 then
				if not NPC.HasModifier(Kunkka.Target, "modifier_kunkka_x_marks_the_spot") then
					if Ability.IsCastable( Kunkka.XMark, Kunkka.Mana ) and Ability.IsReady( Kunkka.XMark ) then
						Ability.CastTarget(Kunkka.XMark, Kunkka.Target)
						Kunkka.MarkPos = Entity.GetAbsOrigin( Kunkka.Target )
					end
				else
					local castTorrent = NPC.GetTimeToFacePosition(Kunkka.Hero, Kunkka.MarkPos) + (Ability.GetCastPoint(Kunkka.Torrent) + 1.6) + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING)
					local XMarkDieTime = Modifier.GetDieTime(NPC.GetModifier(Kunkka.Target, "modifier_kunkka_x_marks_the_spot")) - GameRules.GetGameTime()

					if Ability.IsReady( Kunkka.Torrent ) and Ability.IsCastable( Kunkka.Torrent, Kunkka.Mana ) and XMarkDieTime <= castTorrent then
						Ability.CastPosition(Kunkka.Torrent, Kunkka.MarkPos)
					end
				end
			elseif Kunkka.ComboType == 1 then
				if not NPC.HasModifier(Kunkka.Target, "modifier_kunkka_x_marks_the_spot") then
					if Ability.IsCastable( Kunkka.XMark, Kunkka.Mana ) and Ability.IsReady( Kunkka.XMark ) then
						Ability.CastTarget(Kunkka.XMark, Kunkka.Target)
						Kunkka.MarkPos = Entity.GetAbsOrigin( Kunkka.Target )
					end
				else
					local castShip = NPC.GetTimeToFacePosition(Kunkka.Hero, Kunkka.MarkPos) + (Ability.GetCastPoint(Kunkka.Ship) + 3.1) + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING)
					local XMarkDieTime = Modifier.GetDieTime(NPC.GetModifier(Kunkka.Target, "modifier_kunkka_x_marks_the_spot")) - GameRules.GetGameTime()

					if Ability.IsReady( Kunkka.Ship ) and Ability.IsCastable( Kunkka.Ship, Kunkka.Mana ) and XMarkDieTime <= castShip then
						Ability.CastPosition(Kunkka.Ship, Kunkka.MarkPos)
					end
				end
			elseif Kunkka.ComboType == 2 then
				if not NPC.HasModifier(Kunkka.Target, "modifier_kunkka_x_marks_the_spot") then
					if Ability.IsCastable( Kunkka.XMark, Kunkka.Mana ) and Ability.IsReady( Kunkka.XMark ) then
						Ability.CastTarget(Kunkka.XMark, Kunkka.Target)
						Kunkka.MarkPos = Entity.GetAbsOrigin( Kunkka.Target )
					end
				else
					local castTorrent = NPC.GetTimeToFacePosition(Kunkka.Hero, Kunkka.MarkPos) + (Ability.GetCastPoint(Kunkka.Torrent) + 1.6) + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING)
					local castShip = NPC.GetTimeToFacePosition(Kunkka.Hero, Kunkka.MarkPos) + (Ability.GetCastPoint(Kunkka.Ship) + 3.1) + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING)
					local XMarkDieTime = Modifier.GetDieTime(NPC.GetModifier(Kunkka.Target, "modifier_kunkka_x_marks_the_spot")) - GameRules.GetGameTime()
							
					if NPC.IsEntityInRange(Kunkka.Hero, enemy, Ability.GetCastRange(Kunkka.Torrent)) and XMarkDieTime  <= castTorrent then
						Ability.CastPosition(Kunkka.Torrent, Kunkka.MarkPos)
					end
							
					if Ability.IsReady( Kunkka.Ship ) and Ability.IsCastable( Kunkka.Ship, Kunkka.Mana ) and XMarkDieTime <= castShip then
						Ability.CastPosition(Kunkka.Ship, Kunkka.MarkPos)
					end
				end
			end
			
			if NPC.HasState(enemy, Enum.ModifierState.MODIFIER_STATE_INVULNERABLE) or not Menu.IsEnabled( Kunkka.optionAttack ) then return end
				Player.AttackTarget(Players.GetLocal(), Kunkka.Hero, Kunkka.Target)
		end
	else
		Kunkka.Target = nil
	end

	if not Menu.IsEnabled( Kunkka.optionStakerEnable ) then Kunkka.needStacker = false return end
	if not Kunkka.Hero or not Kunkka.Torrent then return end
	
	Kunkka.needStacker = true
	
	if GameRules.GetGameState() == 5 and (GameRules.GetGameTime()- GameRules.GetGameStartTime()) > 60 then
		if Ability.IsReady(Kunkka.Torrent) then
			local second = (GameRules.GetGameTime()-GameRules.GetGameStartTime()) % 60
			
			if second >= 60 - 2.6 - NetChannel.GetAvgLatency(Enum.Flow.MAX_FLOWS) then
				for _,camp in pairs(Kunkka.AnchentPoint) do
					if camp[2] and NPC.IsPositionInRange(Kunkka.Hero, camp[1], Ability.GetCastRange(Kunkka.Torrent)) then
						Ability.CastPosition(Kunkka.Torrent,camp[1])
					end
				end
			end
		end
	end
end

function Kunkka.OnDraw()
	if not Kunkka.needStacker then return end
	
	for _,camp in pairs(Kunkka.AnchentPoint) do
		if camp then
			local X,Y,vis = Renderer.WorldToScreen(camp[1])
			if vis then
				if camp[2] then
					Renderer.SetDrawColor(0,255,0,150)
				else
					Renderer.SetDrawColor(255,0,0,150)
				end
				Renderer.DrawFilledRect(X - Kunkka.sizeBar / 2, Y - Kunkka.sizeBar / 2, Kunkka.sizeBar, Kunkka.sizeBar)
			end
		
			if Input.IsCursorInRect(X - Kunkka.sizeBar / 2, Y - Kunkka.sizeBar / 2, Kunkka.sizeBar, Kunkka.sizeBar) then
				if Menu.IsKeyDownOnce(Kunkka.optionStakerKey) then
					camp[2] = not camp[2]
				end
			end
		end
	end
end

function Kunkka.LockTarget(enemy)
	if Kunkka.Target == nil and enemy then 
		Kunkka.Target = enemy 
	end
	
	if Kunkka.Target ~= nil then
		if not Entity.IsAlive(Kunkka.Target) then
			Kunkka.Target = nil
		elseif Entity.IsDormant(Kunkka.Target) then
			Kunkka.Target = nil
		elseif not NPC.IsEntityInRange(Kunkka.Hero, Kunkka.Target, Ability.GetCastRange(Kunkka.XMark)) then
			Kunkka.Target = nil
		end
	end
end

function Kunkka.heroCanCast(Hero)
	if not Hero then return false end
	if not Entity.IsAlive(Hero) then return false end

	if NPC.IsStunned(Hero) then return false end
	if NPC.HasModifier(Hero, "modifier_bashed") then return false end
	if NPC.HasState(Hero, Enum.ModifierState.MODIFIER_STATE_INVULNERABLE) then return false end	
	if NPC.HasModifier(Hero, "modifier_obsidian_destroyer_astral_imprisonment_prison") then return false end
	if NPC.HasModifier(Hero, "modifier_shadow_demon_disruption") then return false end	
	if NPC.HasModifier(Hero, "modifier_invoker_tornado") then return false end
	if NPC.HasState(Hero, Enum.ModifierState.MODIFIER_STATE_HEXED) then return false end
	if NPC.HasModifier(Hero, "modifier_legion_commander_duel") then return false end
	if NPC.HasModifier(Hero, "modifier_axe_berserkers_call") then return false end
	if NPC.HasModifier(Hero, "modifier_winter_wyvern_winters_curse") then return false end
	if NPC.HasModifier(Hero, "modifier_bane_fiends_grip") then return false end
	if NPC.HasModifier(Hero, "modifier_bane_nightmare") then return false end
	if NPC.HasModifier(Hero, "modifier_faceless_void_chronosphere_freeze") then return false end
	if NPC.HasModifier(Hero, "modifier_enigma_black_hole_pull") then return false end
	if NPC.HasModifier(Hero, "modifier_magnataur_reverse_polarity") then return false end
	if NPC.HasModifier(Hero, "modifier_pudge_dismember") then return false end
	if NPC.HasModifier(Hero, "modifier_shadow_shaman_shackles") then return false end
	if NPC.HasModifier(Hero, "modifier_techies_stasis_trap_stunned") then return false end
	if NPC.HasModifier(Hero, "modifier_storm_spirit_electric_vortex_pull") then return false end
	if NPC.HasModifier(Hero, "modifier_tidehunter_ravage") then return false end
	if NPC.HasModifier(Hero, "modifier_windrunner_shackle_shot") then return false end
	if NPC.HasModifier(Hero, "modifier_item_nullifier_mute") then return false end
	
	if NPC.IsChannellingAbility(Hero) then return false end
	if NPC.HasModifier(Hero, "modifier_teleporting") then return false end
	
	return true
end

function Kunkka.getComboTarget()
	local mousePos = Input.GetWorldCursorPos()

	local enemyTable = Heroes.InRadius(mousePos, Ability.GetCastRange(Kunkka.XMark), Entity.GetTeamNum(Kunkka.Hero), Enum.TeamType.TEAM_ENEMY)
	if enemyTable == nil or #enemyTable < 1 then return end

	local nearestTarget = nil
	local distance = 99999

	for i, v in ipairs(enemyTable) do
		if v and Entity.IsHero( v ) and not NPC.IsIllusion( v ) and Entity.GetHealth( v ) > 0 then
			local enemyDist = (Entity.GetAbsOrigin(v) - mousePos):Length2D()
			if enemyDist < distance then
				nearestTarget = v
				distance = enemyDist
			end
		end
	end
	return nearestTarget or nil
end

return Kunkka
