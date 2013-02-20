DiceParser = require './DiceParser'

randInt = (min, max) ->
  values = max - min + 1
  Math.floor(Math.random() * values) + min

class DiceInterpretter
  constructor: (@context, @dice_rolled = []) ->

  BinOps: (op) ->
    switch op
      when '*'
        (left, right) -> left * right
      when '+'
        (left, right) -> left + right
      when '-'
        (left, right) -> left - right
      when '/'
        (left, right) -> Math.floor(left / right)
      when 'DiceRoll'
        @roll
      else
        throw "Bad binary operation: #{op}"

  UnOps: (op) ->
    switch op
      when '-'
        (value) -> -value
      when 'DiceRoll'
        (sides) => @roll 1, sides
      else
        throw "Bad unary operation: #{op}"

  roll: (dice, sides) =>
    result = (randInt(1,sides) for i in [1..dice]).reduce (t, s) -> t + s
    @dice_rolled.push
      dice: dice
      sides: sides
      result: result
    result

  interpret: (expr) ->
    @dice_rolled = []
    { result: @interpret_node DiceParser.parse expr
      rolls: @dice_rolled }

  interpret_node: (node) ->
    switch node.type
      when "UnaryExpression"
        @UnOps(node.operator) @interpret_node(node.operand)
      when "BinaryExpression"
        left = @interpret_node(node.left)
        right = @interpret_node(node.right)
        @BinOps(node.operator) left, right
      when "Number"
        node.value
      else
        throw "Bad node type: #{node.type}"

exports.interpret = (expr) ->
  new DiceInterpretter().interpret expr

exports.parse = (expr) -> DiceParser.parse expr