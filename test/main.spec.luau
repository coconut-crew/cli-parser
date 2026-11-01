const mediator = require("@mediator/")
const pp = require("@ext/utils/pp")
const test = require("@std/test")
const test_types = require("@std/test/types")
const pathlib = require("@std/path")

const command, tpath, enum, parse =
	mediator.command, mediator.tpath, mediator.enum, mediator.parse

const tests = {}

function tests.cli_opts_work(ass: test_types.Asserts)
	const dev = mediator.command("dev", function(cli)
		tpath(cli.path, { "p" })
		mediator.required(cli.path)
		enum({ "dev-ardi", "dev-alice", "dev-frost", "prod" }, "any_case")(
			cli.target,
			{ "t" }
		)
	end)

	const parsed = parse(dev, { "--path", "./meow", "--target", "dev-ALICE" })

	ass.that(parsed, "non-nil parse result")

	ass.eq(parsed.path, pathlib.parse("./meow"))
	ass.eq(parsed.target, "dev-alice")
end

function tests.cli_shortopts_work(ass: test_types.Asserts)
	const aya = mediator.command("aya", function(cli)
		mediator.tpath(cli.path, { "p" })
		mediator.enum({ "idk", "idk2" }, "any_case")(cli.ex, { "x" })
	end)

	local parsed = mediator.parse(aya, { "-p", "./meow" })

	ass.that(parsed, "non-nil parsed result from 1 shortopt")
	ass.eq(parsed.path, pathlib.parse("./meow"))

	parsed = mediator.parse(aya, { "-px", "./meow", "idk" })
	ass.eq(parsed.path, pathlib.parse("./meow"))
	ass.eq(parsed.ex, "idk")

	ass.that(parsed, "non-nil parsed result from 2 shortopts")
end

function tests.cli_positionals_work(ass: test_types.Asserts)
	const idk = mediator.command("somecli", function(cli)
		mediator.tnum(cli.meow)
		mediator.positional(cli, cli.meow)
		mediator.positional(cli, cli.mrrp)
	end)

	const parsed = mediator.parse(idk, { "0b101010", "0b101010" })
	ass.eq(parsed.meow, 0b101010)
	ass.eq(parsed.mrrp, "0b101010")
end

function tests.cli_flags_work(ass: test_types.Asserts)
	const idk = mediator.command("somecli", function(cli)
		mediator.tnum(cli.meow)
		mediator.flag(cli.help, { "h" })
		mediator.positional(cli, cli.meow)
		mediator.positional(cli, cli.mrrp)
	end)

	const parsed = mediator.parse(idk, { "-h", "0b101010", "0b101010" })
	ass.that(parsed.help, "parsed help mode")
	ass.eq(parsed.meow, 0b101010)
	ass.eq(parsed.mrrp, "0b101010")
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
