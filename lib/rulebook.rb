require "rulebook/version"
require "rulebook/lexer"

require 'pry'
require 'pry-debugger'

module Rulebook
  class Rulebook
    attr_reader :rules, :name
    def initialize(name)
      @name = name
      @rules = []
    end

    def call(&block)
      instance_eval(&block) if block
    end

    def apply(objects)
      collection = CollectionProxy.new(objects)
      @rules.each{ |rule| rule.call(collection) }
    end

    def rule(name, &block)
      r = Rule.new(name, &block)
      @rules << r
    end
  end

  class Rule
    attr_reader :name
    def initialize(name, &block)
      @name = name
      @block = block
    end

    def call(collection)
      context = Context.new(nil, self)
      context.call(collection, &@block)
    end
  end

  class Context
    def initialize(parent, rule, *args)
      @parent = parent
      @rule = rule
      @args = args
    end

    def call(&block)
      instance_exec(*@args, &block)
    end

    def find(*args, &block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      group = find_groups(args, options)
      MatchContext.new(self, group)
    end

    def apply(object, params)

    end

    protected

    def find_groups(args, options)
      previously_found = []
      found = args.map { |collection, matchers, find_options|
        collection.__find__(matchers, previously_found, find_options)
      }

      MatchGroup.new(found, options)
    end
  end

  class MatchContext
    attr_accessor :match_group

    def initialize(parent, match_group)
      @parent = parent
      @match_group = match_group
    end

    def call(&block)
      @match_group.each do |arguments|
        Context.new(@parent, @parent.rule, *arguments).call(&block)
      end
    end
  end

  class MatchGroup
    include Enumerable

    attr_accessor :iterations

    def initialize(objects, options)
      iterations = objects.length > 1 ? objects[0].zip(*objects[1..-1]) : objects

      max = options.fetch(:max) { -1 }

      iterations = iterations[0..max]

      @iterations = iterations.select{ |iteration| iteration.all? }
    end

    def each(&block)
      @iterations.each(&block)
    end
  end

  class CollectionProxy
    def initialize(objects)
      @objects = objects.is_a?(Array) ? objects : [objects]
    end

    def method_missing(name, *args)
      return super if name.to_s.match /^__.*__$/
      CollectionProxy.new(__collection_proxy__(name))
    end

    [:==, :>=, :>, :<=, :<, :!=].each do |operator|
      define_method(operator) do |other|
        @objects.any?{ |o| o.send(operator, other) }
      end
    end

    def __find__(matchers, previously_found, options)
      selected = __objects__(options).select do |object|
        next if previously_found.include?(object)
        matchers.all? do |properties, operator, comparator|
          value = __method_chain__(object, properties)
          value.send(operator, comparator)
        end
      end
      previously_found.push(*selected)
      __group__(selected, options)
    end

    protected

    def __group__(array, options)
      options[:count] ? array.each_slice(options[:count]).to_a : [array]
    end

    def __collection_proxy__(name)
      @objects.map{ |o| __proxy__(o, name) }.flatten(1).compact
    end

    def __method_chain__(object, properties)
      properties.reduce(CollectionProxy.new object) do |o, property|
        o.send(property)
      end
    end

    def __objects__(options)
      objects = @objects.dup
      if sort = options[:sort]
        objects = __sort__(objects, sort)
      end
      objects
    end

    def __sort__(objects, info)
      method = info[0]
      direction = (info[1] || 'asc').to_s
      raise ArgumentError, "Sort direction must be 'asc' or 'desc', was #{direction}" unless direction.match /asc|desc/
      objects.sort_by! do |object|
        __proxy__(object, method)
      end
      objects = objects.reverse if direction != 'asc'
      objects
    end

    def __proxy__(object, method)
      if object.respond_to?(method)
        object.method
      elsif object.respond_to?(:[])
        begin
          object[method] || object[method.to_s] || object[method.to_sym]
        rescue ArgumentError, TypeError => e
          nil
        end
      end
    end
  end

  class Reader
    attr_reader :books

    def initialize
      @books = []
    end

    def call(&block)
      instance_eval(&block)
    end

    def book(name, &block)
      b = Rulebook.new(name)
      b.call(&block) if block
      @books << b
    end
  end
end
