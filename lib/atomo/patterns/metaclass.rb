module Atomo::Patterns
  class Metaclass < Pattern
    attr_reader :body

    def initialize(body)
      @body = body
    end

    def construct(g)
      get(g)
      @body.construct(g, nil)
      g.send(:new, 1)
    end

    def ==(b)
      b.kind_of?(Metaclass) and \
      @body == b.body
    end

    def target(g)
      @body.bytecode(g)
      g.send :call, 0
      g.send :metaclass, 0
    end

    def matches?(g)
      g.pop
      g.push_true
    end
  end
end
