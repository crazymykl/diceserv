{interpret, parse} = require './DiceInterpretter'

express = require 'express'
app = express()
app.use express.logger()
app.use express.bodyParser()

roll = interpret

app.get '/', (req, res) ->
  res.send '''
    <form action='/roll' method='post'>
      Roll
      <input type="text" name="roll">
      <input type="submit">
    </form>
    <form action='/parse' method='post'>
      Parse
      <input type="text" name="roll">
      <input type="submit">
    </form>
    '''
app.post '/roll', (req, res) ->
  res.header "Access-Control-Allow-Origin", "*"
  res.header "Access-Control-Allow-Headers", "X-Requested-With"
  res.send roll req.body.roll

app.post '/parse', (req, res) ->
  res.header "Access-Control-Allow-Origin", "*"
  res.header "Access-Control-Allow-Headers", "X-Requested-With"
  res.send parse req.body.roll


exports.run = (port) -> app.listen(port)
