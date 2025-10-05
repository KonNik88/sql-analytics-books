SET search_path TO dw, public;

-- Книги (берём book_id как основной PK)
CREATE TABLE IF NOT EXISTS dim_books (
  book_id           INT PRIMARY KEY,
  title             TEXT NOT NULL,
  authors           TEXT,
  language_code     TEXT,
  publication_year  INT,
  avg_rating        NUMERIC(3,2),
  ratings_count     INT,
  meta              JSONB
);

-- Пользователи (в goodbooks есть только ID)
CREATE TABLE IF NOT EXISTS dim_users (
  user_id INT PRIMARY KEY
);

-- Теги
CREATE TABLE IF NOT EXISTS dim_tags (
  tag_id   INT PRIMARY KEY,
  tag_name TEXT NOT NULL
);

-- Мост книга↔тег
CREATE TABLE IF NOT EXISTS bridge_book_tags (
  book_id   INT NOT NULL REFERENCES dw.dim_books(book_id),
  tag_id    INT NOT NULL REFERENCES dw.dim_tags(tag_id),
  tag_count INT,
  PRIMARY KEY (book_id, tag_id)
);

-- Оценки
CREATE TABLE IF NOT EXISTS fact_ratings (
  user_id INT NOT NULL REFERENCES dw.dim_users(user_id),
  book_id INT NOT NULL REFERENCES dw.dim_books(book_id),
  rating  INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  PRIMARY KEY (user_id, book_id)
);

-- «Хочу прочитать»
CREATE TABLE IF NOT EXISTS fact_to_read (
  user_id INT NOT NULL REFERENCES dw.dim_users(user_id),
  book_id INT NOT NULL REFERENCES dw.dim_books(book_id),
  PRIMARY KEY (user_id, book_id)
);
