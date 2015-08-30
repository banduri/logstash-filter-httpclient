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
  # not implemented
  config :cacert, :validate => :path
  # not implemented
  config :cert, :validate => :path
  # not implemented
  config :key, :validate => :path
  # Not implemented
  config :reqtype, :validate => :string, :default => "Get"
  #relativ to base_url
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
  # the User Agent String to send
  config :useragent, :validate => :string, :default => "logstash-filter-httpclient"

  public
  def register
    require "httpclient"
    begin
      @httpagent = HTTPClient.new(nil,@useragent,'',@base_url)
      if @username
        @httpagent.set_auth(@base_url,@username,@password)
      end
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
      event[@target_field] = @httpagent.get(event.sprintf(@path)).body
      filter_matched(event)
    rescue Exception => e
      @logger.warn("Unhandled exception",
                   :httpagent => @httpagent,
                   :event => event,
                   :exception => e, :stacktrace => e.backtrace) 
    end
  end

end # class LogStash::Filters::RestclientFilter
