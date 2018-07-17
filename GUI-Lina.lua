local Lina = {}
Lina.Identity = "lina_gui_combos"

Lina.Locale = {
	["name"] = {
		["english"] = "Lina"
	},
	["desc"] = {
		["english"] = "Full combo",
		["russian"] = "Полное комбо"
	},
	
	["order"] = {
		["english"] = "Select item order",
		["russian"] = "Порядок использования предметов"
	},
	["blink_range"] = {
		["english"] = "Blink range to enemy",
		["russian"] = "Дистанция до врага после блинка"
	},
	
	["SlaveIC"] = {
		["english"] = "Use slave in combos",
		["russian"] = "Использовать задув в комбо"
	},
	["StunIC"] = {
		["english"] = "Use stun in combos",
		["russian"] = "Использовать стан в комбо"
	},
	["LagunaIC"] = {
		["english"] = "Use laguna in combos",
		["russian"] = "Использовать ульту в комбо"
	},
	["combo"] = {
		["english"] = "Combo Key",
		["russian"] = "Кнопка активации комбо"
	},
	["autoES"] = {
		["english"] = "Auto stun under Eul's Scepter",
		["russian"] = "Автоматический стан под Eul's Scepter"
	},

	["autoLaguna"] = {
		["english"] = "Auto Laguna Blade",
		["russian"] = "Автоматически использовать Laguna, чтобы убить врага"
	},
	["DoNotUseLaguna"] = {
		["english"] = "Laguna will not be used if:",
		["russian"] = "Не использовать Laguna если:"
	},

	["Aegis"] = {
		["english"] = "Enemy has Aegis",
		["russian"] = "Враг имеет Aegis"
	},
	["Invisible"] = {
		["english"] = "You're invisible",
		["russian"] = "Вы в невидимости"
	}
}

Lina.Items  = {
	["item_blink"] = "resource/flash3/images/items/",
	["item_veil_of_discord"] = "resource/flash3/images/items/",
	["item_soul_ring"] = "resource/flash3/images/items/",
	["item_orchid"] = "resource/flash3/images/items/",
	["item_bloodthorn"] = "resource/flash3/images/items/",
	["item_dagon"] = "resource/flash3/images/items/",
	["item_sheepstick"] = "resource/flash3/images/items/",
	["item_ethereal_blade"] = "resource/flash3/images/items/",
	["item_nullifier"] = "resource/flash3/images/items/",
}

Lina.CastTypes  = {
	["item_blink"] = 3,
	["item_veil_of_discord"] = 3,
	["item_soul_ring"] = 1,
	["item_orchid"] = 2,
	["item_bloodthorn"] = 2,
	["item_dagon"] = 2,
	["item_sheepstick"] = 2,
	["item_ethereal_blade"] = 2,
	["item_nullifier"] = 2,
	["lina_dragon_slave"] = 3,
	["lina_light_strike_array"] = 3,
	["lina_laguna_blade"] = 2
}

Lina.Target = nil
Lina.CastTime = 0

function Lina.OnDraw()
	if GUI == nil then return end
	if not GUI.Exist(Lina.Identity) then
		GUI.Initialize(Lina.Identity, GUI.Category.Heroes, Lina.Locale["name"], Lina.Locale["desc"], "MrSpenk", "")

		GUI.AddMenuItem(Lina.Identity, Lina.Identity .. "ordercast", Lina.Locale["order"],
			GUI.MenuType.OrderBox, Lina.Items, "", "item_", 40, 40)
		GUI.AddMenuItem(Lina.Identity, Lina.Identity .. "slider_blink", Lina.Locale["blink_range"], GUI.MenuType.Slider, 150, 1000, 300)

		GUI.AddMenuItem(Lina.Identity, Lina.Identity .. "SlaveIC", Lina.Locale["SlaveIC"], GUI.MenuType.CheckBox, 0)
		GUI.AddMenuItem(Lina.Identity, Lina.Identity .. "StunIC", Lina.Locale["StunIC"], GUI.MenuType.CheckBox, 0)
		GUI.AddMenuItem(Lina.Identity, Lina.Identity .. "LagunaIC", Lina.Locale["LagunaIC"], GUI.MenuType.CheckBox, 0)
		
		GUI.AddMenuItem(Lina.Identity, Lina.Identity .. "combokey", Lina.Locale["combo"], GUI.MenuType.Key, "A", Lina.Combo)
		
		GUI.AddMenuItem(Lina.Identity, Lina.Identity .. "autoES", Lina.Locale["autoES"], GUI.MenuType.CheckBox, 0)
		GUI.AddMenuItem(Lina.Identity, Lina.Identity .. "autoLaguna", Lina.Locale["autoLaguna"], GUI.MenuType.CheckBox, 0)
		
		GUI.AddMenuItem(Lina.Identity, Lina.Identity .. "DoNotUseLaguna", Lina.Locale["DoNotUseLaguna"], GUI.MenuType.Label)
		GUI.AddMenuItem(Lina.Identity, Lina.Identity .. "Aegis", Lina.Locale["Aegis"], GUI.MenuType.CheckBox, 1)
		GUI.AddMenuItem(Lina.Identity, Lina.Identity .. "Invisible", Lina.Locale["Invisible"], GUI.MenuType.CheckBox, 1)
	end
