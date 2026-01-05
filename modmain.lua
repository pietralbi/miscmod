-- UTILS
local STRINGS = GLOBAL.STRINGS
local TUNING = GLOBAL.TUNING
local hasROG = GLOBAL.TheSim:IsDLCInstalled(GLOBAL.REIGN_OF_GIANTS)
local hasSHIP = GLOBAL.TheSim:IsDLCInstalled(GLOBAL.CAPY_DLC)
local hasPORK = GLOBAL.TheSim:IsDLCInstalled(GLOBAL.PORKLAND_DLC)
local enabledROG = GLOBAL.IsDLCEnabled(GLOBAL.REIGN_OF_GIANTS)
local enabledSHIP = GLOBAL.rawget(GLOBAL, "CAPY_DLC") and GLOBAL.IsDLCEnabled(GLOBAL.CAPY_DLC)
local enabledPORK = GLOBAL.rawget(GLOBAL, "PORKLAND_DLC") and GLOBAL.IsDLCEnabled(GLOBAL.PORKLAND_DLC)
local enabledAnyDLC = enabledROG or enabledSHIP or enabledPORK
local vanilla = not enabledAnyDLC

DEBUG = false

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
    AddPrefabPostInit("forest", function(inst)
        dprint("/AAT forest PostInit")
        local FrogRain = inst.components.frograin
        if not FrogRain then return end
        FrogRain.frogcap = 9007199254740991    -- Remove frog cap
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
    dprint("/AAT enabling BOOMERANG CATCH")
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
            dprint("/AAT rabbit make_home: " .. tostring(make_home))
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
            
            if DEBUG then
                dprint("==== RABBIT BT DUMP ====")
                DumpBTNode(self.bt.root, "/AAT ")
            end
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
