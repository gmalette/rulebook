# Rulebook

Rulebook is an embeddable rule application language that aims to be simple and concise to write.

The language looks like a mix between XPath and CoffeeScript

## Basic concepts

```
book Discounts ->
  rule 'buy two coats, get a 30% on hats' -> (cart)
    (cart.items[category = 'coat'], count: 2), (cart.items[category = 'hat']) -> (coats, hat)
      apply hat, value: 0.3 * hat.value

  rule '10$ off for purchases over 100$' -> (cart)
    (cart[price > 100]) ->
      apply cart, value: 10
```

Books are the basic object. You need to define at least one book.

Books define rules. Rules have names. Rules receive the input passed down from the reader.

Rules use match groups `(cart[price > 100])` to filter how to apply the rules, then apply them.

Match groups can also use match groups to further filter objects.

The rule application is still fuzzy.

## Installation

Add this line to your application's Gemfile:

    gem 'rulebook'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rulebook

## Usage

The usage is not set yet, but in the end it should look something like this:

```ruby
require 'rulebook'

reader = Rulebook.parse(source_file)
reader.apply(input) => [AppliedRule, AppliedRule, ...]
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
