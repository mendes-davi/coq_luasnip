local utils = require("coq_3p.utils")

COQsources = COQsources or {}
local snip_cache = {}
local doc_cache = {}

local function get_documentation(snip, data)
	local header = (snip.name or "") .. " _ `[" .. data.filetype .. "]`\n"
	local docstring = { "", "```" .. vim.bo.filetype, snip:get_docstring(), "```" }
	local documentation = { header .. "---", (snip.dscr or ""), docstring }
	documentation = vim.lsp.util.convert_input_to_markdown_lines(documentation)
	documentation = table.concat(documentation, "\n")

	doc_cache[data.filetype] = doc_cache[data.filetype] or {}
	doc_cache[data.filetype][data.snip_id] = documentation

	return documentation
end

COQsources[utils.new_uid(COQsources)] = {
	name = "LuaSnip",
	fn = function(args, callback)
		-- Check if source is available
		local ok, ls = pcall(require, "luasnip")
		if not ok then
			callback(nil)
			return
		end

		local _, col = unpack(args.pos)
		local line_to_cursor = utils.split_line(args.line, col)
		local cword = utils.cword(args.line, col)

		local filetypes = require("luasnip.util.util").get_snippet_filetypes()
		local items = {}

		for i = 1, #filetypes do
			local ft = filetypes[i]
			if not snip_cache[ft] then
				-- ft not yet in cache.
				local ft_items = {}
				local ft_table = ls.get_snippets(ft, { type = "snippets" })
				if ft_table then
					for j, snip in pairs(ft_table) do
						if not snip.hidden then
							ft_items[#ft_items + 1] = {
								label = snip.trigger,
								insertText = snip.trigger,
								kind = vim.lsp.protocol.CompletionItemKind.Snippet,
								data = {
									luasnip = {
										filetype = ft,
										snip_id = snip.id,
										show_condition = snip.show_condition(line_to_cursor),
									},
								},
								command = {
									title = "",
									command = "",
									arguments = { snip.id },
								},
							}
						end
					end
				end
				snip_cache[ft] = ft_items
			end
			vim.list_extend(items, snip_cache[ft])
		end
		callback({ isIncomplete = true, items = items })
	end,

	resolve = function(args, callback)
		local completion_item = args.item

		if completion_item.data == nil or completion_item.data.luasnip == nil then
			callback(nil)
			return
		end

		local item_snip_id = completion_item.data.luasnip.snip_id
		local ft = completion_item.data.luasnip.filetype
		local documentation
		if doc_cache[ft] and doc_cache[ft][item_snip_id] then
			documentation = doc_cache[ft][item_snip_id]
		else
			local snip = require("luasnip").get_id_snippet(item_snip_id)
			documentation = get_documentation(snip, completion_item.data.luasnip)
		end
		completion_item.documentation = {
			kind = vim.lsp.protocol.MarkupKind.Markdown,
			value = documentation,
		}

		callback(completion_item)
	end,

	exec = function(args, callback)
		local snip_id = args.arguments[1]

		local snip = require("luasnip").get_id_snippet(snip_id)
		-- if trigger is a pattern, expand "pattern" instead of actual snippet.
		if snip.regTrig then
			snip = snip:get_pattern_expand_helper()
		end

		local cursor = vim.api.nvim_win_get_cursor(0)
		-- get_cursor returns (1,0)-indexed position, clear_region expects (0,0)-indexed.
		cursor[1] = cursor[1] - 1

		-- text cannot be cleared before, as TM_CURRENT_LINE and
		-- TM_CURRENT_WORD couldn't be set correctly.
		require("luasnip").snip_expand(snip, {
			-- clear word inserted into buffer by coq.
			-- cursor is currently behind word.
			clear_region = {
				from = {
					cursor[1],
					cursor[2] - #snip.trigger,
				},
				to = cursor,
			},
		})
		callback(nil)
	end,
}
