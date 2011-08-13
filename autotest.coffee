fs = require 'fs'
tty = require 'tty'
{spawn, exec} = require 'child_process'
{extend}      = require './lib/helpers'

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

    unless err 
      ok("Syntax #{file} ok!") 
      cb?()
    else 
      fail("Syntax #{file} incorrect!")

compile = (file, cb)->
 console.log "Checking #{file} ... "
 exec "./bin/coffee -c -a rb -o lib #{file}", (err, stdout, stderr) ->
    log(stdout, stderr)

    unless err
      ok("Compiled #{file}!")
      cb?()
    else
      fail("Cannot compile #{file}")

fs.open 'log/autotest.log', 'w', (e, fd) ->
  log = (stdout, stderr) ->
    fs.write(fd, stdout) if stdout
    fs.write(fd, stderr) if stderr

  files = fs.readdirSync 'src'
  files = ('src/' + file for file in files when file.match(/\.coffee$/))

  files.forEach (file) ->
    rbFile = file.replace('src', 'lib').replace('coffee', 'rb')
    compile file, -> checkRuby rbFile
    fs.watchFile file, {persistent: true, interval: 500}, (curr, prev) ->
      return if curr.size is prev.size and curr.mtime.getTime() is prev.mtime.getTime()
      compile file, -> checkRuby rbFile

