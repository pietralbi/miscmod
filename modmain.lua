-- UTILS
local STRINGS = GLOBAL.STRINGS
local TUNING = GLOBAL.TUNING
local enabledROG = GLOBAL.IsDLCEnabled(GLOBAL.REIGN_OF_GIANTS)
local enabledSHIP = GLOBAL.rawget(GLOBAL, "CAPY_DLC") and GLOBAL.IsDLCEnabled(GLOBAL.CAPY_DLC)
local enabledPORK = GLOBAL.rawget(GLOBAL, "PORKLAND_DLC") and GLOBAL.IsDLCEnabled(GLOBAL.PORKLAND_DLC)
local enabledAnyDLC = enabledROG or enabledSHIP or enabledPORK
local vanilla = not enabledAnyDLC

local seg_time = 30
local total_day_time = seg_time*16
local day_segs = 10
local dusk_segs = 4
local night_segs = 2
local day_time = seg_time * day_segs
local dusk_time = seg_time * dusk_segs
local night_time = seg_time * night_segs

local MAX_INT = 2^53
local DEBUG = true

local function dprint(...)
    if DEBUG then
        print(...)
    end
end

local function DumpBTNode(node, indent)
    indent = indent or ""
    if node == nil then
        dprint(indent .. "<nil node>")
        return
    end

    local classname = (node.is_a and (
        node:is_a(GLOBAL.PriorityNode) and "PriorityNode"
        or node:is_a(GLOBAL.ParallelNodeAny) and "ParallelNodeAny"
        or node:is_a(GLOBAL.ParallelNode) and "ParallelNode"
        or node:is_a(GLOBAL.SequenceNode) and "SequenceNode"
        or node:is_a(GLOBAL.SelectorNode) and "SelectorNode"
        or node:is_a(GLOBAL.EventNode) and "EventNode"
        or node:is_a(GLOBAL.ConditionNode) and "ConditionNode"
        or node:is_a(GLOBAL.ActionNode) and "ActionNode"
        or node:is_a(GLOBAL.DecoratorNode) and "DecoratorNode"
    )) or "BehaviourNode"

    dprint(string.format(
        "%s- %s  name='%s'  children=%s",
        indent,
        classname,
        tostring(node.name),
        node.children and tostring(#node.children) or "nil"
    ))
    
    if node.children then
        for i, child in ipairs(node.children) do
            dprint(string.format("%s  [%d]", indent, i))
            DumpBTNode(child, indent .. "    ")
        end
    end
end

-- NO MOD WARNING --
if GetModConfigData("mods_warning") then
    dprint("/AAT enabling NO MOD WARNING")
    GLOBAL.getmetatable(GLOBAL.TheSim).__index.ShouldWarnModsLoaded = function() return false end
end

-- CAVE INSULATION --
local cave_insulation = GetModConfigData("cave_insulation")
if cave_insulation then
    dprint("/AAT enabling CAVE INSULATION")
    TUNING.CAVE_INSULATION_BONUS = TUNING.SEG_TIME * cave_insulation
end

-- MEAT AND FLORAL REPAIR -- 
if GetModConfigData("floral_repair") then
    dprint("/AAT enabling MEAT AND FLORAL REPAIR")
    -- Inits adding repairable component
    local function HanaRepairInit(inst)
            inst:AddComponent("repairable")
            inst.components.repairable.repairmaterial = "FLOWER"
            inst.components.repairable.announcecanfix = false
    end
    local function NikuRepairInit(inst)
            inst:AddComponent("repairable")
            inst.components.repairable.repairmaterial = "MEAT"
            inst.components.repairable.announcecanfix = true
    end
    local function SuikaRepairInit(inst)
            inst:AddComponent("repairable")
            inst.components.repairable.repairmaterial = "MELON"
            inst.components.repairable.announcecanfix = true
    end
    AddPrefabPostInit("hambat", NikuRepairInit)
    AddPrefabPostInit("flowerhat", HanaRepairInit)
    AddPrefabPostInit("grass_umbrella", HanaRepairInit)
    if enabledAnyDLC then
        AddPrefabPostInit("watermelonhat", SuikaRepairInit)
        AddPrefabPostInit("hawaiianshirt", HanaRepairInit)
    end
    if enabledSHIP or enabledPORK then
        AddPrefabPostInit("palmleaf_umbrella", HanaRepairInit)
    end

    -- Inits adding repairer component
    local function CactusRepairInit(inst)
        local divisor = GetModConfigData("cactus_divisor")
        inst:AddComponent("repairer")
        inst.components.repairer.repairmaterial = "FLOWER"
        inst.components.repairer.perishrepairvalue = 1./divisor
    end
    local function PetalsRepairInit(inst)
        local divisor = GetModConfigData("petal_divisor")
        inst:AddComponent("repairer")
        inst.components.repairer.repairmaterial = "FLOWER"
        inst.components.repairer.perishrepairvalue = 1./divisor
    end
    local function MelonRepairInit(inst)
        inst:AddComponent("repairer")
        inst.components.repairer.repairmaterial = "MELON"
        inst.components.repairer.perishrepairvalue = 1.
    end
    local function MeatRepairInit(inst)
        local divisor = GetModConfigData("meat_divisor")
        inst:AddComponent("repairer")
        inst.components.repairer.repairmaterial = "MEAT"
        inst.components.repairer.perishrepairvalue = 1./divisor
    end
    local function MorselRepairInit(inst)
        local divisor = GetModConfigData("morsel_divisor")
        inst:AddComponent("repairer")
        inst.components.repairer.repairmaterial = "MEAT"
        inst.components.repairer.perishrepairvalue = 1./divisor
    end
    AddPrefabPostInit("petals", PetalsRepairInit)
    AddPrefabPostInit("meat", MeatRepairInit)
    AddPrefabPostInit("smallmeat", MorselRepairInit)
    AddPrefabPostInit("drumstick", MorselRepairInit)
    if enabledAnyDLC then
        AddPrefabPostInit("watermelon", MelonRepairInit)
        AddPrefabPostInit("cactus_flower", CactusRepairInit)
    end
end

-- CLOSER PLACEMENT --
local min_spacing = GetModConfigData("close_placement")
if min_spacing then
    dprint("/AAT enabling CLOSER PLACEMENT")
    AddGamePostInit(function()
        for _, v in pairs(GLOBAL.GetAllRecipes()) do
            local old_spacing = v.min_spacing
            v.min_spacing = math.min(min_spacing, v.min_spacing)
            dprint(string.format("/AAT %-30s %g -> %g", v.name, old_spacing, v.min_spacing))
        end
    end)
end

-- DO NOT DELETE SAVE --
if GetModConfigData("dont_delete_save") then
    dprint("/AAT enabling DO NOT DELETE SAVE")
    -- Editing PlayerProfile:Save if called from HandleDeathCleanup
    local PlayerProfile = GLOBAL.PlayerProfile
    local orig_Save = PlayerProfile.Save
    function PlayerProfile:Save(callback)
        dprint("/AAT PlayerProfile:Save")
        local handle_death = false
        for i = 2, 10 do
            local info = GLOBAL.debug.getinfo(i, "nS")
            if info and info.name=="HandleDeathCleanup" then
                handle_death = true
                break
            end
        end

        if handle_death then
            dprint("/AAT called from HandleDeathCleanup, executing callback(true)")
			callback(true)
        else
            dprint("/AAT not called from HandleDeathCleanup, executing original function")
            orig_Save(self, callback)
        end
    end

    -- Editing SaveIndex:EraseCurrent if called from HandleDeathCleanup
    local SaveIndex = GLOBAL.SaveIndex
    local orig_EraseCurrent = SaveIndex.EraseCurrent
    function SaveIndex:EraseCurrent(cb, should_docaves)
        dprint("/AAT SaveIndex:EraseCurrent")
        local handle_death = false
        for i = 2, 10 do
            local info = GLOBAL.debug.getinfo(i, "nS")
            if info and info.name=="HandleDeathCleanup" then
                handle_death = true
                break
            end
        end

        if handle_death then
            dprint("/AAT called from HandleDeathCleanup, executing cb()")
			cb()
        else
            dprint("/AAT not called from HandleDeathCleanup, executing original function")
            orig_EraseCurrent(self, cb, should_docaves)
        end
    end

    -- Editing DeathScreen class
    STRINGS.UI.DEATHSCREEN.MAINMENU = "Delete Save"
    STRINGS.UI.DEATHSCREEN.RETRY = "Reload"

    AddClassPostConstruct("screens/deathscreen", function(self)
        -- Replacing DeathScreen:OnMenu
        function self:OnMenu(escaped)
            dprint("/AAT DeathScreen:OnMenu")
            self.menu:Disable()
            GLOBAL.TheFrontEnd:Fade(false, 2, function()
                if escaped then
                    GLOBAL.StartNextInstance()
                else
                    -- ShowLoading()
                    if GLOBAL.global_loading_widget then 
		                GLOBAL.global_loading_widget:SetEnabled(true)
	                end
                    GLOBAL.EnableAllDLC()
                    --GLOBAL.StartNextInstance()
                    GLOBAL.Profile:Save(function()
                        GLOBAL.SaveGameIndex:EraseCurrent(function()
                            GLOBAL.SaveGameIndex:DeleteSlot(GLOBAL.SaveGameIndex:GetCurrentSaveSlot(), function()
                                GLOBAL.StartNextInstance()
                            end)
		    	        end)
		            end)
                end
            end)
        end

        -- Replacing DeathScreen:OnRetry
        function self:OnRetry()
            dprint("/AAT DeathScreen:OnRetry")
            GLOBAL.StartNextInstance({reset_action=GLOBAL.RESET_ACTION.LOAD_SLOT, save_slot=GLOBAL.SaveGameIndex:GetCurrentSaveSlot()}, true)
        end
    end)
end

-- ATTACKS RESET --
local reset_attack_days = GetModConfigData("attacks_reset")
if reset_attack_days then
    dprint("/AAT enabling ATTACKS RESET")
    -- Replace Hounded:CalcEscalationLevel
    AddComponentPostInit("hounded", function(inst)
        function inst:CalcEscalationLevel()
            dprint("/AAT Hounded:CalcEscalationLevel")
            local day = GLOBAL.GetClock():GetNumCycles()
            day = day % reset_attack_days
            if day < 10 then
                self.attackdelayfn = self.attack_delays.intro
                self.attacksizefn = self.attack_levels.intro.numhounds
                self.warndurationfn = self.attack_levels.intro.warnduration
            elseif day < 25 then
                self.attackdelayfn = self.attack_delays.light
                self.attacksizefn = self.attack_levels.light.numhounds
                self.warndurationfn = self.attack_levels.light.warnduration
            elseif day < 50 then
                self.attackdelayfn = self.attack_delays.med
                self.attacksizefn = self.attack_levels.med.numhounds
                self.warndurationfn = self.attack_levels.med.warnduration
            elseif day < 100 then
                self.attackdelayfn = self.attack_delays.heavy
                self.attacksizefn = self.attack_levels.heavy.numhounds
                self.warndurationfn = self.attack_levels.heavy.warnduration
            else
                self.attackdelayfn = self.attack_delays.crazy
                self.attacksizefn = self.attack_levels.crazy.numhounds
                self.warndurationfn = self.attack_levels.crazy.warnduration
            end
        end
    end)

    -- Replace FrogRain ListenForEvent "rainstart"
    -- but only for DLCs. Vanilla frog rain has no scaling with time
    if enabledAnyDLC then
        AddPrefabPostInit("forest", function(inst)
            dprint("/AAT forest PostInit")
            local FrogRain = inst.components.frograin
            if not FrogRain then return end
            FrogRain.frogcap = MAX_INT    -- Remove frog cap
            local function FrogRainListener()
                if GLOBAL.SaveGameIndex:GetCurrentMode() ~= "adventure" then
                    local day = GLOBAL.GetClock():GetNumCycles()
                    day = day % reset_attack_days
                    local min = GLOBAL.Lerp(TUNING.FROG_RAIN_LOCAL_MIN_EARLY, TUNING.FROG_RAIN_LOCAL_MIN_LATE, day/100)
                    local max = GLOBAL.Lerp(TUNING.FROG_RAIN_LOCAL_MAX_EARLY, TUNING.FROG_RAIN_LOCAL_MAX_LATE, day/100)
                    min = math.clamp(min, TUNING.FROG_RAIN_LOCAL_MIN_EARLY, TUNING.FROG_RAIN_LOCAL_MIN_LATE)
                    max = math.clamp(max, TUNING.FROG_RAIN_LOCAL_MAX_EARLY, TUNING.FROG_RAIN_LOCAL_MAX_LATE)
                    FrogRain.local_rain_max = math.random(min, max)
                else
                    FrogRain.local_rain_max = math.random(TUNING.FROG_RAIN_LOCAL_MIN_ADVENTURE, TUNING.FROG_RAIN_LOCAL_MAX_ADVENTURE)
                end
            end
            -- Replace in event_listeners
            local listeners = inst.event_listeners and inst.event_listeners["rainstart"]
            if listeners and listeners[inst] then
                for i, fn in ipairs(listeners[inst]) do
                    local info = GLOBAL.debug.getinfo(fn, "nS")
                    if info and info.source:find("frograin.lua", 1, true) then
                        listeners[inst][i] = FrogRainListener
                        break
                    end
                end
            end
            -- Replace in event_listening
            local listening = inst.event_listening and inst.event_listening["rainstart"]
            if listening and listening[inst] then
            for i, fn in ipairs(listening[inst]) do
                    local info = GLOBAL.debug.getinfo(fn, "nS")
                    if info and info.source:find("frograin.lua", 1, true) then
                        listening[inst][i] = FrogRainListener
                        break
                    end
                end
            end
        end)
    end

    -- Replace PeriodicThreat worm data on AddThreat
    AddComponentPostInit("periodicthreat", function(inst)
        local orig_AddThreat = inst.AddThreat
        function inst:AddThreat(name, data)
            dprint("/AAT PeriodicThreat:AddThreat")
            if name == "WORM" then
                data.waittime = function(dat)
                    --The older the world, the more often the attacks.
                    --Day 150+ gives the most often
                    local clock = GLOBAL.GetWorld().components.clock
                    local day = clock:GetNumCycles() % reset_attack_days
                    local days = math.random(10)
                    if clock then
                        days = GLOBAL.Lerp(12, 5, day/150)
                        days = math.min(days, 10)
                        days = math.max(days, 3)
                    end
                    return (TUNING.TOTAL_DAY_TIME * 2) + (days * TUNING.TOTAL_DAY_TIME) 
                end
                data.warntime = function(dat)
                    --The older the world, the shorter the warning.
                    local time = math.random(15, 40)
                    local clock = GLOBAL.GetWorld().components.clock
                    local day = clock:GetNumCycles() % reset_attack_days
                    if clock then
                        time = GLOBAL.Lerp(40, 15, day/150)
                        time = math.min(time, 40)
                        time = math.max(time, 15)
                    end
                    return time
                end
                data.numtospawnfn = function(dat)
                    --The older the world, the more that spawn. (2-6)
                    --Day 150+ do max
                    local clock = GLOBAL.GetWorld().components.clock
                    local day = clock:GetNumCycles() % reset_attack_days
                    local num = math.random(1,3)
                    if clock then
                        num = GLOBAL.Lerp(1, 3, day/150)
                        num = math.min(num, 3)
                        num = math.max(num, 1)
                    end
                    num = GLOBAL.RoundDown(num)
                    return num
                end
            end
            orig_AddThreat(self, name, data)
        end
    end)
    
    -- Replace Batted:GetAddTime()
    AddComponentPostInit("batted", function(inst)
        function inst:GetAddTime()
            dprint("/AAT Batted:GetAddTime")
            local day = GLOBAL.GetClock().numcycles
            day = day % reset_attack_days
            local time = 130
            if day < 5 then
                time = 960   -- 1 bat every 2 days
            elseif day < 10 then
                time = 720   -- 1 bat every 1.5 days
            elseif day < 20 then
                time = 480    -- 1 bat a day
            elseif day < 40 then
                time = 360	-- 1.5 bats / day
            else
                time = 240	-- 2 bats / day
            end
            --local time =  math.max((1/(0.5 + 0.19*day + 0.0078*day^2 - 0.000092*day^3) * TUNING.TOTAL_DAY_TIME * 1.2), 0.1 * TUNING.TOTAL_DAY_TIME)
            if self.diffmod then
                time = time * self.diffmod
            end
            return time -- 2
        end
    end)
end

-- F5 SAVE / F9 LOAD --
local save_load = GetModConfigData("save_load")
if save_load then
    dprint("/AAT enabling F5 SAVE / F9 LOAD")
    STRINGS.UI.SAVELOAD = {}
    STRINGS.UI.SAVELOAD.SAVETITLE = "Quicksave"
    STRINGS.UI.SAVELOAD.SAVEBODY = "Do you want to save the game?"
    STRINGS.UI.SAVELOAD.LOADTITLE = "Quickload"
    STRINGS.UI.SAVELOAD.LOADBODY = "Do you want to reload the latest save?"

    local instant = save_load == "instant"

    AddSimPostInit(function()
        local function exit()
            GLOBAL.TheFrontEnd:PopScreen()
            GLOBAL.SetPause(false)
        end

        local function quit()
            GLOBAL.TheFrontEnd:Fade(false, 1, function() GLOBAL.StartNextInstance() end)
        end

        -- F5 Save
	    GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_F5, function()
            dprint("/AAT F5 quicksaving")
            if instant then
                GLOBAL.GetPlayer().components.autosaver:DoSave()
                return
            end
		    if GLOBAL.inGamePlay and GLOBAL.GetPlayer() and not GLOBAL.IsPaused() then
                GLOBAL.SetPause(true)
                local PopupDialogScreen = GLOBAL.require("screens/popupdialog")
                local function savegame()
                    GLOBAL.GetPlayer().components.autosaver:DoSave()
                    GLOBAL.TheFrontEnd:PopScreen()
                    GLOBAL.SetPause(false)
                end

            	GLOBAL.TheFrontEnd:PushScreen(PopupDialogScreen(
                    STRINGS.UI.SAVELOAD.SAVETITLE, STRINGS.UI.SAVELOAD.SAVEBODY,
			        {{text=STRINGS.UI.OPTIONS.YES,      cb=savegame},
			         {text=STRINGS.UI.PAUSEMENU.QUIT,   cb=quit},
                     {text=STRINGS.UI.OPTIONS.NO,       cb=exit}}))
            end
        end)

        -- F9 Load
        GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_F9, function()
            dprint("/AAT F9 quicksaving")
            local function loadgame()
                GLOBAL.TheFrontEnd:HideConsoleLog()
                GLOBAL.TheSim:SetDebugRenderEnabled(false)

                GLOBAL.GetPlayer().HUD:Hide()

                GLOBAL.TheFrontEnd:Fade(false, 1, function()
                GLOBAL.StartNextInstance({reset_action=GLOBAL.RESET_ACTION.LOAD_SLOT,
                    save_slot=GLOBAL.SaveGameIndex:GetCurrentSaveSlot()}, true)
                end)
            end
            if instant then
                loadgame()
                return
            end
		    if GLOBAL.inGamePlay and GLOBAL.GetPlayer() and not GLOBAL.IsPaused() then
                GLOBAL.SetPause(true)
                local PopupDialogScreen = GLOBAL.require("screens/popupdialog")

            	GLOBAL.TheFrontEnd:PushScreen(PopupDialogScreen(
                    STRINGS.UI.SAVELOAD.LOADTITLE, STRINGS.UI.SAVELOAD.LOADBODY,
			        {{text=STRINGS.UI.OPTIONS.YES,      cb=loadgame},
			         {text=STRINGS.UI.PAUSEMENU.QUIT,   cb=quit},
                     {text=STRINGS.UI.OPTIONS.NO,       cb=exit}}))
            end
        end)
	end)
