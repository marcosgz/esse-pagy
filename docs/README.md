# esse-pagy

[Pagy](https://github.com/ddnexus/pagy) pagination for [Esse](../../esse/docs/README.md) search queries.

Unlike `esse-kaminari`, which adds chainable query methods, `esse-pagy` uses Pagy's **controller-backend** pattern: the index builds a delayed search description, and the `pagy_esse` controller helper executes it with pagination.

## Contents

- [Usage guide](usage.md)
- [API reference](api.md)

## Install

```ruby
# Gemfile
gem 'esse', '>= 0.2.4'
gem 'pagy', '>= 5'
gem 'esse-pagy'
```

In your controller (Pagy's `Pagy::Backend` is typically included in `ApplicationController`):

```ruby
class UsersController < ApplicationController
  def index
    @pagy, @response = pagy_esse(
      UsersIndex.pagy_search(body: { query: { match: { name: params[:q] } } }),
      items: 10
    )
    @results = @response.results
  end
end
```

In the view:

```erb
<%== pagy_nav(@pagy) %>
<% @results.each { |hit| %><%= hit.dig('_source', 'name') %><br><% } %>
```

## Multi-index pagination

```ruby
@pagy, @response = pagy_esse(
  Esse.cluster.pagy_search(CitiesIndex, CountiesIndex, body: body),
  items: 25
)
```

## Version

- Version: **0.0.1**
- Ruby: `>= 2.5.0`
- Depends on: `esse >= 0.2.4`, `pagy >= 5`

## License

MIT.
