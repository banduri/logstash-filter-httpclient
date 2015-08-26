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
  config :geturl, :validate => :string, :default => "http://localhost:8000/"

  public
  def register
    require "net/http"
    require "uri"
  end

  public
  def filter(event)
    # no event -> nothing to do
    return unless filter?(event)
    # check if id_field is present in event
    begin 
      uri = URI.parse(event.sprintf(@geturl))
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
      event[@target_field] = response.body
      filter_matched(event)
    rescue Exception => e
      @logger.warn("Unhandled exception", :request => request, :response => response, :exception => e, :stacktrace => e.backtrace) 
    end
  end

end # class LogStash::Filters::RestclientFilter
