-- 1. Find the most family-friendly streaming service

-- Combine records from 4 platforms: amazon, disney, hulu, netflix
-- Add "genre" column from table genres
WITH all_data AS (
WITH service_data AS (
SELECT *, 'amazon' AS PLATFORM  FROM amazon
UNION ALL
SELECT *, 'disney' AS PLATFORM  FROM disney
UNION ALL
SELECT *, 'hulu' AS PLATFORM  FROM hulu
UNION ALL
SELECT *, 'netflix' FROM netflix
)

SELECT s.*, g.genre
FROM service_data s
LEFT JOIN genres g
ON s.title = g.film
)

SELECT 
	platform
	, count(*) AS total_films
	, SUM(CASE 
		WHEN genre ILIKE '%kids%' OR genre ILIKE '%family%' OR genre ILIKE '%children%' THEN 1 
		ELSE 0 END) AS total_family_friendly
	, (AVG(CASE 
		WHEN genre ILIKE '%kids%' OR genre ILIKE '%family%' OR genre ILIKE '%children%' THEN 1 
		ELSE 0 END) * 100) :: DECIMAL(10,2) AS pct_family_friendly
FROM all_data
GROUP BY platform
ORDER BY pct_family_friendly desc
;
-- 2. Find the streaming service with the highest-rated content (based on rotten_tomatoes score)
WITH all_data AS (
WITH service_data AS (
SELECT *, 'amazon' AS PLATFORM  FROM amazon
UNION ALL
SELECT *, 'disney' AS PLATFORM  FROM disney
UNION ALL
SELECT *, 'hulu' AS PLATFORM  FROM hulu
UNION ALL
SELECT *, 'netflix' FROM netflix
)

SELECT s.*, g.genre
FROM service_data s
LEFT JOIN genres g
ON s.title = g.film
)

SELECT 
	platform
	, CASE WHEN type = 1 THEN 'TV' ELSE 'Movie' END as type
	, AVG(SPLIT_PART(rotten_tomatoes, '/', 1)::NUMERIC)::DECIMAL(10,2) as rt_score
FROM all_data
GROUP BY platform, type
ORDER BY rt_score desc
;

-- 3. Find the most popular films
WITH all_data AS (
WITH service_data AS (
SELECT *, 'amazon' AS PLATFORM  FROM amazon
UNION ALL
SELECT *, 'disney' AS PLATFORM  FROM disney
UNION ALL
SELECT *, 'hulu' AS PLATFORM  FROM hulu
UNION ALL
SELECT *, 'netflix' FROM netflix
)

SELECT s.*, g.genre
FROM service_data s
LEFT JOIN genres g
ON s.title = g.film
)

SELECT title, year, genre, COUNT(platform)
FROM all_data
GROUP BY title, year, genre
HAVING COUNT(platform) = 4
ORDER BY COUNT(platform) desc
;

-- 4. How critics (rotten tomatoes) and audiences (imdb) diverged over time?
WITH all_data AS (
WITH service_data AS (
SELECT *, 'amazon' AS PLATFORM  FROM amazon
UNION ALL
SELECT *, 'disney' AS PLATFORM  FROM disney
UNION ALL
SELECT *, 'hulu' AS PLATFORM  FROM hulu
UNION ALL
SELECT *, 'netflix' FROM netflix
)

SELECT s.*, g.genre
FROM service_data s
LEFT JOIN genres g
ON s.title = g.film
)

SELECT 
	platform
	, CASE WHEN type = 1 THEN 'TV' ELSE 'Movie' END as type
	, year
	, AVG(SPLIT_PART(rotten_tomatoes, '/', 1)::NUMERIC)::DECIMAL(10,2) AS rt_score
	, AVG(SPLIT_PART(imdb, '/', 1)::NUMERIC * 10)::DECIMAL(10,2) AS imdb_score
	, AVG(SPLIT_PART(rotten_tomatoes, '/', 1)::NUMERIC-(SPLIT_PART(imdb, '/', 1)::NUMERIC * 10))::DECIMAL(10,2) AS avg_diff
FROM all_data
WHERE rotten_tomatoes IS NOT NULL
AND imdb IS NOT NULL
AND year >= 2000
GROUP BY platform, type, year
ORDER BY platform, type, year
;
	   
