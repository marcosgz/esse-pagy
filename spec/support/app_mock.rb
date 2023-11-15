require "rack"
require "active_support/core_ext/hash/indifferent_access"

# Backend and Frontend poor man mock app
# @source https://github.com/ddnexus/pagy/blob/master/test/mock_helpers/app.rb
class MockApp
  attr_reader :params, :request, :response

  include Pagy::Backend
  include Pagy::Frontend

  # App params are merged into the @request.params (and are all strings)
  # @params are taken from @request.params and merged with app params (which fixes symbols and strings in params)
  def initialize(url: "http://example.com:3000/foo", params: {page: 3})
    @request = Rack::Request.new(Rack::MockRequest.env_for(url, params: params))
    @params = ActiveSupport::HashWithIndifferentAccess.new(@request.params).merge(params)
    @response = Rack::Response.new
  end
end
