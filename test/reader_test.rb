require "minitest/autorun"
require "mocha/setup"
require_relative '../lib/rulebook'

# class ReaderTest < Minitest::Test
#   def setup
#     @reader = Rulebook::Reader.new
#   end

#   def test_creates_book
#     @reader.book 'Rules' do
#     end

#     assert_equal 1, @reader.books.length
#   end
# end

# class BookTest < Minitest::Test
#   def setup
#     @book = Rulebook::Rulebook.new('Rules')
#   end

#   def test_rule_creates_rules
#     @book.rule 'First rule' do |obj|
#     end

#     @book.rule 'Second rule' do |obj|
#     end

#     assert_equal 2, @book.rules.length
#   end
# end

# class RuleTest < Minitest::Test
#   def setup
#     @rule = Rulebook::Rule.new('First rule') {}
#   end

#   def test_find_creates_a_pattern
#     object_properties = [object, {name: 'toto'}, {count: 2}]
#     Rulebook::Pattern.any_instance.expects(:intialize).with(object_properties)
#     @rule.find(object_properties)

#     assert_equal 1, @rule.patterns.length
#   end
# end



class RulebookTest < Minitest::Test
  def setup
    @reader = Rulebook::Reader.new
    @reader.call do
      book 'Discounts' do
        rule 'hats with coats' do |cart|
          find [cart.items, [[[:category], :==, 'hat'], [[:price], :>, 10]], {count: 2, sort: ['price', 'desc']}], limit: 2 do |items|
            apply items, value: 10
          end
        end
      end
    end
    @cart = {
      :items => [
        {:category => 'hat', :price => 20},
        {:category => ['hat'], :price => 40},
        {:category => 'hat', :price => 50},
        {:category => 'hat', :price => 30},
        {:category => 'hat', :price => 10},
        {:category => 'toaster', :price => 10},
      ],
      :customer => {
        :name => "Peter Pan"
      }
    }
  end

  def test_applying_rules
    @reader.books.first.apply(@cart)
  end
end

class CollectionProxyTest < Minitest::Test
  def setup
    @cart = {
      :items => [
        {:category => 'hat', :price => 20, :handles => ["handle-20", 'other-handle']},
        {:category => 'hat', :price => 40},
        {:category => 'hat', :price => 50, :handles => "handle-50"},
        {:category => 'hat', :price => 30},
        {:category => 'hat', :price => 10},
        {:category => 'toaster', :price => 10},
      ],
      :customer => {
        :name => "Peter Pan"
      }
    }
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
