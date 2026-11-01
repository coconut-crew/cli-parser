type _subcommands = "$ subcommands $"
type _subcommandof = "subcommandof"
type _cli = "cli"
type _helpline = "helpline"
type _helpparagraph = "helpparagraph"
type __t_ = "_t_"
type NIL = nil

type _rawkeyof<tbl> = rawkeyof<tbl>
type _rawget<tbl, key> = rawget<tbl, key>

type function iter(value: type): { type }
	if value.tag == `union` or value.tag == `intersection` then
		return value:components()
	end
	return { value }
end

-- todo: add more context (so we can report e.g. "while parsing -p (type FilePath), ... happened")
export type ParseContext = {
	read can_subcommand: (boolean?) -> boolean,
	read remaining: () -> number,
	--[=[
		returns the most recently consumed index (0 if none consumed yet)
	]=]
	read index: () -> number,

	read peek: (offset: number?) -> string,
	read consume: () -> string,
	read bump: (count: number?) -> (),

	--[=[
		returns the value for a problem at a given byte range (1-indexed) and arg
	]=]
	read problem: (
		reason: string,
		offset: number?,
		-- todo: technically an arg could be larger than f32 precision
		ranges: { vector }?
	) -> unknown,
	--[=[
		like 'problem', but error
		sorry if ur reading this all the error handling is so scuffed for now
	]=]
	read error: (reason: string, offset: number?, ranges: { vector }?) -> never,
}

export type PrintContext<data> = {
	read data: data,
}

export type ArgParser<result> = (ctx: ParseContext) -> result
export type ArgPrinter<result> = (ctx: PrintContext<result>) -> { string }

export type Command<tbl = { [any]: any }> = Arg<unknown> & {
	_subcommands: { [string]: Command? },
	subcommandof: (Command) -> (),
}
export type Parser<result = unknown> = {
	read _t_: (never) -> result,
}
export type Arg<result = unknown> = Parser<result> & {
	_name: string,
	_typename: string,
	_is_positional: boolean,
	helpline: string?,
	helpparagraph: string?,

	_alias_list: { string? },

	_option_list: { Arg },
	_option_set: { [string]: Arg },

	_positional_list: { Arg },
	_trailing_list: { Arg } | false,

	_parse: ArgParser<result>,
	_print: ArgPrinter<result>,
}

export type Required = {
	_required: true,
}
export type Default<T> = {
	_has_default: true,
	_default_value: T,
}
export type Flag = {
	_flag: true,
}

type AnyStructure = {}

type inject_parsed_type<T> = (never) -> T
type function extract_parsed_type(object: type): type
	const fun: type = _rawget(object, __t_)
	if fun == NIL then
		return types.string
	end

	const extracted = assert(assert(fun:returns().head)[1])

	return extracted
end

export type command_dsl<name, cli> = _command_dsl<name, cli>
type function _command_dsl(name: type, cli: type): type
	const output = types.newtable()
	const parsed_output = types.newtable()

	if cli:issubtypeof(AnyStructure) then
		for _, key_name in iter(_rawkeyof(cli)) do
			const substructure = _rawget(cli, key_name)
			output:setreadproperty(key_name, substructure)

			local extracted_ty = extract_parsed_type(substructure)

			if not substructure:issubtypeof(Required) then
				extracted_ty = types.optional(extracted_ty)
			end

			parsed_output:setreadproperty(key_name, extracted_ty)
		end
	end

	output:setproperty(__t_, inject_parsed_type(parsed_output))

	output:setproperty(_helpline, types.string)
	output:setproperty(_helpparagraph, types.optional(types.string))

	output:setreadproperty(
		_subcommandof,
		types.newfunction({
			head = {
				types.newtable({
					[name] = output,
				}),
			},
		})
	)

	return output
end

export type AddAliases = { read [number]: string } | { read [number]: string? }

export type ArgError = {
	read ranges: { vector },
	read reason: string,
}

export type HelpGenConfig = {
	sections_enabled: boolean,
	sections_design: string,
	sections_width: number,
	sections_pad_above: number,
	sections_pad_below: number,

	args_enabled: boolean,
	args_args_text: string,
	args_opts_text: string,
	args_positionals_text: string,
	args_column_wrapping: number,
	args_alignment: "always" | "never",
	args_aliases: boolean,
	args_annotation: false | (args: { string }) -> string,
	args_newline: (indentation: number) -> string,
	args_separator: (ideal_width: number) -> string,
}

return table.freeze({})
