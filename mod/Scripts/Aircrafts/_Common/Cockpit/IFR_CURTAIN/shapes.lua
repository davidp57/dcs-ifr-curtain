-- IFR curtain: the aircraft that get the curtain, and the shape of the bubble for each.
-- Read by declare.lua (an aircraft missing here gets no curtain at all) and by page.lua.
--
-- Each aircraft is matched against its module's cockpit script path. For each, the distance
-- in meters from the cockpit frame origin to each side of the bubble, and its squareness
-- (2 = ellipsoid, higher = closer to a box with rounded edges).
-- The origin is ahead of the pilot's head (A-10C: towards the panel), and roughly centred
-- left-right. Too close and the bubble hides part of the cockpit; too far and the ground or
-- the aircraft's own wings show through the canopy between the frame and the bubble.
--
-- input: the aircraft's folder under Saved Games\DCS\InputCommands (Quaggles' injector),
-- where device.lua looks for the curtain commands to decide whether the curtain starts open.
--
-- A-10C II: walls tuned in flight on 2026-11-12, head at its highest position, canopy closed
-- (ceiling 0.1 cuts the canopy bow, 0.5 shows the outside above it). Down is hidden under
-- the cockpit; 1.5 keeps the floor, pedals and seat inside without stretching the sides.
local shapes = {
	{match = "A-10C_2", shape = {left = 1.0, right = 1.0, up = 0.3, down = 1.5, front = 1.2, back = 1.6, squareness = 3.0,
		input = "A-10C_2/Input/A-10C_2"}},
}

local function find(script_path)
	for _, entry in ipairs(shapes) do
		if string.find(script_path or "", entry.match, 1, true) then
			return entry.shape
		end
	end
	return nil
end

return {find = find}
