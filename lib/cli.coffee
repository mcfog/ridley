fs = require 'fs'
program = require 'commander'
ejs = require 'ejs'
pkg = require '../package.json'
Ridley = require '../'

program
  .version pkg.version

program
  .command 'json <idl_file>'
  .description 'convert idl to json'
  .action (file)->
    r = fromSourceFile file
    console.log (JSON.stringify r, null, 2)

program
  .command 'tpl <tpl_file>'
  .option '-i, --idl [file]', 'idl file input'
  .option '-j, --json [file]', 'json file input'
  .action (tpl_file, program)->
    r = switch
      when program.idl then fromSourceFile program.idl
      when program.json then fromJsonFile program.json
      else
        program.help()
    tpl = fs.readFileSync(tpl_file).toString()

    console.log (ejs.render tpl, r)

fromSourceFile = (file)-> Ridley.fromSource(fs.readFileSync(file).toString());
fromJsonFile = (file)-> Ridley.fromJson(JSON.parse(fs.readFileSync(file).toString()));

program.parse process.argv
