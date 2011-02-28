module Atomo
  module AST
    class String < Node
      attr_reader :value

      def initialize(line, value)
        @value = value
        @line = line
      end

      def ==(b)
        b.kind_of?(String) and \
        @value == b.value
      end

      def self.ary(x)
        x.split("")
      end

      def bytecode(g)
        pos(g)
        g.push_literal @value
        g.string_dup
      end
    end
  end
end
