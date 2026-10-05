import os
import csv
import re
import time

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
SQL_FILE = os.path.join(BASE_DIR, 'db_init.sql')

def escape_sql(val):
    if val is None:
        return 'NULL'
    return "'" + str(val).replace("'", "''") + "'"

def generate_sql():
    start_time = time.time()
    
    with open(SQL_FILE, 'w', encoding='utf-8') as out:
        out.write("PRAGMA foreign_keys = OFF;\n")
        out.write("PRAGMA synchronous = OFF;\n")
        out.write("PRAGMA journal_mode = MEMORY;\n\n")

        out.write("DROP TABLE IF EXISTS movies;\n")
        out.write("CREATE TABLE movies (\n")
        out.write("    id INTEGER PRIMARY KEY,\n")
        out.write("    title TEXT NOT NULL,\n")
        out.write("    year INTEGER,\n")
        out.write("    genres TEXT\n")
        out.write(");\n\n")

        out.write("DROP TABLE IF EXISTS ratings;\n")
        out.write("CREATE TABLE ratings (\n")
        out.write("    id INTEGER PRIMARY KEY AUTOINCREMENT,\n")
        out.write("    user_id INTEGER NOT NULL,\n")
        out.write("    movie_id INTEGER NOT NULL,\n")
        out.write("    rating REAL NOT NULL,\n")
        out.write("    timestamp INTEGER NOT NULL\n")
        out.write(");\n\n")

        out.write("DROP TABLE IF EXISTS tags;\n")
        out.write("CREATE TABLE tags (\n")
        out.write("    id INTEGER PRIMARY KEY AUTOINCREMENT,\n")
        out.write("    user_id INTEGER NOT NULL,\n")
        out.write("    movie_id INTEGER NOT NULL,\n")
        out.write("    tag TEXT NOT NULL,\n")
        out.write("    timestamp INTEGER NOT NULL\n")
        out.write(");\n\n")

        out.write("DROP TABLE IF EXISTS users;\n")
        out.write("CREATE TABLE users (\n")
        out.write("    id INTEGER PRIMARY KEY,\n")
        out.write("    name TEXT NOT NULL,\n")
        out.write("    email TEXT NOT NULL,\n")
        out.write("    gender TEXT,\n")
        out.write("    register_date TEXT,\n")
        out.write("    occupation TEXT\n")
        out.write(");\n\n")

        out.write("BEGIN TRANSACTION;\n\n")

        movies_path = os.path.join(BASE_DIR, 'movies.csv')
        if os.path.exists(movies_path):
            with open(movies_path, 'r', encoding='utf-8') as f:
                reader = csv.reader(f)
                next(reader, None)
                batch = []
                for row in reader:
                    if not row or len(row) < 3:
                        continue
                    m_id = int(row[0])
                    full_title = row[1].strip()
                    genres = row[2].strip()
                    
                    year_match = re.search(r'\((\d{4})\)\s*$', full_title)
                    if year_match:
                        year = int(year_match.group(1))
                        title = re.sub(r'\s*\(\d{4}\)\s*$', '', full_title)
                    else:
                        year = 'NULL'
                        title = full_title
                    
                    batch.append(f"({m_id}, {escape_sql(title)}, {year}, {escape_sql(genres)})")
                    if len(batch) >= 500:
                        out.write("INSERT INTO movies (id, title, year, genres) VALUES\n" + ",\n".join(batch) + ";\n")
                        batch = []
                if batch:
                    out.write("INSERT INTO movies (id, title, year, genres) VALUES\n" + ",\n".join(batch) + ";\n")

        ratings_path = os.path.join(BASE_DIR, 'ratings.csv')
        if os.path.exists(ratings_path):
            with open(ratings_path, 'r', encoding='utf-8') as f:
                reader = csv.reader(f)
                next(reader, None)
                batch = []
                for row in reader:
                    if not row or len(row) < 4:
                        continue
                    u_id, m_id, rating, ts = row[0], row[1], row[2], row[3]
                    batch.append(f"({u_id}, {m_id}, {rating}, {ts})")
                    if len(batch) >= 1000:
                        out.write("INSERT INTO ratings (user_id, movie_id, rating, timestamp) VALUES\n" + ",\n".join(batch) + ";\n")
                        batch = []
                if batch:
                    out.write("INSERT INTO ratings (user_id, movie_id, rating, timestamp) VALUES\n" + ",\n".join(batch) + ";\n")

        tags_path = os.path.join(BASE_DIR, 'tags.csv')
        if os.path.exists(tags_path):
            with open(tags_path, 'r', encoding='utf-8') as f:
                reader = csv.reader(f)
                next(reader, None)
                batch = []
                for row in reader:
                    if not row or len(row) < 4:
                        continue
                    u_id, m_id, tag, ts = row[0], row[1], row[2], row[3]
                    batch.append(f"({u_id}, {m_id}, {escape_sql(tag)}, {ts})")
                    if len(batch) >= 1000:
                        out.write("INSERT INTO tags (user_id, movie_id, tag, timestamp) VALUES\n" + ",\n".join(batch) + ";\n")
                        batch = []
                if batch:
                    out.write("INSERT INTO tags (user_id, movie_id, tag, timestamp) VALUES\n" + ",\n".join(batch) + ";\n")

        users_path = os.path.join(BASE_DIR, 'users.csv')
        if not os.path.exists(users_path):
            users_path = os.path.join(BASE_DIR, 'users.txt')

        if os.path.exists(users_path):
            with open(users_path, 'r', encoding='utf-8') as f:
                sample = f.read(2048)
                f.seek(0)
                delimiter = '|' if '|' in sample else ','
                reader = csv.reader(f, delimiter=delimiter)
                next(reader, None)
                batch = []
                for row in reader:
                    if not row or len(row) < 6:
                        continue
                    u_id, name, email, gender, reg_date, occ = row[0], row[1], row[2], row[3], row[4], row[5]
                    batch.append(f"({u_id}, {escape_sql(name)}, {escape_sql(email)}, {escape_sql(gender)}, {escape_sql(reg_date)}, {escape_sql(occ)})")
                    if len(batch) >= 500:
                        out.write("INSERT INTO users (id, name, email, gender, register_date, occupation) VALUES\n" + ",\n".join(batch) + ";\n")
                        batch = []
                if batch:
                    out.write("INSERT INTO users (id, name, email, gender, register_date, occupation) VALUES\n" + ",\n".join(batch) + ";\n")

        out.write("\nCOMMIT;\n")

    print(f"db_init.sql успешно сгенерирован за {time.time() - start_time:.3f} сек.")

if __name__ == '__main__':
    generate_sql()
