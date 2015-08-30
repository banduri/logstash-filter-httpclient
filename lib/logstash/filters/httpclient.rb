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
  config :server, :valudate => :string, :default => "localhost"
  config :port, :validate => :number, :default => 443
  config :proto, :validate => :string, :default => "https"
  # Not implemented
  config :username, :validate => :string
  # Not implemented
  config :password, :validate => :string, :default => ""
  config :cacert, :validate => :path
  config :cert, :validate => :path
  config :key, :validate => :path
  # Not implemented
  config :reqtype, :validate => :string, :default => "Get"
  config :path, :validate => :string, :default => "/"
  # Not implemented
  config :parms, :validate => :hash
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

  public
  def register
    require "net/http"
    require "net/https"
    require "uri"
    begin
      httpagent = Net::HTTP.new(@server,@port)
      if @proto == "https"
        httpagent.use_ssl = true
      end
      if @cert
        cert = File.read(@cert)
        httpagent.cert = OpenSSL::X509::Certificate.new(@cert)
        key = File.read(@key)
        httpagent.key = OpenSSL::PKey::PSA.new(@key)
      end
      if @cacert
        httpagent.ca_file = @cacert
      end
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
      httpagent.request_get(event.sprintf(@path)){|res|
        event[@target_field] = res.read_body
      }
      filter_matched(event)
    rescue Exception => e
      @logger.warn("Unhandled exception",
                   :request => @httpagent,
                   :event => event,
                   :exception => e, :stacktrace => e.backtrace) 
    end
  end

end # class LogStash::Filters::RestclientFilter
