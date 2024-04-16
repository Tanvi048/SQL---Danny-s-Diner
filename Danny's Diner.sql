#Q1. What is the total amount each customer spent at the restaurant?
use dannys_diner;

select customer_id, sum(price) as total_amt
from sales
join menu 
on sales.product_id = menu.product_id
group by customer_id;
#---------------------------------------------------------------------------------
#Q2. How many days has each customer visited the restaurant?

select customer_id, Count(order_date) as total_days
from sales
group by customer_id;
#---------------------------------------------------------------------------------
#Q3. What was the first item from the menu purchased by each customer?

With Rank1 as
(
Select customer_id, 
       product_name, 
       order_date,
       DENSE_RANK() OVER (PARTITION BY customer_id Order by order_date) as rank1
From menu
join sales
On menu.product_id = sales.product_id
group by customer_id, product_name, order_date
)
Select customer_id, product_name
From Rank1
Where rank1 = 1;
#---------------------------------------------------------------------------------
#Q4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select product_name, Count(order_date) as times_pur
from menu
join sales
on menu.product_id = sales.product_id
group by product_name
order by times_pur DESC
LIMIT 1;
#---------------------------------------------------------------------------------
#Q5. Which item was the most popular for each customer?

With rank1 as
(
Select customer_id,
       product_name, 
       Count(sales.product_id) as Count,
       Dense_rank()  Over (Partition by customer_id order by Count(product_id) DESC ) as Rank1
From menu 
join sales 
On menu.product_id = sales.product_id
group by customer_id, sales.product_id, product_name
)
Select customer_id,product_name,Count
From rank1
where Rank1 = 1;
#---------------------------------------------------------------------------------
#Q6. Which item was purchased first by the customer after they became a member?

With CTE as
(
Select  sales.customer_id,
        product_name,
        members.join_date,
        sales.order_date,
	Dense_rank() OVER (Partition by customer_id Order by order_date) as RankofOrder
From sales
Join menu 
ON menu.product_id = sales.product_id
JOIN members 
ON members.customer_id = sales.customer_id
Where sales.order_date >= members.join_date 
)
Select *
From CTE
Where RankofOrder = 1 ;
#---------------------------------------------------------------------------------
#Q7. Which item was purchased just before the customer became a member?

With CTE as
(
Select  sales.customer_id,
        product_name,
        members.join_date,
        sales.order_date,
	Dense_rank() OVER (Partition by customer_id Order by order_date desc) as RankofOrder
From sales
Join menu 
ON menu.product_id = sales.product_id
JOIN members 
ON members.customer_id = sales.customer_id
Where sales.order_date < members.join_date  
)
Select *
From CTE
Where RankofOrder = 1 ;
#---------------------------------------------------------------------------------
#Q8. What is the total items and amount spent for each member before they became a member?

Select  sales.customer_id,
        count(sales.product_id) as tot_qty,
        sum(price) as tot_sales
From sales
Join menu 
ON menu.product_id = sales.product_id
JOIN members 
ON members.customer_id = sales.customer_id
Where sales.order_date < members.join_date 
Group by customer_id
order by customer_id asc;
#---------------------------------------------------------------------------------
#Q9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier, how many points would each customer have?

with CTE as
(
SELECT sales.customer_id,
       CASE menu.product_id WHEN 1 THEN 20*price
       ELSE 10*price
       END "Points"
From sales
Join menu 
ON menu.product_id = sales.product_id
)
select customer_id, sum(Points) from CTE 
Group by customer_id
order by customer_id asc;
#---------------------------------------------------------------------------------
#Q10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
#not just sushi - how many points do customer A and B have at the end of January?

WITH dates AS 
(
   SELECT *, 
   DATE_ADD(join_date,interval 6 day) AS valid_date, 
   last_day('2021-01-31') AS last_date
   FROM members 
)
Select sales.customer_id, 
       SUM(
	         Case 
		       When menu.product_ID = 1 THEN price*20
			   When order_date between join_date and valid_date Then price*20
			   Else price*10
			   END 
		       ) as Points
From dates 
join sales 
On dates.customer_id = sales.customer_id
Join menu
On menu.product_id = sales.product_id
Where order_date < last_date
Group by customer_id
order by customer_id asc;
#---------------------------------------------------------------------------------
#Bonus Questions
#BQ1. Join All The Things

select sales.customer_id, sales.order_date, product_name, price,
(Case 
		       When order_date>= members.join_date then 'y'
               Else 'n'
			   END
     ) as is_Member
from sales
cross join menu
on sales.product_id = menu.product_id
left outer join members
on members.customer_id = sales.customer_id;
#---------------------------------------------------------------------------------
#BQ2. Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking 
#for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

with CTE as 
(
select sales.customer_id, sales.order_date, product_name, price,
(Case 
		       When order_date>= members.join_date then 'y'
               Else 'n'
			   END
     ) as is_Member
from sales
cross join menu
on sales.product_id = menu.product_id
left outer join members
on members.customer_id = sales.customer_id
)
SELECT *,
 (
   CASE
     WHEN is_Member = 'n' THEN null
     ELSE rank() over(PARTITION BY customer_id, is_Member ORDER BY order_date)
   END
 ) AS ranking
FROM CTE;
#---------------------------------------------------------------------------------