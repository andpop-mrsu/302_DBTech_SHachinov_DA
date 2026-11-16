#!/bin/bash
chcp 65001 2>/dev/null || true

sqlite3 movies_rating.db < db_init.sql

echo "1. Для каждого фильма выведите его название, год выпуска и средний рейтинг. Дополнительно добавьте столбец rank_by_avg_rating, в котором укажите ранг фильма среди всех фильмов по убыванию среднего рейтинга (фильмы с одинаковым средним рейтингом должны получить одинаковый ранг). Используйте оконную функцию RANK() или DENSE_RANK(). В результирующем наборе данных оставить 10 фильмов с наибольшим рангом."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT m.title, m.year, ROUND(AVG(r.rating), 2) AS avg_rating, RANK() OVER (ORDER BY AVG(r.rating) DESC) AS rank_by_avg_rating FROM movies m JOIN ratings r ON m.id = r.movie_id GROUP BY m.id, m.title, m.year ORDER BY rank_by_avg_rating ASC, m.title ASC LIMIT 10;"
echo " "

echo "2. С помощью рекурсивного CTE выделить все жанры фильмов, имеющиеся в таблице movies. Для каждого жанра рассчитать средний рейтинг avg_rating фильмов в этом жанре. Выведите genre, avg_rating и ранг жанра по убыванию среднего рейтинга, используя оконную функцию RANK()."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split_genres(movie_id, genre, remaining) AS (SELECT id, CASE WHEN instr(genres, '|') > 0 THEN substr(genres, 1, instr(genres, '|') - 1) ELSE genres END, CASE WHEN instr(genres, '|') > 0 THEN substr(genres, instr(genres, '|') + 1) ELSE '' END FROM movies WHERE genres IS NOT NULL AND genres != '' AND genres != '(no genres listed)' UNION ALL SELECT movie_id, CASE WHEN instr(remaining, '|') > 0 THEN substr(remaining, 1, instr(remaining, '|') - 1) ELSE remaining END, CASE WHEN instr(remaining, '|') > 0 THEN substr(remaining, instr(remaining, '|') + 1) ELSE '' END FROM split_genres WHERE remaining != '') SELECT sg.genre, ROUND(AVG(r.rating), 2) AS avg_rating, RANK() OVER (ORDER BY AVG(r.rating) DESC) AS rank_by_avg_rating FROM split_genres sg JOIN ratings r ON sg.movie_id = r.movie_id GROUP BY sg.genre ORDER BY rank_by_avg_rating ASC;"
echo " "

echo "3. Посчитайте количество фильмов в каждом жанре. Выведите два столбца: genre и movie_count, отсортировав результат по убыванию количества фильмов."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split_genres(movie_id, genre, remaining) AS (SELECT id, CASE WHEN instr(genres, '|') > 0 THEN substr(genres, 1, instr(genres, '|') - 1) ELSE genres END, CASE WHEN instr(genres, '|') > 0 THEN substr(genres, instr(genres, '|') + 1) ELSE '' END FROM movies WHERE genres IS NOT NULL AND genres != '' AND genres != '(no genres listed)' UNION ALL SELECT movie_id, CASE WHEN instr(remaining, '|') > 0 THEN substr(remaining, 1, instr(remaining, '|') - 1) ELSE remaining END, CASE WHEN instr(remaining, '|') > 0 THEN substr(remaining, instr(remaining, '|') + 1) ELSE '' END FROM split_genres WHERE remaining != '') SELECT genre, COUNT(DISTINCT movie_id) AS movie_count FROM split_genres GROUP BY genre ORDER BY movie_count DESC;"
echo " "

