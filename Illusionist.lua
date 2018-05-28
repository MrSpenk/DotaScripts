local Illusionist = {}

Illusionist.optionEnable = Menu.AddOptionBool({"Utility", "Illusionist"}, "Activation", false)
Illusionist.optionManualCreate = Menu.AddOptionBool({"Utility", "Illusionist"}, "Create illusions manually", true)
Illusionist.Key1 = Menu.AddKeyOption({"Utility", "Illusionist"}, "Illusions run to the sides", Enum.ButtonCode.BUTTON_CODE_NONE)
Illusionist.Key2 = Menu.AddKeyOption({"Utility", "Illusionist"}, "One runs to the base", Enum.ButtonCode.BUTTON_CODE_NONE)


function Illusionist.OnUpdate()
	if not Menu.IsEnabled(Illusionist.optionEnable) then return end
	
	local myHero = Heroes.GetLocal()
	if not myHero then return end
	
	if not Menu.IsKeyDown(Illusionist.Key1) and not Menu.IsKeyDown(Illusionist.Key2) then return end
	
	local illustable = Illusionist.FindIllus()
	if #illustable == 0 and not Menu.IsEnabled( Illusionist.optionManualCreate ) then
	
		local naga = NPC.GetAbility(myHero, "naga_siren_mirror_image")
		if naga and Ability.IsReady(naga) then
			if Illusionist.triger <= GameRules.GetGameTime() then
				Ability.CastNoTarget(naga)
				Illusionist.triger = GameRules.GetGameTime() + 1
			end
		end
		
		local doppelwalk = NPC.GetAbility(myHero, "phantom_lancer_doppelwalk")
		if doppelwalk and Ability.IsReady(doppelwalk) then
			if Illusionist.triger <= GameRules.GetGameTime() then
				if Entity.GetAbsOrigin(myHero):Distance(Input.GetWorldCursorPos()):Length2D() < Ability.GetCastRange(doppelwalk) then
					Ability.CastPosition(doppelwalk,Illusionist.GetVec(Entity.GetAbsOrigin(myHero),Input.GetWorldCursorPos(),Entity.GetAbsOrigin(myHero):Distance(Input.GetWorldCursorPos()):Length2D()))
				else
					Ability.CastPosition(doppelwalk,Illusionist.GetVec(Entity.GetAbsOrigin(myHero),Input.GetWorldCursorPos(),Ability.GetCastRange(doppelwalk)))
				end
				Illusionist.triger = GameRules.GetGameTime() + 0.5
			end
		end
	end
	
	
	if Menu.IsKeyDown(Illusionist.Key1) then
		if Illusionist.movetriger <= GameRules.GetGameTime() then
			if #illustable > 0 then
				for _,illusion in pairs(illustable) do
					if illusion then
						local npc = nil
						while not npc do
							npc = Trees.Get(math.random(0,Trees.Count()))
						end
						local vector = Entity.GetAbsOrigin(npc)
						NPC.MoveTo(illusion,vector)
					end
				end
				Illusionist.movetriger = GameRules.GetGameTime() + 1
			end
		end
	end
	
	if Menu.IsKeyDown(Illusionist.Key2) then
		if Illusionist.movetriger <= GameRules.GetGameTime() then
			if #illustable > 0 then
				NPC.MoveTo(illustable[1],Illusionist.FindBase())
				for i,illusion in pairs(illustable) do
					if illusion ~= illustable[1] then
						NPC.MoveTo(illusion,Input.GetWorldCursorPos())
					end
				end
				NPC.MoveTo(Heroes.GetLocal(),Input.GetWorldCursorPos())
				Illusionist.movetriger = GameRules.GetGameTime() + 0.2
			end
		end
	end
end

function Illusionist.GetVec(poss1,poss2,range)
	if poss1 and poss2 and range then
		local pos1 = poss1
		local pos2 = poss1
		local pos3 = poss2
		pos1:SetZ(0)
		pos3:SetZ(0)
		return pos2 + ((pos3 - pos1):Normalized()):Scaled(range)
	else
		return nil
	end
end

function Illusionist.FindBase()
	for _,NA_Unit in pairs(NPCs.GetAll()) do
		if NA_Unit then
			if NPC.GetUnitName(NA_Unit) == "dota_fountain" and Entity.IsSameTeam(NA_Unit,Heroes.GetLocal()) then
				return Entity.GetAbsOrigin(NA_Unit)
			end
		end
	end
	return nil
end

function Illusionist.FindIllus()
	local myillus = {}
	for _,npc in pairs(NPCs.GetAll()) do
		if npc and Entity.IsAlive(npc) and NPC.IsIllusion(npc) and NPC.GetUnitName(npc) == NPC.GetUnitName(Heroes.GetLocal()) then
			table.insert(myillus,npc)
		end
	end
	return myillus
end

function Illusionist.init()
	Illusionist.triger = 0
	Illusionist.movetriger = 0
end

function Illusionist.OnGameStart()
	Illusionist.init()
end

function Illusionist.OnGameEnd()
	Illusionist.init()
end

Illusionist.init()

return Illusionist
