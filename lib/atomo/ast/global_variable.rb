module Atomo
  module AST
    class GlobalVariable < Rubinius::AST::GlobalVariableAccess
      include NodeLike

      attr_accessor :variable, :line
      attr_reader :name


      def initialize(name)
        @name = name
        @line = 1 # TODO
      end

      def ==(b)
        b.kind_of?(GlobalVariable) and \
        @name == b.name
      end
    end
  end
end
