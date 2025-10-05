SET search_path TO dw, public;

SELECT plan(8);

SELECT has_table('dw','dim_books','dim_books exists');
SELECT has_table('dw','dim_users','dim_users exists');
SELECT has_table('dw','dim_tags','dim_tags exists');
SELECT has_table('dw','bridge_book_tags','bridge_book_tags exists');
SELECT has_table('dw','fact_ratings','fact_ratings exists');
SELECT has_table('dw','fact_to_read','fact_to_read exists');

SELECT ok( (SELECT COUNT(*) FROM dw.dim_books) > 0, 'books loaded');
SELECT ok( (SELECT COUNT(*) FROM dw.fact_ratings) > 0, 'ratings loaded');

SELECT finish();
