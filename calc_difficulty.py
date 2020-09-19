from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
import sqlite3
import sys


def get_data(problem_id: int = 5075) -> (list, list, list):
    conn = sqlite3.connect("db.db")
    sql = 'SELECT C.inner_rating, A.solved, A.user_id, B.atcoder_user_name FROM UserContestProblemResults AS A ' \
        + 'INNER JOIN yukicoderAtCoderUserMap AS B ON A.user_id = B.yukicoder_user_id ' \
        + 'INNER JOIN AtCoderUserRatingHistory AS C ON C.user_name = B.atcoder_user_name ' \
        + 'WHERE A.problem_id = ? AND C.datetime = (' \
        + '    SELECT MAX(datetime) FROM AtCoderUserRatingHistory AS D ' \
        + '    WHERE C.user_name = D.user_name AND D.datetime < (' \
        + '        SELECT F.datetime FROM ContestProblemMap AS E ' \
        + '        INNER JOIN Contests AS F ON E.contest_id = F.contest_id ' \
        + '        WHERE E.problem_id = ? ' \
        + '    ) ' \
        + ') ' \
        + 'ORDER BY C.inner_rating'
    inner_rating = []
    solved = []
    user_id = []
    atcoder_user_name = []
    for row in conn.execute(sql, (problem_id, problem_id)):
        # print(row)
        inner_rating.append([row[0]])
        solved.append(row[1])
        user_id.append(row[2])
        atcoder_user_name.append(row[3])
    conn.close()
    return (inner_rating, solved, user_id, atcoder_user_name)


def estimate(inner_rating: list, solved: list):
    # append dummy data
    sz = len(solved)
    # inf = 100000.0
    x = []
    y = []
    for i in range(sz):
        x.append(inner_rating[i])
        # x.append([-inf])
        # x.append([inf])
        y.append(solved[i])
        # y.append(0)
        # y.append(1)

    # fitting
    lr = LogisticRegression()
    lr.fit(x, y)

    coef = lr.coef_[0][0]
    bias = lr.intercept_[0]
    # diff = -bias / coef

    return coef, bias


def fix_float(rating):
    if rating < 400:
        return 400.0 / np.exp((400 - rating) / 400)
    return rating


def plot(inner_rating, solved, coef, bias):
    diff = -bias / coef

    mi = np.min([diff, np.min(inner_rating)])
    ma = np.max([diff, np.max(inner_rating)])
    x = np.arange(mi, ma + 1)

    solved_prob = np.dot(x, coef) + bias
    solved_prob = 1 / (1 + np.exp(-solved_prob))  # expit(x) = 1/(1+exp(-x))

    np_fix = np.frompyfunc(fix_float, 1, 1)

    diff = fix_float(diff)
    x = np_fix(x)
    inner_rating = np_fix(inner_rating)

    print("coefficient = ", coef)
    print("intercept = ", bias)
    print("difficulty = ", diff)

    fig = plt.figure()
    ax = fig.add_subplot(111)
    ax.plot(x, solved_prob)
    ax.scatter(inner_rating, solved, s=10, c="red", alpha=0.3)

    ax.axhline(0.5, ls="-.", color="magenta")
    ax.axvline(diff, ls="-.", color="navy")

    # ax.xaxis.set_major_locator(mpl.ticker.MultipleLocator(400))
    # ax.yaxis.set_minor_locator(mpl.ticker.MultipleLocator(0.1))

    plt.grid(b=True, which='major', color='#666666', linestyle='dotted')
    plt.show()


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print('usage: $ python calc_difficulty.py problem_id')
        exit()

    problem_id = int(sys.argv[1])
    inner_rating, solved, user_id, atcoder_user_name = get_data(problem_id)

    # print raw data
    print("Raw data:")
    for _inner_rating, _solved, _user_id, _atcoder_user_name in zip(inner_rating, solved, user_id, atcoder_user_name):
        print(_inner_rating, _solved, _user_id, _atcoder_user_name)
    print(f" (size = {len(solved)})")
    print("")

    if len(solved) < 2:
        print(f"data size is too small ({len(solved)})")
        exit()
    if np.unique(solved).size != 2:
        print(f"data is uniform ({solved[0]})")
        exit()
    coef, bias = estimate(inner_rating, solved)
    if coef < 0:
        print(f"coef is weird ({coef})")
        exit()
    plot(inner_rating, solved, coef, bias)
