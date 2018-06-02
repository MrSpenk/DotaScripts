local Kunnka = {}

Kunnka.optionEnable = Menu.AddOptionBool({ "Hero Specific", "Kunnka" }, "Activation", false)
Kunnka.optionAttack = Menu.AddOptionBool({ "Hero Specific", "Kunnka" }, "Attack after combo", false)
Kunnka.optionComboType = Menu.AddOptionCombo({ "Hero Specific", "Kunnka" }, "Combo Type", {" X-Mark + Torrent", " X-Mark + GhostShip", " X-Mark + Torrent + GhostShip"}, 0)
Kunnka.optionComboKey = Menu.AddKeyOption({ "Hero Specific", "Kunnka" }, "Combo Key", Enum.ButtonCode.BUTTON_CODE_NONE)

Kunnka.Hero = nil
Kunnka.Mana = nil

Kunnka.Target = nil

Kunnka.Torrent = nil
Kunnka.XMark = nil
Kunnka.Ship = nil
Kunnka.Return = nil

Kunnka.MarkPos = Vector()

Kunnka.ComboType = 0

function Kunnka.OnUpdate()
	if not Menu.IsEnabled( Kunnka.optionEnable ) then return end
	
	Kunnka.Hero = Heroes.GetLocal()
	if not Kunnka.Hero or NPC.GetUnitName(Kunnka.Hero) ~= "npc_dota_hero_kunkka" then return end
		
	Kunnka.Mana = NPC.GetMana(Kunnka.Hero)

	Kunnka.ComboType = Menu.GetValue( Kunnka.optionComboType )
	
	Kunnka.Torrent = NPC.GetAbility(Kunnka.Hero, "kunkka_torrent")
	Kunnka.Splash = NPC.GetAbility(Kunnka.Hero, "kunkka_tidebringer")
	Kunnka.XMark = NPC.GetAbility(Kunnka.Hero, "kunkka_x_marks_the_spot")
	Kunnka.Ship = NPC.GetAbility(Kunnka.Hero, "kunkka_ghostship")
	Kunnka.Return = NPC.GetAbility(Kunnka.Hero, "kunkka_return")
	
	if Menu.IsKeyDown( Kunnka.optionComboKey ) then	
		local enemy = Input.GetNearestHeroToCursor(Entity.GetTeamNum(Kunnka.Hero), Enum.TeamType.TEAM_ENEMY)
		if enemy and not NPC.IsIllusion( enemy ) and Entity.GetHealth( enemy ) > 0 and NPC.IsEntityInRange(Kunnka.Hero, enemy, 999) then
			Kunnka.LockTarget(enemy)
			if Kunnka.Target == nil then return end

			if Kunnka.ComboType == 0 then
				if not NPC.HasModifier(Kunnka.Target, "modifier_kunkka_x_marks_the_spot") then
					if Kunnka.XMark and Kunnka.heroCanCast( Kunnka.Hero ) 
						and Ability.IsCastable( Kunnka.XMark, Kunnka.Mana ) and Ability.IsReady( Kunnka.XMark ) 
						and Ability.IsCastable( Kunnka.Torrent, Kunnka.Mana ) and Ability.IsReady( Kunnka.Torrent ) then
						
						Ability.CastTarget(Kunnka.XMark, Kunnka.Target, false)
						Kunnka.MarkPos = Entity.GetAbsOrigin( Kunnka.Target )
					end
				else
					local castTorrent = NPC.GetTimeToFacePosition(Kunnka.Hero, Kunnka.MarkPos) + (Ability.GetCastPoint(Kunnka.Torrent) + 1.6) + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING)
					local XMarkDieTime = Modifier.GetDieTime(NPC.GetModifier(Kunnka.Target, "modifier_kunkka_x_marks_the_spot"))

					if Ability.IsReady( Kunnka.Torrent ) and Ability.IsCastable( Kunnka.Torrent, Kunnka.Mana ) and XMarkDieTime - GameRules.GetGameTime() <= castTorrent then
						Ability.CastPosition(Kunnka.Torrent, Kunnka.MarkPos, true)
					end
				end
			elseif Kunnka.ComboType == 1 then
				if not NPC.HasModifier(Kunnka.Target, "modifier_kunkka_x_marks_the_spot") then
					if Kunnka.XMark and Kunnka.heroCanCast( Kunnka.Hero ) 
						and Ability.IsCastable( Kunnka.XMark, Kunnka.Mana ) and Ability.IsReady( Kunnka.XMark )
						and Ability.IsCastable( Kunnka.Ship, Kunnka.Mana ) and Ability.IsReady( Kunnka.Ship ) then
						Ability.CastTarget(Kunnka.XMark, Kunnka.Target, false)
						Kunnka.MarkPos = Entity.GetAbsOrigin( Kunnka.Target )
					end
				else
					local castShip = NPC.GetTimeToFacePosition(Kunnka.Hero, Kunnka.MarkPos) + (Ability.GetCastPoint(Kunnka.Ship) + 3.1) + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING)
					local XMarkDieTime = Modifier.GetDieTime(NPC.GetModifier(Kunnka.Target, "modifier_kunkka_x_marks_the_spot"))

					if Ability.IsReady( Kunnka.Ship ) and Ability.IsCastable( Kunnka.Ship, Kunnka.Mana ) and XMarkDieTime - GameRules.GetGameTime() <= castShip then
						Ability.CastPosition(Kunnka.Ship, Kunnka.MarkPos, true)
					end
				end
			elseif Kunnka.ComboType == 2 then
				if not NPC.HasModifier(Kunnka.Target, "modifier_kunkka_x_marks_the_spot") then
					if Kunnka.XMark and Kunnka.heroCanCast( Kunnka.Hero ) 
						and Ability.IsCastable( Kunnka.XMark, Kunnka.Mana ) and Ability.IsReady( Kunnka.XMark )
						and Ability.IsCastable( Kunnka.Torrent, Kunnka.Mana ) and Ability.IsReady( Kunnka.Torrent )
						and Ability.IsCastable( Kunnka.Ship, Kunnka.Mana ) and Ability.IsReady( Kunnka.Ship ) then
						
						Ability.CastTarget(Kunnka.XMark, Kunnka.Target, false)
						Kunnka.MarkPos = Entity.GetAbsOrigin( Kunnka.Target )
					end
				else
					local castTorrent = NPC.GetTimeToFacePosition(Kunnka.Hero, Kunnka.MarkPos) + (Ability.GetCastPoint(Kunnka.Torrent) + 1.6) + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING)
					local castShip = NPC.GetTimeToFacePosition(Kunnka.Hero, Kunnka.MarkPos) + (Ability.GetCastPoint(Kunnka.Ship) + 3.1 + Ability.GetCastPoint(Kunnka.Torrent)) + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING)
					local XMarkDieTime = Modifier.GetDieTime(NPC.GetModifier(Kunnka.Target, "modifier_kunkka_x_marks_the_spot"))
					
					local castReturn = XMarkDieTime - castTorrent - Ability.GetCastPoint(Kunnka.Return)
					if Ability.IsReady( Kunnka.Torrent ) and Ability.IsCastable( Kunnka.Torrent, Kunnka.Mana ) and XMarkDieTime - GameRules.GetGameTime() <= castTorrent then
						Ability.CastPosition(Kunnka.Torrent, Kunnka.MarkPos, true)
					end
					
					if Ability.IsReady( Kunnka.Ship ) and Ability.IsCastable( Kunnka.Ship, Kunnka.Mana ) and XMarkDieTime - GameRules.GetGameTime() <= castShip then
						Ability.CastPosition(Kunnka.Ship, Kunnka.MarkPos, true)
					end
				end
			end
			
			if NPC.HasState(enemy, Enum.ModifierState.MODIFIER_STATE_INVULNERABLE) and not Menu.IsEnabled( Kunnka.optionAttack ) then return end
				Player.AttackTarget(Players.GetLocal(), Kunnka.Hero, Kunnka.Target)
		end
	else
		Kunnka.Target = nil
	end

	if not Menu.IsEnabled( Kunnka.optionAutoLaguna ) then return end
		Kunnka.AutoLaguna()
end

function Kunnka.LockTarget(enemy)
	if Kunnka.Target == nil and enemy then Kunnka.Target = enemy end
	
	if Kunnka.Target ~= nil then
		if not Entity.IsAlive(Kunnka.Target) then
			Kunnka.Target = nil
		elseif Entity.IsDormant(Kunnka.Target) then
			Kunnka.Target = nil
		elseif not NPC.IsEntityInRange(Kunnka.Hero, Kunnka.Target, 570) then
			Kunnka.Target = nil
		end
	end
end

function Kunnka.heroCanCast(Hero)
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

return Kunnka