end

-- BOOMERANG CATCH --
local boomerang_catch = GetModConfigData("boomerang_catch")
if boomerang_catch then
    dprint("/AAT enabling BOOMERANG CATCH MODE: " .. boomerang_catch)
    AddPrefabPostInit("boomerang", function(inst)
        local orig_Hit = inst.components.projectile.Hit
        local orig_OnUpdate = inst.components.projectile.OnUpdate
        local orig_Catch = inst.components.projectile.Catch
        local drop_timeout = 3
        local speed_threshold = 1
        
        function inst.components.projectile:Hit(target)
            dprint("/AAT projectile:Hit")
            if target == self.owner and target.components.catcher then
                dprint("/AAT target is owner, overriding Hit behaviour")
                if boomerang_catch == "drop" and self.homing then
                    self:SetHoming(false)
                    self._returned = true
                    self._original_speed = self.speed
                    self._timeout = drop_timeout
                elseif boomerang_catch == "auto" then
                    target.components.catcher:PrepareToCatch()
                end
            else
                dprint("/AAT target is not owner, executing original Hit")
                orig_Hit(self, target)
            end
        end
        
        function inst.components.projectile:OnUpdate(dt)
            orig_OnUpdate(self, dt)
            if self._returned and boomerang_catch == "drop" then
                dprint("/AAT projectile:OnUpdate drop")
                self._timeout = self._timeout - dt
                if self._original_speed then
                    self.speed = (self._timeout / drop_timeout)^2 * self._original_speed
                    self.inst.Physics:SetMotorVel(self.speed, 0, 0)
                end
                if self.speed < speed_threshold then
                    self:_ResetReturned()
                    self:Stop()
                    self.inst.Physics:Stop()
                    self.inst.AnimState:PlayAnimation("idle")
                end
            end
        end
        
        function inst.components.projectile:Catch(catcher)
            dprint("/AAT projectile:Catch")
            if boomerang_catch == "drop" and self._returned then self:_ResetReturned() end
            orig_Catch(self, catcher)
        end
        
        function inst.components.projectile:_ResetReturned()
            dprint("/AAT projectile:_ResetReturned")
            self._returned = false
            self._timeout = nil
            if not self.homing then self:SetHoming(true) end
            if self._original_speed then
                self.speed = self._original_speed
                self.inst.Physics:SetMotorVel(self.speed, 0, 0)
            end
        end
    end)