end
	
function Lina.Combo()
	if not GUI.IsEnabled(Lina.Identity) then return end
    local self = Heroes.GetLocal()
    if NPC.GetUnitName(self) ~= "npc_dota_hero_lina" then return end
    
	local enemy = Input.GetNearestHeroToCursor(Entity.GetTeamNum(self), Enum.TeamType.TEAM_ENEMY)
    if not enemy or Entity.IsDormant(enemy) or NPC.IsIllusion(enemy) or not (Entity.GetHealth(enemy) > 0) then return end

    local mana = NPC.GetMana(self)
	local slave = NPC.GetAbility(self, "lina_dragon_slave")
	local stun = NPC.GetAbility(self, "lina_light_strike_array")
	local laguna = NPC.GetAbility(self, "lina_laguna_blade")
	
	local enemy = Input.GetNearestHeroToCursor(Entity.GetTeamNum(self), Enum.TeamType.TEAM_ENEMY)
    if not enemy or Entity.IsDormant(enemy) or NPC.IsIllusion(enemy) or not Lina.targetChecker(self, enemy, false) or not (Entity.GetHealth(enemy) > 0) then return end

	Lina.LockTarget(enemy)
	if not Lina.Target then return end
	
	if Lina.CastTime <= os.clock() then
		local pos = Entity.GetAbsOrigin( Lina.Target )
		local ordercast = GUI.Get(Lina.Identity .. "ordercast", 1)
		if ordercast ~= nil then
			for i = 1, Length(ordercast) do
				Lina.Cast(ordercast[i], self, Lina.Target, pos, mana)
			end
		end
		
		local casted_slave, casted_stun = false
		
		if GUI.IsEnabled(Lina.Identity .."SlaveIC") then
			
			local slavePred = Ability.GetCastPoint(slave) + (Entity.GetAbsOrigin( Lina.Target ):__sub(Entity.GetAbsOrigin(self)):Length2D() / 1200) + (NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) * 2)
			Lina.Cast("lina_dragon_slave", self, Lina.Target, Lina.castPred(self, Lina.Target, slavePred), mana)
			casted_slave = true
		else
			casted_slave = true
		end

		if casted_slave and GUI.IsEnabled(Lina.Identity .."StunIC") then
			local dist = Ability.GetCastRange( stun )
			local stunPred = Ability.GetCastPoint(stun) + (Entity.GetAbsOrigin( Lina.Target ):__sub(Entity.GetAbsOrigin(self)):Length2D() / dist) + (NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) * 2)

			Lina.Cast("lina_light_strike_array", self, Lina.Target, Lina.castPred(self, Lina.Target, stunPred), mana)
			casted_stun = true
		else
			casted_stun = true
		end

		if casted_stun and GUI.IsEnabled(Lina.Identity .."LagunaIC") then
			Lina.Cast("lina_laguna_blade", self, Lina.Target, nil, mana)
		end
		
		if NPC.HasState(Lina.Target, Enum.ModifierState.MODIFIER_STATE_INVULNERABLE) then return end
			Player.AttackTarget(Players.GetLocal(), self, Lina.Target)
	end
end

