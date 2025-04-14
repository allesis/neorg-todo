local neorg = require("neorg.core")
local modules, lib, log = neorg.modules, neorg.lib, neorg.log

local treesitter ---@type core.integrations.treesitter

local module = neorg.modules.create("external.todo")
module.setup = function()
	return { success = true, requires = { "core.dirman" } }
end

module.load = function()
	treesitter = module.required["core.integrations.treesitter"]
	dirman = module.required["core.dirman"]

	modules.await("core.neorgcmd", function(neorgcmd)
		neorgcmd.add_commands_from_table({
			todo = { -- this is the name of the subcommand
				name = "external.todo.todo", -- this is the `id` of the subcommand
				args = 1, -- this command takes 1 argument
				complete = { -- we can provide completions for this position in the
					-- command line. see `:h :command-completion-customlist` for more info
					function()
						return dirman.get_workspace_names()
					end,
				},
			},
		})
	end)
end

-- here, we subscribe to the command so that our module is notified when that
-- command fires
module.events.subscribed = {
	["core.neorgcmd"] = {
		["external.todo.todo"] = true,
	},
}

local handlers = {
	["external.todo.todo"] = function(workspace)
		local workspace_table = dirman.get_workspaces()[workspace]
		dirman.touch_file("todo.norg", workspace)
		print(vim.inspect(dirman.get_norg_files(workspace)))
	end,
}

-- And now we set the event handler
module.on_event = function(event)
	-- Have a look at all the information in this event!
	-- vim.print(event)

	local ev_name = event.split_type[2]
	if handlers[ev_name] then
		handlers[ev_name](event.content[1])
	end
end

return module
