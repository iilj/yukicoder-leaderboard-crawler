from calc_difficulty import get_data, estimate, fix_float, fit_2plm_irt
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
import sqlite3
import sys
from typing import List, Tuple, Dict
import copy
import json
import os


def augment_data(inner_rating_flatten: List[float], solved: List[bool]) -> Tuple[List[List[float]], List[float], List[bool]]:
    # .sort()
    ls = list(zip(inner_rating_flatten, solved))
    ls.sort(key=lambda x: x[0])
    left = ls[0][0]
    right = ls[-1][0]
    dx = (right - left) / (len(ls) - 1)
    len_low = len(ls) // 2
    len_high = len(ls) - len_low
    # print(ls, left, right, dx, len_low, len_high)
    for i in range(len_low):
        ls.append((left - dx * (i + 1), False))
    for i in range(len_high):
        ls.append((right + dx * (i + 1), True))
    ret_inner_rating = []
    ret_inner_rating_flatten = []
    ret_solved = []
    for _rating, _solved in ls:
        ret_inner_rating.append([_rating])
        ret_inner_rating_flatten.append(_rating)
        ret_solved.append(_solved)

    return ret_inner_rating, ret_inner_rating_flatten, ret_solved


ERROR_COEF_IS_WEIRD = -1
ERROR_DIFF_NOT_OPTIMAL = -2
ERROR_DIFF_INF = -3
ERROR_DATA_TOO_FEW = -4


def calc_coef_bias(inner_rating: List[List[float]], inner_rating_flatten: List[float], solved: List[bool]) -> Tuple[float, float, float]:
    # coef, bias = estimate(inner_rating, solved)
    # if coef < 0:
    #     print(f" -> coef is weird ({coef}) 🥺")
    #     return ERROR_COEF_IS_WEIRD, -1, -1

    # diff = -bias / coef
    # diff = int(fix_float(diff))

    inner_rating = [x[0] for x in inner_rating]
    diff, discrimination = fit_2plm_irt(inner_rating, solved)
    coef = discrimination
    bias = -coef * diff
    diff = int(fix_float(diff))

    mi = min(inner_rating_flatten)
    # print(diff, mi)
    if diff + 200 < mi:
        print(f" -> difficulty seems not optimal ({diff}) 🥺")
        return ERROR_DIFF_NOT_OPTIMAL, -1, -1
    print(f" -> difficulty = {diff} 🐶")
    return diff, coef, bias


