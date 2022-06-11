select * from df_vancouver_availability      --1653453
where available = 'True';                    --561412

select * from host_vancouver_df;  --3128

select * from listing_vancouver_df;  --4530

select * from review_vancouver_df;  --164536

--Data cleaning
select distinct minimum_nights from df_vancouver_availability;--minimum_nights


--checking duplicates

select name, count(*) from listing_vancouver_df
group by name having count(*) > 1;  --44




/*a. Analyze different metrics to draw the distinction between Super Host and Other Hosts:
	To achieve this, you can use the following metrics and explore a few yourself as well. 
	Acceptance rate, response rate, instant booking, profile picture, identity verified, review review scores, average no of bookings per month, etc.
*/

--Acceptance Rate
select host_response_time,AVG(host_response_rate) response_rate, avg(host_acceptance_rate) acceptance_rate
from host_vancouver_df
group by host_response_time;

--Response Rate

select host_id, host_name, host_response_time, host_response_rate
from host_vancouver_df
where host_response_time = 'within a few hours';   --416

select host_id, host_name, host_response_time, host_response_rate
from host_vancouver_df
where host_response_time = 'a few days or more';  --77

select host_id, host_name, host_response_time, host_response_rate
from host_vancouver_df
where host_response_time = 'within a day';  --240

select host_id, host_name, host_response_time, host_response_rate
from host_vancouver_df
where host_response_time = 'within an hour';  --1471

--Instant Bookable
select * from listing_toronto_df
where instant_bookable = 'True' and price > 150
order by maximum_nights desc;                     --1195



--Profile Picture
select * 
from host_vancouver_df
where host_has_profile_pic = 'True'; --3104


--Identity verified
select * 
from host_vancouver_df
where host_identity_verified = 'True';  --2767

--Is superhost
select * 
from host_vancouver_df
where host_is_superhost = 'True';  --1228


--Review Score
select a.listing_id, b.name, count(*) as N_reviews
from review_vancouver_df a
join listing_vancouver_df b
on a.listing_id = b.id
group by a.listing_id, b.name
order by count(*) desc;                           --3839


select id, name, minimum_nights, 
(review_scores_rating + review_scores_accuracy + review_scores_cleanliness + review_scores_checkin + review_scores_communication + review_scores_location + review_scores_value)/7 as ratings
from listing_vancouver_df
where minimum_nights > 5 and review_scores_accuracy >4
order by ratings desc, minimum_nights;		    --1421


select id, name, (minimum_nights + maximum_nights)/2 as avg_nights, 
(review_scores_rating + review_scores_accuracy + review_scores_cleanliness + review_scores_checkin + review_scores_communication + review_scores_location + review_scores_value)/7 as ratings
from listing_vancouver_df
order by ratings desc, avg_nights desc;  --4530



--Booking per month
select a.listing_id, b.name, concat(year(a.date),'-',month(a.date)) as months, count(*) n_bookings
from df_vancouver_availability a
join listing_vancouver_df b
on a.listing_id = b.id
group by a.listing_id, b.name, concat(year(a.date),'-',month(a.date))
order by concat(year(a.date),'-',month(a.date)), count(*) desc;


--b. Using the above analysis, identify top 3 crucial metrics one needs to maintain to become a Super Host and also, find their average values.
select * 
from host_vancouver_df
where host_is_superhost = 'True';

select  host_id, host_name, host_has_profile_pic, host_identity_verified
from host_vancouver_df
where host_is_superhost = 'True';

select distinct host_response_time, count(*) as n_superhost
from host_vancouver_df
where host_is_superhost = 'True'
group by host_response_time
order by count(*) desc;

select distinct host_response_rate, count(*) as n_superhost
from host_vancouver_df
where host_is_superhost = 'True'
group by host_response_rate
order by count(*) desc;

select distinct host_acceptance_rate, count(*) as n_superhost
from host_vancouver_df
where host_is_superhost = 'True'
group by host_acceptance_rate
order by count(*) desc;

-- In order to become a superhost, a host should have a verified identity with profile picture along with high response time, response rate and acceptance rate 


/*c. Analyze how does the comments of reviewers vary for listings of Super Hosts vs Other Hosts
	--(Extract words from the comments provided by the reviewers)
*/
select a.listing_id, c.host_id, c.host_name, 
(b.review_scores_rating + b.review_scores_accuracy + b.review_scores_cleanliness + b.review_scores_checkin + b.review_scores_communication + b.review_scores_location + b.review_scores_value)/7 as ratings,
a.comments
from review_vancouver_df a
join listing_vancouver_df b
on a.listing_id = b.id
join host_vancouver_df c
on b.host_id = c.host_id
where a.comments like '%great%' or a.comments like '%wonderful%' or a.comments like '%loved%'; --88632

