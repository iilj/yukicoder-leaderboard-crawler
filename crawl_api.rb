require_relative './modules/api'
require 'sqlite3'
require 'time'

def insert_problems(db)
    problems = get_problems()
    problems.each{|problem|
        # {
        #   "No"=>1228, "ProblemId"=>4613, "Title"=>"I hate XOR Matching", "AuthorId"=>7584, "TesterId"=>10424,
        #   "Level"=>3.5, "ProblemType"=>0, "Tags"=>"構築,排他的論理和,掃き出し法", "Date"=>"2020-09-11T21:20:00+09:00",
        #   "Statistics"=>{
        #     "Total"=>0, "Solved"=>0, "FirstAcceptedTimeSecond"=>0, "FirstACSubmissionId"=>0,
        #     "ShortCodeSubmissionId"=>0, "PureShortCodeSubmissionId"=>0, "FastSubmissionId"=>0
        #   }
        # }
        sql = 'INSERT OR IGNORE INTO Problems(problem_id, problem_no, title, author_id, tester_id, level) VALUES(?,?,?,?,?,?)'
        db.execute(sql, problem['ProblemId'], problem['No'], problem['Title'], problem['AuthorId'], problem['TesterId'], problem['Level'])
    }
end

def insert_contests(db)
    contests = get_contests()
    contests.each{|contest|
        # {
        #   "Id"=>280, "Name"=>"yukicoder contest 265", "Date"=>"2020-09-11T21:20:00+09:00", "EndDate"=>"2020-09-11T23:20:00+09:00",
        #   "ProblemIdList"=>[4856, 4612, 4833, 5075, 4455, 4613]
        # }
        sql = 'INSERT OR IGNORE INTO Contests(contest_id, name, datetime) VALUES(?,?,?)'
        db.execute(sql, contest['Id'], contest['Name'], Time.parse(contest['Date']).to_i)

        contest['ProblemIdList'].each{|problem_id|
            sql = 'INSERT OR IGNORE INTO ContestProblemMap(contest_id, problem_id) VALUES(?,?)'
            db.execute(sql, contest['Id'], problem_id)
        }
    }
end

if __FILE__ == $0
    db = SQLite3::Database.new("db.db")
    puts "# insert problems"
    insert_problems(db)
    puts "# insert contests"
    insert_contests(db)
end