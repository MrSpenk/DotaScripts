local Kunkka = {}

Kunkka.optionEnable = Menu.AddOptionBool({ "Hero Specific", "Kunkka" }, "Activation", false)
Kunkka.optionComboKey = Menu.AddKeyOption({ "Hero Specific", "Kunkka" }, "Combo Key", Enum.ButtonCode.BUTTON_CODE_NONE)

Kunkka.optionTargetCheckAM = Menu.AddOptionBool({ "Hero Specific", "Kunkka", "Check the enemy" }, "AM Shield", true)
Kunkka.optionTargetCheckLotus = Menu.AddOptionBool({ "Hero Specific", "Kunkka", "Check the enemy" }, "Lotus Orb", true)
Kunkka.optionTargetCheckBlademail = Menu.AddOptionBool({ "Hero Specific", "Kunkka", "Check the enemy" }, "Blade Mail", true)
Kunkka.optionTargetCheckNyx = Menu.AddOptionBool({ "Hero Specific", "Kunkka", "Check the enemy" }, "NyXMark Carapace", true)
Kunkka.optionTargetCheckAbbadon = Menu.AddOptionBool({ "Hero Specific", "Kunkka", "Check the enemy" }, "Abaddon Ultimate", true)

Kunkka.optionTargetRange = Menu.AddOptionSlider({ "Hero Specific", "Kunkka" }, "Target search range", 50, 1000, 400)

Kunkka.optionStakerEnable = Menu.AddOptionBool({ "Hero Specific", "Kunkka", "Auto Stacker"}, "Activation", false)
Kunkka.optionStakerKey = Menu.AddKeyOption({ "Hero Specific", "Kunkka", "Auto Stacker"}, "Key on/off stack in spot", Enum.ButtonCode.BUTTON_CODE_NONE)

function Kunkka.init()
	Kunkka.lastTick = 0
	Kunkka.ComboTimer = 0
	Kunkka.XMarkCastTime = 0
	Kunkka.XMarkPos = Vector()
	
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

  	local Torrent = NPC.GetAbility(myHero, "kunkka_torrent")
 	local XMark = NPC.GetAbility(myHero, "kunkka_x_marks_the_spot")
	local XMarkreturn = NPC.GetAbility(myHero, "kunkka_return")
	local Ship = NPC.GetAbility(myHero, "kunkka_ghostship")

	local myMana = NPC.GetMana(myHero)

	if os.clock() < Kunkka.lastTick then return end

	local enemy = Kunkka.getComboTarget(myHero)
	if Kunkka.Target == nil then Kunkka.Target = enemy end
	
	if Kunkka.ComboTimer < os.clock() then
		if Kunkka.Target and Entity.IsAlive(Kunkka.Target) and not NPC.HasState(Kunkka.Target, Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) and not NPC.IsLinkensProtected(Kunkka.Target) and Kunkka.heroCanCastSpells(myHero, Kunkka.Target) == true then
			if not NPC.HasModifier(Kunkka.Target, "modifier_kunkka_x_marks_the_spot") then
				if Menu.IsKeyDownOnce(Kunkka.optionComboKey) then
					if Ship and Ability.IsCastable(Ship, myMana) and NPC.IsEntityInRange(myHero, Kunkka.Target, Ability.GetCastRange(Ship)) then
						if XMark and Ability.IsCastable(XMark, myMana) and NPC.IsEntityInRange(myHero, Kunkka.Target, Ability.GetCastRange(XMark)) then
							Ability.CastTarget(XMark, Kunkka.Target)
							Kunkka.XMarkPos = Entity.GetAbsOrigin(Kunkka.Target)
							Kunkka.XMarkCastTime = os.clock() + 1
							Kunkka.lastTick = os.clock() + 0.1
							return
						end
					else
						if XMark and Ability.IsCastable(XMark, myMana) and NPC.IsEntityInRange(myHero, Kunkka.Target, Ability.GetCastRange(XMark)) then
							Ability.CastTarget(XMark, Kunkka.Target)
							Kunkka.XMarkPos = Entity.GetAbsOrigin(Kunkka.Target)
							Kunkka.ComboTimer = os.clock() + 3.08
							Kunkka.XMarkCastTime = os.clock() + 1
							Kunkka.lastTick = os.clock() + 0.1
							return
						end
					end
				end
			else
				if Ship and Ability.IsCastable(Ship, myMana) and NPC.IsEntityInRange(myHero, Kunkka.Target, Ability.GetCastRange(Ship)) then
					Ability.CastPosition(Ship, Kunkka.XMarkPos)
					Kunkka.ComboTimer = os.clock() + 3.08
					Kunkka.lastTick = os.clock() + 0.1
					return
				end
			end
		end
	else
		if Kunkka.ComboTimer - os.clock() <= 2.05 then
			if Torrent and Ability.IsCastable(Torrent, myMana) then
				Ability.CastPosition(Torrent, Kunkka.XMarkPos)
				Kunkka.lastTick = os.clock() + 0.1
				return
			end
		end

		if Kunkka.ComboTimer - os.clock() <= 0.55 then
			if XMarkreturn and Ability.IsCastable(XMarkreturn, myMana) then
				Ability.CastNoTarget(XMarkreturn)
				Kunkka.lastTick = os.clock() + 0.1
				Kunkka.Target = nil
				return
			end
		end
	end
	
	if not Menu.IsEnabled( Kunkka.optionStakerEnable ) then Kunkka.needStacker = false return end
	local Torrent = NPC.GetAbility(myHero, "kunkka_torrent")
	if not myHero or not Torrent then return end
	
	Kunkka.needStacker = true
	
	if GameRules.GetGameState() == 5 and (GameRules.GetGameTime()- GameRules.GetGameStartTime()) > 60 then
		if Ability.IsReady(Torrent) then
			local second = (GameRules.GetGameTime()-GameRules.GetGameStartTime()) % 60
			
			if second >= 60 - 2.6 - NetChannel.GetAvgLatency(Enum.Flow.MAXMark_FLOWS) then
				for _,camp in pairs(Kunkka.AnchentPoint) do
					if camp[2] and NPC.IsPositionInRange(myHero, camp[1], Ability.GetCastRange(Torrent)) then
						Ability.CastPosition(Torrent,camp[1])
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

