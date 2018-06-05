local Lina = {}

Lina.optionEnable = Menu.AddOptionBool({ "Hero Specific", "Lina" }, "Eul's Combo", false)
Lina.optionComboKey = Menu.AddKeyOption({ "Hero Specific", "Lina" }, "Combo Key", Enum.ButtonCode.BUTTON_CODE_NONE)
Lina.optionAttack = Menu.AddOptionBool({ "Hero Specific", "Lina" }, "Attack after combo", true)

Lina.optionAutoLaguna = Menu.AddOptionBool({ "Hero Specific", "Lina" }, "Auto Laguna Blade", false)

Lina.optionLagunaCheckAM = Menu.AddOptionBool({ "Hero Specific", "Lina", "Do not use Laguna when" }, "AM Shield", true)
Lina.optionLagunaCheckLotus = Menu.AddOptionBool({ "Hero Specific", "Lina", "Do not use Laguna when" }, "Lotus Orb", true)
Lina.optionLagunaCheckBladeMail = Menu.AddOptionBool({ "Hero Specific", "Lina", "Do not use Laguna when" }, "Blade Mail", true)
Lina.optionLagunaCheckNyx = Menu.AddOptionBool({ "Hero Specific", "Lina", "Do not use Laguna when" }, "Nyx Carapace", true)
Lina.optionLagunaCheckAegis = Menu.AddOptionBool({ "Hero Specific", "Lina", "Do not use Laguna when" }, "Enemy has Aegis", false)
Lina.optionLagunaCheckAbbadon = Menu.AddOptionBool({ "Hero Specific", "Lina", "Do not use Laguna when" }, "Abaddon Ultimate", true)
Lina.optionLagunaInvisible = Menu.AddOptionBool({ "Hero Specific", "Lina", "Do not use Laguna when" }, "When you're invisible", false)

function Lina.OnUpdate()
	if not Menu.IsEnabled( Lina.optionEnable ) then return end

	Lina.Hero = Heroes.GetLocal()
	if not Lina.Hero or NPC.GetUnitName(Lina.Hero) ~= "npc_dota_hero_lina" then return end
	
	Lina.Mana = NPC.GetMana(Lina.Hero)
	 
	Lina.Slave = NPC.GetAbility(Lina.Hero, "lina_dragon_slave")
	Lina.Strike = NPC.GetAbility(Lina.Hero, "lina_light_strike_array")
	Lina.Laguna = NPC.GetAbility(Lina.Hero, "lina_laguna_blade")

	Lina.Eul = NPC.GetItem(Lina.Hero, "item_cyclone")
	if not Lina.Eul then Lina.Eul = nil end

	if Menu.IsKeyDown( Lina.optionComboKey ) then
		local enemy = Input.GetNearestHeroToCursor(Entity.GetTeamNum(Lina.Hero), Enum.TeamType.TEAM_ENEMY)
		if enemy and not Entity.IsDormant(enemy) and not NPC.IsIllusion(enemy) and Entity.GetHealth(enemy) > 0 then
	 
			Lina.LockTarget(enemy)
			if Lina.Target == nil then return end
	 
			local pos = Entity.GetAbsOrigin( Lina.Target )
	 
			if Lina.Eul and Lina.heroCanCast( Lina.Hero ) and Ability.IsCastable( Lina.Eul, Lina.Mana ) and Ability.IsReady(Lina.Eul) then
				Ability.CastTarget(Lina.Eul, Lina.Target, false)
				Lina.CastTime = os.clock() + 2.5
			end
			
			if NPC.HasModifier(Lina.Target, "modifier_eul_cyclone") then
				local castStrike = NPC.GetTimeToFacePosition(Lina.Hero, pos) + (Ability.GetCastPoint(Lina.Strike) + 0.5) + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING)
				local cycloneDieTime = Modifier.GetDieTime(NPC.GetModifier(Lina.Target, "modifier_eul_cyclone"))

				if Ability.IsReady( Lina.Strike ) and Ability.IsCastable( Lina.Strike, Lina.Mana ) and cycloneDieTime - GameRules.GetGameTime() <= castStrike then
					Ability.CastPosition(Lina.Strike, pos, true)
				end

				local castSlave = NPC.GetTimeToFacePosition(Lina.Hero, pos) + Ability.GetCastPoint(Lina.Slave) + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING)
				
				if Ability.IsCastable( Lina.Slave, Lina.Mana ) and Ability.IsReady( Lina.Slave ) and cycloneDieTime - GameRules.GetGameTime() <= castSlave then
					Ability.CastPosition(Lina.Slave, pos, true)
				end
			end
			
			if Lina.CastTime <= os.clock() then
				if Lina.Slave and Ability.IsCastable( Lina.Slave, Lina.Mana ) and Ability.IsReady( Lina.Slave ) then
					local slavePred = Ability.GetCastPoint(Lina.Slave) + (pos:__sub(Entity.GetAbsOrigin(Lina.Hero)):Length2D() / 1200) + (NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) * 2)
					Ability.CastPosition(Lina.Slave, Lina.castPred(Lina.Target, slavePred, "line"))
				end
				
				if NPC.HasState(Lina.Target, Enum.ModifierState.MODIFIER_STATE_INVULNERABLE) or not Menu.IsEnabled( Lina.optionAttack ) then return end
					Player.AttackTarget(Players.GetLocal(), Lina.Hero, Lina.Target)
			end
		end
	else
		Lina.Target = nil
	end
	
	if not Menu.IsEnabled( Lina.optionAutoLaguna ) then
		Lina.AutoLaguna()
	end
	
	if Lina.Thanks == false then Lina.SayThanks() end
