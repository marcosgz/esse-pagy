# Usage Guide

## Installation

```ruby
# Gemfile
gem 'esse'
gem 'pagy'
gem 'esse-pagy'
```

Loading the gem:

- Extends every `Esse::Index` with `pagy_search`.
- Prepends `pagy_search` into `Esse::Cluster`.
- Adds `pagy_esse` to `Pagy::Backend` (already included in your controllers).
- Adds `Pagy.new_from_esse`.

No initializer needed.

## Basic controller usage

```ruby
class UsersController < ApplicationController
  def index
    @pagy, @response = pagy_esse(
      UsersIndex.pagy_search(body: { query: { match_all: {} } }),
      items: 10
    )
  end
end
```

- `UsersIndex.pagy_search(...)` returns a deferred "search description" (it does **not** execute a query).
- `pagy_esse(description, **vars)` executes the search with the pagination info pulled from `params` (or provided `vars`) and returns `[pagy_instance, query_or_response]`.

## Rendering

```erb
<%== pagy_nav(@pagy) %>

<% @response.results.each do |hit| %>
  <%= hit.dig('_source', 'name') %>
<% end %>
```

## Multiple indices / cluster search

Use `Esse.cluster.pagy_search`:

```ruby
@pagy, @response = pagy_esse(
  Esse.cluster.pagy_search(CitiesIndex, CountiesIndex, body: body),
  items: 20
)
```

You can also pass wildcard index names:

```ruby
@pagy, @response = pagy_esse(
  Esse.cluster.pagy_search('geos_*', body: { query: { match_all: {} } }),
  items: 15
)
```

## Passing a query-modification block

The block is forwarded to the underlying `search` call:

```ruby
@pagy, @response = pagy_esse(
  UsersIndex.pagy_search("*") { |query| query.filter('status', 'active') },
  items: 10
)
```

## Reading params

By default `pagy_esse` reads `params[:page]` and `params[:items]`:

```
/users?page=2&items=25
```

Override by passing `vars`:

```ruby
pagy_esse(description, page: 3, items: 50)
```

Pagy's standard configuration applies:

```ruby
# config/initializers/pagy.rb
Pagy::DEFAULT[:items] = 20
Pagy::DEFAULT[:page_param] = :p
```

## Creating a Pagy from an executed query

If you have a query already executed, use:

```ruby
query = UsersIndex.search(body: body).limit(10).offset(20)
pagy  = Pagy.new_from_esse(query)

# pagy.page  => 3
# pagy.items => 10
# pagy.count => total hits
```

## Overflow handling

With `Pagy::OverflowExtra` loaded:

```ruby
@pagy, @response = pagy_esse(description, items: 10, overflow: :last_page)
```

When the requested page is beyond the available pages, Pagy falls back to the last valid page instead of raising `Pagy::OverflowError`.

## Customizing method names

The default method is `pagy_search`, aliased from `pagy_esse`. Change the alias name via Pagy's defaults:

```ruby
Pagy::DEFAULT[:esse_pagy_search] = :my_method
```

Now call `UsersIndex.my_method(...)` and `Esse.cluster.my_method(...)`.

## Comparing to esse-kaminari

| Aspect | esse-pagy | esse-kaminari |
|--------|-----------|---------------|
| Style | Controller backend | Chainable query methods |
| Multi-index | Built-in via cluster | Single-index focus |
| Execution | Deferred until `pagy_esse` | Lazy until `.response` |
| Best for | Rails controllers, multi-index | Service objects, single-index |