select a.listing_id, c.host_id, c.host_name, 
(b.review_scores_rating + b.review_scores_accuracy + b.review_scores_cleanliness + b.review_scores_checkin + b.review_scores_communication + b.review_scores_location + b.review_scores_value)/7 as ratings,
a.comments
from review_vancouver_df a
join listing_vancouver_df b
on a.listing_id = b.id
join host_vancouver_df c
on b.host_id = c.host_id
where a.comments like '%bad%'; --986


--d. Analyze do Super Hosts tend to have large property types as compared to Other Hosts
select a.host_id, a.host_name, a.host_is_superhost, b.property_type, b.room_type, b.accommodates
from host_vancouver_df a
join listing_vancouver_df b
on a.host_id = b.host_id
where a.host_is_superhost = 'True'
order by b.accommodates desc; --1779

select a.host_id, a.host_name, a.host_is_superhost, b.property_type, b.room_type, b.accommodates
from host_vancouver_df a
join listing_vancouver_df b
on a.host_id = b.host_id
where a.host_is_superhost = 'False'
order by b.accommodates desc;  --2749

--Observation: Cannot say that super hosts hold large properties.

--e. Analyze the average price and availability of the listings for the upcoming year between Super Hosts and Other Hosts
select b.id, b.name, b.property_type, b.room_type, b.price, b.host_is_superhost, b.ratings, a.available
from df_vancouver_availability a
join 
(select a.id, a.name, a.property_type, a.room_type, AVG(a.price) price, b.host_is_superhost, 
(avg(review_scores_rating) + avg(review_scores_accuracy) + avg(review_scores_cleanliness) + avg(review_scores_checkin) + avg(review_scores_communication) + avg(review_scores_location) + avg(review_scores_value))/7 as ratings
from listing_vancouver_df a
join host_vancouver_df b
on a.host_id = b.host_id
where b.host_is_superhost = 'True'
group by a.property_type, a.room_type, a.id, name, b.host_is_superhost) b
on a.id = b.id
where a.available = 'True';  

select b.id, b.name, b.property_type, b.room_type, b.price, b.host_is_superhost, b.ratings, a.available
from df_vancouver_availability a
join 
(select a.id, a.name, a.property_type, a.room_type, AVG(a.price) price, b.host_is_superhost, 
(avg(review_scores_rating) + avg(review_scores_accuracy) + avg(review_scores_cleanliness) + avg(review_scores_checkin) + avg(review_scores_communication) + avg(review_scores_location) + avg(review_scores_value))/7 as ratings
from listing_vancouver_df a
join host_vancouver_df b
on a.host_id = b.host_id
where b.host_is_superhost = 'False'
group by a.property_type, a.room_type, a.id, name, b.host_is_superhost) b
on a.id = b.id
where a.available = 'True';

select b.id, b.name, b.property_type, b.room_type, b.price, b.host_is_superhost, b.ratings, a.available
from df_vancouver_availability a
join 
(select a.id, a.name, a.property_type, a.room_type, AVG(a.price) price, b.host_is_superhost, 
(avg(review_scores_rating) + avg(review_scores_accuracy) + avg(review_scores_cleanliness) + avg(review_scores_checkin) + avg(review_scores_communication) + avg(review_scores_location) + avg(review_scores_value))/7 as ratings
from listing_vancouver_df a
join host_vancouver_df b
on a.host_id = b.host_id
where b.host_is_superhost = 'False'
group by a.property_type, a.room_type, a.id, name, b.host_is_superhost) b
on a.id = b.id
where a.available = 'False';

select b.id, b.name, b.property_type, b.room_type, b.price, b.host_is_superhost, b.ratings, a.available
from df_vancouver_availability a
join 
(select a.id, a.name, a.property_type, a.room_type, AVG(a.price) price, b.host_is_superhost, 
(avg(review_scores_rating) + avg(review_scores_accuracy) + avg(review_scores_cleanliness) + avg(review_scores_checkin) + avg(review_scores_communication) + avg(review_scores_location) + avg(review_scores_value))/7 as ratings
from listing_vancouver_df a
join host_vancouver_df b
on a.host_id = b.host_id
where b.host_is_superhost = 'True'
group by a.property_type, a.room_type, a.id, name, b.host_is_superhost) b
on a.id = b.id
where a.available = 'False';

--Average price for different property types
select property_type, room_type, AVG(price) price
from listing_vancouver_df
group by property_type, room_type
order by price desc;   --52



--f. Analyze if there is some difference in above mentioned trends between Local Hosts or Hosts residing in other locations 


--g. Analyze the above trends for the two cities for which data has been provided and provide insights on comparison



