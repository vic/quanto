module Atomo
  module AST
    class Define < Rubinius::AST::ClosedScope
      include NodeLike
      extend SentientNode

      children :pattern, :body
      generate

      def arguments
        case pattern
        when BinarySend
          args = [pattern.rhs]
        when Variable, Unary
          args = []
        else
          args = pattern.arguments
        end

        DefineArguments.new args
      end

      def receiver
        case pattern
        when BinarySend
          recv = pattern.lhs
        when Variable
          recv = Primitive.new(pattern.line, :self)
        else
          recv = pattern.receiver
        end

        recv.to_pattern
      end

      def method_name
        case pattern
        when Variable
          pattern.name
        else
          pattern.method_name
        end
      end

      def bytecode(g)
        pos(g)

        defn = receiver.kind_of?(Patterns::Match) && receiver.value == :self

        if defn
          g.push_rubinius
          g.push_literal method_name.to_sym
          g.dup
          g.push_cpath_top
          g.find_const :Atomo
          g.swap
        else
          g.push_cpath_top
          g.find_const :Atomo
          receiver.target(g)
          g.push_literal method_name.to_sym
        end

        create = g.new_label
        added = g.new_label
        receiver.construct(g)
        arguments.patterns.each do |p|
          p.construct(g)
        end
        g.make_array arguments.size
        g.make_array 2
        @body.construct(g, nil)
        g.make_array 2

        receiver.target(g)
        g.push_literal "@__atomo_#{method_name}__".to_sym
        g.send :instance_variable_get, 1
        g.dup
        g.gif create

        g.push_cpath_top
        g.find_const :Atomo
        g.move_down 2
        g.send :insert_method, 2
        g.goto added

        create.set!
        g.pop
        g.make_array 1
        receiver.target(g)
        g.swap
        g.push_literal "@__atomo_#{method_name}__".to_sym
        g.swap
        g.send :instance_variable_set, 2

        added.set!

        if defn
          g.push_false
          g.push_literal :dynamic
          g.push_int @line
          g.send :build_method, 5
          g.push_scope
          g.push_variables
          g.send :method_visibility, 0
          g.send :add_defn_method, 4
        else
          g.push_scope
          g.send :add_method, 4
        end
      end

      def local_count
        local_names.size
      end

      def local_names
        receiver.local_names + arguments.local_names
      end

      class DefineArguments < Node
        attr_accessor :patterns

        def initialize(args)
          @patterns = args.collect(&:to_pattern)
        end

        def construct(g, d = nil)
          get(g)
          @patterns.each do |a|
            a.construct(g)
          end
          g.make_array @patterns.size
          g.send :new, 1
        end

        def bytecode(g)
          return if @patterns.empty?
          g.cast_for_multi_block_arg
          @patterns.each do |a|
            g.shift_array
            a.deconstruct(g)
          end
          g.pop
        end

        def local_names
          @patterns.collect { |a| a.local_names }.flatten
        end

        def size
          @patterns.size
        end

        def locals
          local_names.size
        end

        def required_args
          size # TODO
        end

        def total_args
          size # TODO
        end

        def splat_index
          nil
        end
      end
    end
  end
end
