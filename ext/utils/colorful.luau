--[[
	Copyright 2024 ffrostfall

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]
--!nocheck
const ESCAPE = string.char(27)
const ANSI_16 = `{ESCAPE}[%dm`

export type Styler = (text: string) -> string

const function create_styler_function(
	opener: number,
	closer: number
): Styler
	const open = string.format(ANSI_16, opener)
	const close = string.format(ANSI_16, closer)

	return function(text: string): ()
		return `{open}{text}{close}`
	end
end

const function combine_styles(
	style_array: { (text: string) -> string }
): Styler
	return function(text: string): ()
		local result = text

		for _, style in style_array do
			result = style(result)
		end

		return result
	end
end

return {
	combine_styles = combine_styles,

	modifier = {
		dim = create_styler_function(2, 22),
		reset = create_styler_function(0, 0),
		bold = create_styler_function(1, 22),
		italic = create_styler_function(3, 23),
		hidden = create_styler_function(8, 28),
		inverse = create_styler_function(7, 27),
		underline = create_styler_function(4, 24),
		overline = create_styler_function(53, 55),
		strikethrough = create_styler_function(9, 29),
	},

	color = {
		red = create_styler_function(31, 39),
		blue = create_styler_function(34, 39),
		cyan = create_styler_function(36, 39),
		gray = create_styler_function(90, 39),
		grey = create_styler_function(90, 39),
		black = create_styler_function(30, 39),
		green = create_styler_function(32, 39),
		white = create_styler_function(37, 39),
		yellow = create_styler_function(33, 39),
		magenta = create_styler_function(35, 39),
		red_bright = create_styler_function(91, 39),
		blue_bright = create_styler_function(94, 39),
		cyan_bright = create_styler_function(96, 39),
		black_bright = create_styler_function(90, 39),
		green_bright = create_styler_function(92, 39),
		white_bright = create_styler_function(97, 39),
		yellow_bright = create_styler_function(93, 39),
		magenta_bright = create_styler_function(95, 39),
	},
}