end

-- RABBITS MAKE HOLES --
if GetModConfigData("rabbit_hole") then
    dprint("/AAT enabling RABBITS MAKE HOLES")
    -- Add MAKERABBITHOLE action
    local MAKERABBITHOLE = GLOBAL.Action({},4, false, false, 0)
    MAKERABBITHOLE.str = "Make Rabbit Hole"
    MAKERABBITHOLE.id = "MAKERABBITHOLE"
    MAKERABBITHOLE.fn = function(act)
        dprint("/AAT MAKERABBITHOLE.fn")
        if act.doer and act.doer.prefab == "rabbit" then
            local rabbithole = GLOBAL.SpawnPrefab("rabbithole")
            local pos = act.doer:GetPosition()
            rabbithole.Transform:SetPosition(pos.x, pos.y, pos.z)
            rabbithole:PushEvent("confignewhome", {rabbit=act.doer})
            act.doer.needs_home_time = nil
            return true
        end
    end
    AddAction(MAKERABBITHOLE)

    -- Modify rabbit prefab
    AddPrefabPostInit("rabbit", function(inst)
        -- Edit ondrop function
        local function ondrop(inst)
            dprint("/AAT rabbit ondrop")
        	inst.sg:GoToState("stunned")
	        inst.CheckTransformState(inst)
            if not (inst.components.homeseeker and inst.components.homeseeker.home and inst.components.homeseeker.home:IsValid()) and not GLOBAL.GetWorld():IsCave() then
                inst.needs_home_time = GLOBAL.GetTime()
            end
            dprint("/AAT needs_home_time " .. inst.needs_home_time)
        end

        inst.components.inventoryitem:SetOnDroppedFn(function(inst)
            if enabledAnyDLC then
                inst.components.perishable:StopPerishing()
            end
            ondrop(inst)
        end)

        -- Edit OnSave function
        local orig_OnSave = inst.OnSave
        inst.OnSave = function(inst, data)
            dprint("/AAT rabbit OnSave")
            orig_OnSave(inst, data)
            data.needs_home_time = inst.needs_home_time and (GLOBAL.GetTime() - inst.needs_home_time) or nil
        end

        -- Edit OnLoad function
        local orig_OnLoad = inst.OnLoad
        inst.OnLoad = function(inst, data)
            dprint("/AAT rabbit OnLoad")
            orig_OnLoad(inst, data)
            if data then
                inst.needs_home_time = data.needs_home_time and -data.needs_home_time or nil
            end
        end

        -- Add make_home_delay
        inst.make_home_delay = math.random(5,10)
    end)

    -- Modify rabbithole prefab
    AddPrefabPostInit("rabbithole", function(inst)
        -- Edit confignewhome and ownership events
        local function confignewhome(inst, data)
            if inst.spawner_config_task then inst.spawner_config_task:Cancel() end
            if data.rabbit then inst.components.spawner:TakeOwnership(data.rabbit) end
            inst.components.spawner:Configure( "rabbit", TUNING.RABBIT_RESPAWN_TIME)
        end

        inst:ListenForEvent("confignewhome", confignewhome)
	    -- inst.spawner_config_task = inst:DoTaskInTime(1, function(inst)
		--     inst.components.spawner:Configure( "rabbit", TUNING.RABBIT_RESPAWN_TIME)
		--     inst.spawner_config_task = nil
        -- end)

        -- Edit dig_up function
        local function dig_up(inst, chopper)
            dprint("/AAT rabbithole dig_up")
            if inst.components.spawner.child and not inst.components.spawner.child:HasTag("INLIMBO") then
                inst.components.spawner.child.needs_home_time = GLOBAL.GetTime()
            end
            if inst.components.spawner:IsOccupied() then
                inst.components.spawner:ReleaseChild()
                inst.components.spawner.child.needs_home_time = GLOBAL.GetTime()
            end
            inst:Remove()
        end
        inst.components.workable:SetOnFinishCallback(dig_up)
    end)

    -- Modify rabbitbrain
    AddBrainPostInit("rabbitbrain", function(self)
        local function ShouldMakeHome(inst)
            local make_home = false
            if not (inst.components.homeseeker and inst.components.homeseeker.home and inst.components.homeseeker.home:IsValid()) then
                make_home = true
            end
            make_home = make_home and (inst.needs_home_time and (GLOBAL.GetTime() - inst.needs_home_time > inst.make_home_delay))
            -- dprint("/AAT rabbit make_home: " .. tostring(make_home))
            return make_home
        end

        local function MakeNewHomeAction(inst)
            dprint("/AAT MakeNewHomeAction")
            local angle = math.random(0,360)
            local offset = GLOBAL.FindGroundOffset(inst:GetPosition(), angle*GLOBAL.DEGREES, math.random(5,15), 120, false, false)
            return GLOBAL.BufferedAction(inst, nil, GLOBAL.ACTIONS.MAKERABBITHOLE, nil, inst:GetPosition() + offset)
        end

        if self.bt and self.bt.root and self.bt.root.children then
            local makehome_node = GLOBAL.WhileNode(
                    function() return ShouldMakeHome(self.inst) end, "HomeDugUp",
                    GLOBAL.DoAction(self.inst, MakeNewHomeAction, "make home", false)
            )

            table.insert(self.bt.root.children, 4, makehome_node)
            
            -- if DEBUG then
            --     dprint("==== RABBIT BT DUMP ====")
            --     DumpBTNode(self.bt.root, "/AAT ")
            -- end
        end
    end)

    -- Add SG ActionHandler
    AddStategraphActionHandler("rabbit", GLOBAL.ActionHandler(GLOBAL.ACTIONS.MAKERABBITHOLE, "make_rabbithole"))

    -- Add SG State
    AddStategraphState("rabbit",
        GLOBAL.State{
        name = "make_rabbithole",
        tags = {"busy"},
        onenter = function(inst, playanim)
            inst.data.donelooking = nil
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("lookdown_pre")
            inst.AnimState:PushAnimation("lookdown_loop", true)
            inst.sg:SetTimeout(1 + math.random()*1)

        end,
        ontimeout = function(inst)
            inst.data.donelooking = true
            inst.AnimState:PlayAnimation("lookdown_pst")
        end,
        events=
        {
            GLOBAL.EventHandler("animover", function(inst, data)
                if inst.data.donelooking then
                    inst:PerformBufferedAction()
                    inst.SoundEmitter:PlaySound(inst.sounds.hurt)
                    inst.sg:GoToState("idle")
                end
            end),
        },
    })
