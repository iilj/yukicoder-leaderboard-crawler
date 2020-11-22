require_relative './modules/atcoder_user'
require 'sqlite3'

def try_map_user(user_id, name, twitter_screen_name, url, atcoder_user_name)
    re = /https?:\/\/atcoder\.jp\/users\/([a-zA-Z0-9_]+)/
    re_name = /^([a-zA-Z0-9_]+)$/
    sec = 5

    # atcoder_user_name = nil
    iRequestFlag = 0

    # url に書いてくれてあるとき
    if atcoder_user_name == nil && url != nil
        m = re.match(url)
        if m
            atcoder_user_name = m[1]
            puts " -> source: URL 🌏"
        end
    end

    # Unofficial API + twitter screen name 経由で
    if atcoder_user_name == nil && twitter_screen_name != nil
        # AtCoder ユーザと結び付けられたらOK
        data = atcoder_unofficial_api_from_twitter(twitter_screen_name)["data"]
        if data != nil && data["username"] != nil
            atcoder_user_name = data["username"]
            puts " -> source: Unofficial API 😺"
        end
        iRequestFlag |= 1
    end

    # yukicoder と同一ユーザ名
    if atcoder_user_name == nil
        if re_name.match(name) # ascii ユーザ名の場合
            if atcoder_user_exists?(name) # 存在するかどうか確かめたい
                atcoder_user_name = name
                puts " -> source: name 📛"
            end
            iRequestFlag |= 2
        end  
    end

    # twitter と同一ユーザ名
    if atcoder_user_name == nil && twitter_screen_name != nil
        if iRequestFlag & 2 > 0
            sleep sec
        end
        if atcoder_user_exists?(twitter_screen_name) # 存在するかどうか確かめたい
            atcoder_user_name = twitter_screen_name
            puts " -> source: twitter_screen_name 🐦"
        end
        iRequestFlag |= 4
    end

    return atcoder_user_name, iRequestFlag
end

def main_crawl_atcoder_user(db)
    sql = 'SELECT user_id, name, twitter_screen_name, atcoder_user_name, url FROM Users WHERE crawled = 1 and mapping_calculated = 0'
    users = db.execute(sql)
    
    sec = 5
    users.each_with_index{|user, idx|
        user_id, name, twitter_screen_name, atcoder_user_name, url = user

        rem = sec * (users.length - 1 - idx) / 60
        rem_h = rem / 60
        rem_m = (rem - rem_h * 60).to_s.rjust(2, "0")
        puts "processing user #{name} (#{user_id}) (index #{idx} / #{users.length}, approx. #{rem_h}:#{rem_m} remaining)..."
        
        atcoder_user_name, iRequestFlag = try_map_user(user_id, name, twitter_screen_name, url, atcoder_user_name)

        # マッピング登録
        if atcoder_user_name != nil
            puts " -> yukicoder[#{name} (#{user_id})] -> AtCoder[#{atcoder_user_name}]"
            sql = 'INSERT OR IGNORE INTO AtCoderUser(user_name, twitter_screen_name) VALUES(?,?)'
            db.execute(sql, atcoder_user_name, twitter_screen_name)
            sql = 'INSERT OR IGNORE INTO yukicoderAtCoderUserMap(yukicoder_user_id, atcoder_user_name) VALUES(?,?)'
            db.execute(sql, user_id, atcoder_user_name)
        else
            puts " -> yukicoder[#{name} (#{user_id})] -> mapping not found 🥺"
        end

        # 計算済みフラグを立てる
        sql = 'UPDATE Users SET mapping_calculated = 1 WHERE user_id = ?'
        db.execute(sql, user_id)

        # break
        if iRequestFlag > 0 && idx < users.length - 1
            puts " -> sleeping for #{sec} sec..."
            sleep sec
        end
    }
end

# 仮：プロフィール情報を使ってアップデートする
def main_map_from_yukicoder_profile(db)
    sql = 'SELECT user_id, name, twitter_screen_name, atcoder_user_name, url FROM Users WHERE crawled = 1' #  and mapping_calculated = 0
    users = db.execute(sql)
    users.each_with_index{|user, idx|
        user_id, name, twitter_screen_name, atcoder_user_name, url = user
        if atcoder_user_name != nil
            puts "#{user_id}: #{name} -> #{atcoder_user_name}"
            sql = 'SELECT atcoder_user_name FROM yukicoderAtCoderUserMap WHERE yukicoder_user_id = ?'
            atcoder_user_name_db = db.execute(sql, user_id)
            if atcoder_user_name_db.length == 0
                puts " -> Not registered" # 新たに挿入すればよい
                sql = 'INSERT OR IGNORE INTO AtCoderUser(user_name, twitter_screen_name) VALUES(?,?)'
                db.execute(sql, atcoder_user_name, twitter_screen_name)
                sql = 'INSERT OR IGNORE INTO yukicoderAtCoderUserMap(yukicoder_user_id, atcoder_user_name) VALUES(?,?)'
                db.execute(sql, user_id, atcoder_user_name)
            elsif atcoder_user_name_db[0][0].downcase == atcoder_user_name.downcase
                puts " -> OK" # 何もしなくてよい
            else
                puts " -> Bad (profile=#{atcoder_user_name}, db=#{atcoder_user_name_db[0][0]})" # atcoder_user_name のほうで上書き
                sql = 'INSERT OR IGNORE INTO AtCoderUser(user_name, twitter_screen_name) VALUES(?,?)'
                db.execute(sql, atcoder_user_name, twitter_screen_name)
                sql = 'UPDATE yukicoderAtCoderUserMap SET atcoder_user_name = ? WHERE yukicoder_user_id = ?'
                db.execute(sql, atcoder_user_name, user_id)
            end
        end
    }
end

if __FILE__ == $0
    db = SQLite3::Database.new("db.db")
    main_crawl_atcoder_user(db)
    # main_map_from_yukicoder_profile(db)
end