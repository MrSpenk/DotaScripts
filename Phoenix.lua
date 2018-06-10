local Phoenix = {}

Phoenix.optionFireSpirit = Menu.AddOptionBool({"Hero Specific", "Phoenix"}, "Auto Fire Spirit", false)
Phoenix.optionSunRay = Menu.AddOptionBool({"Hero Specific", "Phoenix"}, "Sun Ray Aim", false)
Phoenix.posList = {}

function Phoenix.OnPrepareUnitOrders(orders)
    if not Menu.IsEnabled(Phoenix.optionFireSpirit) then return true end
	
    if not orders or not orders.ability then return true end
	
	if orders.order == Enum.UnitOrder.DOTA_UNIT_ORDER_TRAIN_ABILITY then return true end
	if not (orders.order == Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_NO_TARGET) then return true end
	
    if Ability.GetName(orders.ability) ~= "phoenix_supernova" then return true end

    local myHero = Heroes.GetLocal()
    if not myHero or NPC.IsStunned(myHero) or NPC.IsSilenced(myHero) then return true end

    local fire_spirit = NPC.GetAbility(myHero, "phoenix_fire_spirits")
    local launch_fire_spirit = NPC.GetAbility(myHero, "phoenix_launch_fire_spirit")
    local supernova = NPC.GetAbility(myHero, "phoenix_supernova")

    local manaCost_supernova = Ability.GetManaCost(supernova)
    local myMana = NPC.GetMana(myHero)

    if Ability.IsCastable(fire_spirit, myMana - manaCost_supernova) then
        Ability.CastNoTarget(fire_spirit)
    end

    if not Ability.IsCastable(launch_fire_spirit, 0) then return true end
	if not Ability.IsCastable(supernova, myMana) then return true end

    local enemyHeroes = Entity.GetHeroesInRadius(myHero, 1300, Enum.TeamType.TEAM_ENEMY)
	if not enemyHeroes or #enemyHeroes < 1 then return false end
	
    for _, enemy in ipairs(enemyHeroes) do
          if Ability.IsCastable(launch_fire_spirit, myMana) then
            Ability.CastPosition(launch_fire_spirit, Entity.GetAbsOrigin(enemy))
        end
    end
	
    return true
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

    local npc = Input.GetNearestHeroToCursor(Entity.GetTeamNum(myHero), Enum.TeamType.TEAM_BOTH)
    if not npc or not Phoenix.CanCastSpellOn(npc) then return end
    if not NPC.IsPositionInRange(npc, Input.GetWorldCursorPos(), 500, 0) then return end

    Player.PrepareUnitOrders(Players.GetLocal(), Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION, npc, Entity.GetAbsOrigin(npc), nil, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, myHero)
end

function Phoenix.CanCastSpellOn(npc)
	if Entity.IsDormant(npc) or not Entity.IsAlive(npc) then return false end
	if NPC.IsStructure(npc) or not NPC.IsKillable(npc) then return false end
	if NPC.HasState(npc, Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) then return false end
	if NPC.HasState(npc, Enum.ModifierState.MODIFIER_STATE_INVULNERABLE) then return false end

	return true
end

function Phoenix.FireSpirit(myHero)
    if not NPC.HasModifier(myHero, "modifier_phoenix_icarus_dive") then Phoenix.posList = {}; return end

    local fireSpirit = NPC.GetAbility(myHero, "phoenix_launch_fire_spirit")
    if not fireSpirit or not Ability.IsCastable(fireSpirit, NPC.GetMana(myHero)) then return end

    local enemies = Entity.GetHeroesInRadius(myHero, Ability.GetCastRange(fireSpirit), Enum.TeamType.TEAM_ENEMY)
    if not enemies or #enemies < 1 then return end

    for i, npc in ipairs(enemies) do
        if npc and not NPC.IsIllusion(npc) and Phoenix.CanCastSpellOn(npc) then
            local speed = 900
            local dis = (Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(npc)):Length()
            local delay = dis / speed
            local pos = Phoenix.GetPredictedPosition(npc, delay)

            if not Phoenix.PositionIsCovered(pos) then
                Ability.CastPosition(fireSpirit, pos)
                table.insert(Phoenix.posList, pos)
                return
            end
        end
    end
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