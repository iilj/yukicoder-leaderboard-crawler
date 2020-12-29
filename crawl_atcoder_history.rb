require_relative './modules/atcoder_history'
require 'sqlite3'
require 'time'
require 'optparse'

def crawl_atcoder_history_by_user_list(db, users)
    sec = 10
    users.each_with_index{|atcoder_user_name, idx|
        rem = sec * (users.length - 1 - idx) / 60
        rem_h = rem / 60
        rem_m = (rem - rem_h * 60).to_s.rjust(2, "0")
        puts "processing user #{atcoder_user_name} (index #{idx} / #{users.length}, approx. #{rem_h}:#{rem_m} remaining)..."

        # 現在の最新レコードを取得する
        sql = 'SELECT MAX(datetime) FROM AtCoderUserRatingHistory WHERE user_name = ?'
        max_datetime = db.execute(sql, atcoder_user_name).flatten[0]
        if max_datetime == nil
            max_datetime = 0
        end

        # 履歴を取得する
        history = nil
        request_cnt = 0
        loop {
            begin
                request_cnt += 1
                history = atcoder_get_history_with_inner_rating(atcoder_user_name)
                puts " -> Request OK"
                break
            rescue => exception
                if request_cnt >= 3
                    10.times{ system "paplay /usr/share/sounds/freedesktop/stereo/dialog-error.oga" }
                    puts "Failed to get resource"
                    exit
                end
                3.times{ system "paplay /usr/share/sounds/freedesktop/stereo/dialog-error.oga" }
                puts "SLEEP 3, request_cnt=#{request_cnt}"
                sleep 3.0
            end
        }
        
        # 履歴を格納する
        cnt = 0
        history.each{|entry|
            datetime, perf, innerPerf, rating, innerRating = entry
            if datetime <= max_datetime
                next
            end
            sql = 'INSERT OR IGNORE INTO AtCoderUserRatingHistory' \
                + '(user_name, datetime, performance, inner_performance, rating, inner_rating) VALUES(?,?,?,?,?,?)'
            db.execute(sql, atcoder_user_name, datetime, perf, innerPerf, rating, innerRating)
            cnt += 1
        }
        puts " -> #{cnt} line(s) inserted"

        sql = 'UPDATE AtCoderUser SET datetime_history_last_crawled = ? WHERE user_name = ?'
        db.execute(sql, Time.now.to_i, atcoder_user_name)

        if idx < users.length - 1
            puts " -> sleeping for #{sec} sec..."
            sleep sec
        end
    }
    puts "crawl completed"
    5.times{ system "paplay /usr/share/sounds/freedesktop/stereo/complete.oga" }
end

# とりあえず全部クロールする版
def main_crawl_atcoder_history(db)
    sql = 'SELECT user_name FROM AtCoderUser'
    users = db.execute(sql).flatten
    crawl_atcoder_history_by_user_list(db, users)
end

# min 分以上経っている人のみクロールする版
def main_crawl_atcoder_history_min(db, min)
    cur = Time.now.to_i - 60 * min
    sql = 'SELECT user_name FROM AtCoderUser WHERE datetime_history_last_crawled < ?'
    users = db.execute(sql, cur).flatten
    crawl_atcoder_history_by_user_list(db, users)
end

# ある問題が出題されたコンテストに出た人のみクロールする版
def main_crawl_atcoder_history_contest(db, problem_id)
    # UserContestProblemResults に problem_id の記録があるユーザの yukicoder userid
    # -> そのユーザの atcoder_user_name，と辿る
    sql = 'SELECT atcoder_user_name FROM yukicoderAtCoderUserMap ' \
        + 'WHERE yukicoder_user_id IN (SELECT user_id FROM UserContestProblemResults WHERE problem_id = ?)'
    users = db.execute(sql, problem_id).flatten
    crawl_atcoder_history_by_user_list(db, users)
end

if __FILE__ == $0
    db = SQLite3::Database.new("db.db")

    opt = OptionParser.new
    opt.on('-p', '--problem_id PID', 'crawl records of whom has UserContestProblemResults of specified problem_id') {|v|
        problem_id = v.to_i
        puts "problem_id = #{problem_id}"
        # main_crawl_atcoder_history_contest(db, 4455)
        main_crawl_atcoder_history_contest(db, problem_id)
    }
    opt.on('-m', '--minutes MIN', 'crawl records of whom has no record in specified minutes') {|v|
        minutes = v.to_i
        puts "[minutes = #{minutes}]"
        # main_crawl_atcoder_history_min(db, 60 * 24 * 7)
        main_crawl_atcoder_history_min(db, minutes)
    }
    opt.on('-a', '--all', 'crawl all records') {
        puts "[all]"
        main_crawl_atcoder_history(db)
    }
    opt.parse(ARGV)
end