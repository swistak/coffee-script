fs            = require 'fs'
tty           = require 'tty'
{spawn, exec} = require 'child_process'
{extend}      = require '../lib/helpers'
cmp           = require './compare'
cli           = require './node-cli'

# ANSI Terminal Colors.
bold  = '\033[0;1m'
red   = '\033[0;31m'
green = '\033[0;32m'
reset = '\033[0m'

ok = (text) -> console.log green + text + reset
fail = (text) -> console.log red + text + reset
log = (stdout, stderr) ->

checkRuby = (file, cb) ->
  exec "ruby -v -w -c #{file}", (err, stdout, stderr) ->
    log(stdout, stderr)

    fail("#{file} - Syntax incorrect!") if err

    cb?(!err)
 
compile = (file, cb)->
  exec "./bin/coffee -b -c -a rb -o documentation/rb #{file}", (err, stdout, stderr) ->
    log(stdout, stderr)

    if err
      fail("#{file} - Cannot compile")
    else
      cb?(true)
 
compare = (file, rbFile, cb) ->
  jsFile = file.replace(/coffee/g, 'js')
  cmp([file, rbFile, jsFile])

  cb?(true)

dir = process.argv[2]
showFile = process.argv[3]

files = fs.readdirSync dir
files = (dir + file for file in files when file.match(/\.coffee$/))

check = (file) ->
  rbFile = file.replace(/coffee/g, 'rb')
  compile file, -> 
    checkRuby rbFile, (passed) -> 
      ok("#{file} Compiled, and syntax correct") if passed
      compare(file, rbFile) if showFile
      

checkAll = () ->
  cli.clear().move(0,0)

  files.forEach (file) -> 
    check(file) if (showFile && file.indexOf(showFile) != -1) || !showFile

# Watch all files for changes
files.forEach (file) ->
  fs.watchFile file, {persistent: true, interval: 500}, (curr, prev) -> 
    return if curr.size is prev.size and curr.mtime.getTime() is prev.mtime.getTime()

    cli.clear().move(0,0)
    check(file)

# If nodes.rb.js changes - the nwe need to recheck all files!
fs.watchFile 'src/nodes.rb.coffee', {persistent: true, interval: 500}, (curr, prev) ->
  return if curr.mtime.getTime() is prev.mtime.getTime()

  exec './bin/coffee -o lib -c src/nodes.rb.coffee', (err, stdout, stderr) ->
    log(stdout, stderr)

    if err
      fail("Could not compile src/nodes.rb.coffee !")
    else
      checkAll()

checkAll()