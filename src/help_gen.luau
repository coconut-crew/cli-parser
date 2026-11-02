const typedef = require(`@mediator/typedef`)
const colorful = require(`@ext/utils/colorful`)

const modifier = colorful.modifier
const bold = modifier.bold
const dim = modifier.dim

const module = {}

function module.help_config(): typedef.HelpGenConfig
	return {
		sections_enabled = false,
		sections_design = `=`,
		sections_width = 90,
		sections_pad_above = 0,
		sections_pad_below = 0,

		args_enabled = true,
		args_args_text = `required `,
		args_opts_text = `optional `,
		args_positionals_text = `positional `,
		args_column_wrapping = 80,
		args_alignment = `never`,
		args_aliases = true,

		args_separator = function(ideal_width: number): string
			return string.rep(` `, ideal_width)
		end,
		args_newline = function(width: number): string
			return `\n{string.rep(` `, width)}`
		end,
		args_annotation = function(args: { string }): string
			const count = #args
			if count == 0 then
				return ``
			elseif count == 1 then
				return `: {args[1]}`
			else
				const annotation = table.concat(args, ` `)

				return `: {annotation}`
			end
		end,
	}
end

const function append_section(str: string, config: typedef.HelpGenConfig): string
	if not config.sections_enabled then
		str ..= `\n\n`
		return str
	end

	str ..= string.rep(`\n`, config.sections_pad_above + 1)

	if #config.sections_design ~= 0 then
		str ..= string.rep(
			config.sections_design,
			math.ceil(config.sections_width / #config.sections_design)
		)
	end

	str ..= string.rep(`\n`, config.sections_pad_below + 1)

	return str
end

const function arg_category(
	usage_strings: { string },
	category: string,
	config: typedef.HelpGenConfig
): string
	const wrapping_size = config.args_column_wrapping
	const thin_separator = config.args_separator(1)
	const thin_separator_size = #thin_separator

	const lines: { { string } }, line_widths: { number } = {}, {}

	local working_line: { string } = {}
	local working_line_width: number = 0

	for _, usage_string in usage_strings do
		const usage_string_len = #usage_string

		if working_line_width == 0 then
			working_line_width = usage_string_len
			table.insert(working_line, usage_string)
			continue
		end

		const new_line_width = working_line_width + usage_string_len + thin_separator_size

		if new_line_width < wrapping_size then
			working_line_width = new_line_width
			table.insert(working_line, usage_string)
			continue
		end

		table.insert(lines, working_line)
		table.insert(line_widths, working_line_width)
		working_line, working_line_width = { usage_string }, usage_string_len
	end

	if next(working_line) then
		table.insert(lines, working_line)
		table.insert(line_widths, working_line_width)
		working_line, working_line_width = {}, 0
	end

	const prefix_len = #category
	-- ansi codes add length to the prefix
	const prefix = bold(category)
	local suffix = ``

	const lines_count = #lines
	if lines_count == 0 then
		return `{prefix} {dim(`( none )`)}`
	end

	if lines_count == 1 then
		return prefix .. dim(table.concat(lines[1], thin_separator))
	end

	const newline = config.args_newline(prefix_len)

	if config.args_alignment == `never` then
		for i, line in lines do
			suffix ..= table.concat(line, thin_separator)

			if i ~= lines_count then
				suffix ..= newline
			end
		end

		return prefix .. dim(suffix)
	elseif config.args_alignment == `always` then
		const output_strings = {}

		for i = 1, lines_count - 1 do
			const line, line_width = lines[i], line_widths[i]

			const total_remaining = wrapping_size - line_width
			if total_remaining <= 0 then
				table.insert(output_strings, table.concat(line, thin_separator))
				continue
			end

			const str_count = #line
			if str_count == 1 then
				table.insert(output_strings, line[1])
				continue
			end

			const separator_count = str_count - 1

			const ideal_width = total_remaining / separator_count
			print(ideal_width)
			if ideal_width <= 1 then
				table.insert(output_strings, table.concat(line, thin_separator))
				continue
			end

			const remainder = total_remaining % separator_count
			if remainder == 0 then
				table.insert(output_strings, config.args_separator(ideal_width))
				continue
			end

			const min_width = ideal_width // 1
			const min_separator = config.args_separator(min_width)

			const max_separator = config.args_separator(min_width + 1)

			if remainder == 1 then
				line[str_count] = max_separator .. line[str_count]
				for idx = 2, str_count - 1 do
					line[idx] = min_separator .. line[idx]
				end
			elseif remainder == 2 then
				line[2] = max_separator .. line[2]
				line[str_count] = max_separator .. line[str_count]
				for idx = 3, str_count - 1 do
					line[idx] = min_separator .. line[idx]
				end
			else
				const ma = {
					[1] = true,
					[separator_count] = true,
				}

				for _ = 3, remainder do
					local best_left, best_right, best_size = 0, 0, -1

					local left = 1

					for right = 2, separator_count do
						if ma[right] then
							const size = right - left

							if size >= best_size then
								best_size, best_left, best_right = size, left, right
							end

							left = right
						end
					end

					const middle = (best_left + best_right + 1) // 2
					ma[middle] = true
				end

				for idx = 2, str_count do
					if ma[idx - 1] then
						line[idx] = max_separator .. line[idx]
					else
						line[idx] = min_separator .. line[idx]
					end
				end
			end

			table.insert(output_strings, table.concat(line))
		end

		table.insert(output_strings, table.concat(lines[lines_count], thin_separator))

		suffix ..= table.concat(output_strings, newline)
	end

	return prefix .. dim(suffix)
end

function module.cli_args(cli: typedef.Command, config: typedef.HelpGenConfig): string
	const required_strings: { string } = {}
	const optional_strings: { string } = {}

	for _, arg in cli._option_set do
		if arg._is_positional then
			continue
		end

		const alias_usage_list = {}

		if config.args_aliases then
			for _, alias in arg._alias_list do
				table.insert(alias_usage_list, `-{alias}`)
			end
		end

		table.insert(alias_usage_list, `--{arg._name}`)

		local arg_usage_str = `[{table.concat(alias_usage_list, ` | `)}`

		if config.args_annotation then
			const arg_annotations = {}
			if not (arg :: typedef.Flag)._flag then
				table.insert(arg_annotations, arg._typename)
			end

			for _, positional in arg._positional_list do
				table.insert(arg_annotations, positional._typename)
			end

			arg_usage_str ..= config.args_annotation(arg_annotations)
		end

		arg_usage_str ..= `]`

		if (arg :: typedef.Flag)._flag or (arg :: typedef.Default<any>)._has_default then
			table.insert(optional_strings, arg_usage_str)
		else
			table.insert(required_strings, arg_usage_str)
		end
	end

	local output = ``

	if #required_strings ~= 0 then
		output ..= arg_category(required_strings, config.args_args_text, config)
		if #optional_strings ~= 0 then
			output = append_section(output, config)
		end
	end

	if #optional_strings ~= 0 then
		output ..= arg_category(optional_strings, config.args_opts_text, config)
	end

	const positionals_strings: { string } = {}

	for _, positional in cli._positional_list do
		table.insert(positionals_strings, positional._typename)
	end

	const tail_list = cli._trailing_list
	if tail_list then
		for _, tail in tail_list do
			table.insert(positionals_strings, `{tail._typename}?`)
		end
	end

	if not tail_list or #tail_list == 0 then
		if #cli._positional_list == 0 then
			table.insert(positionals_strings, `( none )`)
		else
			table.insert(positionals_strings, `( none optional )`)
		end
	elseif #cli._positional_list == 0 then
		table.insert(positionals_strings, `( none required )`)
	end

	if #positionals_strings ~= 0 then
		const categorized =
			arg_category(positionals_strings, config.args_positionals_text, config)
		output = `{categorized}\n\n{output}`
	end

	return output
end

function module.cli_helpscreen(
	cli: typedef.Command,
	config: typedef.HelpGenConfig
): string
	local output = bold(cli._name)

	if cli.helpline then
		output ..= `; {cli.helpline}`
	end

	if cli.helpparagraph then
		output ..= `\n\n{cli.helpparagraph}`
	end

	if config.args_enabled then
		output ..= `\n\n`
		output ..= module.cli_args(cli, config)
	end

	return output
end

function module.help_screen(obj: unknown, helpgen_options: typedef.HelpGenConfig?): string
	if type(obj) ~= `table` then
		return `An object ({obj})`
	end

	const metatable: unknown = getmetatable(obj)

	if metatable == `mediator-cli` then
		helpgen_options = helpgen_options or module.help_config()
		return module.cli_helpscreen(obj :: typedef.Command, helpgen_options)
	elseif metatable == `mediator-arg` then
		-- TODO
	end

	const helpline = rawget(obj :: any, `helpline`)
	if not helpline then
		return `An object ({obj})`
	end

	const helpparagraph = rawget(obj :: any, `helpparagraph`)
	if not helpparagraph then
		return helpline
	end

	return `{helpline}\n\n{helpparagraph}`
end

return table.freeze(module)
