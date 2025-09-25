# frozen_string_literal: true

require "esse"
require "pagy"

::Pagy::DEFAULT[:esse_search] ||= :search
::Pagy::DEFAULT[:esse_pagy_search] ||= :pagy_search

# I'll try to move this to the `pagy` gem. But we need to wait for the `pagy` author to accept the PR.
# @see https://github.com/ddnexus/pagy/blob/master/lib/pagy/extras/elasticsearch_rails.rb

module Esse
  module Pagy
    module IndexSearch
      def pagy_esse(*args, &block)
        kwargs = extract_search_options!(args)
        [cluster, self, kwargs, block].tap do |args|
          args.define_singleton_method(:method_missing) { |*a| args += a }
        end
      end
      alias_method ::Pagy::DEFAULT[:esse_pagy_search], :pagy_esse
    end

    module ClusterSearch
      def pagy_esse(*indices, **kwargs, &block)
        [self, indices, kwargs, block].tap do |args|
          args.define_singleton_method(:method_missing) { |*a| args += a }
        end
      end
      alias_method ::Pagy::DEFAULT[:esse_pagy_search], :pagy_esse
    end

    module ClassMethods
      def new_from_esse(query, vars = {})
        vars[:count] = query.response.total
        vars[:page] = (query.offset_value / query.limit_value.to_f).ceil + 1
        vars[:limit] = query.limit_value

        if ::Pagy::VERSION.to_i < 9
          # Convert :limit back to :items for older Pagy versions
          vars[:items] = vars.delete(:limit)
          ::Pagy.new(vars)
        else
          ::Pagy.new(**vars)
        end
      end
    end

    # Add specialized backend methods to paginate Esse::Search::Query
    module Backend
      private

      # Return Pagy object and query
      def pagy_esse(pagy_search_args, vars = {})
        cluster, indices, kwargs, block, *called = pagy_search_args
        vars = pagy_esse_get_vars(nil, vars)

        query = cluster.send(::Pagy::DEFAULT[:esse_search], *indices, **kwargs, &block)
          .limit(vars[:limit])
          .offset(vars[:limit] * (vars[:page] - 1))
        vars[:count] = query.response.total

        # Handle Pagy 9+ API changes
        if ::Pagy::VERSION.to_i >= 9
          pagy = ::Pagy.new(**vars)
        else
          legacy_vars = vars.dup
          legacy_vars[:items] = legacy_vars.delete(:limit)
          pagy = ::Pagy.new(legacy_vars)
        end
        # with :last_page overflow we need to re-run the method in order to get the hits
        return pagy_esse(pagy_search_args, vars.merge(page: pagy.page)) \
               if defined?(::Pagy::OverflowExtra) && pagy.overflow? && pagy.vars[:overflow] == :last_page

        [pagy, called.empty? ? query : query.send(*called)]
      end

      # Sub-method called only by #pagy_esse: here for easy customization of variables by overriding
      # the _query argument is not available when the method is called
      def pagy_esse_get_vars(_query, vars)
        pagy_set_items_from_params(vars) if defined?(ItemsExtra)

        # Convert :items to :limit for consistency, this is not needed for Pagy 9+
        vars[:limit] = vars.delete(:items) if vars.key?(:items)
        if ::Pagy::VERSION.to_i < 9
          vars[:limit] ||= ::Pagy::DEFAULT[:items]
        else
          vars[:limit] ||= ::Pagy::DEFAULT[:limit]
        end

        vars[:page] ||= (params[vars[:page_param] || ::Pagy::DEFAULT[:page_param]] || 1).to_i
        vars
      end
    end
  end
end

::Pagy::Backend.prepend(Esse::Pagy::Backend)
::Pagy.extend(Esse::Pagy::ClassMethods)
::Esse::Index.extend(Esse::Pagy::IndexSearch)
::Esse::Cluster.prepend(Esse::Pagy::ClusterSearch)
