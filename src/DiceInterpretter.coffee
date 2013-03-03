{randInt} = require 'crypto-rand'
{parse} = require './DiceParser'

class DiceError extends SyntaxError
  constructor: (@message) ->
    @name = "DiceError"

ZERO =
  type: "Number"
  value: 0

class DiceInterpretter
  constructor: (@results = [], @dice_rolled = []) ->

  MuxOps: (op) ->
    switch op
      when ','
        (left, right) =>
          @interpret_subroll left
          @interpret_node right
      when '#'
        (times, ast) =>
          count = @interpret_subroll times
          unless count > 0
            throw new DiceError "Cannot roll #{count} times, minimum 1."
          for _ in [1...count]
            @interpret_subroll ast
          @interpret_node ast
      else
        throw "Bad multiplex operation: #{op}"

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
      when 'Shadowrun4DicePool'
        @sr4_pool
      else
        throw "Bad binary operation: #{op}"

  UnOps: (op) ->
    switch op
      when '-'
        (value) -> -value
      when 'DiceRoll'
        (sides) => @roll 1, sides
      when 'Shadowrun4DicePool'
        @sr4_pool
      else
        throw "Bad unary operation: #{op}"

  roll: (dice, sides) =>
    return ZERO if dice == 0 or sides == 0
    if dice < 0
      throw new DiceError "Cannot roll a negative number of dice."
    if sides < 0
      throw new DiceError "Dice must have a non-negative number of sides."
    result = (randInt(sides) for i in [1..dice]).reduce (t, s) -> t + s
    @dice_rolled.push
      dice:   dice
      sides:  sides
      result: result
    result

  sr4_pool: (dice, edge=0) =>
    dice += edge
    return ZERO if dice == 0
    if dice < 0
      throw new DiceError "Cannot roll a negative number of dice."
    hits = 0
    ones = 0
    pool_size = dice
    while dice > 0
      roll = randInt(6)
      ++ones if roll == 1
      ++hits if roll == 5
      if roll == 6
        ++dice if edge > 0
        ++hits
      --dice
    glitch = ones > Math.floor(pool_size / 2)
    glitch = 'critical' if glitch and hits == 0
    @dice_rolled.push
      pool:   pool_size
      hits:   hits
      edge:   (edge > 0)
      glitch: glitch
    hits

  interpret: (expr) ->
    @results = []
    try
      @interpret_subroll parse expr
      @results
    catch exception
      unless exception.name in ["DiceError", "SyntaxError"]
        throw exception
      exception.error = true
      [exception]

  interpret_subroll: (ast) ->
    result = @interpret_node ast
    @results.push
      result: result
      rolls: @dice_rolled
    @dice_rolled = []
    result

  interpret_node: (node) ->
    switch node.type
      when "MuxExpression"
        @MuxOps(node.operator) node.left, node.right
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

exports.parse = parse
