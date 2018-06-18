local AntiBlur = {}

AntiBlur.optionEnable = Menu.AddOptionBool({ "Awareness" }, "Anti-Blur PA", false)

local timer = 0
local Phantom = {false, false, false}

function AntiBlur.GetPA(object)
	if not object[1] then
		for i = 1, 10 do
			local hero = Heroes.Get(i)
			if hero and Entity.IsEntity( hero ) then
				local name = NPC.GetUnitName( hero )
				if (name == "npc_dota_hero_phantom_assassin") then
					object[1] = hero
					return
				end
			end
		end
	end
end

function AntiBlur.FindPA(object)
	local visible = not Entity.IsDormant( object[1] )
	local hasBlur = NPC.HasModifier(object[1], "modifier_phantom_assassin_blur_active") or false
	
	if visible and hasBlur then
		local pos = Entity.GetAbsOrigin( object[1] )
		object[2] = pos
		object[3] = true
	else
		object[2] = false
		object[3] = false
	end

	timer = os.clock() + 1
end

function AntiBlur.OnUpdate()
	AntiBlur.enabled = Menu.IsEnabled( AntiBlur.optionEnable )
	if not AntiBlur.enabled then return end

	if not Phantom[1] then
		AntiBlur.GetPA(Phantom)
	end
	
	if timer - os.clock() <= 0 then
		AntiBlur.FindPA(Phantom)
	end
end

function AntiBlur.OnDraw()
	if not AntiBlur.enabled then return end
	if Phantom[3] and Phantom[2] then
		MiniMap.DrawHeroIcon( "npc_dota_hero_phantom_assassin", Phantom[2], 255, 255, 255 )
	end
end

return AntiBlur