end
 
function Lina.AutoLaguna()
	if Menu.IsEnabled( Lina.optionAutoLaguna ) then
		if Lina.IsHeroInvisible(Lina.Hero) and Menu.IsEnabled( Lina.optionLagunaInvisible ) then return end
	
		local heroes = Entity.GetHeroesInRadius(Lina.Hero, Ability.GetCastRange(Lina.Laguna), Enum.TeamType.TEAM_ENEMY)
		if not heroes then return end
			
		for _, enemy in pairs(heroes) do
			if not NPC.IsIllusion( enemy ) and not Entity.IsDormant( enemy ) and Entity.IsAlive( enemy ) then
			
			local throughBKB, damage = Lina.LagunaDamage(enemy)
			if not Lina.targetChecker(enemy, throughBKB) then return end
			
			local enemyHP = math.ceil( Entity.GetHealth( enemy ) +  NPC.GetHealthRegen( enemy ) )
				
			if enemyHP <= damage then
				if not Ability.IsCastable( Lina.Laguna, Lina.Mana ) or not Ability.IsReady( Lina.Laguna ) then return end
					Ability.CastTarget(Lina.Laguna, enemy)
					Lina.Target = nil
				end
			end
		end
	end
 end
 
function Lina.LagunaDamage(enemy)
	local amplify = Hero.GetIntellectTotal( Lina.Hero ) * 0.0875
	local kaya = NPC.GetItem( Lina.Hero, "item_kaya" )

	if Ability.GetLevel(NPC.GetAbility(Lina.Hero, "special_bonus_spell_amplify_12")) > 0 then amplify = amplify + 12 end
	if kaya then amplify = amplify + 10 end

	local damage = math.floor(Ability.GetDamage( Lina.Laguna ) + ( Ability.GetDamage( Lina.Laguna ) * ( amplify / 100 ) ))

	if NPC.HasModifier(Lina.Hero, "modifier_wisp_tether_scepter") or NPC.HasModifier(Lina.Hero, "modifier_item_ultimate_scepter") or NPC.HasModifier(Lina.Hero, "modifier_item_ultimate_scepter_consumed") then
		local throughBKB = true
	else
		local throughBKB = false
		damage = NPC.GetMagicalArmorDamageMultiplier(enemy) * damage
	end
	return throughBKB, damage
end

