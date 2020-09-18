yukicoder-leaderboard-crawler
=====

## 概要

- yukicoder の順位表をクロールして，適当に AtCoder のユーザとマッピングして difficulty を推定します．
- クローラは Ruby, ロジスティクス回帰の計算は Python で書いてあります．
- 雑な作りですが，テスト用なのでご勘弁を．


## データベース構成

![db](https://github.com/iilj/yukicoder-leaderboard-crawler/blob/master/out/uml/db/db.png?raw=true)


## 使用方法

### 準備

```sh
$ gem install nokogiri
$ gem install sqlite3
```

### yukicoder コンテスト一覧情報の取得

```sh
$ ruby crawl_api.rb
```

### yukicoder 順位表のクロール

```sh
$ ruby crawl_leaderboard.rb
```

### yukicoder ユーザページのクロール

```sh
$ ruby crawl_userpage.rb
```

### AtCoder ユーザとのマッピング

```sh
$ ruby crawl_atcoder_user.rb
```

### yukicoder ユーザにマップされた AtCoder ユーザのコンテスト履歴のクロール

```sh
$ ruby crawl_atcoder_history.rb
```

### difficulty の計算結果出力

```sh
$ python calc_difficulty_gen.py
```
