yukicoder-leaderboard-crawler
=====

## 概要

- yukicoder の順位表をクロールして，適当に AtCoder のユーザとマッピングして difficulty を推定します．
- クローラは Ruby, ロジスティクス回帰の計算は Python で書いてあります．
- 雑な作りですが，テスト用なのでご勘弁を．

## Difficulty 推定手法

- x=[AtCoder 内部レーティング]，y=時間内に解けたか, の組に対して，ロジスティクス回帰を流します．
- 時間内に解ける確率 = 0.5 となる AtCoder 内部レーティングの値が Difficulty です．
  - AtCoder Problems と概ね同様の手法です．
- 様々な理由により，推定値をあまり信用しないほうがよいと考えられます．主に以下の理由によります．
  - データが少ない
    - コンテスト出場者数は AtCoder に比べて少ない
    - 出場者のうち，AtCoder ユーザとマッピングの取れないユーザもいるため，その分だけデータが減る
  - 各データの精度が低い
    - AtCoder ユーザとのマッピングは機械的に求めているため，正しいことは保証されていない
  - 出場者がレートに見合った実力を発揮していない場合があり，Difficulty 値が高く出る傾向にある
    - 低レート者は，序盤に WA を出して早々に撤退してしまうことがある
    - 高レート保持者は，自身が解きたい問題のみを解き，その他の問題を放置することがある


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

#### 代替手段：手動でマッピングする

```sh
$ ruby add_user_map.rb -l            # マッピングが設定されていないユーザ一覧
$ ruby add_user_map.rb -a 1234,abcd  # yukicoder userid=1234, atcoder username=abcd のマップを登録
```

### yukicoder ユーザにマップされた AtCoder ユーザのコンテスト履歴のクロール

#### 全ユーザをクロールする場合

```sh
$ ruby crawl_atcoder_history.rb -a
```

#### min 分以上経っている人のみクロールする場合

例：1440分（=1日）以上経っている人のみクロールするとき

```sh
$ ruby crawl_atcoder_history.rb -m 1440
```

#### ある問題が出題されたコンテストに出た人のみクロールする版

例：問題ID 4455 の問題が出題されたコンテストに出た人のみクロールする版

```sh
$ ruby crawl_atcoder_history.rb -p 4455
```

### difficulty の計算結果出力

```sh
$ python calc_difficulty_gen.py
```

### 補足：単一の問題 ID を指定しての difficulty 推定結果確認

```sh
$ python calc_difficulty.py 1234
```