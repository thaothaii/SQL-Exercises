-- 1. Find the following information 
--- Buyer Id / Email 
--- First Order Date / Most recent order date 
--- Total Spend 
--- Preferred rating 

with rental_detail as (
	SELECT r.customer_id
	, r.rental_id
	, i.film_id
	, f.rating
	FROM rental r
	LEFT JOIN inventory i ON r.inventory_id = i.inventory_id
	LEFT JOIN film f ON i.film_id = f.film_id
),

customer_rating as (
	SELECT customer_id
	, rating
	, count(*) as rating_count
	, dense_rank() over (partition by customer_id order by count(*) desc) as prefer_rank
	FROM rental_detail
	GROUP BY 1, 2
)

SELECT c1.*
, c2.preferred_rating
--, c2.rating_count as order_count
FROM (
	select p.customer_id
	, c.email
	, min(p.payment_date) as first_order_date
	, max(p.payment_date) as recent_order_date
	, sum(p.amount) as total_spending
	from payment p
	left join customer c on c.customer_id = p.customer_id
	group by 1, 2
) c1
LEFT JOIN (
	SELECT customer_id
	, array_agg(rating) as preferred_rating 
	FROM customer_rating 
	where prefer_rank = 1
	group by customer_id) c2 
ON c1.customer_id = c2.customer_id
ORDER BY 1
;

-- 2. Analyze Time in-between Customer Orders

WITH time_between AS (
SELECT 
	t.*
	, t.payment_date - t.prior_order AS some_interval
	, (EXTRACT(epoch FROM t.payment_date - t.prior_order) /3600)::DECIMAL(10,2) AS hours_since

FROM (
		SELECT 
			p.*
			, row_number() OVER (PARTITION BY p.customer_id ORDER BY p.payment_date) AS order_rank
			, lag(p.payment_date) OVER (PARTITION BY p.customer_id ORDER BY p.payment_date) as prior_order
		FROM payment p
) t
)

SELECT 
	floor(hours_since / 24) * 1 as range_floor
	, concat(floor(hours_since / 24) * 24, '-', floor(hours_since / 24) * 24 + 23) as range_label_hours
	, count(*) as frequency
FROM time_between
WHERE hours_since is not null
GROUP BY range_floor, range_label_hours
ORDER BY frequency desc
;

-- 3. Find the top 10% of movies based on dollar value rented amounts
SELECT * 
FROM (
SELECT 
	f.film_id
	, f.title
	, SUM(p.amount) AS sales
	, NTILE(100) OVER(ORDER BY SUM(p.amount) DESC) AS p_rank
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON f.film_id = i.film_id
JOIN payment p ON p.rental_id = r.rental_id
GROUP BY 1,2
) percentile
WHERE p_rank <= 10
;

-- 4. Find Top 5 Highest Grossing Actors
--- Top 5 actors/actresses by rental revenues
--- Find all film they appear in

WITH gross_amount AS (
SELECT 
	p.amount
	, r.inventory_id
	, i.film_id
	, fa.actor_id
	, CONCAT(a.first_name, ' ', a.last_name) as actor_actress
FROM payment p
JOIN rental r ON r.rental_id = p.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON f.film_id = i.film_id
JOIN film_actor fa ON fa.film_id = f.film_id
JOIN actor a ON fa.actor_id = a.actor_id
),

top5 AS (
SELECT 
	actor_actress
	, actor_id
	, SUM(amount) AS total_amount
FROM gross_amount
GROUP BY 1, 2
ORDER BY 3 desc
LIMIT 5
)

SELECT 
	t5.actor_id
	, t5.actor_actress
	, array_agg(f.title) as movies
	, array_length(array_agg(f.title), 1) as total_movies
FROM top5 t5
LEFT JOIN film_actor fa ON t5.actor_id = fa.actor_id
LEFT JOIN film  f ON f.film_id = fa.film_id 
GROUP BY 1, 2
	
