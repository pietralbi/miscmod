-- This information tells other players more about the mod
name = "Miscellaneous tweaks"
description = "Compilation of my script mods & tweaks, configurable"
author = "Alberto Pietralunga"

version = "1.1.6"
forumthread = ""

api_version = 6
dont_starve_compatible      = true
reign_of_giants_compatible  = true
shipwrecked_compatible      = true
hamlet_compatible           = true

icon_atlas = "modicon.xml"
icon = "modicon.tex"

-- Configs
local function simpleopt(x)
	return {description = x, data = x}
end

local function append(t, x)
	t[#t + 1] = x
	return t
end

local function prepend(t, x)
    for i = #t, 1, -1 do
        t[i + 1] = t[i]
    end
    t[1] = x
    return t
end

local function range(a, b, step)
	local opts = {}
	for x = a, b, step do
		append(opts, simpleopt(x))
	end
	if #opts > 0 then
		local fdata = opts[#opts].data
		if fdata < b and fdata + step - b < 1e-10 then
			append(opts, simpleopt(b))
		end
	end
	return opts
end

-- CAVE INSULATION --
local ci_opt = range(0, 32, 8)
local ci_opt_ext = range(48, 128, 16)
local ci_opt_ext2 = range(128, 512, 32)
for i = 1, #ci_opt_ext do
	append(ci_opt, ci_opt_ext[i])
end
for i = 1, #ci_opt_ext2 do
	append(ci_opt, ci_opt_ext2[i])
end
ci_opt = prepend(ci_opt, {description = "Off", data = false})

-- CLOSER PLACEMENT --
local cp_opt = range(0.0, 3.2, 0.1)
cp_opt = prepend(cp_opt, {description = "Off", data = false})

-- ATTACKS RESET --
local ar_opt = range(0, 15, 1)
local ar_opt_ext = range(20, 150, 5)
local ar_opt_ext2 = range(160, 300, 10)
for i = 1, #ar_opt_ext do
	append(ar_opt, ar_opt_ext[i])
end
for i = 1, #ar_opt_ext2 do
	append(ar_opt, ar_opt_ext2[i])
end
ar_opt[1] = {description = "Off", data = false}

configuration_options =
{
	{
        name = "mods_warning",
        label = "Remove mods warning",
        options =
	    {
	    	{description = "Off", data = false},
	    	{description = "On", data = true}
	    },
        default = true
	},
	{
        name = "cave_insulation",
        label = "Cave insulation (V:8)",
        options = ci_opt,
        default = 128
	},
	{
        name = "floral_repair",
        label = "Floral & meat repair",
        options =
	    {
	    	{description = "Off", data = false},
	    	{description = "On", data = true}
	    },
        default = true
	},
    {
        name = "petal_divisor",
        label = "Petals",
        options = range(1, 30, 1),
        default = 6,
    },
    {
        name = "cactus_divisor",
        label = "Cactus flowers",
        options = range(1, 30, 1),
        default = 3,
    },
    {
        name = "meat_divisor",
        label = "Meat",
        options = range(1, 30, 1),
        default = 2,
    },
    {
        name = "morsel_divisor",
        label = "Morsel/drumstick",
        options = range(1, 30, 1),
        default = 4,
    },
    {
        name = "close_placement",
        label = "Closer spacing (V:3.2)",
        options = cp_opt,
        default = 1.2
    },
    {
        name = "dont_delete_save",
        label = "Do not delete save",
        options =
	    {
	    	{description = "Off", data = false},
	    	{description = "On", data = true}
	    },
        default = true
    },
    {
        name = "attacks_reset",
        label = "Attacks reset",
        options = ar_opt,
        default = 70
    },
    {
        name = "save_load",
        label = "F5/F9 Save/Load",
        options =
	    {
	    	{description = "Off", data = false},
	    	{description = "On", data = true},
            {description = "No popup", data = "instant"}
	    },
        default = true
    },
    {
        name = "boomerang_catch",
        label = "Boomerang catch",
        options =
        {
            {
                description = "Vanilla",
                data = false
            },
            {
                description = "Drop",
                data = "drop"
            },
            {
                description = "Auto",
                data = "auto"
            }
        },
        default = "drop",
    },
    {
        name = "rabbit_hole",
        label = "Rabbits make holes",
        options =
        {
            {description = "Off", data = false},
            {description = "On", data = true}
        },
        default = false,
    },
}