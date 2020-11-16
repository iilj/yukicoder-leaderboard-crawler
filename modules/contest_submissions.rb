require_relative './req'
require 'nokogiri'
require 'time'

def mysleep(sec = 10)
    puts "sleeping for #{sec} sec..."
    sleep sec
end

$cahce_submission_page_max = {}

# 最大ページ数を取得する
def get_contest_submissions_page_count(contest_id = 245)
    if $cahce_submission_page_max.has_key?(contest_id)
        return $cahce_submission_page_max[contest_id]
    end
    html = requestHttps("https://yukicoder.me/contests/#{contest_id}/submissions?page=100000")
    doc = Nokogiri::HTML.parse(html, nil, 'utf-8')
    pagination = doc.css('nav ul.pagination')
    pages = pagination.css('li.page-item a').map{|lnk|
        next lnk.attr("href").split("=")[-1].to_i
    }
    ret = pages.max
    $cahce_submission_page_max[contest_id] = ret
    return ret
end

$cahce_submission_page = {}

# 単一の提出一覧ページをパースする
def get_contest_submissions_page(contest_id = 245, page = 1)
    # https://yukicoder.me/contests/245/submissions?page=122
    req_url = "https://yukicoder.me/contests/#{contest_id}/submissions?page=#{page}&date_asc=enabled"
    if $cahce_submission_page.has_key?(req_url)
        return $cahce_submission_page[req_url]
    end
    mysleep
    html = requestHttps(req_url)
    doc = Nokogiri::HTML.parse(html, nil, 'utf-8')
    tbl = doc.css('div#content table.table')

    submissions = tbl.css('tbody tr').map {|tr|
        iSubmissionId = tr.css('td:nth-child(1) a').attr("href").value.split("/")[-1].to_i
        iTime = Time.parse(tr.css('td:nth-child(2)').inner_text.strip).to_i
        iUserId = tr.css('td:nth-child(4) a').attr("href").value.split("/")[-1].to_i
        iProblemNo = tr.css('td:nth-child(5) a').attr("href").value.split("/")[-1].to_i
        sLabel = tr.css('td:nth-child(7) span.label:last-child').inner_text.strip # 最初のジャッジ結果
        next [iSubmissionId, iTime, iUserId, iProblemNo, sLabel]
    }
    $cahce_submission_page[req_url] = submissions
    return submissions
end

# 指定日時以降の提出が含まれる最初のページを求める
def search_start_page_binary(contest_id = 245, iStartTime = 946652400) # Time.parse('2000-01-01 00:00:00').to_i
    left = 1
    right = get_contest_submissions_page_count(contest_id)

    puts "get page #{left}"
    submissions_left = get_contest_submissions_page(contest_id, left)
    if submissions_left.map{|sub| next sub[1] }.max >= iStartTime
        return 1
    end
    puts "get page #{right}"
    submissions_right = get_contest_submissions_page(contest_id, right)
    if submissions_right.map{|sub| next sub[1] }.max < iStartTime
        return -1 # 指定日時以降の提出が存在しない
    end

    # 以降，left=ng, right=ok
    while left + 1 < right
        mid = (left + right) / 2
        puts "get page #{mid}"
        submissions_mid = get_contest_submissions_page(contest_id, mid)
        if submissions_mid.map{|sub| next sub[1] }.max >= iStartTime
            right = mid
        else
            left = mid
        end
    end
    return right
end

# 指定日時より前の提出が含まれる最後のページを求める
def search_end_page_binary(contest_id = 245, iEndTime = 946652400) # Time.parse('2000-01-01 00:00:00').to_i
    left = 1
    right = get_contest_submissions_page_count(contest_id)

    puts "get page #{left}"
    submissions_left = get_contest_submissions_page(contest_id, left)
    if submissions_left.map{|sub| next sub[1] }.min >= iEndTime
        return -1 # 指定日時より前の提出が存在しない
    end
    puts "get page #{right}"
    submissions_right = get_contest_submissions_page(contest_id, right)
    if submissions_right.map{|sub| next sub[1] }.min < iEndTime
        return right
    end

    # 以降，left=ok, right=ng
    while left + 1 < right
        mid = (left + right) / 2
        puts "get page #{mid}"
        submissions_mid = get_contest_submissions_page(contest_id, mid)
        if submissions_mid.map{|sub| next sub[1] }.min < iEndTime
            left = mid
        else
            right = mid
        end
    end
    return left
end


if __FILE__ == $0
    # p search_start_page_binary(245, 1575738737)
    p search_end_page_binary(245, 1576594800) # Time.parse('2019-12-18 00:00:00').to_i
    # get_contest_submissions_page(245, 123)
end