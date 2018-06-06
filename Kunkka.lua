local Kunkka = {}

Kunkka.optionEnable = Menu.AddOptionBool({ "Hero Specific", "Kunkka" }, "Activation", false)

Kunkka.optionShipComboKey = Menu.AddKeyOption({ "Hero Specific", "Kunkka" }, "Full Combo", Enum.ButtonCode.BUTTON_CODE_NONE)
Kunkka.optionTorrentComboKey = Menu.AddKeyOption({ "Hero Specific", "Kunkka" }, "Torrent Combo", Enum.ButtonCode.BUTTON_CODE_NONE)

Kunkka.optionTargetRange = Menu.AddOptionSlider({ "Hero Specific", "Kunkka" }, "Radius around the cursor", 100, 500, 150)

Kunkka.optionTargetCheckAM = Menu.AddOptionBool({ "Hero Specific", "Kunkka", "Check the enemy" }, "AM Shield", true)
Kunkka.optionTargetCheckLotus = Menu.AddOptionBool({ "Hero Specific", "Kunkka", "Check the enemy" }, "Lotus Orb", true)
Kunkka.optionTargetCheckBlademail = Menu.AddOptionBool({ "Hero Specific", "Kunkka", "Check the enemy" }, "Blade Mail", true)
Kunkka.optionTargetCheckNyx = Menu.AddOptionBool({ "Hero Specific", "Kunkka", "Check the enemy" }, "NyXMark Carapace", true)
Kunkka.optionTargetCheckAbbadon = Menu.AddOptionBool({ "Hero Specific", "Kunkka", "Check the enemy" }, "Abaddon Ultimate", true)

Kunkka.optionStakerEnable = Menu.AddOptionBool({ "Hero Specific", "Kunkka", "Auto Stacker"}, "Activation", false)
Kunkka.optionStakerKey = Menu.AddKeyOption({ "Hero Specific", "Kunkka", "Auto Stacker"}, "Key on/off stack in spot", Enum.ButtonCode.BUTTON_CODE_NONE)

function Kunkka.init()
	Kunkka.Target = nil

	Kunkka.lastTick = 0
	Kunkka.ComboTimer = 0
	Kunkka.XMarkCastTime = 0
	Kunkka.XMarkPos = Vector()
	
	Kunkka.startShipCombo = false
	
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
	
	local myHero = Heroes.GetLocal()
	if not myHero or NPC.GetUnitName(myHero) ~= "npc_dota_hero_kunkka" then return end

	local Q = NPC.GetAbility(myHero, "kunkka_torrent")
 	local X = NPC.GetAbility(myHero, "kunkka_x_marks_the_spot")
	local Xreturn = NPC.GetAbility(myHero, "kunkka_return")
	local Ship = NPC.GetAbility(myHero, "kunkka_ghostship")
	
	local myMana = NPC.GetMana(myHero)
	
	if os.clock() < Kunkka.lastTick then return end
	
	Kunkka.Target = Kunkka.getComboTarget(myHero)
	
	if Kunkka.ComboTimer < os.clock() then
		if Kunkka.Target and Kunkka.heroCanCastSpells(myHero) then
			if not NPC.HasModifier(Kunkka.Target, "modifier_kunkka_x_marks_the_spot") then
				if Menu.IsKeyDownOnce(Kunkka.optionShipComboKey) then
					if X and Ability.IsCastable(X, myMana) and NPC.IsEntityInRange(myHero, Kunkka.Target, Ability.GetCastRange(X)) then
						Kunkka.startShipCombo = true
						Kunkka.XMarkPos = Entity.GetAbsOrigin(Kunkka.Target)
						Ability.CastTarget(X, Kunkka.Target)
						Kunkka.XMarkCastTime = os.clock() + 1
						Kunkka.lastTick = os.clock() + 0.1
					end
					if not(Ship and Ability.IsCastable(Ship, myMana) and NPC.IsEntityInRange(myHero, Kunkka.Target, Ability.GetCastRange(Ship))) then
						Kunkka.startShipCombo = false
						Kunkka.ComboTimer = os.clock() + 3.08
					end
					
					return
				end
			
				if Menu.IsKeyDownOnce(Kunkka.optionTorrentComboKey) then
					if X and Ability.IsCastable(X, myMana) and NPC.IsEntityInRange(myHero, Kunkka.Target, Ability.GetCastRange(X)) then
						Kunkka.startShipCombo = false
						Kunkka.XMarkPos = Entity.GetAbsOrigin(Kunkka.Target)	
						Ability.CastTarget(X, Kunkka.Target)
						Kunkka.XMarkCastTime = os.clock() + 1
						Kunkka.ComboTimer = os.clock() + 3.08
						Kunkka.lastTick = os.clock() + 0.1
					end
					
					return
				end
			else
				if Kunkka.startShipCombo then
					if Ship and Ability.IsCastable(Ship, myMana) and NPC.IsEntityInRange(myHero, Kunkka.Target, Ability.GetCastRange(Ship)) then
						Ability.CastPosition(Ship, Kunkka.XMarkPos)
						Kunkka.ComboTimer = os.clock() + 3.08
						Kunkka.lastTick = os.clock() + 0.1
					end
				end
				
				return
			end
		end
	else
		if Kunkka.ComboTimer - os.clock() <= 2.05 then
			if Q and Ability.IsCastable(Q, myMana) then
				Ability.CastPosition(Q, Kunkka.XMarkPos)
				Kunkka.lastTick = os.clock() + 0.1
			end
		end

		if Kunkka.ComboTimer - os.clock() <= 0.55 then
			if Xreturn and Ability.IsCastable(Xreturn, myMana) then
				Ability.CastNoTarget(Xreturn)
				Kunkka.lastTick = os.clock() + 0.1
				return
			end
		end
		
		if Kunkka.ComboTimer - os.clock() <= 0.1 then
			Kunkka.Target = nil
			Kunkka.XMarkPos = nil
			startShipCombo = false
			return
		end
	end
	
