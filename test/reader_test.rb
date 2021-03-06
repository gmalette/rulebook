require "minitest/autorun"
require "mocha/setup"
require_relative '../lib/rulebook'

class ReaderTest < Minitest::Test
  def setup
    @reader = Rulebook::Reader.new
  end

  def test_creates_book
    @reader.book 'Rules' do
    end

    assert_equal 1, @reader.books.length
  end
end

class BookTest < Minitest::Test
  def setup
    @book = Rulebook::Rulebook.new('Rules')
  end

  def test_rule_creates_rules
    @book.rule 'First rule' do |obj|
    end

    @book.rule 'Second rule' do |obj|
    end

    assert_equal 2, @book.rules.length
  end
end


class RulebookTest < Minitest::Test
  def setup
    @cart = {
      :items => [
        {:category => 'hat', :price => 20, :handles => ["handle-20", 'other-handle']},
        {:category => ['hat'], :price => 40},
        {:category => 'hat', :price => 50, :handles => "handle-50"},
        {:category => 'hat', :price => 30},
        {:category => 'hat', :price => 10},
        {:category => 'toaster', :price => 10},
      ],
      :customer => {
        :name => "Peter Pan"
      }
    }
  end
end

class CollectionProxyTest < RulebookTest
  def setup
    super
    @collection = Rulebook::CollectionProxy.new(@cart)
  end

  def test_proxy_methods
    assert_equal ['handle-20', 'other-handle', 'handle-50'], @collection.items.handles.instance_variable_get(:@objects)
  end

  def test_collection_sort_one_argument
    objects = @cart[:items].dup
    sorted = @collection.send(:__sort__, objects, [:price])
    assert_equal [10, 10, 20, 30, 40, 50], sorted.map{ |o| o[:price] }
  end

  def test_collection_sort_two_argument_descending
    objects = @cart[:items].dup
    sorted = @collection.send(:__sort__, objects, ['price', 'desc'])
    assert_equal [50, 40, 30, 20, 10, 10], sorted.map{ |o| o[:price] }
  end

  def test_find_elements_one_condition
    results = @collection.items.__find__([[[:price], :>, 20]], [], {})
    expected = @cart[:items].select{ |c| c[:price] > 20 }

    assert_equal [expected], results
  end

  def test_find_elements_one_condition_nested
    results = @collection.__find__([[[:items, :price], :>, 20]], [], {})

    assert_equal [[@cart]], results
  end

  def test_find_elements_no_results
    results = @collection.items.__find__([[[:price], :>, 50]], [], {})

    assert_equal [[]], results
  end

  def test_find_elements_sorted_asc
    results = @collection.items.__find__([[[:price], :>, 20]], [], {sort: ['price', 'asc']})
    expected = @cart[:items].select{ |i| i[:price] > 20 }.sort_by{ |i| i[:price] }

    assert_equal [expected], results
  end

  def test_find_elements_sorted_desc
    results = @collection.items.__find__([[[:price], :>, 20]], [], {sort: ['price', 'desc']})
    expected = @cart[:items].select{ |i| i[:price] > 20 }.sort_by{ |i| i[:price] * -1 }

    assert_equal [expected], results
  end

  def test_find_elements_with_count
    results = @collection.items.__find__([[[:price], :>, 20]], [], {count: 2})
    expected = @cart[:items].select{ |c| c[:price] > 20 }

    assert_equal [expected[0..1], expected[2..3]], results
  end
end

class CollectionProxyOperatorsTest < Minitest::Test
  def setup
    @collection = Rulebook::CollectionProxy.new([20, 30, 40])
  end

  def test_greater_than
    assert(@collection > 20)
    assert(@collection > 30)
    refute(@collection > 40)
  end

  def test_lower_than
    assert(@collection < 40)
    assert(@collection < 30)
    refute(@collection < 20)
  end

  def test_greater_than_or_equal
    assert(@collection >= 20)
    assert(@collection >= 30)
    assert(@collection >= 40)
    refute(@collection >= 50)
  end

  def test_lower_than_or_equal
    assert(@collection <= 40)
    assert(@collection <= 30)
    assert(@collection <= 20)
    refute(@collection <= 10)
  end

  def test_equal
    assert(@collection == 40)
    assert(@collection == 30)
    assert(@collection == 20)
    refute(@collection == 10)
  end

  def test_not_equal
    assert(@collection != 40)
    assert(@collection != 30)
    assert(@collection != 20)
    assert(@collection != 10)

    collection = Rulebook::CollectionProxy.new(20)
    refute(collection != 20)
  end
end


class ContextTest < RulebookTest
  def setup
    super
    @collection = Rulebook::CollectionProxy.new(@cart)
    @context = Rulebook::Context.new(nil, nil, @collection)
  end

  def test_call_yields_arguments
    args = nil
    @context.call { |a| args = a }
    assert_equal args.object_id, @collection.object_id
  end

  def test_call_yields_multiple_arguments
    @items = Rulebook::CollectionProxy.new(@cart[:items])
    context = Rulebook::Context.new(nil, nil, @collection, @items)

    arg1 = nil
    arg2 = nil
    context.call do |a1, a2|
      arg1 = a1
      arg2 = a2
    end

    assert_equal arg1.object_id, @collection.object_id
    assert_equal arg2.object_id, @items.object_id
  end

  def test_find_returns_match_context_with_single_iteration
    result = @context.find([@collection.items, [[[:category], :==, 'hat']], {}])

    assert result.is_a?(Rulebook::MatchContext)
    iterations = result.match_group.iterations

    assert_equal 1, iterations.length

    arguments = iterations.first
    assert_equal 1, arguments.length
  end

  def test_find_with_count_returns_match_context_with_2_iterations
    result = @context.find([@collection.items, [[[:category], :==, 'hat']], {count: 2}])
    iterations = result.match_group.iterations
    assert_equal 2, iterations.count
  end
end