function Kunkka.heroCanCastSpells(myHero, enemy)

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

	if enemy then
		if NPC.HasModifier(enemy, "modifier_item_aeon_disk_buff") then return false end
	end

	return true	

end

function Kunkka.targetChecker(genericEnemyEntity)

	local myHero = Heroes.GetLocal()
		if not myHero then return end

	if genericEnemyEntity and not Entity.IsDormant(genericEnemyEntity) and not NPC.IsIllusion(genericEnemyEntity) and Entity.GetHealth(genericEnemyEntity) > 0 then

		if Menu.IsEnabled(Kunkka.optionTargetCheckAM) then
			if NPC.GetUnitName(genericEnemyEntity) == "npc_dota_hero_antimage" and NPC.HasItem(genericEnemyEntity, "item_ultimate_scepter", true) and NPC.HasModifier(genericEnemyEntity, "modifier_antimage_spell_shield") and Ability.IsReady(NPC.GetAbility(genericEnemyEntity, "antimage_spell_shield")) then return end
		end
		
		if Menu.IsEnabled(Kunkka.optionTargetCheckLotus) then
			if NPC.HasModifier(genericEnemyEntity, "modifier_item_lotus_orb_active") then return end
		end
		
		if Menu.IsEnabled(Kunkka.optionTargetCheckBlademail) then
			if NPC.HasModifier(genericEnemyEntity, "modifier_item_blade_mail_reflect") and Entity.GetHealth(Heroes.GetLocal()) <= 0.25 * Entity.GetMaxHealth(Heroes.GetLocal()) then return end
		end
		
		if Menu.IsEnabled(Kunkka.optionTargetCheckNyx) then
			if NPC.HasModifier(genericEnemyEntity, "modifier_nyx_assassin_spiked_carapace") then return end 
		end	
		
		if NPC.HasModifier(genericEnemyEntity, "modifier_ursa_enrage") then return end
		
		if Menu.IsEnabled(Kunkka.optionTargetCheckAbbadon) then
			if NPC.HasModifier(genericEnemyEntity, "modifier_abaddon_borrowed_time") then return end
		end
		
		if NPC.HasModifier(genericEnemyEntity, "modifier_dazzle_shallow_grave") and NPC.GetUnitName(myHero) ~= "npc_dota_hero_axe" then return end

		if NPC.HasModifier(genericEnemyEntity, "modifier_skeleton_king_reincarnation_scepter_active") then return end
		
		if NPC.HasModifier(genericEnemyEntity, "modifier_winter_wyvern_winters_curse") then return end

	return genericEnemyEntity
	end	
end

function Kunkka.getComboTarget(myHero)
	if not myHero or Kunkka.Target then return end

	local targetingRange = Menu.GetValue(Kunkka.optionTargetRange)
	local mousePos = Input.GetWorldCursorPos()

	local enemyTable = Heroes.InRadius(mousePos, targetingRange, Entity.GetTeamNum(myHero), Enum.TeamType.TEAM_ENEMY)
	if enemyTable == nil or #enemyTable < 1 then return end

	local nearestTarget = nil
	local distance = 99999

	for i, v in ipairs(enemyTable) do
		if v and Entity.IsHero(v) then
			if Kunkka.targetChecker(v) ~= nil then
				local enemyDist = (Entity.GetAbsOrigin(v) - mousePos):Length2D()
				if enemyDist < distance then
					nearestTarget = v
					distance = enemyDist
				end
			end
		end
	end

	return nearestTarget or nil

end

return Kunkka
