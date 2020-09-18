from calc_difficulty import get_data, estimate, fix_float
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

        inner_rating, solved = get_data(problem_id)
        if len(solved) < 2:
            print(f" -> data size is too small ({len(solved)}) 🥺")
            continue
        if np.unique(solved).size != 2:
            print(f" -> data is uniform ({solved[0]}) 🥺")
            continue

        coef, bias = estimate(inner_rating, solved)
        if coef < 0:
            print(f" -> coef is weird ({coef}) 🥺")
            continue

        diff = -bias / coef
        diff = int(fix_float(diff))
        print(f" -> difficulty = {diff} 🐶")
        difficulties[problem_id] = diff

        obj = {"coef": coef, "bias": bias, "difficulty": diff, "inner_rating": inner_rating, "solved": solved}

        with open(f"json/detail/{problem_id}.json", 'w') as f:
            json.dump(obj, f)

    with open(f"json/summary.json", 'w') as f:
        json.dump(difficulties, f)


if __name__ == "__main__":
    main()
