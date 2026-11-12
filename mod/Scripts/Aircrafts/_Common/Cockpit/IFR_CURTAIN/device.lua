-- IFR curtain: Lua device that opens and closes the curtain.
-- The curtain state lives in the cockpit parameter IFR_CURTAIN (0 = open, 1 = closed),
-- read by the indicator in page.lua.
--
-- At mission start, the curtain is open when its commands are available (so the pilot can
-- close it with a key), and closed otherwise (the mod is then used on its own, curtain
-- always down). The commands are available when Quaggles' DCS Input Command Injector is
-- installed and the aircraft's injected keyboard file (Custom_Keybinds package) holds them.

local CMD_TOGGLE = 3001
local CMD_CLOSE  = 3002
local CMD_OPEN   = 3003

-- Text that marks the curtain commands in the injected input file.
local COMMAND_NAME = "IFR curtain: toggle"

-- There is no cockpit Lua function that tells whether a command exists: on 2026-11-12, the
-- globals named like input/command/key/bind were only SetCommand, SetGlobalCommand,
-- a_start_listen_command and get_input_devices (input devices, not commands). Hence the file.
-- DEBUG: write those global names to dcs.log again.
local DUMP_INPUT_GLOBALS = false

local dev   = GetSelf()
local state = get_param_handle("IFR_CURTAIN")
local shape = dofile(LockOn_Options.common_script_path.."IFR_CURTAIN/shapes.lua").find(LockOn_Options.script_path)

dev:listen_command(CMD_TOGGLE)
dev:listen_command(CMD_CLOSE)
dev:listen_command(CMD_OPEN)

local function log_info(message)
	if log and log.write then
		log.write("IFR_CURTAIN", log.INFO, message)
	else
		print("IFR_CURTAIN: "..message)
	end
end

-- Returns available (true/false) and the reason, for the log.
local function find_commands()
	if not (shape and shape.input) then
		return false, "no input folder set for this aircraft in shapes.lua"
	end
	local lfs = require("lfs")
	local game = (lfs.currentdir():gsub("[/\\]$", "")).."/"
	local hook = game.."Scripts/Hooks/QuagglesInputCommandInjector.lua"
	if not lfs.attributes(hook) then
		return false, "Quaggles' injector not found ("..hook..")"
	end
	local path = lfs.writedir().."InputCommands/"..shape.input.."/keyboard/default.lua"
	local file = io.open(path, "r")
	if not file then
		return false, "no injected input file ("..path..")"
	end
	local text = file:read("*a")
	file:close()
	if not string.find(text, COMMAND_NAME, 1, true) then
		return false, "the injected input file has no curtain command ("..path..")"
	end
	return true, "curtain commands found ("..path..")"
end

local function dump_input_globals()
	local names = {}
	for name in pairs(_G) do
		local lower = string.lower(tostring(name))
		if lower:find("input") or lower:find("command") or lower:find("key") or lower:find("bind") then
			names[#names + 1] = tostring(name)
		end
	end
	table.sort(names)
	log_info("globals like input/command/key/bind: "..table.concat(names, ", "))
end

local function set_closed(closed, quiet)
	state:set(closed and 1 or 0)
	if not quiet then
		print_message_to_user(closed and "IFR curtain: closed" or "IFR curtain: open")
	end
end

function post_initialize()
	if DUMP_INPUT_GLOBALS then
		pcall(dump_input_globals)
	end
	local ok, available, reason = pcall(find_commands)
	if not ok then
		available, reason = false, "check failed: "..tostring(available)
	end
	log_info((available and "start open: " or "start closed: ")..reason)
	set_closed(not available, true)
end

function SetCommand(command, value)
	if command == CMD_TOGGLE then
		if value > 0 then
			set_closed(state:get() < 0.5)
		end
	elseif command == CMD_CLOSE then
		set_closed(true)
	elseif command == CMD_OPEN then
		set_closed(false)
	end
end

need_to_be_closed = false
