-- todo: update number parsing

const levenshtein_dist = require(`@mediator/levenshtein_dist`)
const typedef = require("@mediator/typedef")

const char = string.byte

local buf: buffer, pos: number, len: number
const module = {}

const function load(text: string): ()
	buf = buffer.fromstring(text)
	pos, len = 0, buffer.len(buf)
end

const function peek(): number
	return (buffer.readu8(buf, pos))
end

const function bump(): boolean
	const bumping = pos < len
	if bumping then
		pos += 1
	end
	return bumping
end

const function range(left: number, right: number): vector
	return vector.create(left + 1, right + 1)
end

const function is_digit(c: number): boolean
	return c >= char(`0`) and c <= char(`9`)
end

const function is_hexdigit(c: number): boolean
	return is_digit(c)
		or (c >= char(`A`) and c <= char(`F`))
		or (c >= char(`a`) and c <= char(`f`))
end

const function underscores_peak_bump(): number?
	local c: number?

	for i = pos, len - 1 do
		pos = i
		c = peek()

		if c ~= char(`_`) then
			break
		end
	end

	return c
end

-- cursed
const function getutf8(at: number): string
	const start, finish = math.min(at, len - 1), math.min(at + 4, len)
	const count = finish - start

	const str = buffer.readstring(buf, at, count)

	const utf8_code = utf8.codepoint(str)
	return (utf8.char(utf8_code))
end

const function hex_num(ctx: typedef.ParseContext): number
	if pos == len then
		return ctx.error(
			`expected character(s) after hexadecimal number specifier`,
			ctx.index(),
			{ range(pos, pos) }
		)
	end

	const str = buffer.readstring(buf, pos, len - pos)
	local as_number = tonumber(str, 16)
	if as_number then
		return as_number
	end

	const without_underscores = string.gsub(str, `_`, ``)

	as_number = tonumber(without_underscores, 16)
	if as_number then
		return as_number
	end

	while pos < len do
		const c = underscores_peak_bump()
		if not c then
			break
		elseif is_hexdigit(c) then
			bump()
			continue
		end

		return ctx.error(
			`cannot use '{getutf8(pos)}' in a hexadecimal number`,
			ctx.index(),
			{ range(pos, pos) }
		)
	end

	return ctx.error(
		`the value wasn't a valid hexadecimal number.`,
		ctx.index(),
		{ range(0, pos) }
	)
end

const function binary_num(ctx: typedef.ParseContext): number
	if pos == len then
		return ctx.error(
			`expected character(s) after binary number specifier`,
			ctx.index(),
			{ range(0, pos) }
		)
	end

	const str = buffer.readstring(buf, pos, len - pos)
	local as_number = tonumber(str, 2)
	if as_number then
		return as_number
	end

	const without_underscores = string.gsub(str, `_`, ``)

	as_number = tonumber(without_underscores, 2)
	if as_number then
		return as_number
	end

	while pos < len do
		const c = underscores_peak_bump()
		if not c then
			break
		elseif c == char(`0`) or c == char(`1`) then
			bump()
			continue
		end

		return ctx.error(
			`cannot use '{getutf8(pos)}' in a binary number`,
			ctx.index(),
			{ range(pos, pos) }
		)
	end

	return ctx.error(
		`the value wasn't a valid binary number.`,
		ctx.index(),
		{ range(0, pos) }
	)
end

