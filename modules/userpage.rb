require_relative './req'
require 'nokogiri'

def get_userpage(user_id = 7584)
    html = requestHttps("https://yukicoder.me/users/#{user_id}")
    doc = Nokogiri::HTML.parse(html, nil, 'utf-8')
    doc.css('div#profile h1>div').remove
    user_name = doc.css('div#profile h1').inner_text.strip
    data = doc.css('div#summary div.right').map{|d|d.inner_text.strip}[0..-2]
    # p data
    # 0:登録日時, 1:公開問題, 2:提出, 3:AC問題数, 4:ユーザーLv., 5:スコア, 6:ゆるふわポイント,
    # 7:Twitter, 8: AtCoder, 9: Codeforces, 10:URL, 11:yukicoder SlackId, 12:ほしいものリスト
    twitter = data[7]
    if twitter.length > 0
        twitter = twitter[1..-1]
    end
    if twitter.length == 0
        twitter = nil
    end
    atcoder_user_name = data[8];
    if atcoder_user_name.length == 0
        atcoder_user_name = nil
    end
    url = data[10]
    if url.length == 0
        url = nil
    end
    return [user_name, twitter, atcoder_user_name, url]
end

if __FILE__ == $0
    p get_userpage(6366)
    p get_userpage(7584)
    p get_userpage(8091)
end