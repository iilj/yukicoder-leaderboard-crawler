require_relative './modules/contest_submissions'
require 'sqlite3'
require 'optparse'

def main_crawl_contest_submissions(db, contest_id)
    # コンテストの開始・終了日時を取得する
    sql = 'SELECT datetime, datetime_end FROM Contests WHERE contest_id = ?'
    datetime_list = db.execute(sql, contest_id)
    if datetime_list.length == 0
        puts "yukicoder contest contest_id=#{contest_id} does not exist!"
        return
    end
    datetime = datetime_list[0][0]
    datetime_end = datetime_list[0][1]
    puts "date: [#{datetime}, #{datetime_end})"

    # コンテスト提出で手持ちの最新を取得する
    sql = 'SELECT MAX(datetime) FROM Submissions WHERE problem_no IN (' \
        + '    SELECT A.problem_no FROM Problems AS A ' \
        + '    INNER JOIN ContestProblemMap AS B ON A.problem_id = B.problem_id ' \
        + '    WHERE B.contest_id = ?' \
        + ')'
    max_datetime_list = db.execute(sql, contest_id)
    max_datetime = max_datetime_list[0][0] # nil or Integer
    puts "max_datetime = #{max_datetime}"
    if max_datetime != nil
        datetime = [datetime, max_datetime].max # 更新
        puts "date: [#{datetime}, #{datetime_end})"
    end

    page_start = search_start_page_binary(contest_id, datetime)
    if page_start == -1
        puts "start page not found"
        return
    end
    page_end = search_end_page_binary(contest_id, datetime_end)
    if page_end == -1
        puts "end page not found"
        return
    end
    puts "page: [#{page_start}, #{page_end}]"

    # get_contest_submissions_page
    for page in page_start..page_end
        puts "Processing page #{page}"
        cnt = 0
        # array of [iSubmissionId, iTime, iUserId, iProblemNo, sLabel]
        submissions_of_page = get_contest_submissions_page(contest_id, page)
        submissions_of_page.each {|submission|
            iSubmissionId, iTime, iUserId, iProblemNo, sLabel = submission
            if iTime < datetime
                next
            end
            if iTime > datetime_end
                break
            end
            sql = 'INSERT OR IGNORE INTO Submissions(submission_id, datetime, user_id, problem_no, label) VALUES(?,?,?,?,?)'
            db.execute(sql, iSubmissionId, iTime, iUserId, iProblemNo, sLabel)
            cnt += 1
        }
        puts "Inserted #{cnt} lines"
        # break
    end
end

if __FILE__ == $0
    db = SQLite3::Database.new("db.db")

    opt = OptionParser.new
    opt.on('-c', '--contest_id CONTESTID', 'crawl submissions of specified CONTESTID') {|v|
        contest_id = v.to_i
        puts "contest_id = #{contest_id}"
        # main_crawl_contest_submissions(db, 245)
        main_crawl_contest_submissions(db, contest_id)
    }
    opt.parse(ARGV)
end