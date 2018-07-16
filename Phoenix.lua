local Phoenix = {}

Menu.AddOptionIcon({"Hero Specific", "Phoenix"}, "panorama/images/heroes/icons/npc_dota_hero_phoenix_png.vtex_c")
Phoenix.optionFireSpirit = Menu.AddOptionBool({"Hero Specific", "Phoenix", "Auto Fire Spirit"}, "Activation", true)
Phoenix.optionCastFireSpirit = Menu.AddOptionBool({"Hero Specific", "Phoenix", "Auto Fire Spirit"}, "Spirits before Icarus Drive", true)

Phoenix.optionSunRay = Menu.AddOptionBool({"Hero Specific", "Phoenix", "Sun Ray Aim"}, "Activation", true)
Phoenix.optionTargetStyle = Menu.AddOptionCombo({ "Hero Specific", "Phoenix", "Sun Ray Aim" }, "Targeting style", {" Locked target", " Free target"}, 0)
Phoenix.optionTargetRange = Menu.AddOptionSlider({ "Hero Specific", "Phoenix", "Sun Ray Aim" }, "Radius around the cursor", 150, 300, 160)

Phoenix.optionFailSwitch = Menu.AddOptionBool({"Hero Specific", "Phoenix", "FailSwitch" }, "SuperNova", true)
Phoenix.optionFailSwitchPerc = Menu.AddOptionSlider({"Hero Specific", "Phoenix", "FailSwitch" }, "Disable when % HP threshold", 5, 90, 30)

Phoenix.Pause = {}
Phoenix.posList = {}
Phoenix.LockedTarget = nil

Phoenix.CastTypes = { 
	["item_shivas_guard"] = 1, 
	["item_veil_of_discord"] = 3, 
	["phoenix_fire_spirits"] = 1 }

function Phoenix.OnPrepareUnitOrders(orders)
    if not Menu.IsEnabled(Phoenix.optionFireSpirit) then return true end

    if not orders or not orders.ability then return true end

	if orders.order == 5 then Phoenix.LockedTarget = nil end
	
	if orders.order == Enum.UnitOrder.DOTA_UNIT_ORDER_TRAIN_ABILITY then return true end
	if not (orders.order == Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_NO_TARGET) then return true end

    if Ability.GetName(orders.ability) ~= "phoenix_supernova" then return true end

    local myHero = Heroes.GetLocal()
    if not myHero or NPC.IsStunned(myHero) or NPC.IsSilenced(myHero) then return true end

    local enemyHeroes = Entity.GetHeroesInRadius(myHero, 1300, Enum.TeamType.TEAM_ENEMY)

	if Menu.IsEnabled( Phoenix.optionFailSwitch ) then
		local myMaxHealth = Entity.GetMaxHealth(myHero)
		local myHealthPerc =  myMaxHealth * (Menu.GetValue(Phoenix.optionFailSwitchPerc) / 100)
		
		if Entity.GetHealth(myHero) > myHealthPerc then
			if not enemyHeroes or #enemyHeroes < 1 then return false end
			
			Phoenix.FailSwitchCast(myHero, enemyHeroes)
		else
			if enemyHeroes and #enemyHeroes > 0 then
				Phoenix.FailSwitchCast(myHero, enemyHeroes)
			end
		end
	else
		if enemyHeroes and #enemyHeroes > 0 then
			Phoenix.FailSwitchCast(myHero, enemyHeroes)
		end
	end
	
    return true
end

function Phoenix.FailSwitchCast(myHero, enemyHeroes)
	local fire_spirit = NPC.GetAbility(myHero, "phoenix_fire_spirits")
    local launch_fire_spirit = NPC.GetAbility(myHero, "phoenix_launch_fire_spirit")
    local supernova = NPC.GetAbility(myHero, "phoenix_supernova")

    local manaCost_supernova = Ability.GetManaCost(supernova)
    local myMana = NPC.GetMana(myHero)
	
	local launch_spirit = false
	
	if Ability.IsCastable(fire_spirit, myMana - manaCost_supernova) then
		Ability.CastNoTarget(fire_spirit)
		launch_spirit = true
	end

	Phoenix.Cast("item_shivas_guard", myHero, nil, nil, NPC.GetMana(myHero))
	
	if not launch_spirit then return end
	
	for _, enemy in ipairs(enemyHeroes) do
		Ability.CastPosition(launch_fire_spirit, Entity.GetAbsOrigin(enemy))
	end