function Lina.OnUpdate()
	local self = Heroes.GetLocal()
	if not self then return end
	
	local eul = NPC.GetItem(self, "item_cyclone") 
	local strike = NPC.GetAbility(self, "lina_light_strike_array")
	
	local mana = NPC.GetMana(self)
	
	if GUI.IsEnabled(Lina.Identity .. "autoES") then
		if eul then
			local list = Entity.GetHeroesInRadius(self, Ability.GetCastRange(eul), Enum.TeamType.TEAM_ENEMY)
			if list ~= nil then
				for k, enemy in pairs(list) do
					if enemy and not NPC.IsIllusion( enemy ) and NPC.IsEntityInRange(self, enemy, Ability.GetCastRange(strike) ) then
						local pos = Entity.GetAbsOrigin( enemy )
						if NPC.HasModifier(enemy, "modifier_eul_cyclone") then
							local castStrike = NPC.GetTimeToFacePosition(self, pos) + (Ability.GetCastPoint(strike) + 0.5) + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING)
							local cycloneDieTime = Modifier.GetDieTime(NPC.GetModifier(enemy, "modifier_eul_cyclone"))

							if cycloneDieTime - GameRules.GetGameTime() <= castStrike then
								Lina.Cast("lina_light_strike_array", self, enemy, pos, mana)
							end
						end
					end
				end
			end
		end
	end

	local laguna = NPC.GetAbility(self, "lina_laguna_blade")
	if not laguna then return end

	if GUI.IsEnabled(Lina.Identity .. "autoLaguna") then
		if Lina.IsHeroInvisible(self) and GUI.IsEnabled(Lina.Identity .. "Invisible" ) then return end
		
		local heroes = Entity.GetHeroesInRadius(self, Ability.GetCastRange(laguna), Enum.TeamType.TEAM_ENEMY)
		if not heroes then return end

		for _, enemy in pairs(heroes) do
			if not NPC.IsIllusion( enemy ) and not Entity.IsDormant( enemy ) and Entity.IsAlive( enemy ) then
			
				local throughBKB, damage = Lina.LagunaDamage(self, enemy, laguna)
				
				if not Lina.targetChecker(self, enemy, throughBKB) then return end
				
				local enemyHP = math.ceil( Entity.GetHealth( enemy ) +  NPC.GetHealthRegen( enemy ) )

				if enemyHP <= damage then
					Lina.Cast("lina_laguna_blade", self, enemy, nil, mana)
					Lina.Target = nil
				end
			end
		end
	end
 end
 
function Lina.LagunaDamage(self, enemy, laguna)
	local amplify = Hero.GetIntellectTotal( self ) * 0.0875
	local kaya = NPC.GetItem( self, "item_kaya" )

	if Ability.GetLevel(NPC.GetAbility(self, "special_bonus_spell_amplify_12")) > 0 then amplify = amplify + 12 end
	if kaya then amplify = amplify + 10 end

	local damage = math.floor(Ability.GetDamage( laguna ) + ( Ability.GetDamage( laguna ) * ( amplify / 100 ) ))

	if NPC.HasModifier(self, "modifier_wisp_tether_scepter") or NPC.HasModifier(self, "modifier_item_ultimate_scepter") or NPC.HasModifier(self, "modifier_item_ultimate_scepter_consumed") then
		local throughBKB = true
	else
		local throughBKB = false
		damage = NPC.GetMagicalArmorDamageMultiplier(enemy) * damage
	end
	return throughBKB, damage
end

