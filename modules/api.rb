require_relative './req'
require 'json'

def get_contests()
    sUrl = "https://yukicoder.me/api/v1/contest/past"
    sJson = requestHttps(sUrl)
    return JSON.parse(sJson)
end

def get_problems()
    sUrl = "https://yukicoder.me/api/v1/problems"
    sJson = requestHttps(sUrl)
    return JSON.parse(sJson)
end

if __FILE__ == $0
    obj  = get_problems()
    puts obj
end