function Lina.targetChecker(genericEnemyEntity, throughBKB)
	if not Lina.Hero then return end

	if genericEnemyEntity and not Entity.IsDormant(genericEnemyEntity) and not NPC.IsIllusion(genericEnemyEntity) and Entity.GetHealth(genericEnemyEntity) > 0 then

		if NPC.HasModifier(genericEnemyEntity, Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) and not throughBKB then return end
	
		if NPC.IsLinkensProtected( genericEnemyEntity ) then return end
	
		if NPC.HasModifier(genericEnemyEntity, "modifier_item_aeon_disk_buff") then return end
	
		if Menu.IsEnabled(Lina.optionLagunaCheckAM) then
			if NPC.GetUnitName(genericEnemyEntity) == "npc_dota_hero_antimage" and NPC.HasItem(genericEnemyEntity, "item_ultimate_scepter", true) and NPC.HasModifier(genericEnemyEntity, "modifier_antimage_spell_shield") and Ability.IsReady(NPC.GetAbility(genericEnemyEntity, "antimage_spell_shield")) then return end
		end
		
		if Menu.IsEnabled(Lina.optionLagunaCheckLotus) then
			if NPC.HasModifier(genericEnemyEntity, "modifier_item_lotus_orb_active") then return end
		end
		
		if Menu.IsEnabled(Lina.optionLagunaCheckBladeMail) then
			if NPC.HasModifier(genericEnemyEntity, "modifier_item_blade_mail_reflect") and Entity.GetHealth(Lina.Hero) <= 0.25 * Entity.GetMaxHealth(Lina.Hero) then return end
		end
		
		if Menu.IsEnabled(Lina.optionLagunaCheckNyx) then
			if NPC.HasModifier(genericEnemyEntity, "modifier_nyx_assassin_spiked_carapace") then return end 
		end
		
		if NPC.HasModifier(genericEnemyEntity, "modifier_ursa_enrage") then return end
		
		if Menu.IsEnabled(Lina.optionLagunaCheckAbbadon) then
			if NPC.HasModifier(genericEnemyEntity, "modifier_abaddon_borrowed_time") then return end
		end
		
		if NPC.HasModifier(genericEnemyEntity, "modifier_dazzle_shallow_grave") then return end

		if NPC.HasModifier(genericEnemyEntity, "modifier_skeleton_king_reincarnation_scepter_active") then return end
		
		if NPC.HasModifier(genericEnemyEntity, "modifier_winter_wyvern_winters_curse") then return end

		if NPC.HasState(genericEnemyEntity, Enum.ModifierState.MODIFIER_STATE_INVULNERABLE) then return end
		
		if Menu.IsEnabled( Lina.optionLagunaCheckAegis ) then
			if NPC.HasItem(genericEnemyEntity, "item_aegis") then return end
		end
		
		return genericEnemyEntity
	end

	return
end

function Lina.LockTarget(enemy)
	if Lina.Target == nil and enemy then
		Lina.Target = enemy
		return
	end

	if Lina.Target ~= nil then
		if not Entity.IsAlive(Lina.Target) then
			Lina.Target = nil
			return
		elseif Entity.IsDormant(Lina.Target) then
			Lina.Target = nil
			return
		end
	end
	return
end
 
function Lina.IsHeroInvisible(Hero)
	if NPC.HasState(Hero, Enum.ModifierState.MODIFIER_STATE_INVISIBLE) then return true end
	if NPC.HasModifier(Hero, "modifier_invoker_ghost_walk_self") then return true end
	if NPC.HasAbility(Hero, "invoker_ghost_walk") then
		if Ability.SecondsSinceLastUse(NPC.GetAbility(Hero, "invoker_ghost_walk")) > -1 and Ability.SecondsSinceLastUse(NPC.GetAbility(Hero, "invoker_ghost_walk")) < 1 then 
			return true
		end
	end

	if NPC.HasItem(Hero, "item_invis_sword", true) then
		if Ability.SecondsSinceLastUse(NPC.GetItem(Hero, "item_invis_sword", true)) > -1 and Ability.SecondsSinceLastUse(NPC.GetItem(Hero, "item_invis_sword", true)) < 1 then 
			return true
		end
	end
	if NPC.HasItem(Hero, "item_silver_edge", true) then
		if Ability.SecondsSinceLastUse(NPC.GetItem(Hero, "item_silver_edge", true)) > -1 and Ability.SecondsSinceLastUse(NPC.GetItem(Hero, "item_silver_edge", true)) < 1 then 
			return true
		end
	end
	return false
 end