end

function Phoenix.OnUpdate()
    local myHero = Heroes.GetLocal()
    if not myHero or NPC.GetUnitName(myHero) ~= "npc_dota_hero_phoenix" then return end
	
    if Menu.IsEnabled(Phoenix.optionFireSpirit) then
        Phoenix.FireSpirit(myHero)
    end

    if Menu.IsEnabled(Phoenix.optionSunRay) then
        Phoenix.SunRay(myHero)
    end
end

function Phoenix.SunRay(myHero)
    if not NPC.HasModifier(myHero, "modifier_phoenix_sun_ray") then return end
	
	local npc = Phoenix.getComboTarget(myHero)
	
	if Menu.GetValue(Phoenix.optionTargetStyle) < 1 then
		if Phoenix.LockedTarget == nil then
			if npc then
				Phoenix.LockedTarget = npc
				else
				Phoenix.LockedTarget = nil
			end
		end
	else
		if npc then
			Phoenix.LockedTarget = npc
		else
			Phoenix.LockedTarget = nil
		end
	end
	
    if not Phoenix.LockedTarget or not Phoenix.CanCastSpellOn(Phoenix.LockedTarget) then return end
    if not NPC.IsPositionInRange(Phoenix.LockedTarget, Input.GetWorldCursorPos(), 1500, 0) then return end

    Player.PrepareUnitOrders(Players.GetLocal(), Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION, Phoenix.LockedTarget, Entity.GetAbsOrigin(Phoenix.LockedTarget), nil, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, myHero)
end

function Phoenix.FireSpirit(myHero)
    if not NPC.HasModifier(myHero, "modifier_phoenix_icarus_dive") then Phoenix.posList = {}; return end

    local launch_fireSpirit = NPC.GetAbility(myHero, "phoenix_launch_fire_spirit")
	local fireSpirit = NPC.GetAbility(myHero, "phoenix_fire_spirits")
	local mana = NPC.GetMana(myHero)
	
	if Menu.IsEnabled( Phoenix.optionCastFireSpirit ) then
		if fireSpirit and Ability.IsCastable(fireSpirit, mana) then
			Phoenix.Cast("phoenix_fire_spirits", myHero, nil, nil, mana)
		end
	end
	
    if not launch_fireSpirit then return end

    local enemies = Entity.GetHeroesInRadius(myHero, Ability.GetCastRange(launch_fireSpirit), Enum.TeamType.TEAM_ENEMY)
    if not enemies or #enemies < 1 then return end

	Phoenix.Cast("item_veil_of_discord", myHero, nil, Phoenix.BestPosition(enemies, 600), mana)
	
    for i, npc in ipairs(enemies) do
		if npc and not NPC.IsIllusion(npc) and Phoenix.CanCastSpellOn(npc) then
            local speed = 900
            local dis = (Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(npc)):Length()
            local delay = dis / speed
            local pos = Phoenix.GetPredictedPosition(npc, delay)

            if not Phoenix.PositionIsCovered(pos) and not NPC.HasModifier(npc, "modifier_phoenix_fire_spirit_burn") then
                Ability.CastPosition(launch_fireSpirit, pos)
                table.insert(Phoenix.posList, pos)
                return
            end
        end
    end
end

function Phoenix.getComboTarget(myHero)
	if not myHero then return end

	local targetingRange = Menu.GetValue(Phoenix.optionTargetRange)
	local mousePos = Input.GetWorldCursorPos()
	
	local heroes = Input.GetNearestHeroToCursor(Entity.GetTeamNum(myHero), Enum.TeamType.TEAM_BOTH)
	if not heroes then return end 

	local enemyDist = (Entity.GetAbsOrigin(heroes) - mousePos):Length2D()
	if enemyDist <= targetingRange then
		return heroes
	end
	
	return nil
end

