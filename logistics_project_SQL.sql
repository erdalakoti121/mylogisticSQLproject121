create database logistics_db;
use logistics_db;

show tables;

select * from logistics_project_dataset__2500_rows;

drop database if exists logistics_db;

create database logistics_db;
use logistics_db;

show tables;

select * from shipments_data; 

select count(*) from shipments_data;

-- here project begins.
-- PHASE 1  KPI;s
-- Q1 find total transportation cost.

select sum(transport_cost) as total_transportation_cost from shipments_data;

-- Q2 total shipmnets by status.

select shipment_status, count(*) as total_count 
from shipments_data 
group by shipment_status;

-- Q3 avg transport cost per warehouse.

select warehouse_city, avg(transport_cost) as average_costper_warehouse
from shipments_data
group by warehouse_city order by avg(transport_cost) desc;

-- Q4 top5 most expensive shipments.

select shipment_id, transport_cost from shipments_data
order by transport_cost desc limit 5;

-- Q5 delayed shipments , took > 5days to deliver.

select shipment_id, shipment_date, delivery_date, datediff(delivery_date,shipment_date) as delivery_days
from shipments_data
where datediff(delivery_date,shipment_date)>5
order by delivery_days desc;

-- PHASE 2 , ANALYTICS OF WAREHOUSE.

-- Q6 rank warehouses by shipment volume.   

select warehouse_city, count(*) as shipment_volume
from shipments_data
group by warehouse_city order by shipment_volume desc;

-- Q7 warehouse contributing highest logistics cost.

select warehouse_city, sum(transport_cost) as max_logistics_cost
from shipments_data group by warehouse_city
order by max_logistics_cost desc limit 1;

-- Q8 warehouse with best delivery speed 

select warehouse_city, avg (datediff(delivery_date,shipment_date)) as shipment_time
from shipments_data 
group by warehouse_city order by shipment_time asc limit 3;

-- Q9 find cost/km for each shipment.

select shipment_id, order_id, round(transport_cost*1.0/distance_km,2) as costperkm 
from shipments_data;

-- Q10 identify and count inefficinet shipments.

select count(*) as inefficient_shipment from shipments_data
where weight_kg < ( select avg(weight_kg) from shipments_data) and
transport_cost> ( select avg(transport_cost) from shipments_data) ;

-- -- PHASE 3 , window function ANALYTICS. 

-- Q 11 find running transportation cost over time.

select shipment_date, transport_cost, sum(transport_cost) over (order by shipment_date asc)
as runningcost from shipments_data;
  
-- Q 12 Find rolling 7-shipment average transportation cost.

select shipment_date, shipment_id, transport_cost, avg(transport_cost)
over ( order by shipment_date rows between 6 preceding and current row)
as rollingavg from shipments_data; 

-- Q13 find latest shipment date of each warehouse.

select * from (
select warehouse_city, shipment_date, row_number() 
over ( partition by warehouse_city order by shipment_date desc) as latest_shipment 
from shipments_data) t
where latest_shipment =1;

-- Q 14 Find warehouses whose average transport cost exceeds company average.

select warehouse_city, avg(transport_cost) as avgtransport
from shipments_data
group by warehouse_city
having avg(transport_cost)> (select avg(transport_cost) from shipments_data);

-- PHASE 4 ;  FINAL ONE; real business questions.

-- Q 15 calculate on time delivery %. 
SELECT
  ROUND(COUNT(CASE WHEN shipment_status = 'Delivered'
  AND DATEDIFF(delivery_date, shipment_date) <= 5
  THEN 1 END) * 100.0 / COUNT(*), 2) AS otd_pct
FROM shipments_data;

-- Q 16 find monthly shipment trends. 

select month(shipment_date) as monthlytrend, count(*) as totalcount
from shipments_data
group by monthlytrend order by totalcount desc;

-- Q 17 Find top 3 costly shipments per warehouse.

select * from (
select warehouse_city, transport_cost, row_number() over(partition by warehouse_city) 
as max_cost from shipments_data) t 
where max_cost <= 3;

-- Q18 Find customer cities receiving maximum shipments.

select customer_city, count(*) as max_shipments
from shipments_data
group by customer_city order by max_shipments desc limit 1;

-- Q19 How much each warehouse contributes to total company fuel cost.

select warehouse_city, sum(fuel_cost) as fuel_warehouse, 
round (sum (fuel_cost)*100 / (select sum(fuel_cost) from shipments_data),2)
from shipments_data
group by warehouse_city;

-- Q20 count cancelled shipments. 

select round(count(case when  shipment_status='cancelled' then 1 end)*100/count(*),2) as cancel
from shipments_data;

-- Q21 find a vehicle efficiency comaprision.

select vehicle_type,
  count(*) AS shipments,
  round(AVG(transport_cost/distance_km),3) AS avg_cost_per_km,
  round(AVG(DATEDIFF(delivery_date,shipment_date)),1) AS avg_days
from shipments_data
group by vehicle_type
order by avg_cost_per_km ASC;

-- Q22 find a monthly trend of cost vs shipments.
select 
  DATE_FORMAT(shipment_date,'%Y-%m') AS month,
  COUNT(*) AS shipments,
  ROUND(SUM(transport_cost),0) AS total_cost,
  ROUND(AVG(transport_cost),0) AS avg_cost
FROM shipments_data
GROUP BY month
ORDER BY month;