function module.num(ctx: typedef.ParseContext): number
	const str = ctx.peek()
	local as_number = tonumber(str)
	if as_number then
		return as_number
	end

	load(str)

	local c = peek()
	if c == char(`0`) then
		bump()
		const next_c = underscores_peak_bump()
		if next_c == nil then
			return 0
		end

		if next_c == char(`x`) or next_c == char(`X`) then
			bump()
			underscores_peak_bump()
			return (hex_num(ctx))
		elseif next_c == char(`b`) or next_c == char(`B`) then
			bump()
			underscores_peak_bump()
			return (binary_num(ctx))
		else
			pos = 1
		end
	elseif c == char(`_`) then
		return ctx.error(
			`number cannot have leading underscores.`,
			ctx.index(),
			{ range(0, pos) }
		)
	elseif not is_digit(c) then
		return ctx.error(
			`number cannot have leading '{getutf8(pos)}'`,
			ctx.index(),
			{ range(0, pos) }
		)
	end

	const without_underscores = string.gsub(str, `_`, ``)
	as_number = tonumber(without_underscores)
	if as_number then
		return as_number
	end

	local dot_pos: number?, e_pos: number?
	while pos < len do
		c = underscores_peak_bump()
		if not c then
			break
		elseif is_digit(c) then
			continue
		end

		if c == char(`.`) then
			if not dot_pos then
				dot_pos = pos
				continue
			end

			return ctx.error(
				`number cannot have multiple decimal points`,
				ctx.index(),
				{ range(dot_pos, pos) }
			)
		elseif c == char(`e`) or c == char(`E`) then
			if not e_pos then
				e_pos = pos
			else
				return ctx.error(
					`number cannot have multiple 'e' exponent notations in a regular number. Did you mean to write a hex literal? (0x)`,
					ctx.index(),
					{ range(e_pos, pos) }
				)
			end

			bump()
			c = underscores_peak_bump()
			if not c then
				return ctx.error(
					`number exponent notation expected a following digit, "+", or "-"; found {string.format(
						"%q",
						string.sub(str, e_pos + 1, pos + 1)
					)}`,
					ctx.index(),
					{ range(e_pos, pos) }
				)
			end

			if c == char(`+`) or c == char(`-`) then
				continue
			end

			return ctx.error(
				`number exponent notation expects a following digit, "+", or "-"; found {string.format(
					"%q",
					string.sub(str, e_pos + 1, pos + 1)
				)}`,
				ctx.index(),
				{ range(e_pos, pos) }
			)
		elseif is_digit(c) then
			continue
		else
			return ctx.error(
				`character '{getutf8(pos)}' was not a valid number`,
				ctx.index(),
				{ range(pos, pos) }
			)
		end
	end

	return ctx.error(
		`the value wasn't a valid base-10 number.`,
		ctx.index(),
		{ range(0, pos) }
	)
end

function module.bool(ctx: typedef.ParseContext): boolean
	local str = ctx.peek()

	const lower = string.lower(str)
	if lower == `true` then
		return true
	elseif lower == `false` then
		return false
	end

	local found_start, found_stop = string.find(lower, `true`, 1, true)
	if found_start and found_start ~= 1 then
		return ctx.error(
			`bool expected to be 'true' or 'false', but got invalid prefix`,
			ctx.index(),
			{ vector.create(1, found_start) }
		)
	elseif found_stop and found_stop ~= #lower then
		return ctx.error(
			`bool expected to be 'true' or 'false', but got invalid suffix`,
			ctx.index(),
			{ vector.create(found_stop, #lower) }
		)
	end

	found_start, found_stop = string.find(lower, `true`, 1, true)
	if found_start and found_start ~= 1 then
		return ctx.error(
			`expected 'true' or 'false', but got invalid prefix`,
			ctx.index(),
			{ vector.create(1, found_start) }
		)
	elseif found_stop and found_stop ~= #lower then
		return ctx.error(
			`expected 'true' or 'false', but got invalid suffix`,
			ctx.index(),
			{ vector.create(found_stop, #lower) }
		)
	end

	return ctx.error(
		`expected 'true' or 'false', but got invalid value`,
		ctx.index(),
		{ vector.create(1, #lower) }
	)
end

function module.enum<str>(
	values: { read [number]: string? },
	mode: "sensitive" | "any_case",
	dist_cutoff: number
): (ctx: typedef.ParseContext) -> str
	const case_sensitive = mode == `sensitive`

	const lookup_values = {}
	if case_sensitive then
		for _, str in values do
			lookup_values[str] = true
		end
	else
		for _, str in values do
			lookup_values[string.lower(str)] = true
		end
	end

	-- todo(luau)
	local available = table.concat(values :: { string }, `, `, 1, #values - 1)
	available ..= `, or {values[#values]}`

	if not case_sensitive then
		available = string.lower(available)
	end

	const function parse_enum(ctx: typedef.ParseContext): str
		local str = ctx.peek()

		if lookup_values[str] then
			return str :: str
		elseif not case_sensitive then
			str = string.lower(str)
			if lookup_values[str] then
				return str :: str
			end
		end

		const similar = levenshtein_dist.restricted_edit_damerau_lookup(
			str,
			lookup_values,
			dist_cutoff
		)

		if similar == nil then
			return ctx.error(
				`got '{str}', but expected one of {available}`,
				ctx.index(),
				{ vector.create(1, #str) }
			)
		else
			return ctx.error(
				`got '{str}', but this was unknown to the enum. did \z
				you mean to use '{similar}'?`,
				ctx.index(),
				{ vector.create(1, #str) }
			)
		end
	end

	return parse_enum
end

return table.freeze(module)