--------------------------------------------------- Auto Stacker ---------------------------------------------------
	if not Menu.IsEnabled( Kunkka.optionStakerEnable ) then Kunkka.needStacker = false return end
	if not myHero or not Q then return end
	
	Kunkka.needStacker = true
	
	if GameRules.GetGameState() == 5 and (GameRules.GetGameTime()- GameRules.GetGameStartTime()) > 60 then
		if Ability.IsReady(Q) then
			local second = (GameRules.GetGameTime()-GameRules.GetGameStartTime()) % 60
			if second >= 60 - 2.6 - NetChannel.GetAvgLatency(Enum.Flow.MAX_FLOWS) then
				for _,camp in pairs(Kunkka.AnchentPoint) do
					if camp[2] and NPC.IsPositionInRange(myHero, camp[1], Ability.GetCastRange(Q)) then
						Ability.CastPosition(Q,camp[1])
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

function Kunkka.OnPrepareUnitOrders(orders)
	local myHero = Heroes.GetLocal()
	if myHero and NPC.GetUnitName(myHero) == "npc_dota_hero_kunkka" and Kunkka.ComboTimer > os.clock() and Kunkka.XMarkCastTime > os.clock() then
		local Q = NPC.GetAbility(myHero, "kunkka_torrent")
		local Xreturn = NPC.GetAbility(myHero, "kunkka_return")
		local Ship = NPC.GetAbility(myHero, "kunkka_ghostship")
		if Kunkka.XMarkCastTime - os.clock() < 1 and Kunkka.XMarkCastTime - os.clock() > 0 and Ability.IsReady(Ship) then
			return false
		elseif Kunkka.ComboTimer - os.clock() < 2.25 and Kunkka.ComboTimer - os.clock() > 1.75 and Ability.IsReady(Q) then
			return false
		elseif Kunkka.ComboTimer - os.clock() < 0.80 and Kunkka.ComboTimer - os.clock() > 0.30 and not Ability.IsHidden(Xreturn) then
			return false
		elseif Q and Ability.IsInAbilityPhase(Q) then
			return false
		elseif Xreturn and Ability.IsInAbilityPhase(Xreturn) then
			return false
		elseif Ship and Ability.IsInAbilityPhase(Ship) then
			return false
		end
	end
end

