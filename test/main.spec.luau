const mediator = require("@mediator/")
const pathlib = require("@std/path")
const pp = require("@ext/utils/pp")
const test = require("@std/test")
const test_types = require("@std/test/types")

const command, tpath, enum, parse =
	mediator.command, mediator.tpath, mediator.enum, mediator.parse

const tests = {}

function tests.cli_opts_work(asserts: test_types.Asserts)
	const dev = mediator.command("dev", function(cli)
		tpath(cli.path, { "p" })
		mediator.required(cli.path)
		enum({ "dev-ardi", "dev-alice", "dev-frost", "prod" }, "any_case")(
			cli.target,
			{ "t" }
		)
	end)

	const parsed = parse(dev, { "--path", "./meow", "--target", "dev-ALICE" })

	asserts.that(parsed, "non-nil parse result")

	asserts.eq(parsed.path, pathlib.parse("./meow"))
	asserts.eq(parsed.target, "dev-alice")
end

function tests.cli_shortopts_work(asserts: test_types.Asserts)
	const aya = mediator.command("aya", function(cli)
		mediator.tpath(cli.path, { "p" })
		mediator.enum({ "idk", "idk2" }, "any_case")(cli.ex, { "x" })
	end)

	local parsed = mediator.parse(aya, { "-p", "./meow" })

	asserts.that(parsed, "non-nil parsed result from 1 shortopt")
	asserts.eq(parsed.path, pathlib.parse("./meow"))

	parsed = mediator.parse(aya, { "-px", "./meow", "idk" })
	asserts.eq(parsed.path, pathlib.parse("./meow"))
	asserts.eq(parsed.ex, "idk")

	asserts.that(parsed, "non-nil parsed result from 2 shortopts")
end

function tests.cli_positionals_work(asserts: test_types.Asserts)
	const idk = mediator.command("somecli", function(cli)
		mediator.tnum(cli.meow)
		mediator.positional(cli, cli.meow)
		mediator.positional(cli, cli.mrrp)
	end)

	const parsed = mediator.parse(idk, { "0b101010", "0b101010" })
	asserts.eq(parsed.meow, 0b101010)
	asserts.eq(parsed.mrrp, "0b101010")
end

function tests.cli_flags_work(asserts: test_types.Asserts)
	const idk = mediator.command("somecli", function(cli)
		mediator.tnum(cli.meow)
		mediator.flag(cli.help, { "h" })
		mediator.positional(cli, cli.meow)
		mediator.positional(cli, cli.mrrp)
	end)

	const parsed = mediator.parse(idk, { "-h", "0b101010", "0b101010" })
	asserts.that(parsed.help, "parsed help mode")
	asserts.eq(parsed.meow, 0b101010)
	asserts.eq(parsed.mrrp, "0b101010")
end

function tests.subcommand_parses_args(asserts: test_types.Asserts)
	const command = mediator.command("main", function(cli)
		mediator
			.command("sub", function(cli)
				mediator.tnum(cli.nyanya)
				mediator.positional(cli, cli.meow)
			end)
			.subcommandof(cli)
	end)

	const parsed = mediator.parse(command, { "sub", "--nyanya", "1234", "meowmeow" })

	asserts.that(parsed.sub, "parsed the subcommand")
	assert(parsed.sub)
	asserts.eq(parsed.sub.meow, "meowmeow")
	asserts.eq(parsed.sub.nyanya, 1234)
end

function tests.prioritize_positionals_over_subcommand(asserts: test_types.Asserts)
	const command = mediator.command("main", function(cli)
		mediator.positional(cli, cli.priority)

		mediator
			.command("sub", function(cli)
				mediator.tnum(cli.nyanya)
			end)
			.subcommandof(cli)
	end)

	const parsed = mediator.parse(command, { "high", "sub", "--nyanya", "1e10" })

	asserts.eq(parsed.priority, "high")
	asserts.that(parsed.sub, "parsed subcommand")
	assert(parsed.sub)
	asserts.eq(parsed.sub.nyanya, 1e10)
end

const test_names = {}

for k, v in tests do
	table.insert(test_names, k)
end

table.sort(test_names)

test.suite("mediator", function(suite)
	for _, name in test_names do
		suite:case(name, tests[name])
	end
end)
