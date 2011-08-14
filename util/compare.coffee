fs = require 'fs'
tty = require('tty')
t = require './colors'

compare = (args) ->
  [height, width] = tty.getWindowSize(process.stdout)

  files = args.map (file)->
    content = fs.readFileSync(file, 'utf8')
    lines = content.split("\n")
  
    lines

  cWidth = Math.floor(width / args.length) - 2

  padR = (s) ->
    ts = if s then s.slice(0, cWidth) else ""
    ts = ts + " " while ts.length < cWidth
    
    ts

  console.log args.map(padR).map((l)->t.bold + l + t.reset).join(" | ")

  max = (l, r) -> if l >= r then l else r
  min = (l, r) -> if l <  r then l else r

  maxLines = files.map((f)-> f.length).reduce(max)
  maxLines = min(maxLines, height - 2)

  for i in [0...maxLines]
    line = files.map((f)->f[i]).map(padR).join(" | ")
    console.log(line)

args = process.argv.slice(2)

if module.parent
  module.exports = compare
else if args.length < 2
  console.log "You need to give at least 2 files as arguments"
  process.exit()
else 
  if args[0] == "-w"
    args = args.slice(1)
    args.forEach (f) ->
      fs.watchFile f, {persistent: true, interval: 500}, (curr, prev) ->
        return if curr.size is prev.size and curr.mtime.getTime() is prev.mtime.getTime()
        compare(args)
  compare(args)

