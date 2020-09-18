require_relative './req'
require 'json'

def atcoder_user_exists?(atcoder_user_name)
    code = requestHttpsCode("https://atcoder.jp/users/#{atcoder_user_name}")
    return code == 200
end

# {"data"=>nil}
# {"data"=>{
#     "affiliation"=>"会津大学", "competitions"=>78, "country"=>"JP", "formal_country_name"=>"Japan", "highest_rating"=>2618,
#     "rank"=>310, "rating"=>2446, "updated"=>"2018-11-20 10:23:25.770883", "user_color"=>"orange", "username"=>"beet", "wins"=>0
# }}
def atcoder_unofficial_api_from_twitter(twitter_screen_name)
    sJson = requestHttps("https://us-central1-atcoderusersapi.cloudfunctions.net/api/info/TwitterID/#{twitter_screen_name}")
    return JSON.parse(sJson)
end

if __FILE__ == $0
    # p atcoder_user_exists?("abb")
    p atcoder_unofficial_api_from_twitter("beet_aizu")
end