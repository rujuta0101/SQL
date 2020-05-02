use db_Analytixlab_v1

-----------####################################     Data Preparation    ###########################
--1. Total Number of rows
select 'Customer', count(*) from csb_Customer
union
select 'Transaction', count(*) from csb_transaction
union
select 'Product Category', count(*) from csb_prod_cat_info

--2. Total number of transactions returned
select 'Returned Transaction', count(*) from csb_transaction
where total_amt<0

--3. Covert characters into Date
--3A. Customers DOB
uPDATE csb_Customer
set dob= CONVERT(DATE,(RIGHT(dob,4) + SUBSTRING(DOB,4,2)+ LEFT(dob,2)),101)

select * from csb_customer


--3B. Transacation date

uPDATE csb_transaction
set tran_date= DATEFROMPARTS (
RIGHT(tran_date,4),
convert(varchar(2),substring(	(REPLACE(tran_date,'-','/')),	((CHARINDEX('/',REPLACE(tran_date,'-','/'),1))+1),	(len(tran_date)-(charindex('/', (REPLACE(tran_date,'-','/')), (CHARINDEX('/',REPLACE(tran_date,'-','/'),1))) +1 )-4) )),
convert(varchar(2),substring((REPLACE(tran_date,'-','/')),1,(CHARINDEX('/',REPLACE(tran_date,'-','/'),1))-1))
)

select * from csb_transaction
 
---4. Time rang of transaction available
--4A. Indiviual in terms of year, month and days
select DATEDIFF(YEAR,min(tran_date), max(tran_date)) year, DATEDIFF(MONTH,min(tran_date),max(tran_date)) month, DATEDIFF(DAY,min(tran_date), max(tran_date)) day
from csb_transaction

--4B. Total difference in net no of years, months and days
select DATEDIFF(YEAR,min(tran_date), max(tran_date)) year, 
((DATEDIFF(MONTH,min(tran_date),max(tran_date)))- (DATEDIFF(YEAR,min(tran_date), max(tran_date))*12))  month, 
(DATEDIFF(YEAR,min(tran_date), max(tran_date)) * 365) -
(((DATEDIFF(MONTH,min(tran_date),max(tran_date)))*61/2)- 
		 (DATEDIFF(YEAR,min(tran_date), max(tran_date))*12)
) days
from csb_transaction

--5. Product category where sub category "DIY" belongs
select prod_Cat from csb_prod_cat_info where prod_subcat='DIY'


-----############################### Data Analysis  ###########################

--1. Channel most freq used for trasaction
select top 1 store_type,  count(store_type) from csb_transaction 
group by Store_type 
order by 2 desc



--2. male female count 
select Gender, count(customer_Id) No_of_customer
from csb_Customer
WHERE GENDER IN ('M', 'F') --Can comment this line to check for null values
group by Gender



--3. City with max customers and how many
select top 1  city_code City_With_Max_Customers,count( distinct (customer_id)) No_Of_Customer from csb_Customer
group by city_code 
order by 2 desc



--4. How many Sub cat under Book Cat
select prod_cat, count(prod_subcat) No_of_Sub_Cat
from csb_prod_cat_info
where prod_cat ='Books'
group by prod_cat



--5. Max qty of products ever ordered
--5A. For which type of productcategory max qty was ever ordered  (considering single order with max qty)
select b.prod_cat, b.prod_cat_code, max(qty) Total_Qty_Ordered from csb_transaction a, csb_prod_cat_info b
where a. prod_cat_code=b.prod_cat_code
group by b.prod_cat, b.prod_cat_code
order by 3 desc

--5B. Which prod catgory was order max in terms of net qty
select b.prod_cat, b.prod_cat_code, sum(qty) Total_Qty_Ordered from csb_transaction a, csb_prod_cat_info b
where a. prod_cat_code=b.prod_cat_code
group by b.prod_cat, b.prod_cat_code
order by 3 desc



--6. net total revenue generated in CAT -> Electronics, Books
select sum(total_amt) Revenue_From_Electronics_N_Books
from csb_transaction a, csb_prod_cat_info b
where a. prod_cat_code=b.prod_cat_code
and b.prod_cat in ('Electronics', 'Books')



--7. Customers with trans>10 excluding returns
SELECT COUNT(*) No_Of_Cust FROM
(Select (a.cust_id), count(a.transaction_id) c   from csb_transaction a 
where a.total_amt>0  --To exclude returns ; as in returns amt is negative
group by a.cust_id
having  count(a.transaction_id)>10
) as b



