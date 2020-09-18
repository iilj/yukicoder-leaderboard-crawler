require 'net/http'
require 'uri'

def requestHttps(sUrl)
    sBody = nil
    uri = URI.parse(sUrl)
    Net::HTTP.start(uri.host, uri.port, :use_ssl=>true) {|http|
        response = http.get(uri.request_uri)
        sBody = response.body
    }
    return sBody
end

def requestHttpsCode(sUrl)
    iCode = nil
    uri = URI.parse(sUrl)
    Net::HTTP.start(uri.host, uri.port, :use_ssl=>true) {|http|
        response = http.get(uri.request_uri)
        iCode = response.code.to_i
    }
    return iCode
end