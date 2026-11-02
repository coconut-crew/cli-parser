const mediator = require("@mediator")

const command, flag, tpath = mediator.command, mediator.flag, mediator.tpath

const function boiler(cli)
	flag(cli.help, { "h" })
	cli.help.helpline = "prints information relating to this command"
end

const aya = command("aya", function(cli)
	boiler(cli)
	flag(cli.version, { "v" })

	command("test", function(cli)
		boiler(cli)

		tpath(cli.directory)
		tpath(cli.shell)

		flag(cli.ignore_scripts)
	end).subcommandof(cli)

	command("make", function(cli) end).subcommandof(cli)
end)

aya.helpline = "aya :3"
aya.version.helpline = "the current version of aya"

aya.test.helpline = "runs tests"
aya.test.directory.helpline = "the directory to run tests from"

aya.make.helpline = "makes"

const help_config = mediator.help_config()

print(mediator.help_screen(aya, help_config))