function Phoenix.BestPosition(unitsAround, radius)
    if not unitsAround or #unitsAround <= 0 then return nil end
    local enemyNum = #unitsAround

	if enemyNum == 1 then return Entity.GetAbsOrigin(unitsAround[1]) end

	
	
	
	local maxNum = 1
	local bestPos = Entity.GetAbsOrigin(unitsAround[1])
	for i = 1, enemyNum-1 do
		for j = i+1, enemyNum do
			if unitsAround[i] and unitsAround[j] then
				local pos1 = Entity.GetAbsOrigin(unitsAround[i])
				local pos2 = Entity.GetAbsOrigin(unitsAround[j])
				local mid = pos1:__add(pos2):Scaled(0.5)

				local heroesNum = 0
				for k = 1, enemyNum do
					if NPC.IsPositionInRange(unitsAround[k], mid, radius, 0) then
						heroesNum = heroesNum + 1
					end
				end

				if heroesNum > maxNum then
					maxNum = heroesNum
					bestPos = mid
				end

			end
		end
	end

	return bestPos
end

function Phoenix.Cast(name, self, hero, position, manapoint)
	if not Phoenix.SleepReady("cast_" .. name) then return end
	
	local ability = NPC.GetItem(self, name, true) or NPC.GetAbility(self, name)
	
	local casttype = Phoenix.CastTypes[name]
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
		if Ability.IsCastable(ability, manapoint) and Ability.IsReady(ability) then
			Ability.CastPosition(ability, position)
		end
	end
	
	Phoenix.Sleep("cast_" .. name, 0.1)
end

function Phoenix.Sleep(where, time)
	Phoenix.Pause[where] = os.clock() + time
end

function Phoenix.SleepReady(where)
	if Phoenix.Pause[where] == nil then Phoenix.Pause[where] = 0 end
	if os.clock() > Phoenix.Pause[where] then return true else return false end
end

function Phoenix.CanCastSpellOn(npc)
	if Entity.IsDormant(npc) or not Entity.IsAlive(npc) then return false end
	if NPC.IsStructure(npc) or not NPC.IsKillable(npc) then return false end
	if NPC.HasState(npc, Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) then return false end
	if NPC.HasState(npc, Enum.ModifierState.MODIFIER_STATE_INVULNERABLE) then return false end

	return true
end

function Phoenix.CantMove(npc)
    if not npc then return false end

    if Phoenix.GetStunTimeLeft(npc) >= 1 then return true end
    if NPC.HasModifier(npc, "modifier_axe_berserkers_call") then return true end
    if NPC.HasModifier(npc, "modifier_legion_commander_duel") then return true end

    return false
end

function Phoenix.GetStunTimeLeft(npc)
    local mod = NPC.GetModifier(npc, "modifier_stunned")
    if not mod then return 0 end
    return math.max(Modifier.GetDieTime(mod) - GameRules.GetGameTime(), 0)
end

function Phoenix.GetPredictedPosition(npc, delay)
    local pos = Entity.GetAbsOrigin(npc)
    if Phoenix.CantMove(npc) then return pos end
    if not NPC.IsRunning(npc) or not delay then return pos end

    local dir = Entity.GetRotation(npc):GetForward():Normalized()
    local speed = Phoenix.GetMoveSpeed(npc)

    return pos + dir:Scaled(speed * delay)
end

function Phoenix.GetMoveSpeed(npc)
    local base_speed = NPC.GetBaseSpeed(npc)
    local bonus_speed = NPC.GetMoveSpeed(npc) - NPC.GetBaseSpeed(npc)

    if NPC.HasModifier(npc, "modifier_invoker_ice_wall_slow_debuff") then return 100 end

    if Phoenix.GetHexTimeLeft(npc) > 0 then return 140 + bonus_speed end

    return base_speed + bonus_speed
end

function Phoenix.GetHexTimeLeft(npc)
    local mod
    local mod1 = NPC.GetModifier(npc, "modifier_sheepstick_debuff")
    local mod2 = NPC.GetModifier(npc, "modifier_lion_voodoo")
    local mod3 = NPC.GetModifier(npc, "modifier_shadow_shaman_voodoo")

    if mod1 then mod = mod1 end
    if mod2 then mod = mod2 end
    if mod3 then mod = mod3 end

    if not mod then return 0 end
    return math.max(Modifier.GetDieTime(mod) - GameRules.GetGameTime(), 0)
end

function Phoenix.PositionIsCovered(pos)
    if not Phoenix.posList or #Phoenix.posList <= 0 then return false end

    local range = 175
    for i, vec in ipairs(Phoenix.posList) do
        if vec and (pos - vec):Length() <= range then return true end
    end

    return false
end

return Phoenix
