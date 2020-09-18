require_relative './modules/leaderboard'
require 'sqlite3'

def insert_contest_leaderboard(db, contest_id)
    sz, problemNumbers, prlblemTitles, userResults  = get_contest_leaderboard(contest_id)

    problemIds = problemNumbers.map{|problemNo|
        sql = 'SELECT problem_id FROM Problems WHERE problem_no = ?'
        next db.execute(sql, problemNo).flatten.first
    }
    
    userResults.each{|userResult|
        iRank, iUserId, sUserName, bIsWriter, solved = userResult
        if bIsWriter # writer 設定された人は飛ばす
            next
        end
        # ユーザの登録
        sql = 'INSERT OR IGNORE INTO Users(user_id, name) VALUES(?,?)'
        db.execute(sql, iUserId, sUserName)

        # コンテスト結果の登録
        problemIds.zip(solved).each{|result|
            problem_id, bSolved = result
            sql = 'INSERT OR IGNORE INTO UserContestProblemResults(user_id, problem_id, solved) VALUES(?,?,?)'
            db.execute(sql, iUserId, problem_id, bSolved && 1 || 0)
        }
    }

    sql = 'UPDATE Contests SET crawled = 1 WHERE contest_id = ?'
    db.execute(sql, contest_id)
end

def main_crawl_leaderboard(db)
    sql = 'SELECT contest_id FROM Contests WHERE crawled = 0'
    contests = db.execute(sql).flatten
    contests.each{|contest_id|
        puts "processing contest #{contest_id}..."
        insert_contest_leaderboard(db, contest_id)
        sleep 5
    }
end

if __FILE__ == $0
    db = SQLite3::Database.new("db.db")
    main_crawl_leaderboard(db)
end