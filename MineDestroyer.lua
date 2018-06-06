local MineDestroyer = {}

MineDestroyer.optionEnable = Menu.AddOptionBool({"Utility", "Mine Destroyer"}, "Activation", false)
MineDestroyer.optionInvAttack = Menu.AddOptionBool({"Utility", "Mine Destroyer"}, "Attack during invisibility", false)
MineDestroyer.optionPanicKey = Menu.AddKeyOption({"Utility", "Mine Destroyer"}, "Panic Key ", Enum.ButtonCode.BUTTON_CODE_NONE)

function MineDestroyer.OnUpdate()
	if not Menu.IsEnabled( MineDestroyer.optionEnable ) then return end
	
	if Menu.IsKeyDown( MineDestroyer.optionPanicKey ) then 
		Menu.SetEnabled( MineDestroyer.optionEnable, false )
	end
		
	local myHero = Heroes.GetLocal()
	if not myHero then return end
		
	local radius = NPC.GetAttackRange( myHero )
		
	if radius < 430 then radius = 430 end
		
	local npcs = Entity.GetUnitsInRadius(myHero, radius, Enum.TeamType.TEAM_ENEMY)
	if not npcs or #npcs < 1 then return end
	
	for _,npc in pairs(npcs) do
		if npc and not Entity.IsSameTeam(myHero, npc) then
			local name = NPC.GetUnitName( npc )
			
			if name and name == "npc_dota_techies_land_mine" or name == "npc_dota_techies_remote_mine" or name == "npc_dota_techies_stasis_trap" then
				MineDestroyer.Attack(myHero, npc)
			end
		end
	end
end

function MineDestroyer.Attack(myHero, target)
	if not myHero or not target then return end
	
	if not Menu.IsEnabled( MineDestroyer.optionInvAttack ) and MineDestroyer.IsHeroInvisible(myHero) == true then return end
	
	if MineDestroyer.isHeroChannelling(myHero) == true then return end
	if MineDestroyer.heroCanCastItems(myHero) == false then return end
	
	if target ~= nil then
	
		if not Menu.IsEnabled( MineDestroyer.optionEnable ) then return end
		Player.AttackTarget(Players.GetLocal(), myHero, target)
	end
end

function MineDestroyer.IsHeroInvisible(myHero)

	if not myHero then return false end
	if not Entity.IsAlive(myHero) then return false end

	if NPC.HasState(myHero, Enum.ModifierState.MODIFIER_STATE_INVISIBLE) then return true end
	if NPC.HasModifier(myHero, "modifier_invoker_ghost_walk_self") then return true end
	if NPC.HasAbility(myHero, "invoker_ghost_walk") then
		if Ability.SecondsSinceLastUse(NPC.GetAbility(myHero, "invoker_ghost_walk")) > -1 and Ability.SecondsSinceLastUse(NPC.GetAbility(myHero, "invoker_ghost_walk")) < 1 then 
			return true
		end
	end

	if NPC.HasItem(myHero, "item_invis_sword", true) then
		if Ability.SecondsSinceLastUse(NPC.GetItem(myHero, "item_invis_sword", true)) > -1 and Ability.SecondsSinceLastUse(NPC.GetItem(myHero, "item_invis_sword", true)) < 1 then 
			return true
		end
	end
	if NPC.HasItem(myHero, "item_silver_edge", true) then
		if Ability.SecondsSinceLastUse(NPC.GetItem(myHero, "item_silver_edge", true)) > -1 and Ability.SecondsSinceLastUse(NPC.GetItem(myHero, "item_silver_edge", true)) < 1 then 
			return true
		end
	end
	return false
end

function MineDestroyer.heroCanCastItems(myHero)

	if not myHero then return false end
	if not Entity.IsAlive(myHero) then return false end

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

function MineDestroyer.isHeroChannelling(myHero)

	if not myHero then return true end

	if NPC.IsChannellingAbility(myHero) then return true end
	if NPC.HasModifier(myHero, "modifier_teleporting") then return true end

	return false

end

return MineDestroyer
