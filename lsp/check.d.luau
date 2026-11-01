export type config_lute_lint_ruleconfig = {
	--- Array of globs (.gitignore style) that are EXEMPT from this rule
	ignores: { string }?,
	--- Override a rule's default severity
	severity: ("warning" | "error" | "info" | "hint")?,
	--- Pass custom options through to a rule;
	--- see specific rule's implementation / docs for expected options structure
	options: { [string]: unknown }?,
	--- Disable a rule
	off: boolean?,
}
export type config_lute_lint_ruleconfigs = {
	[string]: config_lute_lint_ruleconfig?,
}
export type config_lute_lint = {
	-- Array of globs (.gitignore style) to EXEMPT from linting
	ignores: { string }?,
	-- Table of string:unknown pairs; globals are passed down to each rule
	globals: { [string]: unknown }?,
	-- Array of paths from which to load local lint rules (similar to -r CLI option)
	rulepaths: { string }?,
	-- Specify per-rule options and overrides
	ruleconfigs: config_lute_lint_ruleconfigs?,
}
export type config_lute_check_definitions = {
	[string]: string?,
}
export type config_lute_check = {
	definitions: config_lute_check_definitions?,
}
export type config_lute = {
	lint: config_lute_lint?,
	check: config_lute_check?,
}

type config_luau_languagemode = "strict" | "nonstrict" | "nocheck"
type config_luau_lintwarning =
	| "*"
	| "UnknownGlobal"
	| "DeprecatedGlobal"
	| "GlobalUsedAsLocal"
	| "LocalShadow"
	| "SameLineStatement"
	| "MultiLineStatement"
	| "LocalUnused"
	| "FunctionUnused"
	| "ImportUnused"
	| "BuiltinGlobalWrite"
	| "PlaceholderRead"
	| "UnreachableCode"
	| "UnknownType"
	| "ForRange"
	| "UnbalancedAssignment"
	| "ImplicitReturn"
	| "DuplicateLocal"
	| "FormatString"
	| "TableLiteral"
	| "UninitializedLocal"
	| "DuplicateFunction"
	| "DeprecatedApi"
	| "TableOperations"
	| "DuplicateCondition"
	| "MisleadingAndOr"
	| "CommentDirective"
	| "IntegerParsing"
	| "ComparisonPrecedence"
	| "RedundantNativeAttribute"
export type config_luau_lint = { [string]: boolean }
export type config_luau = {
	languagemode: config_luau_languagemode?,
	lint: config_luau_lint?,
	linterrors: boolean?,
	typeerrors: boolean?,
	globals: { string }?,
	aliases: { [string]: string }?,
}

export type configuration = {
	luau: config_luau?,
	lute: config_lute?,
}

declare task: nil | { read spawn: <A..., R...>(threadOrFunction: ((A...) -> (R...)) | thread, A...) -> thread }
declare warn: nil | <T...>(T...) -> ()