--8.Rev from 'Electronics','Clothing; Flagship STORE
select sum(a.total_amt) from csb_transaction a , csb_prod_cat_info b
where a.prod_cat_code=b.prod_cat_code
and b.prod_cat in ( 'Electronics','Clothing')
and a.Store_type='Flagship store'



--9. Total Rev by 'M' in 'Electronics' ; display rev by prod sub cat
select b.prod_subcat,sum(a.total_amt) Revenue
from csb_transaction a, csb_prod_cat_info b, csb_Customer c
where a.prod_cat_code=b.prod_cat_code
and b.prod_cat in ( 'Electronics')
and c.Gender='M'
GROUP BY B.prod_subcat



--10. % of sales and returns by prod_sub_cat; display top 5 sub cat by sales
select D.prod_subcat, Round((D.sales/D.total)*100,2) Percentage_Sales, Round((D.REturns/D.total)*-100,2) Percentage_Returns from
(
select P.prod_subcat,P.prod_sub_cat_code,
(SUM( case when T.Qty > 0 then total_amt else 0 end)) sales  ,
(SUM(case when T.Qty < 0 then total_amt else 0 end)) Returns, 
--(SUM(total_amt)) Total
(SUM(case when T.Qty < 0 then -1*total_amt else total_amt end)) Total
from csb_transaction T, csb_prod_cat_info P 
WHERE T.prod_subcat_code = P.prod_sub_cat_code
AND prod_subcat_code in 
		(select top 5 prod_subcat_code code from csb_transaction
		group by prod_subcat_code
		order by sum(total_amt) desc
		)

group by P.prod_subcat, P.prod_sub_cat_code
) D


--11. total rev
--			customers aged 25-30;
--			transdate ->last 30 days from max trsncation

select sum(a.total_amt) Rev_from_25to30Age_Last30daysOfTrans from csb_transaction a, csb_Customer b
where 
a. tran_date > dateadd(day,-30, (select max(tran_date) from csb_transaction))
and b.DOB >=  (dateadd(year,-30, SYSDATETIME()))
AND B.DOB <= (dateadd(year,-25, SYSDATETIME()))
				


--12. Prod cat with max returns in last 3 months of transaction
select top 1 c.prod_Cat, count(transaction_id)No_of_Return_Tran_InLast3Months from csb_transaction b, csb_prod_cat_info c
where c.prod_cat_code= b.prod_cat_code
and c.prod_sub_cat_code=b. prod_subcat_code
and b.total_amt< 0
and b.tran_date > dateadd(month,-3, (select max(tran_date) from csb_transaction))
group by c.prod_cat
order by 2 desc


--13. store type sells max products l by value of sales amt and qty sold
SELECT * FROM
(
select  TOP 1 store_type,'Qty' Type, sum(total_amt) Value from csb_transaction 
group by Store_type
ORDER BY 2,3
) AS A
UNION 
SELECT * FROM
(
select   TOP 1 store_type,  'Sum' Type, sum(qty) Value  from csb_transaction 
group by Store_type
ORDER BY 2,3
) AS B



--14. categories with avg rev above overall avergae
select c.prod_cat Prod_cat_with_above_avg_Revenue,c.prod_cat_code, avg(b.total_amt) Avg_Revenue 
from csb_transaction b, csb_prod_cat_info c
where b.prod_cat_code=c.prod_cat_code
and b.prod_subcat_code=c.prod_sub_cat_code
group by c.prod_cat, c.prod_cat_code
having avg(total_amt) > (select (sum(t1.total_amt)/ count(t1.prod_cat_code)) from csb_transaction t1)


--15. Avg and Total Revenue by each subcat for catgories  which are top 5 in terms of qunatity sold
select c.prod_cat , c.prod_subcat,avg(b.total_amt) Avg, sum(b.total_amt) Total
from csb_transaction b, csb_prod_cat_info c
where b.prod_cat_code=c.prod_cat_code
and b.prod_subcat_code=c.prod_sub_cat_code
and c.prod_cat_code in (
select top 5 prod_Cat_code
from csb_transaction t1
group by prod_cat_code
order by  count(qty)
)
group by c.prod_Cat,c.prod_subcat
order by 1,2 desc