function Kunkka.heroCanCastSpells(myHero)
	
	if not myHero then return false end
	if not Entity.IsAlive(myHero) then return false end

	if NPC.IsSilenced(myHero) then return false end
	if NPC.IsStunned(myHero) then return false end
	if NPC.HasModifier(myHero, "modifier_bashed") then return false end
	if NPC.HasState(myHero, Enum.ModifierState.MODIFIER_STATE_INVULNERABLE) then return false end	
	if NPC.HasModifier(myHero, "modifier_eul_cyclone") then return false end
	if NPC.HasModifier(myHero, "modifier_obsidian_destroyer_astral_imprisonment_prison") then return false end
	if NPC.HasModifier(myHero, "modifier_shadow_demon_disruption") then return false end	
	if NPC.HasModifier(myHero, "modifier_invoker_tornado") then return false end
	if NPC.HasState(myHero, Enum.ModifierState.MODIFIER_STATE_HEXED) then return false end
	if NPC.HasModifier(myHero, "modifier_legion_commander_duel") then return false end
	if NPC.HasModifier(myHero, "modifier_axe_berserkers_call") then return false end
	if NPC.HasModifier(myHero, "modifier_winter_wyvern_winters_curse") then return false end
	if NPC.HasModifier(myHero, "modifier_bane_fiends_grip") then return false end
	if NPC.HasModifier(myHero, "modifier_bane_nightmare") then return false end
	if NPC.HasModifier(myHero, "modifier_faceless_void_chronosphere_freeze") then return false end
	if NPC.HasModifier(myHero, "modifier_enigma_black_hole_pull") then return false end
	if NPC.HasModifier(myHero, "modifier_magnataur_reverse_polarity") then return false end
	if NPC.HasModifier(myHero, "modifier_pudge_dismember") then return false end
	if NPC.HasModifier(myHero, "modifier_shadow_shaman_shackles") then return false end
	if NPC.HasModifier(myHero, "modifier_techies_stasis_trap_stunned") then return false end
	if NPC.HasModifier(myHero, "modifier_storm_spirit_electric_vortex_pull") then return false end
	if NPC.HasModifier(myHero, "modifier_tidehunter_ravage") then return false end
	if NPC.HasModifier(myHero, "modifier_windrunner_shackle_shot") then return false end
	if NPC.HasModifier(myHero, "modifier_item_nullifier_mute") then return false end

	return true
end

function Kunkka.targetChecker(genericEnemyEntity, myHero)
	if not myHero then return end

	if genericEnemyEntity and not Entity.IsDormant(genericEnemyEntity) and not NPC.IsIllusion(genericEnemyEntity) and Entity.GetHealth(genericEnemyEntity) > 0 then

		if NPC.IsLinkensProtected(genericEnemyEntity) then return end
		
		if NPC.HasState(genericEnemyEntity, Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) then return end
	
		if Menu.IsEnabled(Kunkka.optionTargetCheckAM) then
			if NPC.GetUnitName(genericEnemyEntity) == "npc_dota_hero_antimage" and NPC.HasItem(genericEnemyEntity, "item_ultimate_scepter", true) and NPC.HasModifier(genericEnemyEntity, "modifier_antimage_spell_shield") and Ability.IsReady(NPC.GetAbility(genericEnemyEntity, "antimage_spell_shield")) then return end
		end
		
		if Menu.IsEnabled(Kunkka.optionTargetCheckLotus) then
			if NPC.HasModifier(genericEnemyEntity, "modifier_item_lotus_orb_active") then return end
		end
		
		if Menu.IsEnabled(Kunkka.optionTargetCheckBlademail) then
			if NPC.HasModifier(genericEnemyEntity, "modifier_item_blade_mail_reflect") and Entity.GetHealth(myHero) <= 0.25 * Entity.GetMaxHealth(myHero) then return end
		end
		
		if Menu.IsEnabled(Kunkka.optionTargetCheckNyx) then
			if NPC.HasModifier(genericEnemyEntity, "modifier_nyx_assassin_spiked_carapace") then return end 
		end	
		
		if Menu.IsEnabled(Kunkka.optionTargetCheckAbbadon) then
			if NPC.HasModifier(genericEnemyEntity, "modifier_abaddon_borrowed_time") then return end
		end
		
		if NPC.HasModifier(genericEnemyEntity, "modifier_dazzle_shallow_grave") and NPC.GetUnitName(myHero) ~= "npc_dota_hero_axe" then return end

		if NPC.HasModifier(genericEnemyEntity, "modifier_skeleton_king_reincarnation_scepter_active") then return end
		
		if NPC.HasModifier(genericEnemyEntity, "modifier_winter_wyvern_winters_curse") then return end

		if NPC.HasModifier(genericEnemyEntity, "modifier_item_aeon_disk_buff") then return end
		
	return genericEnemyEntity
	end	
end

function Kunkka.getComboTarget(myHero)
	if not myHero then return end

	local targetingRange = Menu.GetValue(Kunkka.optionTargetRange)
	local mousePos = Input.GetWorldCursorPos()

	local enemy = Input.GetNearestHeroToCursor(Entity.GetTeamNum(myHero), Enum.TeamType.TEAM_ENEMY)
	
	if enemy then
		local enemyDist = (Entity.GetAbsOrigin(enemy) - mousePos):Length2D()
		if enemyDist <= targetingRange then
			if Kunkka.targetChecker(enemy, myHero) ~= nil then return enemy end
		end
	end
	return nil
end

return Kunkka
