require_relative './req'
require 'nokogiri'

def get_contest_leaderboard(contest_id = 280)
    html = requestHttps("https://yukicoder.me/contests/#{contest_id}/table")
    doc = Nokogiri::HTML.parse(html, nil, 'utf-8')
    tbl = doc.css('div#content table.table')

    # 問題の抽出
    sz = 0;
    problemNumbers = []
    prlblemTitles = []
    tbl.css('thead a').each {|a|
        sHref = a.attr("href")
        iProblemNo = sHref.split("/")[-1].to_i
        sProblemTitle = a.inner_html.split("<br>")[-1]
        # puts [iProblemNo, sProblemTitle].join(", ")
        problemNumbers << iProblemNo
        prlblemTitles << sProblemTitle
        sz += 1
    }

    # ユーザの抽出
    userResults = []
    tbl.css('tbody tr').each {|tr|
        sTrClass = tr.attr("class") # "writer" or nil
        # p sTrClass
        bIsWriter = (sTrClass == "writer")

        iRank = tr.css('td:nth-child(1)').inner_text.strip.to_i
        lnkUserName = tr.css('td:nth-child(2) a')
        iUserId = lnkUserName.attr("href").value.split("/")[-1].to_i
        sUserName = lnkUserName.inner_text.strip
        # puts [iRank, iUserId, sUserName].join(", ")

        solved = []
        sz.times {|i|
            iPoint = tr.css("td:nth-child(#{3 + i}) b").inner_text.strip.to_i
            solved << (iPoint > 0)
        }
        # puts solved.join(", ")

        userResults << [iRank, iUserId, sUserName, bIsWriter, solved]
    }

    return sz, problemNumbers, prlblemTitles, userResults
end

if __FILE__ == $0
    sz, problemNumbers, prlblemTitles, userResults  = get_contest_leaderboard(280)
    puts sz, problemNumbers, prlblemTitles, userResults
end