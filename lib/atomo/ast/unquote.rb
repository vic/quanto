module Atomo
  module AST
    class Unquote < Node
      children :expression
      generate

      def construct(g, d = nil)
        pos(g)
        # TODO: fail if depth == 0
        if d == 1
          @expression.bytecode(g)
          g.send :to_node, 0
        else
          get(g)
          g.push_int @line
          @expression.construct(g, unquote(d))
          g.send :new, 2
        end
      end

      def bytecode(g)
        pos(g)
        # TODO: this should raise an exception since
        # it'll only happen outside of a quasiquote.
        g.push_literal @expression
      end
    end
  end
end
