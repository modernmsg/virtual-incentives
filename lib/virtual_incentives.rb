require 'virtual_incentives/version'
require 'virtual_incentives/base'

class VirtualIncentives
  extend Base
  include Base

  # Class-level methods only work if you have a single API account. This lets
  # you instantiate the API for a given account, if you have multiple.
  def initialize(auth:)
    fail 'no auths set' unless auths = self.class.auths
    self.auth = auths.fetch(auth)
  end

  # This lets you call the same API requests on every account you have.
  # This is useful e.g. to check the status of every gift in every account.
  def self.each_auth
    fail 'no auths set' unless auths
    auths.each do |name, _|
      yield new auth: name
    end
  end

  def ==(other)
    other.is_a?(VirtualIncentives) && auth == other.auth
  end

  module Methods

    def place_order(options = {})
      post 'order', options
    end

    def order(id)
      raise 'Order Id needed.' unless id
      get "order/#{id}"
    end

    def orders(options = {})
      post 'order/list', options
    end
  end

  extend Methods
  include Methods
end
