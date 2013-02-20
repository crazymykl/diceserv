PEG = require 'pegjs'
PEGjsCoffeePlugin = require 'pegjs-coffee-plugin'

PEGjsCoffeePlugin.addTo PEG

DiceParser = PEG.buildParser '''
expression
  = multiplicative_expression

multiplicative_expression
  = head:additive_expression tail:([*/] expression)*
  { 
    result = head
    for node in tail
      result =
        type:     "BinaryExpression"
        operator: node[0]
        left:     result
        right:    node[1]
    result
  }

additive_expression
  = head:dice_expression tail:([+-] expression)* 
  { 
    result = head
    for node in tail
      result =
        type:     "BinaryExpression"
        operator: node[0]
        left:     result
        right:    node[1]
    result
  }
  
dice_expression
  = lhs:value "d" rhs:dice_expression
    {
      type: "BinaryExpression"
      operator: "DiceRoll"
      left: lhs
      right: rhs
    } / unary_expression

unary_expression
 = op:[-d] val:expression
  {
    type:         "UnaryExpression"
    operator:     if op == 'd' then "DiceRoll" else op
    operand:      val
  } / value

value
 = "(" expr:expression ")" { expr } / number

number
  = num:[0-9]+
  {
    type: "Number"
    value: parseInt num.join(''), 10
  }

'''

exports.parse = (expr) -> DiceParser.parse expr
