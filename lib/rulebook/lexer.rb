class Rulebook::Lexer
  KEYWORDS = %w(rule book apply true false nil)

  def tokenize(code)
    code.chomp!
    tokens = []

    current_indent = 0
    indent_stack = []

    rest = code
    position = 0

    while rest.size > 0
      case rest
      when /\A([a-z]\w*):/
        tokens << [:KEY, $1]
      when /\A([a-z]\w*)/
        if KEYWORDS.include?($1)
          tokens << [$1.upcase.to_sym, $1]
        else
          tokens << [:IDENTIFIER, $1]
        end

      when /\A([A-Z]\w*)/
        tokens << [:CONSTANT, $1]

      when /\A([0-9]+(?:.[0-9]+)?)/
        tokens << [:NUMBER, $1.to_f]

      when /\A"([^"]*)"/
        tokens << [:STRING, $1]

      when /\A'([^'']*)'/
        tokens << [:STRING, $1]

      when /\A(\->)(.*)\n( +)/
        _, arrow, rest_of_line, indent = *$~
        tokens << [:ARROW, arrow]
        rest_tokens = tokenize(rest_of_line)
        tokens.push(*rest_tokens)
        tokens << [:NEWLINE, "\n"]

        if indent.size > current_indent
          current_indent = indent.size
          indent_stack.push(current_indent)
          tokens.push << [:INDENT, indent.size]
        end

      when /\A\n( *)/
        if indent.size == current_indent
          tokens << [:NEWLINE, "\n"]

        elsif indent.size < current_indent
          while indent.size < current_indent
            indent_stack.pop
            current_indent = indent_stack.last || 0
            tokens << [:DEDENT, indent.size]
          end
          tokens << [:NEWLINE, "\n"]
        else
          raise "Missing '->' at #{position}"
        end

      when /\A(!=|<=|>=)/
        tokens << [$1, $1]

      when /\A /

      when /(.)/
        tokens << [$1, $1]
      end

      length = $&.length
      position += length
      rest = rest[length..-1]
    end

    while indent = indent_stack.pop
      tokens << [:DEDENT, indent_stack.first || 0]
    end

    tokens
  end
end
