program = require 'commander'
pkg = require '../package.json'
Ridley = require '../'


program
  .version pkg.version

program
  .command 'json <idl_file>'
  .description 'convert idl to json'
  .action (file)->
    r = Ridley.fromSource(require('fs').readFileSync(file).toString());
    console.log(JSON.stringify(r, null, 2));




program.parse process.argv
