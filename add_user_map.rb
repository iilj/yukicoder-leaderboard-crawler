require_relative './modules/atcoder_user'
require 'optparse'
require 'sqlite3'

def main_show_list(db)
    sql = 'SELECT A.user_id, A.name FROM Users AS A' \
        + ' WHERE A.mapping_calculated = 1' \
        + ' AND NOT EXISTS (' \
        + '     SELECT yukicoder_user_id FROM yukicoderAtCoderUserMap AS B' \
        + '     WHERE A.user_id = B.yukicoder_user_id)'
    user_names = db.execute(sql)
    user_names.each_with_index{|user, idx|
        yukicoder_user_id, yukicoder_user_name = user
        puts "##{idx} id=#{yukicoder_user_id} name=#{yukicoder_user_name}"
    }
end

def main_add_atcoder_user(db, yukicoder_user_id, atcoder_user_name)
    # 存在しない yukicoder ユーザ名を弾く
    sql = 'SELECT user_id FROM Users WHERE user_id = ?'
    user_names = db.execute(sql, yukicoder_user_id).flatten
    if user_names.length == 0
        puts "yukicoder user #{yukicoder_user_id} does not exist!"
        return
    end
    
    # マッピングが既に存在する場合を弾く（選択）
    sql = 'SELECT yukicoder_user_id, atcoder_user_name FROM yukicoderAtCoderUserMap' \
        + ' WHERE yukicoder_user_id = ? OR atcoder_user_name = ?'
    user_names = db.execute(sql, yukicoder_user_id, atcoder_user_name)
    if user_names.length > 0
        puts "Mapping already exists!"
        p user_names
        puts "Force to insert? [y/n]"
        if /^[yY]/ === STDIN.gets.chomp
            puts "continue."
        else
            return
        end
    end

    # 存在しない AtCoder ユーザを弾く
    if !atcoder_user_exists?(atcoder_user_name)
        puts "AtCoder user #{atcoder_user_name} does not exist!"
        return
    end

    # マッピングを追加する
    sql = 'INSERT OR IGNORE INTO AtCoderUser(user_name) VALUES(?)'
    db.execute(sql, atcoder_user_name)
    sql = 'INSERT OR IGNORE INTO yukicoderAtCoderUserMap(yukicoder_user_id, atcoder_user_name) VALUES(?,?)'
    db.execute(sql, yukicoder_user_id, atcoder_user_name)

    puts "Added yukicoder_user_id=#{yukicoder_user_id}, atcoder_user_name=#{atcoder_user_name}"
end


if __FILE__ == $0
    db = SQLite3::Database.new("db.db")

    opt = OptionParser.new
    opt.on('-l', '--list', 'show user list who are not mapped') {
        main_show_list(db)
    }
    opt.on('-a v', '--add v', 'add user mapping') { |v|
        yukicoder_user_id, atcoder_user_name = v.split(',')
        yukicoder_user_id = yukicoder_user_id.to_i
        main_add_atcoder_user(db, yukicoder_user_id, atcoder_user_name)
    }
    opt.parse(ARGV)
end