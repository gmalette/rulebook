require "rulebook/version"
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
      context = Context.new(collection)
      context.call(&@block)
    end
  end

  class Context
    def initialize(collection)
      @collection = collection
    end

    def call(&block)
      instance_exec(@collection, &block)
    end

    def find(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      groups = []
      args.each do |collection, matchers, options|
        matched = collection.__find__(matchers, options)
        binding.pry
      end
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

    def __find__(matchers, options)
      selected = __objects__(options).select do |object|
        matchers.all? do |properties, operator, comparator|
          value = __method_chain__(object, properties)
          value.send(operator, comparator)
        end
      end
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
        __sort__(objects, sort)
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
      objects.reverse! if direction != 'asc'
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

  class Pattern
    def initialize(lambda, &block)
      # p =
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

    protected

    def book(name, &block)
      b = Rulebook.new(name)
      b.call(&block) if block
      @books << b
    end
  end
end
