require 'singleton'
require "net/http"
require "uri"
require 'net/http/digest_auth'
require 'json'

module MMS

  class Client

    include Singleton

    attr_accessor :username
    attr_accessor :apikey

    attr_accessor :api_protocol
    attr_accessor :api_host
    attr_accessor :api_port
    attr_accessor :api_path
    attr_accessor :api_version

    def initialize
      @username, @apikey = nil

      @api_protocol = 'https'
      @api_host = 'mms.mongodb.com'
      @api_port = '443'
      @api_path = '/api/public'
      @api_version = 'v1.0'
    end

    def auth_setup(username, apikey)
      @username = username
      @apikey = apikey
    end

    def site
      [@api_protocol, '://', @api_host, ':', @api_port, @api_path, '/',  @api_version].join.to_s
    end

    def get(path)
      _get site + path, @username, @apikey
    end

    def post(path, data)
      _post site + path, data, @username, @apikey
    end

    private

    def _get(path, username, password)

      digest_auth = Net::HTTP::DigestAuth.new
      digest_auth.next_nonce

      uri = URI.parse path
      uri.user= CGI.escape(username)
      uri.password= CGI.escape(password)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      req = Net::HTTP::Get.new uri.request_uri
      res = http.request req

      auth = digest_auth.auth_header uri, res['WWW-Authenticate'], 'GET'
      req = Net::HTTP::Get.new uri.request_uri
      req.add_field 'Authorization', auth

      response = http.request(req)
      response_json = JSON.parse(response.body)

      unless response_json['error'].nil?
       response_json = nil
      end

      (response_json.nil? or response_json['results'].nil?) ? response_json : response_json['results']
    end

    def _post(path, data, username, password)
      digest_auth = Net::HTTP::DigestAuth.new
      digest_auth.next_nonce

      uri = URI.parse path
      uri.user= CGI.escape(username)
      uri.password= CGI.escape(password)

      http = Net::HTTP.new uri.host, uri.port
      http.use_ssl = true

      req = Net::HTTP::Post.new uri.request_uri, {'Content-Type' =>'application/json'}
      res = http.request req

      auth = digest_auth.auth_header uri, res['WWW-Authenticate'], 'POST'
      req = Net::HTTP::Post.new uri.request_uri, {'Content-Type' =>'application/json'}
      req.add_field 'Authorization', auth
      req.body = data.to_json

      response = http.request req
      response_json = JSON.parse response.body

      unless response_json['error'].nil?
        response_json = nil
      end

      (response_json.nil? or response_json['results'].nil?) ? response_json : response_json['results']
    end

  end
end