end

-- Pickable:Pick bugfix for vanilla and DLCs
local function PickablePickBugFix(inst)
    function inst:Pick(picker)
        if self.canbepicked and self.caninteractwith then
            if self.transplanted and self.cycles_left ~= nil then
                self.cycles_left = math.max(0, self.cycles_left - 1)
            end

            if enabledAnyDLC then
                if self.protected_cycles ~= nil then
                    self.protected_cycles = self.protected_cycles - 1
                    if self.protected_cycles <= 0 then
                        if not self:IsWithered() then
                            self:MakeWitherable()
                        end
                    end
                end
            end

            local loot = nil
            if picker and picker.components.inventory and self.product then
                loot = GLOBAL.SpawnPrefab(self.product)

                if loot then
                    if self.numtoharvest > 1 and loot.components.stackable then
                        loot.components.stackable:SetStackSize(self.numtoharvest)
                    end

                    -- Moisture handling, ROG
                    if enabledROG then
                        local targetMoisture = 0

                        if self.inst.components.moisturelistener then
                            targetMoisture = self.inst.components.moisturelistener:GetMoisture()
                        elseif self.inst.components.moisture then
                            targetMoisture = self.inst.components.moisture:GetMoisture()
                        else
                            targetMoisture = GLOBAL.GetWorld().components.moisturemanager:GetWorldMoisture()
                        end

                        loot.targetMoisture = targetMoisture
                        loot:DoTaskInTime(2*GLOBAL.FRAMES, function()
                            if loot.components.moisturelistener then 
                                loot.components.moisturelistener.moisture = loot.targetMoisture
                                loot.targetMoisture = nil
                                loot.components.moisturelistener:DoUpdate()
                            end
                        end)
                    -- Moisture handling, SHIP and PORKLAND
                    elseif enabledSHIP or enabledPORK then
                        self.inst:ApplyInheritedMoisture(loot)
                    end

                    picker:PushEvent("picksomething", {object = self.inst, loot= loot})
                    picker.components.inventory:GiveItem(loot, nil, GLOBAL.Vector3(GLOBAL.TheSim:GetScreenPos(self.inst.Transform:GetWorldPosition())))
                end
            end

            if self.onpickedfn then
                self.onpickedfn(self.inst, picker, loot)
            end
            self.canbepicked = false
            if enabledAnyDLC then
                self.hasbeenpicked = true
            end

            local can_regen = not self.paused and (self.cycles_left == nil or self.cycles_left > 0)
            -- Vanilla: check on regentime only
            if vanilla then
                can_regen = can_regen and self.regentime
            -- DLCs: also check withered and baseregentime
            elseif enabledAnyDLC then 
                can_regen = can_regen and not self.withered and self.baseregentime
                -- PORK: also check inst:IsValid()
                if enabledPORK then
                    can_regen = can_regen and self.inst:IsValid()
                end
            end

            if can_regen then
                -- Vanilla: use regentime if getregentimefn not exists
                if vanilla then
                    self.regentime = self.getregentimefn and self.getregentimefn(self.inst) or self.regentime
                -- ROG: use baseregentime if getregentimefn not exists, unless IsSpring
                elseif enabledROG and GLOBAL.GetSeasonManager():IsSpring() then
                        local time = self.getregentimefn and self.getregentimefn(self.inst) or self.baseregentime
                        self.regentime = time * TUNING.SPRING_GROWTH_MODIFIER
                -- SHIP and PORK: use baseregentime if getregentimefn not exists and GetGrowthMod
                elseif enabledSHIP or enabledPORK then
                    local time = self.getregentimefn and self.getregentimefn(self.inst) or self.baseregentime
                    self.regentime = time * self:GetGrowthMod()
                end
                self.task = self.inst:DoTaskInTime(self.regentime, function(inst)
                    if inst.components.pickable then inst.components.pickable:Regen() end
                end, "regen")
                self.targettime = GLOBAL.GetTime() + self.regentime
            end

            local pickeddata = { picker = picker, loot = loot }
            if enabledAnyDLC then
                pickeddata.plant = self.inst
            end
            self.inst:PushEvent("picked", pickeddata)
        end
    end