def calc_difficulty_from_submissions(conn, problem_no: int, datetime_end: int):
    sql = 'SELECT A.user_id, A.label, C.inner_rating, B.atcoder_user_name FROM Submissions AS A' \
        + ' INNER JOIN yukicoderAtCoderUserMap AS B ON A.user_id = B.yukicoder_user_id ' \
        + ' INNER JOIN AtCoderUserRatingHistory AS C ON C.user_name = B.atcoder_user_name' \
        + ' WHERE A.problem_no = ? AND A.datetime < ?' \
        + ' AND A.user_id NOT IN (' \
        + '     SELECT author_id FROM Problems WHERE problem_no = ?' \
        + ' )'\
        + ' AND A.user_id NOT IN (' \
        + '     SELECT tester_id FROM Problems WHERE problem_no = ?' \
        + ' )' \
        + ' AND C.datetime = (' \
        + '     SELECT MAX(datetime) FROM AtCoderUserRatingHistory AS D ' \
        + '     WHERE C.user_name = D.user_name AND D.datetime < ?' \
        + ' ) '

    submissions_dict = {}
    for row in conn.execute(sql, (problem_no, datetime_end, problem_no, problem_no, datetime_end)):
        # submissions.append(row) # A.user_id, A.label, C.inner_rating, B.atcoder_user_name
        if row[0] in submissions_dict:
            if submissions_dict[row[0]][1] != 'AC':
                submissions_dict[row[0]] = row  # 既にある行が AC でないなら上書きする
        else:
            submissions_dict[row[0]] = row
    # print(submissions_dict) # {90: (90, 'AC', 2666.8890295760307, 'kmjp'), 174: (174, 'AC', 3296.4126240352975, 'hos_lyric'), ... }

    inner_rating = []
    inner_rating_flatten = []
    solved = []
    user_id = []
    atcoder_user_name = []
    for submission in submissions_dict.values():
        inner_rating.append([submission[2]])
        inner_rating_flatten.append(submission[2])
        solved.append(submission[1] == 'AC')
        user_id.append(submission[0])
        atcoder_user_name.append(submission[3])
    # print(inner_rating, solved, user_id, atcoder_user_name)

    if len(solved) < 2:
        print(f"data size is too small ({len(solved)})")
        return ERROR_DATA_TOO_FEW, -1, -1, False, inner_rating_flatten, solved, user_id, atcoder_user_name
    if np.unique(solved).size != 2:
        print(f"data is uniform ({solved[0]})")
        if solved[0] == True:
            # 全員正解
            # ダミーデータ挿入
            print(" -> 🧪")
            aug_inner_rating, aug_inner_rating_flatten, aug_solved = augment_data(inner_rating_flatten, solved)
            diff, coef, bias = calc_coef_bias(aug_inner_rating, aug_inner_rating_flatten, aug_solved)
            augmented = True
        else:
            # 全員不正解
            return ERROR_DIFF_INF, -1, -1
    else:
        diff, coef, bias = calc_coef_bias(inner_rating, inner_rating_flatten, solved)
        augmented = False
        if diff == ERROR_COEF_IS_WEIRD or diff == ERROR_DIFF_NOT_OPTIMAL:
            # ダミーデータ挿入
            print(" -> 🧪")
            aug_inner_rating, aug_inner_rating_flatten, aug_solved = augment_data(inner_rating_flatten, solved)
            diff, coef, bias = calc_coef_bias(aug_inner_rating, aug_inner_rating_flatten, aug_solved)
            augmented = True

    # augmented = True
    return diff, coef, bias, augmented, inner_rating_flatten, solved, user_id, atcoder_user_name


# 提出情報から計算する
def main_calc_contest_diff(conn, contest_id: int, difficulties: Dict[int, Tuple[int, float, float, bool]]):
    # コンテスト問題一覧取得
    sql = 'SELECT A.problem_id, A.problem_no FROM Problems AS A' \
        + ' INNER JOIN ContestProblemMap AS B ON A.problem_id = B.problem_id' \
        + ' WHERE B.contest_id = ?' \
        + ' ORDER BY A.problem_no ASC'
    problems = []
    for row in conn.execute(sql, (contest_id,)):
        problems.append(row)  # row = (problem_id, problem_no)

    # コンテスト開催日時を取得
    sql = 'SELECT datetime FROM Contests WHERE contest_id = ?'
    row_datetime = conn.execute(sql, (contest_id,)).fetchone()
    if row is None:
        print("datetime is unknown")
        return
    datetime: int = row_datetime[0]  # コンテスト開始日時
    print(datetime)

    # 問題ごとの出題終了期間を計算（問題 No 順と出題順は等しいと仮定する）
    sec_of_hour = 60 * 60
    datetime_end_first = datetime + (sec_of_hour * 23 + 60 * 30)
    datetime_end_list = [datetime_end_first + (sec_of_hour * 24 * i) for i in range(len(problems))]
    print(datetime_end_list)

    # 問題ごとに，author/tester 以外の期間内提出を取得
    for i, problem in enumerate(problems):
        problem_id = problem[0]
        problem_no = problem[1]
        datetime_end = datetime_end_list[i]
        print(f"i={i}, problem_no={problem_no}")

        # json があったら消す
        fn_json = f"json/detail/{problem_id}.json"
        if os.path.isfile(fn_json):
            os.remove(fn_json)

        # summary に載っていたら消す
        if problem_id in difficulties:
            del difficulties[problem_id]

        diff, coef, bias, augmented, inner_rating_flatten, solved, user_id, atcoder_user_name = calc_difficulty_from_submissions(
            conn, problem_no, datetime_end)
        if diff < 0:
            print(" -> ERROR")
            continue
        #
        detail = [{
            "inner_rating": _inner_rating,
            "solved": _solved,
            "user_id": _user_id,
            "atcoder_user_name": _atcoder_user_name
        } for _inner_rating, _solved, _user_id, _atcoder_user_name in zip(inner_rating_flatten, solved, user_id, atcoder_user_name)]
        obj = {
            "difficulty": diff,
            "coef": coef,
            "bias": bias,
            "augmented": augmented,
            "detail": detail
        }

        # summary への登録
        difficulties[problem_id] = (diff, coef, bias, augmented)

        # 個別 json の保存
        with open(fn_json, 'w') as f:
            json.dump(obj, f)


