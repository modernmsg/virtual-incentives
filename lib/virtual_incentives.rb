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
      options = {'orders' => options}
      post 'orders', body: options
    end

    def order(id)
      raise 'Order Id needed.' unless id
      get "orders/#{id}"
    end

    def orders(options = {})
      get 'orders', options
    end

    def product(sku)
      raise 'SKU is needed.' unless sku
      get "products/#{sku}"
    end

    def product_faceplate(sku)
      raise 'SKU is needed.' unless sku
      get "products/#{sku}/faceplate"
    end

    def product_marketing(sku)
      raise 'SKU is needed.' unless sku
      get "products/#{sku}/marketing"
    end

    def product_terms(sku)
      raise 'SKU is needed.' unless sku
      get "products/#{sku}/terms"
    end

    def products(options = {})
      get 'products', options
    end

    def balances
      get 'balances'
    end

    def program_balances
      get 'balances/programs'
    end

    def program_products(id)
      raise 'Need Program Id' unless id
      get "programs/#{id}/products"
    end

    def program_balance(id)
      raise 'Need Program Id' unless id
      get "balances/programs/#{id}"
    end

    def program_product(id, sku)
      raise 'Need Program Id' unless id
      raise 'Need SKU' unless sku
      get "programs/#{id}/products/#{sku}"
    end
  end

  extend Methods
  include Methods
end