function Lina.targetChecker(self, genericEnemyEntity, throughBKB)
	if not self then return end

	if genericEnemyEntity and not Entity.IsDormant(genericEnemyEntity) and not NPC.IsIllusion(genericEnemyEntity) and Entity.GetHealth(genericEnemyEntity) > 0 then
		
		if NPC.HasAbility(genericEnemyEntity, "modifier_eul_cyclone") then return end
		
		if NPC.HasModifier(genericEnemyEntity, Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) and not throughBKB then return end
	
		if NPC.IsLinkensProtected( genericEnemyEntity ) then return end
	
		if NPC.HasModifier(genericEnemyEntity, "modifier_item_aeon_disk_buff") then return end

		if NPC.GetUnitName(genericEnemyEntity) == "npc_dota_hero_antimage" and NPC.HasItem(genericEnemyEntity, "item_ultimate_scepter", true) and NPC.HasModifier(genericEnemyEntity, "modifier_antimage_spell_shield") and Ability.IsReady(NPC.GetAbility(genericEnemyEntity, "antimage_spell_shield")) then return end
		
		if NPC.HasModifier(genericEnemyEntity, "modifier_item_lotus_orb_active") then return end

		if NPC.HasModifier(genericEnemyEntity, "modifier_item_blade_mail_reflect") and Entity.GetHealth(self) <= 0.25 * Entity.GetMaxHealth(self) then return end

		if NPC.HasModifier(genericEnemyEntity, "modifier_nyx_assassin_spiked_carapace") then return end 
		
		if NPC.HasModifier(genericEnemyEntity, "modifier_ursa_enrage") then return end
		
		if NPC.HasModifier(genericEnemyEntity, "modifier_abaddon_borrowed_time") then return end
		
		if NPC.HasModifier(genericEnemyEntity, "modifier_dazzle_shallow_grave") then return end

		if NPC.HasModifier(genericEnemyEntity, "modifier_skeleton_king_reincarnation_scepter_active") then return end
		
		if NPC.HasModifier(genericEnemyEntity, "modifier_winter_wyvern_winters_curse") then return end

		if NPC.HasAbility(genericEnemyEntity, "necrolyte_reapers_scythe") then return end
		
		if NPC.HasState(genericEnemyEntity, Enum.ModifierState.MODIFIER_STATE_INVULNERABLE) then return end
		
		if not GUI.IsEnabled( Lina.Identity .. "Aegis" ) then
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

	if Lina.Target and Entity.IsHero(Lina.Target) then
		if not Entity.IsAlive(Lina.Target) then
			Lina.Target = nil
			return
		elseif Entity.IsDormant(Lina.Target) then
			Lina.Target = nil
			return
		elseif Lina.targetChecker(Heroes.GetLocal(), enemy, false) then
			Lina.Target = nil
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

function Lina.castPred(self, enemy, adjustmentVariable)
	if not enemy or not adjustmentVariable then return end

	local enemyRotation = Entity.GetRotation(enemy):GetVectors()
		enemyRotation:SetZ(0)
	local enemyOrigin = Entity.GetAbsOrigin(enemy)
		enemyOrigin:SetZ(0)

	if enemyRotation and enemyOrigin then
		if not NPC.IsRunning(enemy) then
			return enemyOrigin
		else
			return enemyOrigin:__add(enemyRotation:Normalized():Scaled(Lina.GetMoveSpeed(enemy) * adjustmentVariable))
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

function Lina.HeroCanCast(self, Hero)
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
	
	if NPC.IsChannellingAbility(self) then return false end
	if NPC.HasModifier(self, "modifier_teleporting") then return false end
	
	return true
end

function Lina.Cast(name, self, hero, position, manapoint)
	if not GUI.SleepReady(Lina.Identity .. "cast_" .. name) then return end
	local ability = NPC.GetItem(self, name, true) or NPC.GetAbility(self, name)
	
	if name == "item_dagon" then
		ability = NPC.GetItem(self, "item_dagon", true)

		for i = 0, 5 do
			if not ability then ability = NPC.GetItem(self, "item_dagon_" .. i, true) end
		end
	end
	
	local casttype = Lina.CastTypes[name]
	if ability == nil then return end

	if casttype == 1 then
		if Ability.IsReady(ability) then
			Ability.CastNoTarget(ability)
		end
	elseif casttype == 2 then
		if Ability.IsCastable(ability, manapoint) and Ability.IsReady(ability) then
			Ability.CastTarget(ability, hero)
		end
	else
		if not (name == "item_blink") then
			if Ability.IsCastable(ability, manapoint) and Ability.IsReady(ability) then
				Ability.CastPosition(ability, position)
			end
		else
			local range = GUI.Get(Lina.Identity .. "slider_blink")
			local pos = (Entity.GetAbsOrigin(hero) + (Entity.GetAbsOrigin(self) - Entity.GetAbsOrigin(hero)):Normalized():Scaled(range))
			if not NPC.IsEntityInRange(hero, self, range + 1 ) and NPC.IsEntityInRange(hero, self, 1150) then
				Ability.CastPosition(ability, pos)
			end
		end
	end
	
	GUI.Sleep(Lina.Identity .. "cast_" .. name, 0.2)
end

return Lina
