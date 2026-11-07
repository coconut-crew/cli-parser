const ENUM_LEVENSHTEIN_DIST_CUTOFF = 4
const SUBCOMMAND_LEVENSHTEIN_DIST_CUTOFF = 4

const value_parse = require(`./value_parse`)
const typedef = require(`./typedef`)
const path = require(`@std/path`)
const command = require(`./command`)
const help_gen = require(`./help_gen`)

const module = {
	help_screen = help_gen.help_screen,
	help_config = help_gen.help_config,
}

const function add_aliases(clarg: typedef.Arg<any>, aliases: typedef.AddAliases?): ()
	if not aliases then
		return
	end

	for _, alias in aliases :: { string } do
		table.insert(clarg._alias_list, alias)
	end
end

const function parse_str(ctx: typedef.ParseContext): string
	return ctx.peek()
end

const function print_stringified(ctx: typedef.PrintContext<any>): { string }
	local data = tostring(ctx.data)
	data = string.gsub(data, `\\`, `\\\\`)
	data = string.gsub(data, `'`, `\\'`)
	return { data }
end

function module.tstr(clarg: typedef.Arg<string>, aliases: typedef.AddAliases?): ()
	clarg._parse, clarg._print = parse_str, print_stringified
	clarg._typename = `String`
	add_aliases(clarg, aliases)
end

function module.tpath(clarg: typedef.Arg<path.Pathlike>, aliases: typedef.AddAliases?): ()
	clarg._parse, clarg._print =
		function(ctx: typedef.ParseContext)
			return path.parse(ctx.peek())
		end, function(ctx: typedef.PrintContext<path.Pathlike>)
			return print_stringified(path.format(ctx.data))
		end
	clarg._typename = `Path`
	add_aliases(clarg, aliases)
end

function module.tnum(clarg: typedef.Arg<number>, aliases: typedef.AddAliases?): ()
	clarg._parse, clarg._print = value_parse.num, print_stringified
	clarg._typename = `Number`
	add_aliases(clarg, aliases)
end

function module.tbool(clarg: typedef.Arg<boolean>, aliases: typedef.AddAliases?): ()
	clarg._parse, clarg._print = value_parse.bool, print_stringified
	clarg._typename = `Bool`
	add_aliases(clarg, aliases)
end

type tenum<str> = (clarg: typedef.Arg<str>, aliases: typedef.AddAliases?) -> ()
function module.enum<str>(
	values: { read [number]: str & ("" | string) },
	mode: "sensitive" | "any_case"
): tenum<str>
	const function tenum(clarg: typedef.Arg<str>, aliases: typedef.AddAliases?): ()
		clarg._parse, clarg._print =
			value_parse.enum<<str>>(values, mode, ENUM_LEVENSHTEIN_DIST_CUTOFF),
			print_stringified

		-- todo(dev, helpgen): helpgen enums with their values array
		-- if small enough to some user defined threshold
		clarg._typename = if mode == `sensitive` then `Enum` else `InsensitiveEnum`

		add_aliases(clarg, aliases)
	end

	return tenum
end

function module.flag(
	clarg: typedef.Arg<boolean> & typedef.Flag,
	aliases: typedef.AddAliases?
): ()
	clarg._flag = true
	add_aliases(clarg, aliases)
end

function module.default<value>(clarg: typedef.Default<value>, value: value): ()
	clarg._has_default, clarg._default_value = true, value
end

function module.required(arg: typedef.Required): ()
	arg._required = true
end

--- todo: improve internal & external typechecking on positional and tails
function module.positional(
	object: unknown,
	first_positional: typedef.Required,
	...: typedef.Required
): ()
	for _, arg: any in { first_positional, ... } do
		arg._is_positional = true
		table.insert((object :: any)._positional_list, arg)
	end
end

--- todo: improve internal & external typechecking on positional and tails
function module.tails(object: unknown, first_tail: {}, ...: {}): ()
	const trailing_list = (object :: typedef.Arg)._trailing_list
	if not trailing_list then
		(error)(`tail arguments are not supported for '{(object :: any)._name}'`)
		return
	end

	for _, arg in { first_tail, ... } do
		(arg :: typedef.Arg)._is_positional = true
		table.insert(trailing_list, arg :: typedef.Arg)
	end
end

function module.command<name, cli>(
	command_name: name | "",
	command_decl: (cli) -> ()
): typedef.command_dsl<name, cli>
	return command.new(command_name, command_decl, SUBCOMMAND_LEVENSHTEIN_DIST_CUTOFF)
end

function module.parse<parsed>(command: typedef.Parser<parsed>, input: { string }): parsed
	const arr: { read [number]: string? } = table.clone(input)
	const count = #arr
	local index = 0

	local ctx: typedef.ParseContext
	ctx = {
		bump = function(count: number?)
			index += 1
		end,
		peek = function(offset: number?): string
			offset = offset or 1
			const output = arr[index + offset]
			if not output then
				-- todo(ux): make this good
				return error(debug.traceback(`expected more arguments`))
			end

			return output
		end,
		consume = function()
			ctx.bump()
			return ctx.peek()
		end,
		remaining = function()
			return count - index
		end,
		index = function()
			return index
		end,
		problem = function(reason: string, offset: number?, ranges: { vector }?): unknown
			-- todo: display the command and report ranges properly
			local output =
				`command encountered a problem at arg {offset or ctx.index()}:\n{reason}`

			return output
		end,
		error = function(reason: string, offset: number?, ranges: { vector }?)
			return error(ctx.problem(reason, offset, ranges))
		end,
	}

	return (command :: typedef.Command)._parse(ctx)
end

return table.freeze(module)
