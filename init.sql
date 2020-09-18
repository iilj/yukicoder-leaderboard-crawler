CREATE TABLE IF NOT EXISTS Contests (
    contest_id INTEGER PRIMARY KEY,
    name TEXT,
    datetime integer,
    crawled INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS Problems (
    problem_id INTEGER PRIMARY KEY,
    problem_no INTEGER UNIQUE,
    title TEXT,
    author_id INTEGER,
    tester_id INTEGER,
    level INTEGER
);

CREATE TABLE IF NOT EXISTS ContestProblemMap (
    contest_id INTEGER,
    problem_id INTEGER,
    PRIMARY KEY(contest_id, problem_id)
);

CREATE TABLE IF NOT EXISTS Users (
    user_id INTEGER PRIMARY KEY,
    name TEXT,
    twitter_screen_name TEXT,
    crawled INTEGER DEFAULT 0,
    url TEXT,
    mapping_calculated INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS UserContestProblemResults (
    user_id INTEGER,
    problem_id INTEGER,
    solved INTEGER,
    PRIMARY KEY(user_id, problem_id)
);

CREATE TABLE IF NOT EXISTS AtCoderUser (
    user_name TEXT PRIMARY KEY,
    twitter_screen_name TEXT,
    datetime_history_last_crawled INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS yukicoderAtCoderUserMap (
    yukicoder_user_id INTEGER,
    atcoder_user_name TEXT,
    PRIMARY KEY(yukicoder_user_id, atcoder_user_name)
);

CREATE TABLE IF NOT EXISTS AtCoderUserRatingHistory (
    user_name TEXT,
    datetime INTEGER,
    performance INTEGER,
    inner_performance INTEGER,
    rating INTEGER,
    inner_rating REAL,
    PRIMARY KEY(user_name, datetime)
);