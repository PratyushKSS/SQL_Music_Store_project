--Basic Question set
--Q1: Who is the senior most employee based on job title?
 
 select * from employee
 order by levels desc
 limit 1
 
 -- Q2: Which countries have the most Invoices?
 
 select count(*) , billing_country from invoice
 group by billing_country
 order by count desc
 
 --Q3: What are top 3 values of total invoice?
 
 select total from invoice
 order by total desc
 limit 3
 
/*Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals*/

select billing_city, sum(total) as invoice_total from invoice
group by billing_city
order by invoice_total desc

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/

select customer.customer_id, customer.first_name, customer.last_name, sum(invoice.total) as total from customer
join invoice on customer.customer_id = invoice.customer_id
group by customer.customer_id
order by total desc
limit 1

--Moderate Question set
/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

--method 1
select distinct email,first_name,last_name from customer
join invoice on customer.customer_id = invoice.customer_id
join invoice_line on invoice.invoice_id = invoice_line.invoice_id
where track_id in(
	select track_id from track
	join genre on track.genre_id = genre.genre_id
	where genre.name like 'Rock'
)
order by email

--method 2
select distinct email as Email, first_name as First_name, last_name as Last_name, genre.name as Genre
from customer
join invoice on customer.customer_id = invoice.customer_id
join invoice_line on invoice.invoice_id = invoice_line.invoice_id
join track on invoice_line.track_id = track.track_id
join genre on track.genre_id = genre.genre_id
where genre.name like 'Rock'
order by email

/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

select artist.artist_id, artist.name, count(artist.artist_id) as tracks
from track
join album on album.album_id = track.album_id
join artist on artist.artist_id = album.artist_id
join genre on track.genre_id = genre.genre_id
where genre.name like 'Rock'
group by artist.artist_id
order by tracks desc
limit 10

/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

select name, milliseconds from track
where milliseconds > (select avg(milliseconds) from track)
order by milliseconds desc

--Advance Question set
/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

with top_artist as (
	Select artist.artist_id as artist_id, artist.name as artist_name,
	sum(invoice_line.unit_price* invoice_line.quantity) as total_sales
	from invoice_line
	join track on invoice_line.track_id = track.track_id
	join album on track.album_id = album.album_id
	join artist on album.artist_id = artist.artist_id
	group by 1
	order by 3 desc
	limit 1
)

select c.customer_id, c.first_name, c.last_name, ta.artist_name,
sum(il.unit_price*il.quantity) as amount_spent
from customer c
join invoice i on c.customer_id = i.customer_id
join invoice_line il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join album al on t.album_id = al.album_id
join top_artist ta on al.artist_id = ta.artist_id
group by 1,2,3,4
order by 5 desc

/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

with popular_genre as(
	Select count(invoice_line.quantity) as purchases, customer.country, genre.name, genre.genre_id,
	row_number() over(partition by customer.country order by count(invoice_line.quantity) desc) as row_no
	from invoice_line
	join invoice on invoice_line.invoice_id = invoice.invoice_id
	join customer on invoice.customer_id = customer.customer_id
	join track on invoice_line.track_id = track.track_id
	join genre on track.genre_id = genre.genre_id
	group by 2,3,4
	order by 2 asc, 1 desc
)
select * from popular_genre where row_no <= 1

/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

with customer_country as(
	Select customer.customer_id, customer.first_name, customer.last_name, invoice.billing_country,
	sum(invoice.total) as total_spend,
	row_number() over(partition by invoice.billing_country order by sum(total) desc) as row_no
	from customer
	join invoice on customer.customer_id = invoice.customer_id
	group by 1,2,3,4
	order by 4 asc, 5 desc 
)
select * from customer_country where row_no <= 1
