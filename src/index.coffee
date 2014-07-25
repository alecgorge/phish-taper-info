fs         = require 'fs'

express    = require 'express'
morgan     = require 'morgan'
cors       = require 'cors'

app        = express()

app.use cors()
app.use morgan('dev')

TXT_DIR    = './txt'

show_cache =
  notes_count : 0
  shows_count : 0
  shows       : {}
  build_cache : ->
    files = fs.readdirSync './txt'
    date_matcher = /(\d+)-?(\d+|x+)-?(\d+|x+)/

    for f in files
      if f.match /\.txt/
        date = date_matcher.exec f

        if not date
          console.log "invalid: ", f, date

        year = date[1]
        month = date[2]
        day = date[3]

        year = "19" + year if year.length is 2
        show = "#{year}-#{month}-#{day}"

        if not @shows[show]
          @shows[show] = []

        @shows[show].push fs.readFileSync(TXT_DIR + '/' + f).toString().replace("\r\n", "\n").replace("\r", "\n")

        @notes_count++

    @shows_count = Object.keys(@shows).length
  find        : (show) ->
    return @shows[show]

show_cache.build_cache()

app.get '/notes/:show.json', (req, res) ->
  notes = show_cache.find req.param 'show'

  if not notes
    return res.json 404, success: false

  res.json { success: true, data: notes }

app.get '/notes/:show.txt', (req, res) ->
  notes = show_cache.find req.param 'show'

  res.header 'Content-Type', 'text/plain'

  if not notes
    return res.send 404, "No show notes found for #{req.param('show')}"

  res.send notes.join("\n\n\n")

app.get '/', (req, res) ->
  res.send """<pre>Usage:\n<a href="/notes/1998-04-02.json">/notes/1998-04-02.json</a>\n<a href="/notes/1998-04-02.txt">/notes/1998-04-02.txt</a>"""

console.log "Listening on http://localhost:#{process.env.PORT || 19844}/. #{show_cache.notes_count} taper notes for #{show_cache.shows_count} shows."
app.listen process.env.PORT || 19844
