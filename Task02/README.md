# ETL Процесс и инициализация БД SQLite (Task02)

Данная утилита предназначена для автоматического развёртывания базы данных movies_rating.db на основе текстовых датасетов.

## Требования к окружению

Для корректной работы скрипта db_init.bat в операционной системе должны быть установлены:

1. **Python v3.x** (интерпретатор языков программирования)
2. **SQLite v3.x** (консольный клиент sqlite3)
3. **Bash** (для Linux/macOS) или поддержка выполнения .bat / .sh скриптов

## Структура создаваемых таблиц

* movies (id, title, year, genres)
* ratings (id, user_id, movie_id, rating, timestamp)
* tags (id, user_id, movie_id, tag, timestamp)
* users (id, name, email, gender, register_date, occupation)

## Запуск

Для полной пересборки базы данных выполните команду:

    ./db_init.bat

В результате выполнения будут сгенерированы:
* db_init.sql — сформированный файл с DDL/DML запросами.
* movies_rating.db — заполненный файл базы данных SQLite.
