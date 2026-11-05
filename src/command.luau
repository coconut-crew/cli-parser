const levenshtein_dist = require("@pkgs/levenshtein_dist")
const typedef = require(`@mediator/typedef`)

const BYTE = string.byte :: (string, offset: number?, finish: number?) -> number
const RAWGET =
	rawget :: <Table, Key>(tbl: Table, key: Key & keyof<Table>) -> rawget<Table, Key>
const READU8 = buffer.readu8

const function quote(str: string): string
	return string.format("%q", str)
end

const commandmt = {
	__metatable = `mediator-cli`,
}
const argmt = {
	__metatable = `mediator-arg`,
}

const function phantom(input: never): never
	return (error)(`internal method only meant for typechecking`)
end

const function err(...: any): ...any
	return (error)(`this cannot be used yet.`, 2)
end

const function parse_str(ctx: typedef.ParseContext): string
	return ctx.peek()
end
const function print_str(ctx: typedef.PrintContext<string>): string
	return string.format("%q", ctx.data)
end

const function constructor<name, cli>(
	command_name: name | "",
	command_decl: (cli) -> (),
	subcommand_levenshtein_dist: number
): typedef.command_dsl<name, cli>
	local completed_cli: typedef.Command?

	const cli: typedef.Command = {
		_t_ = phantom,
		_name = command_name,
		_is_positional = false,
		_typename = ``,

		_alias_list = {},

		_subcommands = {},
		subcommandof = function(supercommand: typedef.Command): ()
			const subcommands = RAWGET(supercommand, `_subcommands`)
			if not subcommands then
				(error)(
					`did you accidentally try to add a subcommand to an arg or something`
				)
			elseif not completed_cli then
				(error)(
					`you cannot add '{command_name}' as a subcommand of other commands until its declaration is completed`
				)
			end

			const existing_subcommand = subcommands[command_name]
			const existing_thing = rawget(supercommand :: any, command_name)

			if existing_subcommand and existing_subcommand ~= completed_cli then
				(error)(
					`cannot declare multiple subcommands of '{supercommand._name}' with the same name ('{command_name}')`
				)
			end

			if existing_thing and existing_thing ~= completed_cli then
				(error)(
					`cannot declare subcommand '{command_name}' of '{supercommand._name}' because it already exists for '{supercommand._name}'`
				)
			end

			subcommands[command_name] = completed_cli
			rawset(supercommand :: any, command_name, completed_cli)
		end,

		_option_set = {},
		_option_list = {},
		_positional_list = {},
		_trailing_list = {},

		_parse = function(ctx): never
			return (error)(`pending implementation`)
		end,
		_print = function(ctx): never
			return (error)(`printing is not yet supported for commands`, 2)
		end,
	}

	const metatable = {
		__index = function(self: { [any]: any }, opt_name: string): unknown
			if cli._option_set[opt_name] then
				error(
					`this shouldn't ever be possible, an option with name {quote(opt_name)} was allocated twice`
				)
			elseif rawget(self, opt_name) then
				error(`tried to add option with reserved name {quote(opt_name)}`)
			elseif BYTE(opt_name) == BYTE("-") then
				error(`option {quote(opt_name)} cannot start with "-"`)
			end

			const opt: typedef.Arg = {
				_t_ = phantom,
				_name = opt_name,
				helpline = `the {quote(opt_name)} argument`,

				_alias_list = {},

				_option_set = {},
				_option_list = {},
				_positional_list = {},
				_trailing_list = false,

				_is_positional = false,
				_typename = `# undefined #`,
				_parse = err,
				_print = err,
			}
			(setmetatable)(opt, argmt)

			self[opt_name] = opt
			cli._option_set[opt_name] = opt
			table.insert(cli._option_list, opt)

			return opt
		end,
	}

	(setmetatable)(cli, metatable)
	-- luau
	command_decl(cli :: any);
	(setmetatable)(cli, commandmt)

	const alias_owners: { [string]: string? } = {}

	for _, arg in cli._option_list do
		for _, alias in arg._alias_list do
			if #alias > 1 then
				return error(
					`cannot currently define aliases with more than one character ({quote(
						alias
					)}); this limitation is likely to be lifted in the future`
				)
			end

			const owner = alias_owners[alias]
			if owner then
				return (error)(
					`alias -{alias} for --{arg._name} is already taken by argument --{owner}`,
					2
				)
			end

			alias_owners[alias] = arg._name
		end

		const parse_undefined, print_undefined = arg._parse == err, arg._print == err

		if parse_undefined and print_undefined then
			arg._parse, arg._print = parse_str, print_str :: any
			arg._typename = `String`
		elseif print_undefined then
			(error)(`--{arg._name} has a parser, but an undefined printer`)
		elseif parse_undefined then
			(error)(`--{arg._name} has a printer, but an undefined parser`)
		end
	end

	const function parse_kind(str: string): "short_opts" | "opt" | "postfix"
		return if BYTE(str) ~= BYTE("-")
			then "postfix"
			elseif BYTE(str, 2) == BYTE("-") then "opt"
			else "short_opts"
	end

	const function parse_subcommand(ctx: typedef.ParseContext): unknown
		const subcommand_name = ctx.consume()
		const subcommands, options = cli._subcommands, cli._option_set

		const target = subcommands[subcommand_name]
		if target then
			return target._parse(ctx)
		end

		local reason = `could not find subcommand with name {quote(subcommand_name)}`

		-- todo(ux):
		-- if someone types "aya pkg webhook send-update-note" and
		-- "aya pkg" has no "webhook" subcommand, we can guess
		-- perhaps they meant "aya iac webhook send-update-note",
		-- because that would parse.
		--
		-- this will require considerable effort and attention to
		-- detail, because we want all of these properties
		-- possible in our parser:
		-- 1: `cmd subcommand --flag --arg 123 subcommand2 ./path`
		-- 2: `cmd -h subcommand` (where "subcommand" is a tail string input to -h) (do we want to do this?)
		-- 3: `cmd invalid_subcommand subcommand` should be able to suggest `cmd subcommand`
		-- 4: performance
		-- 4.1: configurability for some of these features(?)
		-- 4.2: maybe we do "--" convention
		local nearest_subcommand, subcommand_dist =
			levenshtein_dist.restricted_edit_damerau_lookup(
				subcommand_name,
				subcommands,
				subcommand_levenshtein_dist
			)

		local nearest_option = options[subcommand_name] and options[subcommand_name]._name
		local option_dist = 0

		if not nearest_option then
			nearest_option, option_dist = levenshtein_dist.restricted_edit_damerau_lookup(
				subcommand_name,
				subcommands,
				subcommand_levenshtein_dist
			)
		end

		if nearest_option and nearest_subcommand then
			if option_dist < subcommand_dist then
				nearest_subcommand = nil
			else
				nearest_option = nil
			end
		end

		-- todo(ux): re-print the whole command here for easy
		-- copy-paste fixes for users

		if nearest_option and option_dist < subcommand_dist then
			const quoted = quote(nearest_option)
			reason ..= ` - but there is an option with {if option_dist == 0
				then `the same`
				else `a similar`} name: {quoted}`
		elseif nearest_subcommand then
			const quoted = quote(nearest_subcommand)
			reason ..= ` - did you mean to use the subcommand {quoted}?`
		end

		ctx.error(reason, ctx.index())

		return nil
	end

	const function parse_option(ctx: typedef.ParseContext, name: string): unknown
		const options = cli._option_set

		const option = options[name]

		if option then
			if (option :: typedef.Flag)._flag then
				return true
			end

			const parsed = option._parse(ctx)

			ctx.bump()

			return parsed
		end

		-- todo(ux): report similar options
		return ctx.error(`unknown option {quote(name)}`, -1)
	end

	const function cli_parse(ctx: typedef.ParseContext)
		const output = {}

		const positionals = cli._positional_list
		const trails: { typedef.Arg } = cli._trailing_list or {}
		local positionals_left = #positionals
		local trails_left = #trails

		while ctx.remaining() > 0 do
			const peeked = ctx.peek()
			const peeked_index = 1 + ctx.index()

			const kind = parse_kind(peeked)

			if kind == "postfix" then
				if ctx.can_subcommand() then
					output[peeked] = parse_subcommand(ctx)
					break
				else
					if positionals_left > 0 then
						positionals_left -= 1
						const this = positionals[#positionals - positionals_left]

						-- todo: if a positional is passed outright as an
						-- option (our parser allows this for now), we
						-- should prevent it from being accidentally
						-- passed a second time here
						output[this._name] = this._parse(ctx)

						ctx.bump()
					end
				end
			elseif kind == "opt" then
				ctx.bump()

				const opt_name = string.sub(peeked, 3)
				const result = parse_option(ctx, opt_name)

				output[opt_name] = result
			elseif kind == "short_opts" then
				ctx.bump()

				const visited = {}

				-- todo(design, ux): if someone types `-help`, we
				-- should check if there's a matching opt or
				-- subcommand to prevent it parsing as -h -e -l -p,
				-- but this design is non-trivial because we want
				-- shortflags to be programmably accessible (i.e.,
				-- near-ambiguity is bad practice, but machine-written
				-- commands might not care about that). our choices
				-- seem to be between asking users to avoid shortflags
				-- in these cases, or compromising by only adding a
				-- warning when the command is failing anyway].
				for offset = 2, #peeked do
					const character = string.sub(peeked, offset, offset)

					const existing_location = visited[character]
					if existing_location then
						ctx.error(
							`cannot use short-opt {quote(character)} more than once`,
							peeked_index,
							{
								vector.create(existing_location, existing_location),
								vector.create(offset, offset),
							}
						)
						continue
					end
					visited[character] = offset

					const resolved = alias_owners[character]
					if not resolved then
						ctx.error(
							`unknown short-opt {quote(character)}`,
							peeked_index,
							{ vector.create(offset, offset) }
						)
						continue
					end

					output[resolved] = parse_option(ctx, resolved)
				end
			end
		end

		for opt_name, opt in cli._option_set do
			-- todo: maybe maintain a list of all the required ones so theyre easier to check
			if not (opt :: typedef.Required)._required then
				continue
			end

			if output[opt._name] ~= nil then
				continue
			end

			if (opt :: typedef.Flag)._flag then
				output[opt._name] = false
				continue
			end

			error(`missing a required {opt._typename} for arg {opt._name}`)
		end

		return output
	end

	cli._parse = cli_parse

	completed_cli = cli

	return cli :: any
end

return table.freeze({
	new = constructor,
})
