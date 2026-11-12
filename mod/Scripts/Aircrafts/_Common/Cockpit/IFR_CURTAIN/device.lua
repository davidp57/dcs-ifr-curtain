-- IFR curtain: Lua device that opens and closes the curtain.
-- The curtain state lives in the cockpit parameter IFR_CURTAIN (0 = open, 1 = closed),
-- read by the indicator in page.lua.

local CMD_TOGGLE = 3001
local CMD_CLOSE  = 3002
local CMD_OPEN   = 3003

local dev   = GetSelf()
local state = get_param_handle("IFR_CURTAIN")

dev:listen_command(CMD_TOGGLE)
dev:listen_command(CMD_CLOSE)
dev:listen_command(CMD_OPEN)

local function set_closed(closed)
	if closed then
		state:set(1)
		print_message_to_user("IFR curtain: closed")
	else
		state:set(0)
		print_message_to_user("IFR curtain: open")
	end
end

-- DEBUG: start with the curtain closed, to check the rendering without a key binding.
local START_CLOSED = false

function post_initialize()
	if START_CLOSED then
		state:set(1)
	else
		state:set(0)
	end
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
