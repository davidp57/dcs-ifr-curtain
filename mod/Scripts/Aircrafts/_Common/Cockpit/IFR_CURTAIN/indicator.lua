-- IFR curtain: cockpit indicator, drawn in the 3D cockpit (not in screen space).
dofile(LockOn_Options.common_script_path.."devices_defs.lua")

indicator_type = indicator_types.COMMON
purposes       = {render_purpose.GENERAL}

page_subsets = {LockOn_Options.common_script_path.."IFR_CURTAIN/page.lua"}
pages        = {{1}}
init_pageID  = 1
