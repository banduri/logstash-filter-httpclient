require 'spec_helper'
require "logstash/filters/httpclient"

# we need to start some sort of http server for the tests

describe LogStash::Filters::Example do
  describe "Test simple http request" do
    let(:config) do <<-CONFIG
      filter {
        httpclient {
          geturl => "http://localhost:8000/foobar"
        }
      }
    CONFIG
    end

    sample("message" => "no data") do
      expect(subject).to include("httpclient")
      expect(subject['httpclient']).to eq('foobar')
    end
  end
end
