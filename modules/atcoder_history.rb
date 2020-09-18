require_relative './req'
require 'json'
require 'time'

def atcoder_get_history(atcoder_user_name)
    sJson = requestHttps("https://atcoder.jp/users/#{atcoder_user_name}/history/json")
    return JSON.parse(sJson)
end

def atcoder_get_history_with_inner_rating(atcoder_user_name)
    history = atcoder_get_history(atcoder_user_name)
    # {"IsRated"=>true, "Place"=>37, "OldRating"=>2780, "NewRating"=>2824, "Performance"=>3159, "InnerPerformance"=>3159,
    #  "ContestScreenName"=>"agc047.contest.atcoder.jp", "ContestName"=>"AtCoder Grand Contest 047", "ContestNameEn"=>"",
    #  "EndTime"=>"2020-08-09T23:20:00+09:00"}
    validHistory = history.filter{_1["IsRated"]}

    datetimeHistory = validHistory.map{Time.parse(_1["EndTime"]).to_i}
    ratingHistory = validHistory.map{_1["NewRating"]}
    performanceHistory = validHistory.map{_1["Performance"]}
    innerPerformanceHistory = validHistory.map{_1["InnerPerformance"]}

    innerRatingHistory = innerPerformanceHistory.map.with_index{|entry, idx|
        target = innerPerformanceHistory[0..idx].reverse
        numerator = 0.0 # 分子
        denominator = 0.0 # 分母
        target.each.with_index(1) {|innerPerf, i|
            numerator += (0.9 ** i) * innerPerf.to_f
            denominator += (0.9 ** i)
        }
        next numerator / denominator
    }
    ret = datetimeHistory.zip(performanceHistory, innerPerformanceHistory, ratingHistory, innerRatingHistory)
    return ret
end

if __FILE__ == $0
    p atcoder_get_history_with_inner_rating("abb")
end