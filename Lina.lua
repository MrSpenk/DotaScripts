local Lina = {}

Lina.optionEnable = Menu.AddOptionBool({ "Hero Specific", "Lina" }, "Eul's Combo", false)
Lina.optionComboKey = Menu.AddKeyOption({ "Hero Specific", "Lina" }, "Combo Key", Enum.ButtonCode.BUTTON_CODE_NONE)
Lina.optionAttack = Menu.AddOptionBool({ "Hero Specific", "Lina" }, "Attack after combo", true)
Lina.optionAutoLaguna = Menu.AddOptionBool({ "Hero Specific", "Lina", "Auto Laguna Blade" }, "Activation", false)
Lina.optionLagunaInvisible = Menu.AddOptionBool({ "Hero Specific", "Lina", "Auto Laguna Blade" }, "When you're invisible", false)
Lina.optionLagunaInAegis = Menu.AddOptionBool({ "Hero Specific", "Lina", "Auto Laguna Blade" }, "When an enemy has Aegis", false)

Lina.Hero = nil
Lina.Mana = nil

Lina.Target = nil

Lina.Slave = nil
Lina.Strike = nil
Lina.Laguna = nil

Lina.Eul = nil

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
		if enemy and not NPC.IsIllusion( enemy ) and Entity.GetHealth( enemy ) > 0 and NPC.IsEntityInRange(Lina.Hero, enemy, 570) then

			Lina.LockTarget(enemy)
			if Lina.Target == nil then return end

			local pos = Entity.GetAbsOrigin( Lina.Target )

			if Lina.Eul and Lina.heroCanCast( Lina.Hero ) and Ability.IsCastable( Lina.Eul, Lina.Mana ) and Ability.IsReady(Lina.Eul) then
				Ability.CastTarget(Lina.Eul, Lina.Target, false)
			end

			local castStrike = NPC.GetTimeToFacePosition(Lina.Hero, pos) + (Ability.GetCastPoint(Lina.Strike) + 0.5) + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING)

			if NPC.HasModifier(Lina.Target, "modifier_eul_cyclone") then
				local cycloneDieTime = Modifier.GetDieTime(NPC.GetModifier(Lina.Target, "modifier_eul_cyclone"))

				if Ability.IsReady( Lina.Strike ) and Ability.IsCastable( Lina.Strike, Lina.Mana ) and cycloneDieTime - GameRules.GetGameTime() <= castStrike then
					Ability.CastPosition(Lina.Strike, pos, true)
				end

				local castSlave = NPC.GetTimeToFacePosition(Lina.Hero, pos) + Ability.GetCastPoint(Lina.Slave) + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING)

				if Ability.IsCastable( Lina.Slave, Lina.Mana ) and Ability.IsReady( Lina.Slave ) and cycloneDieTime - GameRules.GetGameTime() <= castSlave then
					Ability.CastPosition(Lina.Slave, pos, true)
				end
			end

			if NPC.HasState(enemy, Enum.ModifierState.MODIFIER_STATE_INVULNERABLE) and not Menu.IsEnabled( Lina.optionAttack ) then return end
				Player.AttackTarget(Players.GetLocal(), Lina.Hero, Lina.Target)
		else
			Lina.Target = nil
		end
	end

	if not Menu.IsEnabled( Lina.optionAutoLaguna ) then return end
		Lina.AutoLaguna()
end

function Lina.AutoLaguna()
	if Menu.IsEnabled( Lina.optionAutoLaguna ) then
		if Lina.IsHeroInvisible(Lina.Hero) and not Menu.IsEnabled( Lina.optionLagunaInvisible ) then return end
		
		local heroes = Entity.GetHeroesInRadius(Lina.Hero, Ability.GetCastRange(Lina.Laguna), Enum.TeamType.TEAM_ENEMY)
		if not heroes then return end
		
		for _, enemy in pairs(heroes) do
			if not NPC.IsIllusion( enemy ) and not Entity.IsDormant( enemy ) and Entity.IsAlive( enemy ) then
			
				local throughBKB, damage = Lina.LagunaDamage(enemy)
				if not Lina.EnemyKillable(enemy, throughBKB) then return end
				
				local enemyHP = math.ceil( Entity.GetHealth( enemy ) +  NPC.GetHealthRegen( enemy ) )
				
				if enemyHP <= damage then
					if not Ability.IsCastable( Lina.Laguna, Lina.Mana ) or not Ability.IsReady( Lina.Laguna ) then return end
					Ability.CastTarget(Lina.Laguna, enemy)
				end
			end
		end
	end
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

function Lina.EnemyKillable( enemy, throughBKB )

	if NPC.HasState(enemy, Enum.ModifierState.MODIFIER_STATE_INVULNERABLE) then return false end
	if NPC.HasModifier(enemy, Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) and not throughBKB then return false end
	if NPC.HasModifier(enemy, "modifier_item_aeon_disk_buff") then return false end
	if NPC.HasModifier(enemy, "modifier_item_blade_mail_reflect") then return false end
	if NPC.IsLinkensProtected( enemy ) then return false end
	if NPC.HasModifier(enemy, "modifier_item_lotus_orb_active") then return false end
	
	if NPC.HasItem(enemy, "item_aegis") then 
		if not Menu.IsEnabled( Lina.optionLagunaInAegis ) then return false end
	end

	return true
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

function Lina.LockTarget(enemy)
	if Lina.Target == nil and enemy then Lina.Target = enemy end
	
	if Lina.Target ~= nil then
		if not Entity.IsAlive(Lina.Target) then
			Lina.Target = nil
		elseif Entity.IsDormant(Lina.Target) then
			Lina.Target = nil
		elseif not NPC.IsEntityInRange(Lina.Hero, Lina.Target, 570) then
			Lina.Target = nil
		end
	end
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

	return true
end

function Lina.isHeroChannelling(Hero)

	if not Hero then return true end

	if NPC.IsChannellingAbility(Hero) then return true end
	if NPC.HasModifier(Hero, "modifier_teleporting") then return true end

	return false

end

return Lina
