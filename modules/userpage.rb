require_relative './req'
require 'nokogiri'

def get_userpage(user_id = 7584)
    html = requestHttps("https://yukicoder.me/users/#{user_id}")
    doc = Nokogiri::HTML.parse(html, nil, 'utf-8')
    user_name = doc.css('div#profile h1').inner_text.strip
    data = doc.css('div#summary div.right').map{|d|d.inner_text.strip}[0..-2]
    # 0:登録日時, 1:公開問題, 2:提出, 3:AC問題数, 4:ユーザーLv., 5:スコア, 6:ゆるふわポイント,
    # 7:Twitter, 8:URL, 9:yukicoder SlackId, 10:ほしいものリスト
    twitter = data[7]
    if twitter.length > 0
        twitter = twitter[1..-1]
    end
    if twitter.length == 0
        twitter = nil
    end
    url = data[8]
    if url.length == 0
        url = nil
    end
    return [user_name, twitter, url]
end

if __FILE__ == $0
    p get_userpage(6366)
    p get_userpage(7584)
end