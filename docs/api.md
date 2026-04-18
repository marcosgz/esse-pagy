# API Reference

The gem adds methods at four layers:

1. `Esse::Index.pagy_search` — build a deferred search description.
2. `Esse::Cluster#pagy_search` — same, for multi-index/cluster searches.
3. `Pagy.new_from_esse` — build a Pagy instance from an already-executed query.
4. `Pagy::Backend#pagy_esse` — controller helper that executes the description with pagination.

---

## `Esse::Index.pagy_search`

Module: `Esse::Pagy::IndexSearch` (extended into `Esse::Index`).

### `.pagy_search(q = nil, **kwargs, &block) → Array`

Returns `[cluster, self, { q: q, **kwargs }, block]` — a **description** of what to search, not an actual search.

```ruby
args = UsersIndex.pagy_search(body: { query: { match_all: {} } })
# => [UsersIndex.cluster, UsersIndex, { body: {...} }, nil]
```

Alias configurable via `Pagy::DEFAULT[:esse_pagy_search]` (default: `:pagy_search`).

---

## `Esse::Cluster#pagy_search`

Module: `Esse::Pagy::ClusterSearch` (prepended into `Esse::Cluster`).

### `#pagy_search(*indices, **kwargs, &block) → Array`

Returns `[self, indices, kwargs, block]`.

```ruby
Esse.cluster.pagy_search(CitiesIndex, CountiesIndex, body: { ... })
```

Indices can be classes, strings, or wildcard patterns.

---

## `Pagy.new_from_esse`

Module: `Esse::Pagy::ClassMethods` (extended into `Pagy`).

### `Pagy.new_from_esse(query, vars = {}) → Pagy`

Builds a Pagy instance from an already-executed `Esse::Search::Query`.

```ruby
query = UsersIndex.search(body: body).limit(10).offset(20)
pagy  = Pagy.new_from_esse(query)
```

Internally:

```ruby
vars[:count] = query.response.total
vars[:page]  = (query.offset_value / query.limit_value.to_f).ceil + 1
vars[:items] = query.limit_value
Pagy.new(vars)
```

---

## `Pagy::Backend#pagy_esse`

Module: `Esse::Pagy::Backend` (prepended into `Pagy::Backend`).

### `#pagy_esse(pagy_search_args, vars = {}) → [Pagy, Esse::Search::Query]`

Executes the deferred search with pagination applied.

```ruby
@pagy, @response = pagy_esse(UsersIndex.pagy_search(body: body), items: 10)
```

Flow:

1. Extract `cluster, indices, kwargs, block` from the description.
2. Merge pagination vars with `params` (uses `Pagy::DEFAULT[:page_param]` and `Pagy::DEFAULT[:items]`).
3. Build the query by calling the search method (default `.search`, configurable via `Pagy::DEFAULT[:esse_search]`) and applying `.limit(items).offset((page - 1) * items)`.
4. Extract total count from `query.response.total`.
5. Construct a `Pagy` instance.
6. Handle `overflow: :last_page` if `Pagy::OverflowExtra` is loaded.
7. Return `[pagy, query]`.

### `#pagy_esse_get_vars(_query, vars)`

Helper: merges Pagy configuration and request params into the vars hash.

| Precedence (high → low) | Source |
|-------------------------|--------|
| Explicit `vars[:page]` / `vars[:items]` | caller |
| `params[page_param]`, `params[:items]` | request |
| `Pagy::DEFAULT[:items]` | config |

---

## Pagy configuration keys used

| Key | Default | Purpose |
|-----|---------|---------|
| `Pagy::DEFAULT[:esse_search]` | `:search` | Name of the search method to call (`.search` by default) |
| `Pagy::DEFAULT[:esse_pagy_search]` | `:pagy_search` | Alias name for the deferred-search method |
| `Pagy::DEFAULT[:items]` | Pagy default | Items per page fallback |
| `Pagy::DEFAULT[:page_param]` | `:page` | Request parameter name for page |

---

## Integration summary

On load:

```ruby
Esse::Index.extend(Esse::Pagy::IndexSearch)
Esse::Cluster.prepend(Esse::Pagy::ClusterSearch)
Pagy::Backend.prepend(Esse::Pagy::Backend)
Pagy.extend(Esse::Pagy::ClassMethods)
```

No configuration is required beyond whatever Pagy setup you already have.
