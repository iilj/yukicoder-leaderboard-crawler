from calc_difficulty import get_data, estimate, fix_float, fit_2plm_irt
import sqlite3
import numpy as np
import json


def main():
    conn = sqlite3.connect("db.db")
    sql = 'SELECT DISTINCT problem_id FROM UserContestProblemResults'
    problem_ids = [row[0] for row in conn.execute(sql)]
    conn.close()

    difficulties: dict = {}
    for problem_id in problem_ids:
        print(f"Problem id = {problem_id}")

        inner_rating, solved, user_id, atcoder_user_name = get_data(problem_id)
        if len(solved) < 1:
            print(f" -> data size is too small ({len(solved)}) 🥺")
            continue
        # if np.unique(solved).size != 2:
        #     print(f" -> data is uniform ({solved[0]}) 🥺")
        #     continue

        # coef, bias = estimate(inner_rating, solved)
        # if coef < 0:
        #     print(f" -> coef is weird ({coef}) 🥺")
        #     continue

        # diff = -bias / coef
        # diff = int(fix_float(diff))

        inner_rating = [x[0] for x in inner_rating]
        diff, discrimination = fit_2plm_irt(inner_rating, solved)
        coef = discrimination
        bias = -coef * diff

        print(f" -> difficulty = {diff} 🐶")
        difficulties[problem_id] = diff

        detail = [{
            "inner_rating": _inner_rating,
            "solved": _solved,
            "user_id": _user_id,
            "atcoder_user_name": _atcoder_user_name
        } for _inner_rating, _solved, _user_id, _atcoder_user_name in zip(inner_rating, solved, user_id, atcoder_user_name)]
        obj = {
            "coef": coef,
            "bias": bias,
            "difficulty": diff,
            "detail": detail
        }

        with open(f"json/detail/{problem_id}.json", 'w') as f:
            json.dump(obj, f)

    with open(f"json/summary.json", 'w') as f:
        json.dump(difficulties, f)


if __name__ == "__main__":
    main()
