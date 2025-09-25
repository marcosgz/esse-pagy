# frozen_string_literal: true

require "spec_helper"

RSpec.describe Esse::Pagy do
  describe "Esse::Index.pagy_search" do
    before do
      stub_esse_index(:cities)
    end

    it { expect(CitiesIndex).to respond_to(:pagy_esse) }
    it { expect(CitiesIndex).to respond_to(:pagy_search) }

    it "returns an array with arguments used to delay the search" do
      args = CitiesIndex.pagy_search("*")
      expect(args).to be_an(Array).and eq([CitiesIndex.cluster, CitiesIndex, {q: "*"}, nil])
    end

    it "returns an array with arguments and block used to delay the search" do
      args = CitiesIndex.pagy_search("*") { |s| s * 2 }
      block = args[-1]
      expect(args).to be_an(Array).and eq([CitiesIndex.cluster, CitiesIndex, {q: "*"}, block])
    end

    it "parses the kwargs and returns an array with arguments used to delay the search" do
      kwargs = {body: {query: {match_all: {}}}, size: 10, from: 0}
      args = CitiesIndex.pagy_search(**kwargs)
      expect(args).to be_an(Array).and eq([CitiesIndex.cluster, CitiesIndex, kwargs, nil])
    end
  end

  describe "Esse::Cluster.pagy_search" do
    it { expect(Esse.cluster).to respond_to(:pagy_esse) }
    it { expect(Esse.cluster).to respond_to(:pagy_search) }

    it "returns an array with arguments used to delay the search" do
      args = Esse.cluster.pagy_search("cities", body: {query: {match_all: {}}})
      expect(args).to be_an(Array).and eq([Esse.cluster, ["cities"], {body: {query: {match_all: {}}}}, nil])
    end

    it "returns an array with arguments and block used to delay the search" do
      args = Esse.cluster.pagy_search("cities", body: {query: {match_all: {}}}) { |s| s * 2 }
      block = args[-1]
      expect(args).to be_an(Array).and eq([Esse.cluster, ["cities"], {body: {query: {match_all: {}}}}, block])
    end

    it "parses the kwargs and returns an array with arguments used to delay the search" do
      kwargs = {body: {query: {match_all: {}}}, size: 10, from: 0}
      args = Esse.cluster.pagy_search("cities", "counties", **kwargs)
      expect(args).to be_an(Array).and eq([Esse.cluster, ["cities", "counties"], kwargs, nil])
    end
  end

  describe "Pagy.new_from_esse" do
    before do
      stub_esse_index(:cities)
    end

    it "returns a Pagy object" do
      stub_esse_search(:default, CitiesIndex, q: "*") do
        {
          "hits" => {
            "total" => {
              "value" => 0
            },
            "hits" => []
          }
        }
      end

      pagy = ::Pagy.new_from_esse(CitiesIndex.search("*"))
      expect(pagy).to be_a(::Pagy)
    end

    it "paginates query with given search kwargs :size and :from" do
      stub_esse_search(:default, CitiesIndex, q: "*", from: 0, size: 2) do
        {
          "hits" => {
            "total" => {
              "value" => 5
            },
            "hits" => [{}, {}]
          }
        }
      end

      pagy = ::Pagy.new_from_esse(CitiesIndex.search("*", from: 0, size: 2))
      expect(pagy.count).to eq(5)
      expect(pagy.page).to eq(1)
      expect(pagy_limit(pagy)).to eq(2)
    end

    it "paginates query with given search body query :size and :from" do
      stub_esse_search(:default, CitiesIndex, body: {query: {}, from: 0, size: 2}) do
        {
          "hits" => {
            "total" => {
              "value" => 5
            },
            "hits" => [{}, {}]
          }
        }
      end

      pagy = ::Pagy.new_from_esse(CitiesIndex.search(body: {query: {}, from: 0, size: 2}))
      expect(pagy.count).to eq(5)
      expect(pagy.page).to eq(1)
      expect(pagy_limit(pagy)).to eq(2)
    end

    it "paginates results with vars" do
      stub_esse_search(:default, CitiesIndex, q: "*", size: 4, from: 2) do
        {
          "hits" => {
            "total" => {
              "value" => 99
            },
            "hits" => [{}, {}, {}, {}, {}]
          }
        }
      end

      pagy = ::Pagy.new_from_esse(CitiesIndex.search("*").limit(4).offset(2), link_extra: "x")
      expect(pagy.count).to eq(99)
      expect(pagy.page).to eq(2)
      expect(pagy_limit(pagy)).to eq(4)
      expect(pagy.vars[:link_extra]).to eq("x")
    end
  end

  describe "Pagy::Backend.pagy_esse on esse index search" do
    let(:app) { MockApp.new }

    before do
      stub_esse_index(:cities)
    end

    it "paginates response with defaults" do
      stub_esse_search(:default, CitiesIndex, q: "*", size: 20, from: 40) do
        {
          "hits" => {
            "total" => {
              "value" => 1000
            },
            "hits" => [{}] * 20
          }
        }
      end

      pagy, query = app.send(:pagy_esse, CitiesIndex.pagy_search("*"))
      expect(pagy).to be_a(::Pagy)
      expect(query).to be_a(Esse::Search::Query)
      expect(pagy.count).to eq(1000)
      expect(pagy_limit(pagy)).to eq(pagy_default_limit)
      expect(pagy.page).to eq(app.params[:page])
    end

    it "paginates response with vars" do
      stub_esse_search(:default, CitiesIndex, q: "*", size: 10, from: 10) do
        {
          "hits" => {
            "total" => {
              "value" => 99
            },
            "hits" => [{}] * 10
          }
        }
      end

      pagy, query = app.send(:pagy_esse, CitiesIndex.pagy_search("*"), page: 2, items: 10, link_extra: "x")
      expect(pagy).to be_a(::Pagy)
      expect(query).to be_a(Esse::Search::Query)
      expect(pagy.count).to eq(99)
      expect(pagy_limit(pagy)).to eq(10)
      expect(pagy.page).to eq(2)
      expect(pagy.vars[:link_extra]).to eq("x")
    end

    it "paginates response with overflow" do
      stub_esse_search(:default, CitiesIndex, q: "*", size: 10, from: 1990) do
        {
          "hits" => {
            "total" => {
              "value" => 1000
            },
            "hits" => []
          }
        }
      end
      stub_esse_search(:default, CitiesIndex, q: "*", size: 10, from: 990) do
        {
          "hits" => {
            "total" => {
              "value" => 1000
            },
            "hits" => [{}] * 20
          }
        }
      end

      pagy, query = app.send(:pagy_esse, CitiesIndex.pagy_search("*"),
        page: 200, items: 10, overflow: :last_page)
      expect(pagy).to be_a(::Pagy)
      expect(query).to be_a(Esse::Search::Query)
      expect(pagy.count).to eq(1000)
      expect(pagy_limit(pagy)).to eq(10)
      expect(pagy.page).to eq(100)
    end
  end

  describe "Pagy::Backend.pagy_esse on esse cluster search" do
    let(:app) { MockApp.new }

    it "paginates response with defaults" do
      stub_esse_search(:default, "geos_*", body: {query: {match_all: {}}, size: 20, from: 40}) do
        {
          "hits" => {
            "total" => {
              "value" => 1000
            },
            "hits" => [{}] * 20
          }
        }
      end

      pagy, query = app.send(:pagy_esse, Esse.cluster.pagy_search("geos_*", body: {query: {match_all: {}}}))
      expect(pagy).to be_a(::Pagy)
      expect(query).to be_a(Esse::Search::Query)
      expect(pagy.count).to eq(1000)
      expect(pagy_limit(pagy)).to eq(pagy_default_limit)
      expect(pagy.page).to eq(app.params[:page])
    end

    it "paginates response with vars" do
      stub_esse_search(:default, "geos_*", body: {query: {match_all: {}}, size: 10, from: 10}) do
        {
          "hits" => {
            "total" => {
              "value" => 99
            },
            "hits" => [{}] * 10
          }
        }
      end

      pagy, query = app.send(:pagy_esse, Esse.cluster.pagy_search("geos_*", body: {query: {match_all: {}}}),
        page: 2, items: 10, link_extra: "x")
      expect(pagy).to be_a(::Pagy)
      expect(query).to be_a(Esse::Search::Query)
      expect(pagy.count).to eq(99)
      expect(pagy_limit(pagy)).to eq(10)
      expect(pagy.page).to eq(2)
      expect(pagy.vars[:link_extra]).to eq("x")
    end

    it "paginates response with overflow" do
      stub_esse_search(:default, "geos_*", body: {query: {match_all: {}}, size: 10, from: 1990}) do
        {
          "hits" => {
            "total" => {
              "value" => 1000
            },
            "hits" => []
          }
        }
      end
      stub_esse_search(:default, "geos_*", body: {query: {match_all: {}}, size: 10, from: 990}) do
        {
          "hits" => {
            "total" => {
              "value" => 1000
            },
            "hits" => [{}] * 20
          }
        }
      end

      pagy, query = app.send(:pagy_esse, Esse.cluster.pagy_search("geos_*", body: {query: {match_all: {}}}),
        page: 200, items: 10, overflow: :last_page)
      expect(pagy).to be_a(::Pagy)
      expect(query).to be_a(Esse::Search::Query)
      expect(pagy.count).to eq(1000)
      expect(pagy_limit(pagy)).to eq(10)
      expect(pagy.page).to eq(100)
    end
  end

  describe "Pagy::Backend.pagy_esse_get_vars" do
    let(:app) { MockApp.new }

    it "returns vars from params" do
      vars = app.send(:pagy_esse_get_vars, nil, {})
      expect(vars[:page]).to eq(3)
      expect(vars[:limit]).to eq(pagy_default_limit)
    end

    it "returns vars from params and merge with given vars" do
      vars = app.send(:pagy_esse_get_vars, nil, page: 2, items: 10)
      expect(vars[:page]).to eq(2)
      expect(vars[:limit]).to eq(10)
    end

    it "returns vars from params and merge with given vars and :page_param" do
      vars = app.send(:pagy_esse_get_vars, nil, page: 2, items: 10, page_param: :p)
      expect(vars[:page]).to eq(2)
      expect(vars[:limit]).to eq(10)
      expect(vars[:page_param]).to eq(:p)
    end
  end

  # Helper method to get items/limit value across Pagy versions
  def pagy_limit(pagy)
    if pagy.respond_to?(:items)
      pagy.items
    elsif pagy.respond_to?(:limit)
      pagy.limit
    else
      raise "Unknown Pagy version - neither items nor limit method available"
    end
  end

  # Helper method to get default items/limit value across Pagy versions
  def pagy_default_limit
    if ::Pagy::DEFAULT.key?(:limit)
      ::Pagy::DEFAULT[:limit]
    elsif ::Pagy::DEFAULT.key?(:items)
      ::Pagy::DEFAULT[:items]
    else
      raise "Unknown Pagy version - neither :items nor :limit in DEFAULT"
    end
  end
end
