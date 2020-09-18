require_relative './modules/userpage'
require 'sqlite3'

def insert_userpage(db, user_id)
    user_name, twitter, url  = get_userpage(user_id)
    # user_name は捨てる

    sql = 'UPDATE Users SET twitter_screen_name = ?, url = ?, crawled = 1 WHERE user_id = ?'
    db.execute(sql, twitter, url, user_id)
end

def main_crawl_userpage(db)
    sql = 'SELECT user_id FROM Users WHERE crawled = 0'
    users = db.execute(sql).flatten

    sec = 10
    users.each_with_index{|user_id, idx|
        rem = sec * (users.length - 1 - idx) / 60
        puts "processing user #{user_id} (index #{idx} / #{users.length}, #{rem} minutes remaining)..."
        insert_userpage(db, user_id)
        if idx < users.length - 1
            puts "sleeping for #{sec} sec..."
            sleep sec
        end
    }
end

if __FILE__ == $0
    db = SQLite3::Database.new("db.db")
    main_crawl_userpage(db)
end