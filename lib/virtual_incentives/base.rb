require 'active_support'
require 'rest-client'

class VirtualIncentives
  module Base
    def self.extended(klass)
      klass.send :cattr_accessor, :endpoint, :auth, :auths
      klass.endpoint = 'https://rest.virtualincentives.com/v4/json/'
    end

    def self.included(klass)
      klass.send :attr_accessor, :auth
    end

    def get_auth
      fail "auth and auths can't both be set" if inherited_auth && auths?

      if auth = instance? ? self.auth : inherited_auth
        auth
      elsif auths?
        fail 'you must init a new API instance with the auth you want to use'
      else
        fail 'you must set an auth token at application boot'
      end
    end

    def inherited_auth
      instance? ? self.class.auth : auth
    end

    def inherited_endpoint
      instance? ? self.class.endpoint : endpoint
    end

    def auths?
      auths = instance? ? self.class.auths : self.auths
      auths && auths.any?
    end

    def instance?
      self.class == VirtualIncentives
    end

  private

    def default_resource_options
      {
        **get_auth,
        headers: {
          "Accept"        => "application/json",
          "Content-Type"  => "json"
        }
      }
    end

    def resource(options = {})
      RestClient::Resource.new inherited_endpoint, default_resource_options.deep_merge(options)
    end

    def handle_response(method, resource, options = {})
      res = response(method, resource, options)
      if error = find_error(res)
        raise "#{error.code}: #{error.field} = #{error.message}"
      end
      res 
    end

    def find_error(object, found=nil)
      key = "errors"
      if object.respond_to?(:key?) && object.key?(key)
        return object[key]
      elsif object.is_a? Enumerable
        object.find { |*a| found = deep_find(key, a.last) }
        return JSON.parse found
      end
    end

    def response(method, resource, options)
      if body = options.delete(:body)
        JSON.parse resource.send(method, JSON.generate(body), options)
      else
        JSON.parse resource.send(method, options)
      end
    rescue => e
      if e.respond_to?(:response)
        JSON.parse(e.response)
      else
        raise
      end
    end

    def get(path, request_options = {}, resource_options = {})
      response :get, resource(resource_options)[path], request_options
    end

    def delete(path, request_options = {}, resource_options = {})
      response :delete, resource(resource_options)[path], request_options
    end

    def post(path, request_options = {}, resource_options = {})
      response :post, resource(resource_options)[path], request_options
    end

    def put(path, request_options = {}, resource_options = {})
      response :put, resource(resource_options)[path], request_options
    end
  end
end
