#!/bin/bash
chcp 65001 2>/dev/null || true

sqlite3 movies_rating.db < db_init.sql

echo "1. Найти все пары пользователей, оценивших один и тот же фильм. Устранить дубликаты, проверить отсутствие пар с самим собой. Для каждой пары должны быть указаны имена пользователей и название фильма, который они оценили. В списке оставить первые 100 записей."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT DISTINCT u1.name AS user1, u2.name AS user2, m.title FROM ratings r1 JOIN ratings r2 ON r1.movie_id = r2.movie_id AND r1.user_id < r2.user_id JOIN users u1 ON r1.user_id = u1.id JOIN users u2 ON r2.user_id = u2.id JOIN movies m ON r1.movie_id = m.id LIMIT 100;"
echo " "

echo "2. Найти 10 самых старых оценок от разных пользователей, вывести названия фильмов, имена пользователей, оценку, дату отзыва в формате ГГГГ-ММ-ДД."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH ranked_ratings AS (SELECT user_id, movie_id, rating, timestamp, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY timestamp ASC) AS rn FROM ratings) SELECT m.title, u.name, r.rating, date(r.timestamp, 'unixepoch') AS review_date FROM ranked_ratings r JOIN users u ON r.user_id = u.id JOIN movies m ON r.movie_id = m.id WHERE r.rn = 1 ORDER BY r.timestamp ASC LIMIT 10;"
echo " "

echo "3. Вывести в одном списке все фильмы с максимальным средним рейтингом и все фильмы с минимальным средним рейтингом. Общий список отсортировать по году выпуска и названию фильма. В зависимости от рейтинга в колонке \"Рекомендуем\" для фильмов должно быть написано \"Да\" или \"Нет\"."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH movie_ratings AS (SELECT m.title, m.year, AVG(r.rating) AS avg_rating FROM movies m JOIN ratings r ON m.id = r.movie_id GROUP BY m.id, m.title, m.year), min_max AS (SELECT MAX(avg_rating) AS max_rating, MIN(avg_rating) AS min_rating FROM movie_ratings) SELECT mr.title, mr.year, mr.avg_rating, CASE WHEN mr.avg_rating = mm.max_rating THEN 'Да' ELSE 'Нет' END AS 'Рекомендуем' FROM movie_ratings mr CROSS JOIN min_max mm WHERE mr.avg_rating = mm.max_rating OR mr.avg_rating = mm.min_rating ORDER BY mr.year ASC, mr.title ASC;"
echo " "

echo "4. Вычислить количество оценок и среднюю оценку, которую дали фильмам пользователи-мужчины в период с 2011 по 2014 год."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT COUNT(r.rating) AS rating_count, ROUND(AVG(r.rating), 2) AS avg_rating FROM ratings r JOIN users u ON r.user_id = u.id WHERE u.gender IN ('M', 'male') AND strftime('%Y', r.timestamp, 'unixepoch') BETWEEN '2011' AND '2014';"
echo " "

echo "5. Составить список фильмов с указанием средней оценки и количества пользователей, которые их оценили. Полученный список отсортировать по году выпуска и названиям фильмов. В списке оставить первые 20 записей."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT m.title, m.year, ROUND(AVG(r.rating), 2) AS avg_rating, COUNT(r.user_id) AS user_count FROM movies m JOIN ratings r ON m.id = r.movie_id GROUP BY m.id, m.title, m.year ORDER BY m.year ASC, m.title ASC LIMIT 20;"
echo " "

echo "6. Определить самый распространенный жанр фильма и количество фильмов в этом жанре. Отдельную таблицу для жанров не использовать, жанры нужно извлекать из таблицы movies."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split_genres(movie_id, genre, remaining) AS (SELECT id, CASE WHEN instr(genres, '|') > 0 THEN substr(genres, 1, instr(genres, '|') - 1) ELSE genres END, CASE WHEN instr(genres, '|') > 0 THEN substr(genres, instr(genres, '|') + 1) ELSE '' END FROM movies WHERE genres IS NOT NULL AND genres != '' AND genres != '(no genres listed)' UNION ALL SELECT movie_id, CASE WHEN instr(remaining, '|') > 0 THEN substr(remaining, 1, instr(remaining, '|') - 1) ELSE remaining END, CASE WHEN instr(remaining, '|') > 0 THEN substr(remaining, instr(remaining, '|') + 1) ELSE '' END FROM split_genres WHERE remaining != '') SELECT genre, COUNT(DISTINCT movie_id) AS movie_count FROM split_genres GROUP BY genre ORDER BY movie_count DESC LIMIT 1;"
echo " "

echo "7. Вывести список из 10 последних зарегистрированных пользователей в формате \"Фамилия Имя|Дата регистрации\" (сначала фамилия, потом имя)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT substr(name, instr(name, ' ') + 1) || ' ' || substr(name, 1, instr(name, ' ') - 1) || '|' || register_date AS 'Фамилия Имя|Дата регистрации' FROM users ORDER BY register_date DESC LIMIT 10;"
echo " "

echo "8. С помощью рекурсивного CTE определить, на какие дни недели приходился ваш день рождения в каждом году."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE birthday_cte(bdate, b_year) AS (SELECT '2006-12-02', 2006 UNION ALL SELECT date(bdate, '+1 year'), b_year + 1 FROM birthday_cte WHERE b_year < 2026) SELECT b_year AS 'Год', bdate AS 'Дата', CASE cast(strftime('%w', bdate) AS integer) WHEN 0 THEN 'Воскресенье' WHEN 1 THEN 'Понедельник' WHEN 2 THEN 'Вторник' WHEN 3 THEN 'Среда' WHEN 4 THEN 'Четверг' WHEN 5 THEN 'Пятница' WHEN 6 THEN 'Суббота' END AS 'День недели' FROM birthday_cte;"
echo " "
