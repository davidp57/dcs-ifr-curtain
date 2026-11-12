-- IFR curtain: declares the Lua device and the cockpit indicator.
-- Loaded from declare_kneeboard_device.lua, so it runs inside each module's device_init.lua.
-- Does nothing for an aircraft that has no shape in shapes.lua, or whose device id is taken.

local IFR_CURTAIN_DEVICE_ID = 250

local path = LockOn_Options.common_script_path.."IFR_CURTAIN/"
local shapes = dofile(path.."shapes.lua")

if shapes.find(LockOn_Options.script_path) then
	if not creators then
		creators = {}
	end
	if not indicators then
		indicators = {}
	end

	if not creators[IFR_CURTAIN_DEVICE_ID] then
		creators[IFR_CURTAIN_DEVICE_ID] = {"avLuaDevice", path.."device.lua"}

		-- Empty connector list: the indicator is placed in the cockpit frame, like the kneeboard.
		indicators[#indicators + 1] = {"ccIndicator", path.."indicator.lua", IFR_CURTAIN_DEVICE_ID, {{}, {}}}
	end
end
