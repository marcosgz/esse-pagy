# Esse Pagy Extension

This gem is a [esse](https://github.com/marcosgz/esse) plugin for the [pagy](https://github.com/ddnexus/pagy) pagination.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'esse-pagy'
```

And then execute:

```bash
$ bundle install
```

## Pagy Version Compatibility

This gem supports Pagy versions 5.x through 9.x, but with different Ruby version requirements:

| Pagy Version | Ruby Version Required |
|--------------|----------------------|
| 5.x, 6.x     | >= 2.5.0             |
| 7.x, 8.x, 9.x| >= 3.1.0             |

## Usage

```ruby
# Single index
query = UsersIndex.pagy_search(body: { ... })

# Multiple indexes
query = Esse.cluster.pagy_search(CitiesIndex, CountiesIndex, body: { ... })
query = Esse.cluster.pagy_search('esse_geos_*', body: { ... })

# paginate it
@pagy, @response = pagy_esse(collection, items: 10)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake none` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/marcosgz/esse-pagy.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