echo "4. Найдите жанры, в которых чаще всего оставляют теги (комментарии). Для этого подсчитайте общее количество записей в таблице tags для фильмов каждого жанра. Выведите genre, tag_count и долю этого жанра в общем числе тегов (tag_share), выраженную в процентах."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split_genres(movie_id, genre, remaining) AS (SELECT id, CASE WHEN instr(genres, '|') > 0 THEN substr(genres, 1, instr(genres, '|') - 1) ELSE genres END, CASE WHEN instr(genres, '|') > 0 THEN substr(genres, instr(genres, '|') + 1) ELSE '' END FROM movies WHERE genres IS NOT NULL AND genres != '' AND genres != '(no genres listed)' UNION ALL SELECT movie_id, CASE WHEN instr(remaining, '|') > 0 THEN substr(remaining, 1, instr(remaining, '|') - 1) ELSE remaining END, CASE WHEN instr(remaining, '|') > 0 THEN substr(remaining, instr(remaining, '|') + 1) ELSE '' END FROM split_genres WHERE remaining != ''), genre_tags AS (SELECT sg.genre, COUNT(t.id) AS tag_count FROM split_genres sg JOIN tags t ON sg.movie_id = t.movie_id GROUP BY sg.genre) SELECT genre, tag_count, ROUND(tag_count * 100.0 / (SELECT COUNT(*) FROM tags), 2) AS tag_share FROM genre_tags ORDER BY tag_count DESC;"
echo " "

echo "5. Для каждого пользователя рассчитайте: общее количество выставленных оценок, средний выставленный рейтинг, дату первой и последней оценки (по полю timestamp в таблице ratings). Выведите user_id, rating_count, avg_rating, first_rating_date, last_rating_date. Отсортируйте результат по убыванию количества оценок и выведите только 10 первых строк."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT user_id, COUNT(rating) AS rating_count, ROUND(AVG(rating), 2) AS avg_rating, date(MIN(timestamp), 'unixepoch') AS first_rating_date, date(MAX(timestamp), 'unixepoch') AS last_rating_date FROM ratings GROUP BY user_id ORDER BY rating_count DESC LIMIT 10;"
echo " "

echo "6. Сегментируйте пользователей по типу поведения: «Комментаторы» — пользователи, у которых количество тегов (tags) больше количества оценок (ratings), «Оценщики» — наоборот, оценок больше, чем тегов, «Активные» — и оценок, и тегов >= 10, «Пассивные» — и оценок, и тегов < 5. Выведите user_id, общее число оценок, общее число тегов и категорию поведения. Используйте CASE."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH user_activity AS (SELECT u.id AS user_id, COALESCE(r.r_cnt, 0) AS rating_count, COALESCE(t.t_cnt, 0) AS tag_count FROM users u LEFT JOIN (SELECT user_id, COUNT(*) AS r_cnt FROM ratings GROUP BY user_id) r ON u.id = r.user_id LEFT JOIN (SELECT user_id, COUNT(*) AS t_cnt FROM tags GROUP BY user_id) t ON u.id = t.user_id) SELECT user_id, rating_count, tag_count, CASE WHEN rating_count >= 10 AND tag_count >= 10 THEN 'Активные' WHEN rating_count < 5 AND tag_count < 5 THEN 'Пассивные' WHEN tag_count > rating_count THEN 'Комментаторы' WHEN rating_count > tag_count THEN 'Оценщики' ELSE 'Смешанный' END AS behavior_category FROM user_activity;"
echo " "

echo "7. Для каждого пользователя выведите его имя и последний фильм, который он оценил (по времени из ratings.timestamp). Если пользователь не оценивал ни одного фильма, он всё равно должен быть в результате (с NULL в полях фильма). Результат: user_id, name, last_rated_movie_title, last_rating_timestamp."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH ranked_user_ratings AS (SELECT user_id, movie_id, timestamp, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY timestamp DESC) AS rn FROM ratings) SELECT u.id AS user_id, u.name, m.title AS last_rated_movie_title, r.timestamp AS last_rating_timestamp FROM users u LEFT JOIN ranked_user_ratings r ON u.id = r.user_id AND r.rn = 1 LEFT JOIN movies m ON r.movie_id = m.id ORDER BY u.id ASC;"
echo " "
