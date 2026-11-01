const luau_config: config_luau = {
	languagemode = `strict`,

	lint = {
		[`*`] = true,
		[`LocalUnused`] = false,
	},
}

--- these are all broken or i dont want to use them
--stylua: ignore
const disabled_lute_lints = {
	`global_function_in_scope`,
	`almost_swapped`,
	`constant_table_comparison`,
	`divide_by_zero`,
	`duplicate_keys`,
	`empty_if_block`,
	`no_any`,
	`parenthesized_conditions`,
	`reassigned_parameter`,
	`unused_variable`,
}

const rule_configs: config_lute_lint_ruleconfigs = {}

for _, disabled in disabled_lute_lints do
	rule_configs[disabled] = { off = true }
end

const lint_config: config_lute_lint = {
	rulepaths = {
		`./ext/lints/`,
	},
	ignores = {
		`./lsp/check.d.luau`,
		`./test/old/**`,
	},
	ruleconfigs = rule_configs,
}

const check_config: config_lute_check = {
	definitions = {
		check = `./lsp/check.d.luau`,
	},
}

const lute_config: config_lute = {
	lint = lint_config,
	check = check_config,
}

const configuration: configuration = {
	lute = lute_config,
	luau = luau_config,
}

return configuration
