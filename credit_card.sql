create database creditcard;
use creditcard;
CREATE DATABASE creditcard;
USE creditcard;

-- Customers Table
CREATE TABLE customers ( 
    customer_id INT PRIMARY KEY,   
    customer_fname VARCHAR(255) NOT NULL, 
    customer_lname VARCHAR(255) NOT NULL,  
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20),   
    state VARCHAR(255),
    postal_code INT,
    age INT,
    gender VARCHAR(255),
    join_date DATE  
); 

-- Credit Cards Table
CREATE TABLE credit_cards ( 
    credit_card_id VARCHAR(255) PRIMARY KEY,   
    card_number VARCHAR(255) NOT NULL,   
    bank_name VARCHAR(100) NOT NULL,   
    card_brand ENUM('visa', 'mastercard', 'amex', 'discover', 'rupay') NOT NULL,  
    card_limit DECIMAL(10,2),
    current_balance DECIMAL(10,2),  
    last_payment_date DATE,         
    payment_due_date DATE,          
    payment_status VARCHAR(255),
    credit_utilization DECIMAL(10,2),
    customer_id INT,   
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)  
); 

-- Transactions Table
CREATE TABLE transactions ( 
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    credit_card_id VARCHAR(255),   
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),   
    transaction_date DATE,   
    transaction_time TIME, 
    transaction_category VARCHAR(255),
    customer_location VARCHAR(255),
    merchant_name VARCHAR(255),
    merchant_location VARCHAR(255),
    merchant_category VARCHAR(255),
    transaction_mode VARCHAR(255),
    previous_transactions_count INT,
    p_status VARCHAR(255),
    FOREIGN KEY (credit_card_id) REFERENCES credit_cards(credit_card_id)  
);





/* 
Step 1: Cleaning the Data      
Before analysis, we must fix missing values, incorrect links, and 
duplicate data. 
   Checking for Missing Data: 
• Find transactions where credit_card_id is missing. 
*/

select *
from creditcard.transactions t1
where t1.credit_card_id is null;

/*
• Identify credit cards that reference a non-existing customer. 
   */
   
select *
from creditcard.credit_cards c
left join creditcard.customers c2
on c2.customer_id = c.customer_id
where c.customer_id is null;
   
   /*
   Removing Invalid Data:
• Delete transactions with a missing or incorrect credit_card_id. 
*/

set sql_safe_updates = 0;
delete from creditcard.transactions
where credit_card_id is null
   or credit_card_id not in (
        select credit_card_id from creditcard.credit_cards
);

/*
• Remove credit cards linked to customers who don’t exist in the 
customer table. 
 */
 
set sql_safe_updates = 0;
delete from creditcard.credit_cards c
where c.customer_id not in (
select c2.customer_id from creditcard.customers c2
);

 
 /*
Step 2: Analyzing Transactions       
Once data is clean, we analyze customer spending and business insights. 
*/

  /*Total Transactions & Amount: */
  
-- • How many transactions happened? 

select count(*)	as total_transaction			
from creditcard.transactions t1;

-- • What is the total amount spent? 

select sum(t1.amount) as total_amount
from creditcard.transactions t1;

  -- Monthly Trends: 
-- • How does spending change month by month? 

select 
month(t1.transaction_date) as month,
dense_rank() over(order by week(t1.transaction_date)) as week,
sum(amount) as total_spent
from creditcard.transactions t1
group by month(t1.transaction_date), week(t1.transaction_date)
order by week;

  -- Top Spending Customers: 
-- • Who are the top 5 customers by total spending? 

select  dense_rank() over (order by SUM(t1.amount) desc) as Top_spender,
concat(c1.customer_fname,' ', c1.customer_lname) as full_name, 
sum(t1.amount) as total_spending
from creditcard.customers c1
inner join creditcard.credit_cards cc1
on cc1.customer_id = c1.customer_id
inner join creditcard.transactions t1
on t1.credit_card_id = cc1.credit_card_id
group by c1.customer_id,c1.customer_fname, c1.customer_lname
order by total_spending desc
limit 5;

 --  Most Popular Banks: 
-- • Which bank’s credit cards are used the most? 
 
 select cc1.bank_name, count(transaction_id) as most_used
 from creditcard.credit_cards cc1 
 inner join creditcard.transactions t1
 on t1.credit_card_id = cc1.credit_card_id
 group by cc1.bank_name
 order by most_used desc
 limit 5;
 
 /*
Step 3: Business Insights     
These insights help banks improve customer service and prevent fraud. 
*/
   -- Big Spenders: 
-- • Customers with the highest spending can be targeted for premium offers. 

select c1.customer_id, c1.customer_fname, c1.customer_lname, sum(t1.amount) as highest_spending
from creditcard.customers c1 
inner join creditcard.credit_cards cc1
on cc1.customer_id = c1.customer_id
inner join creditcard.transactions t1
on t1.credit_card_id = cc1.credit_card_id
group by c1.customer_id, c1.customer_fname, c1.customer_lname
order by highest_spending desc
limit 10;

      -- Best Performing Banks: 
-- • Banks with the highest transactions can attract more customers. 

select cc1.bank_name, sum(t1.amount) as highest_transaction
from creditcard.credit_cards cc1
inner join creditcard.transactions t1
on t1.credit_card_id = cc1.credit_card_id
group by cc1.bank_name
order by highest_transaction desc
limit 5;

             -- Seasonal Spending Trends: 
-- • Identifying peak spending times can help in marketing and promotions.

select dayname(t1.transaction_date) as days, 
sum(t1.amount) as total_spending
from creditcard.transactions t1
group by dayname(t1.transaction_date)
order by total_spending desc;






