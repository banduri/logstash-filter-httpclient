require "logstash/filters/base"
require "logstash/namespace"



class LogStash::Filters::Restclient < LogStash::Filters::Base

  # Setting the config_name here is required. This is how you
  # configure this filter from your logstash config.
  #
  # filter {
  #   foo { ... }
  # }
  config_name "httpclient"

  # New plugins should start life at milestone 1.
  #milestone 1

  # config parameter
  #  baseURL: where is my restservice
  #  timeout: connectiontimeout
  #  id_field: this field contains the id we want to translate
  #  target_field: where to store the result
  #  
  #  request is: @baseURL/@id_field
  #    http://localhost:8000/foobar/id_field

  config :target_field, :validate => :string, :default => "httpclient"
  config :base_url, :validate => :string
  config :username, :validate => :string
  config :password, :validate => :string, :default => ""
  config :cacert, :validate => :path
  config :cert, :validate => :path
  config :key, :validate => :path
  # Not implemented
  config :reqtype, :validate => :string, :default => "Get"
  #relativ to base_url
  config :path, :validate => :string, :default => "/"
  # Not implemented
  config :query, :validate => :hash
  # Not implemented
  config :proxy, :validate => :string
  # Not implemented
  config :proxyport, :validate => :string
  # Not implemented
  config :proxyuser, :validate => :string
  # Not implemented
  config :proxypass, :validate => :string
  # Not implemented
  config :decodejson, :validate => :boolean, :default => false
  # the User Agent String to send
  config :useragent, :validate => :string, :default => "HTTPClient/1.0"
  # directly send request with username and password instead of
  # testing -> 401 -> second request with username/password
  config :force_basic_auth, :validate => :boolean, :default => false

  public
  def register
    require "httpclient"
    begin
      @httpagent = HTTPClient.new(:agent_name => @useragent,
                                  :base_url => @base_url,
                                  :force_basic_auth => @force_basic_auth)
      # we do not support cookies 
      @httpagent.cookie_manager = nil
      if @username and @password
        @httpagent.set_auth(@base_url,@username,@password)
      end
      if @cert and @key
        @httpagent.ssl_config.set_client_cert_file(@cert,@key)
      end
      if @cacert
        # also the add_trust_ca removes all certs from the trust store
        # but this could change.
        @httpagent.ssl_config.clear_cert_store
        @httpagent.ssl_config.add_trust_ca(@cacert)
      # if @proto == "https"
      #   httpagent.use_ssl = true
      # end
      # if @cert
      #   cert = File.read(@cert)
      #   httpagent.cert = OpenSSL::X509::Certificate.new(@cert)
      #   key = File.read(@key)
      #   httpagent.key = OpenSSL::PKey::PSA.new(@key)
      # end
      # if @cacert
      #   httpagent.ca_file = @cacert
      # end
    rescue Exception => e
      @logger.warn("Unhandled exception",
                   :exception => e, :stacktrace => e.backtrace) 
    end
  end

  public
  def filter(event)
    # no event -> nothing to do
    return unless filter?(event)
    # check if id_field is present in event
    begin
      if @query
        event[@target_field] = @httpagent.get_content(event.sprintf(@path),@query)
      else
        event[@target_field] = @httpagent.get_content(event.sprintf(@path))
      filter_matched(event)
    rescue Exception => e
      @logger.warn("Unhandled exception",
                   :httpagent => @httpagent,
                   :event => event,
                   :exception => e, :stacktrace => e.backtrace) 
    end
  end

end # class LogStash::Filters::RestclientFilter