function Lina.castPred(enemy, adjustmentVariable, castType)
	if not enemy or not adjustmentVariable then return end

	local enemyRotation = Entity.GetRotation(enemy):GetVectors()
		enemyRotation:SetZ(0)
	local enemyOrigin = Entity.GetAbsOrigin(enemy)
		enemyOrigin:SetZ(0)

	if enemyRotation and enemyOrigin then
		if not NPC.IsRunning(enemy) then
			return enemyOrigin
		else
			if castType == "pos" then
				local cosGamma = (Entity.GetAbsOrigin(Lina.Hero) - enemyOrigin):Dot2D(enemyRotation:Scaled(100)) / ((Entity.GetAbsOrigin(Lina.Hero) - enemyOrigin):Length2D() * enemyRotation:Scaled(100):Length2D())
				return enemyOrigin:__add(enemyRotation:Normalized():Scaled(Lina.GetMoveSpeed(enemy) * adjustmentVariable * (1 - cosGamma)))
			elseif castType == "line" then
				return enemyOrigin:__add(enemyRotation:Normalized():Scaled(Lina.GetMoveSpeed(enemy) * adjustmentVariable))
			end
		end
	end
end

function Lina.GetMoveSpeed(enemy)
	if not enemy then return end

	local base_speed = NPC.GetBaseSpeed(enemy)
	local bonus_speed = NPC.GetMoveSpeed(enemy) - NPC.GetBaseSpeed(enemy)
	local modifierHex
	
    local modSheep = NPC.GetModifier(enemy, "modifier_sheepstick_debuff")
    local modLionVoodoo = NPC.GetModifier(enemy, "modifier_lion_voodoo")
    local modShamanVoodoo = NPC.GetModifier(enemy, "modifier_shadow_shaman_voodoo")

	if modSheep then
		modifierHex = modSheep
	end
	if modLionVoodoo then
		modifierHex = modLionVoodoo
	end
	if modShamanVoodoo then
		modifierHex = modShamanVoodoo
	end

	if modifierHex then
		if math.max(Modifier.GetDieTime(modifierHex) - GameRules.GetGameTime(), 0) > 0 then
			return 140 + bonus_speed
		end
	end

    	if NPC.HasModifier(enemy, "modifier_invoker_ice_wall_slow_debuff") then 
		return 100 
	end

	if NPC.HasModifier(enemy, "modifier_invoker_cold_snap_freeze") or NPC.HasModifier(enemy, "modifier_invoker_cold_snap") then
		return (base_speed + bonus_speed) * 0.5
	end

	if NPC.HasModifier(enemy, "modifier_spirit_breaker_charge_of_darkness") then
		local chargeAbility = NPC.GetAbility(enemy, "spirit_breaker_charge_of_darkness")
		if chargeAbility then
			local specialAbility = NPC.GetAbility(enemy, "special_bonus_unique_spirit_breaker_2")
			if specialAbility then
				 if Ability.GetLevel(specialAbility) < 1 then
					return Ability.GetLevel(chargeAbility) * 50 + 550
				else
					return Ability.GetLevel(chargeAbility) * 50 + 1050
				end
			end
		end
	end
	
    return base_speed + bonus_speed
end

function Lina.heroCanCast(Hero)
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
	
	if NPC.IsChannellingAbility(Lina.Hero) then return false end
	if NPC.HasModifier(Lina.Hero, "modifier_teleporting") then return false end
	
	return true
 end
 
function Lina.SayThanks()
	Lina.Thanks = true
	for k, v in pairs(Players.GetAll()) do
		local steamid = Player.GetPlayerData( v )["steamid"]
		local user = Player.GetPlayerData(Players.GetLocal())["steamid"]
		
		if user ~= 76561197968780397 and steamid == 76561197968780397 then
			Engine.ExecuteCommand("say MrSpenk, привет! Спасибо за скрипт!")
		end
	end
 end
 
function Lina.init()
	Lina.Hero = nil
	Lina.Mana = nil

	Lina.Target = nil
	
	Lina.Slave = nil
	Lina.Strike = nil
	Lina.Laguna = nil
	
	Lina.Eul = nil
	Lina.CastTime = 0
	Lina.Thanks = false
end

function Lina.OnGameStart()
	Lina.init()
end

function Lina.OnGameEnd()
	Lina.init()
end

Lina.init()
 
return Lina
