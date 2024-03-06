select  top 5 *from credit_card_transactions;

--1.write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
with ctel as (
select city, sum(amount) as total_spends
from credit_card_transactions 
group by city)
,total_spent as (select sum(cast(amount as bigint)) as total_amount from credit_card_transactions)
select top 5 ctel.*, total_amount, 
round(total_spends*1.0 / total_amount*100,2) as percentage_credit  from
ctel inner join total_spent on 1=1
order by total_spends desc; 


-- 2. write a query to print highest spend month and amount spent in that month for each card type
select top 5 *from credit_card_transactions;

with cte as (
select card_type,datepart(YEAR, transaction_date) yt,datepart(month,transaction_date) mt, sum(amount) as total_spend
from credit_card_transactions 
group by card_type,datepart(YEAR, transaction_date),datepart(month,transaction_date)
) 
select *from (select *, rank() over(partition by card_type order by total_spend desc) as rn 
from cte) a where rn =1;

-- 3- write a query to print the transaction details(all columns from the table) for each card type when it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
with cte as (
select*, sum(amount) over(partition by card_type order by transaction_date, transaction_id) as total_spends
from credit_card_transactions) 

select *from  (select *, rank() over(partition by card_type order by total_spends) as rn 
from cte where total_spends >= 1000000) a 
where rn =1;


-- 4. write a query to find city which had lowest percentage spend for gold card type
with cte as (
select city, card_type, sum(amount) as total_spends,
sum(case when card_type='Gold' then amount end) as gold_amount
from credit_card_transactions 
group by city,card_type ) 
select top 1  city,sum(gold_amount)* 1.0 / sum(total_spends) as gold_ratio
from cte
group by city
having sum(gold_amount) is not null
order by gold_ratio;



-- 5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
with cte as (
select city,exp_type, sum(amount) as total_spends
from credit_card_transactions 
group by city,exp_type ) 
select
city, max(case when rn_asc =1 then exp_type end ) as lowest_lowest_expense_type,
      min(case when rn_desc =1 then exp_type end ) as highest_expense_type
	  from	
(select *, rank() over(partition by city order by total_spends desc) as rn_desc,
           rank() over(partition by city order by total_spends asc) as rn_asc
from cte) a
group by city;



-- 6 write a query to find percentage contribution of spends by females for each expense type
with cte as (
select gender,exp_type,sum(amount) as total_amount,
sum(case when gender='f' then amount end) as female_amt_spend
from credit_card_transactions
group by gender,exp_type)
select exp_type, sum(female_amt_spend)* 1.0 / sum(total_amount) as female_ration_expense_type
from cte 
group by exp_type
having sum(female_amt_spend) is not null
order by exp_type

-- 7 which card and expense type combination saw highest month over month growth in Jan-2014
with cte as (
select card_type,exp_type, sum(amount) as total_spends,
DATEPART(month, Transaction_date) as mt, datepart(year,Transaction_date) as yt
from credit_card_transactions
group by card_type,exp_type,datepart(year,Transaction_date),DATEPART(month, Transaction_date)
)
select top 1 * from
(select *, rank() over(partition by exp_type order by total_spends desc) as rn 
from cte) a where rn=1

-- 9 during weekends which city has highest total spend to total no of transcations ratio
  
  with cte as (
 select city, datepart(DW, Transaction_date) as weekend, sum(amount) as total_amount
   from credit_card_transactions
   group by city,datepart(DW, Transaction_date)
  ),
  total_spent as (select sum(cast(amount as bigint)) as total_spends from credit_card_transactions)

 select top 5 cte.*, 
round(total_amount*1.0 / total_spends*100,2) as transaction_ration  from
cte inner join total_spent on 1=1
order by total_amount desc; 


-- 10  which city took least number of days to reach its 500th transaction after the first transaction in that city

with cte as 
(select city,transaction_date, 
row_number() over(partition by city order by transaction_date) as transaction_number
from credit_card_transactions
)
select top 1 city,
 min(transaction_date) as first_transaction_date,
 max(transaction_date) as last_transaction_date,
 DATEDIFF(DAY,min(transaction_date), max(transaction_date)) as reach_500
from cte 
group by city
having count(transaction_number) >= 500
order by reach_500 desc