end

-- FERTILIZATION --
local fertilization = GetModConfigData("fertilization")
if fertilization then
    dprint("/AAT enabling FERTILIZATION MODE: " .. fertilization)
    -- Vanilla bugfix
    if fertilization == "bugfix" then
    -- Replace inst.components.pickable.getregentimefn for berrybushes
    local function BerryBushTimeBugFix(inst)
        if not inst.components.pickable then return end
        inst.components.pickable.getregentimefn = function(inst)
            dprint("/AAT getregentimefn called")
            if inst.components.pickable then
                local num_cycles_passed = math.max(inst.components.pickable.max_cycles - inst.components.pickable.cycles_left, 0)
                local regentime = TUNING.BERRY_REGROW_TIME + TUNING.BERRY_REGROW_INCREASE*num_cycles_passed + math.random()*TUNING.BERRY_REGROW_VARIANCE
                dprint("/AAT pickable.getregentimefn cycles: " .. num_cycles_passed .. "/" .. inst.components.pickable.max_cycles)
                dprint("/AAT pickable.getregentimefn regentime / days: " .. regentime / total_day_time)
                return regentime
            else
                return TUNING.BERRY_REGROW_TIME
            end
        end
    end
    AddPrefabPostInit("berrybush", BerryBushTimeBugFix)
    AddPrefabPostInit("berrybush2", BerryBushTimeBugFix)
    AddComponentPostInit("pickable", PickablePickBugFix)

    -- Fertilize only once, no variance in growth time
    elseif fertilization == "infinite" then
        TUNING.BERRYBUSH_CYCLES = MAX_INT

        local function OnPickedReset(inst, orig_onpickedfn)
            inst.components.pickable.onpickedfn = function(inst, picker)
                dprint("/AAT resetting pickable cycles")
                inst.components.pickable.max_cycles = MAX_INT
                inst.components.pickable.cycles_left = MAX_INT
                orig_onpickedfn(inst, picker)
            end
        end

        local function PickableInit(inst)
            OnPickedReset(inst, inst.components.pickable.onpickedfn)
            -- Override getregentimefn if exists (berrybushes)
            if inst.components.pickable and inst.components.pickable.getregentimefn then
                inst.components.pickable.getregentimefn = function(inst)
                    return TUNING.BERRY_REGROW_TIME
                end
            end
        end

        AddPrefabPostInit("berrybush", PickableInit)
        AddPrefabPostInit("berrybush2", PickableInit)
        AddPrefabPostInit("grass", PickableInit)

        if enabledSHIP or enabledPORK then
            local function OnHackedReset(inst, orig_onhackedfn)
                inst.components.hackable.onhackedfn = function(inst, hacker, hacksleft)
                    if(hacksleft <= 0) then
                        dprint("/AAT resetting hackable cycles")
                        inst.components.hackable.max_cycles = MAX_INT
                        inst.components.hackable.cycles_left = MAX_INT
                    end
                    orig_onhackedfn(inst, hacker, hacksleft)
                end
            end

            local function HackableInit(inst)
                OnHackedReset(inst, inst.components.hackable.onhackedfn)
            end

            AddPrefabPostInit("bambootree", HackableInit)
            AddPrefabPostInit("bush_vine", HackableInit)
            if enabledPORK then
                AddPrefabPostInit("grass_tall", HackableInit)
            end

        end

    -- Fertilization improves growth cycle and growth time
    elseif fertilization == "improved" then
        -- Remove 1 cycle from berrybushes, as it is added at the first Fertilize
        TUNING.BERRYBUSH_CYCLES = TUNING.BERRYBUSH_CYCLES - 1
        
        -- Fix Pick not calling getregentimefn
        AddComponentPostInit("pickable", PickablePickBugFix)

        -- Replace Pickable:Fertilize
        AddComponentPostInit("pickable", function(inst)
            function inst:Fertilize(fertilizer, doer)
                dprint("/AAT Pickable:Fertilize")
                -- Vanilla branch
                if vanilla then
                    fertilizer:Remove()
                    self.max_cycles = self.max_cycles + 1
                    self.cycles_left = self.max_cycles
                    self:MakeEmpty()
                -- DLCs branch
                else
                    if self.inst.components.burnable ~= nil then
                        self.inst.components.burnable:StopSmoldering()
                    end

                    if fertilizer.components.finiteuses then
                        fertilizer.components.finiteuses:Use()
                    else
                        fertilizer.components.stackable:Get(1):Remove()
                    end

                    local fertilize_cycles = fertilizer.components.fertilizer ~= nil and fertilizer.components.fertilizer.withered_cycles or 0

                    self.protected_cycles = (self.protected_cycles or 0) + fertilize_cycles

                    if not self.highfertilizerconsumer then
                        self.protected_cycles = math.max(self.protected_cycles, 0)
                    end

                    if self.withered then
                        self:Rejuvenate(fertilizer)
                        return
                    end
                    self.max_cycles = self.max_cycles + 1
                    self.cycles_left = self.max_cycles
                    self:MakeEmpty()
                end
            end
        end)
        -- Replace inst.components.pickable.getregentimefn for berrybushes
        local BERRY_REGROW_AMP = 7
        local BERRY_REGROW_FLOOR = 3
        local BERRY_REGROW_SCATTER = 5

        local function PickableRegenTimeInit(inst)
            if not inst.components.pickable then return end
            inst.components.pickable.getregentimefn = function(inst)
                    dprint("/AAT pickable.getregentimefn")

                    local max_cycles = inst.components.pickable.max_cycles
                    if max_cycles == nil or max_cycles <= 0 then
                        return BERRY_REGROW_FLOOR
                    end

                    local cycles_left = inst.components.pickable.cycles_left
                    local num_cycles_passed = math.max(max_cycles - cycles_left, 0)

                    local x = num_cycles_passed / max_cycles
                    -- regrowth time decreases with number of fertilizations
                    local amp = (BERRY_REGROW_AMP / max_cycles) ^ 2
                    -- smoothstep function
                    local s = 1.0 - math.exp(-4.0 * x * x)
                    -- positive-only noise, shrinking with max_cycles
                    local noise = (BERRY_REGROW_SCATTER / max_cycles)^2 * math.random()
                    
                    local regentime = (BERRY_REGROW_FLOOR + amp * s + noise) * total_day_time
                    dprint("/AAT pickable.getregentimefn cycles: " .. cycles_left .. "/" .. max_cycles)
                    dprint("/AAT pickable.getregentimefn regentime / days: " .. regentime / total_day_time)
                    return regentime
            end
        end
        AddPrefabPostInit("berrybush", PickableRegenTimeInit)
        AddPrefabPostInit("berrybush2", PickableRegenTimeInit)

        if enabledSHIP or enabledPORK then
            -- Replace Hackable:Fertilize
            AddComponentPostInit("hackable", function(inst)
                function inst:Fertilize(fertilizer)
                    dprint("/AAT Hackable:Fertilize")
                    if self.inst.components.burnable then
                        self.inst.components.burnable:StopSmoldering()
                    end

                    if fertilizer.components.finiteuses then
                        fertilizer.components.finiteuses:Use()
                    else
                        fertilizer.components.stackable:Get(1):Remove()
                    end
                    self.max_cycles = self.max_cycles + 1
                    self.cycles_left = self.max_cycles

                    if self.withered or self.shouldwither then
                        self:Rejuvenate(fertilizer)
                    end
                    self:MakeEmpty()
                end
            end)
        end
    end
