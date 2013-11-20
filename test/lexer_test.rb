require "minitest/autorun"
require "mocha/setup"
require_relative '../lib/rulebook'

class LexerTest < Minitest::Test
  def setup
    path = File.expand_path("../lexer_fixture.rulebook", __FILE__)
    @code = File.read(path)
  end

  def test_converts_code_to_tokens
    tokens = Rulebook::Lexer.new.tokenize(@code)
    expected = [
      [:BOOK, 'book'],
      [:CONSTANT, 'Discount'],
      [:ARROW, '->'],
      [:NEWLINE, "\n"],
      [:INDENT, 2],
      [:RULE, 'rule'],
      [:STRING, 'hats with coats'],
      [:ARROW, '->'],
      ['(', '('],
      [:IDENTIFIER, 'cart'],
      [')', ')'],
      [:NEWLINE, "\n"],
      [:INDENT, 4],
      ['(', '('],
      [:IDENTIFIER, 'cart'],
      ['.', '.'],
      [:IDENTIFIER, 'items'],
      ['[', '['],
      [:IDENTIFIER, 'category'],
      ['.', '.'],
      [:IDENTIFIER, 'name'],
      ['=', '='],
      [:STRING, 'hat'],
      [']', ']'],
      [',', ','],
      [:KEY, 'count'],
      [:NUMBER, 2.0],
      [')', ')'],
      [',', ','],
      ['(', '('],
      [:IDENTIFIER, 'cart'],
      ['.', '.'],
      [:IDENTIFIER, 'items'],
      ['[', '['],
      [:IDENTIFIER, 'category'],
      ['.', '.'],
      [:IDENTIFIER, 'name'],
      ['=', '='],
      [:STRING, 'coat'],
      [']', ']'],
      [',', ','],
      [:KEY, 'count'],
      [:NUMBER, 1.0],
      [')', ')'],
      [',', ','],
      [:KEY, 'limit'],
      [:NUMBER, 1.0],
      [:ARROW, '->'],
      ['(', '('],
      [:IDENTIFIER, 'hats'],
      [',', ','],
      [:IDENTIFIER, 'coats'],
      [')', ')'],
      [:NEWLINE, "\n"],
      [:INDENT, 6],
      [:APPLY, 'apply'],
      [:IDENTIFIER, 'hats'],
      [',', ','],
      [:KEY, 'value'],
      [:NUMBER, 20.0],
      [:DEDENT, 2],
      [:DEDENT, 2],
      [:DEDENT, 0]
    ]
    assert_equal expected, tokens
  end
end