# 順位表情報からデータを作る
def main_from_leaderboard(conn):
    sql = 'SELECT DISTINCT problem_id FROM UserContestProblemResults'
    problem_ids = [row[0] for row in conn.execute(sql)]

    difficulties: Dict[int, Tuple[int, float, float, bool]] = {}
    for problem_id in problem_ids:
        print(f"Problem id = {problem_id}")

        # 古い json があったら消す
        fn_json = f"json/detail/{problem_id}.json"
        if os.path.isfile(fn_json):
            os.remove(fn_json)

        inner_rating, solved, user_id, atcoder_user_name = get_data(problem_id)
        inner_rating_flatten = [x[0] for x in inner_rating]
        if len(solved) < 2:
            print(f" -> data size is too small ({len(solved)}) 🥺")
            continue
        if np.unique(solved).size != 2:
            print(f" -> data is uniform ({solved[0]}) 🥺")
            if solved[0] == True:
                # 全員正解
                # ダミーデータ挿入
                print(" -> 🧪")
                aug_inner_rating, aug_inner_rating_flatten, aug_solved = augment_data(inner_rating_flatten, solved)
                diff, coef, bias = calc_coef_bias(aug_inner_rating, aug_inner_rating_flatten, aug_solved)
                augmented = True
            else:
                # 全員不正解
                continue
        else:
            # coef, bias = estimate(inner_rating, solved)
            augmented = False
            # if coef < 0:
            #     print(f" -> coef is weird ({coef}) 🥺")
            #     # ダミーデータ挿入
            #     print(" -> 🧪")
            #     aug_inner_rating, aug_inner_rating_flatten, aug_solved = augment_data(inner_rating_flatten, solved)
            #     diff, coef, bias = calc_coef_bias(aug_inner_rating, aug_inner_rating_flatten, aug_solved)
            #     augmented = True
            #     continue
            inner_rating = [x[0] for x in inner_rating]
            diff, discrimination = fit_2plm_irt(inner_rating, solved)
            coef = discrimination
            bias = -coef * diff
            diff = int(fix_float(diff))

        # diff = -bias / coef
        # diff = int(fix_float(diff))
        print(f" -> difficulty = {diff} 🐶")
        difficulties[problem_id] = (diff, coef, bias, augmented)

        detail = [{
            "inner_rating": _inner_rating,
            "solved": _solved,
            "user_id": _user_id,
            "atcoder_user_name": _atcoder_user_name
        } for _inner_rating, _solved, _user_id, _atcoder_user_name in zip(inner_rating_flatten, solved, user_id, atcoder_user_name)]
        obj = {
            "difficulty": diff,
            "coef": coef,
            "bias": bias,
            "augmented": augmented,
            "detail": detail
        }

        with open(fn_json, 'w') as f:
            json.dump(obj, f)

    # with open(f"json/summary.json", 'w') as f:
    #     json.dump(difficulties, f)
    return difficulties


def main():
    contest_id_list = [
        300,  # Advent Calendar Contest 2020
        245,  # Advent Calendar Contest 2019
        211,  # Advent Calendar Contest 2018
        182,  # Advent Calendar Contest 2017
        156,  # Advent Calendar Contest 2016
        127,  # Advent Calendar Contest 2015
    ]

    conn = sqlite3.connect("db.db")
    print("🔷 calc from leaderboard")
    difficulties: Dict[int, Tuple[int, float, float, bool]] = main_from_leaderboard(conn)

    print("🔷 calc from submissions")
    for contest_id in contest_id_list:
        print(f"🔷🔷 submissions: contest_id = {contest_id}")
        main_calc_contest_diff(conn, contest_id, difficulties)

    with open(f"json/summary_v2.json", 'w') as f:
        json.dump(difficulties, f)

    conn.close()


if __name__ == "__main__":
    main()