end

-- MANDRAKE RESPAWN --
if GetModConfigData("mandrake_respawn") then
    dprint("/AAT enabling MANDRAKE RESPAWN")

    local function RespawnMandrake(user)
        local pt = GLOBAL.Vector3(user.Transform:GetWorldPosition())

        local offset
        local spawn_pt
        local max_tries = 20

        for i = 1, max_tries do
            local theta  = math.random() * 2 * math.pi
            local radius = 100 + 100 * math.random()
            offset = GLOBAL.FindWalkableOffset(pt, theta, radius, 12, true)
            if offset ~= nil then
                spawn_pt = pt + offset
                break
            end
        end

        if spawn_pt == nil then
            spawn_pt = pt -- nothing found, spawn at player position
        end
        
        dprint("/AAT spawining mandrake at " .. tostring(spawn_pt))
        local mandrake = GLOBAL.SpawnPrefab("mandrake")
        if mandrake then
            mandrake.Physics:Teleport(spawn_pt:Get())
            mandrake:FacePoint(pt)
        end
    end


    local function OnEatenInit(inst)
        local orig_oneaten = inst.components.edible.oneaten
        inst.components.edible:SetOnEatenFn(function(inst, eater)
            RespawnMandrake(eater)
            orig_oneaten(inst, eater)
        end)
    end

    local function OnEatenSoupInit(inst)
        inst.components.edible:SetOnEatenFn(function(inst, eater)
            RespawnMandrake(eater)
        end)
    end

    local function OnFinishedInit(inst)
        local orig_onfinished = inst.components.finiteuses.onfinished
        inst.components.finiteuses:SetOnFinished(function(inst)
            RespawnMandrake(inst.components.inventoryitem.owner)
            orig_onfinished(inst)
        end)
    end

    AddPrefabPostInit("mandrake", OnEatenInit)
    AddPrefabPostInit("cookedmandrake", OnEatenInit)
    AddPrefabPostInit("mandrakesoup", OnEatenSoupInit)
    AddPrefabPostInit("panflute", OnFinishedInit)
end