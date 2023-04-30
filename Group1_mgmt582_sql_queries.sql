set foreign_key_checks = 0;

#Customers Table - Change data type to varchar and add primary key
alter table customers modify column cust_id varchar(255);
alter table customers add primary key(cust_id);

#Customer Phone Table - Change datatype and add primary and foreign key constraints
alter table customer_phone modify column cust_id varchar(255), modify column phone varchar(255);
alter table customer_phone add primary key(cust_id, phone);
alter table customer_phone add foreign key (cust_id) references customers(cust_id);

#Employee Table - Change datatype and add primary key constraint
alter table employee modify column emp_id varchar(255);
alter table employee add primary key (emp_id);

#Employee_Phone Table - Change datatype and add key constraints
delete from employee_phone where emp_id = "emp_id";
alter table employee_phone modify column emp_id varchar(255), modify column phone varchar(255);
alter table employee_phone add primary key(emp_id, phone);
alter table employee_phone add foreign key (emp_id) references employee(emp_id);

#Consumables Table - Change datatype and add primary key constraint
alter table consumables modify column consum_id varchar(255), modify column unit_c_price double;
alter table consumables add primary key (consum_id);

#Contract_Employee Table - Change datatype and add primary key constraint
alter table contract_employee modify column emp_id varchar(255);
alter table contract_employee add primary key (emp_id);

#Fulltime_Employee Table - Change datatype and add primary key constraint
alter table fulltime_employee modify column emp_id varchar(255);
alter table fulltime_employee add primary key (emp_id);

#Service Table - Change datatype and add primary key constraint
alter table services modify column service_id varchar(255);
alter table services add primary key (service_id);

#Vehicle Table - Change datatype and add primary key constraint
alter table vehicle modify column vin varchar(255);
alter table vehicle add primary key (vin);

#Jobs Table - Update datetime, change datatype and add key constraints
update jobs set start_datetime = STR_TO_DATE(start_datetime, "%m/%d/%Y %H:%i:%s");
update jobs set end_datetime = STR_TO_DATE(end_datetime, "%m/%d/%Y %H:%i:%s");
alter table jobs modify column job_id varchar(255), modify column vin varchar(255), modify column cust_id varchar(255);
alter table jobs add primary key(job_id);
alter table jobs add foreign key(vin) references vehicles(vin), add foreign key (cust_id) references customers(cust_id);

#Job_Services Table - Change datatype and add key constraints
alter table job_services modify column job_id varchar(255), modify column service_id varchar(255);
alter table job_services add primary key(job_id, service_id);
alter table job_services add foreign key(job_id) references jobs(job_id), add foreign key(service_id) references services(service_id);

#Invoice Table - Change datatype and add key constraints
alter table invoice modify column inv_no varchar(255), modify column job_id varchar(255), modify column inv_amt_total double;
alter table invoice add primary key(inv_no);
alter table invoice add foreign key(job_id) references jobs(job_id);
update invoice set inv_date = STR_TO_DATE(inv_date, "%m/%d/%Y %H:%i:%s");

#Employee_Job Table - Change datatype and add key constraints
delete from employee_job where emp_id = "emp_id";
alter table employee_job modify column job_id varchar(255), modify column emp_id varchar(255);
alter table employee_job add primary key(job_id, emp_id);
alter table employee_job add foreign key(job_id) references jobs(job_id), add foreign key(emp_id) references employee(emp_id);

#Job_Consumables Table - Change datatype and add key constraints
alter table job_consumables modify column job_id varchar(255), modify column consum_id varchar(255);
alter table job_consumables add primary key(job_id, consum_id);
alter table job_consumables add foreign key(job_id) references jobs(job_id), add foreign key(consum_id) references consumables(consum_id);

set foreign_key_checks = 1;

#Queries:
#1. Most popular service offered
select category, services.name, count(services.service_id) as popular_service from job_services inner join services on job_services.service_id = services.service_id group by category, services.name order by popular_service desc;

#2. Most popular service type offered
select category, count(services.service_id) as popular_service from job_services inner join services on job_services.service_id = services.service_id group by category order by popular_service desc;

#3. Most frequent customer
select c.fname, c.lname, count(c.cust_id) as frequent_customer from jobs as j inner join vehicle as v on j.vin = v.vin inner join customers as c on c.cust_id = j.cust_id group by c.cust_id order by frequent_customer desc limit 5;

#4. Number of jobs that are open longer than average times for a job
select count(job_id) from jobs where status = "Open" and datediff((select max(end_datetime) from jobs), start_datetime) > (select avg(datediff(jobs.end_datetime, jobs.start_datetime)) from jobs);

#5. Cost per hour for every service
select service_id, category, name, round(sum(base_rate)/sum(service_hours),2) as cost_hr
from
(select s.service_id, service_hours, category, name, base_rate
from
job_services as js
inner join
services as s
on s.service_id = js.service_id) as a
group by service_id, category, name
order by cost_hr desc
limit 10;

#6. Vehicle Make Analysis
SELECT make, COUNT(make) As Numvehicles, /*Count frequency of cars with each make*/
count(make)*100/(SELECT count(*) FROM jobs) as percent_vehicles,
sum(inv_amt_total)*100/(SELECT sum(inv_amt_total) FROM invoice) as percent_invoices,
sum(inv_amt_total) as sum_invoices,
avg(inv_amt_total) as avg_invoices,
max(inv_amt_total) as max_invoices
FROM (select a.job_id, a.vin,
a.end_datetime,
a.start_datetime,
a.times_reopened,
b.inv_discount,
b.inv_amt_total,
b.service_miles,
b.inv_tax_total,
c.make,
c.model,
c.year
from jobs a
left join invoice b
on a.job_id=b.job_id
left join vehicle c
on a.vin=c.vin) as ab
GROUP BY make
order by avg_invoices desc;

#7. Sales by Car Type - 7: Majority share (54.8667%)
select make, count(model)*100/(select count(model) as total
from
jobs as j
inner join
vehicle as v
on
v.vin = j.vin) as make_share
from
jobs as j
inner join
vehicle as v
on
v.vin = j.vin
group by make
order by make_share desc
limit 7;

#8. More individuals have newer cars
select year, count(model)*100/(select count(model) as total
from
jobs as j
inner join
vehicle as v
on
v.vin = j.vin) as year_share
from
jobs as j
inner join
vehicle as v
on
v.vin = j.vin
group by year
order by year_share desc;

#9. Car Makes that have jobs frequently reopened
select a.make, b.make_reopen*100/a.make_share as perc_reopen from
(select make, count(model) as make_share
from
jobs as j
inner join
vehicle as v
on
v.vin = j.vin
group by make) as a
inner join
(select make, count(model) as make_reopen
from
(select * from jobs
where times_reopened >0) as j
inner join
vehicle as v
on
v.vin = j.vin
group by make) as b
on a.make = b.make
order by perc_reopen desc
limit 5;

#10. Car Years with the highest % reopen instance.
select a.year,  b.year_reopen*100/a.year_share as perc_reopen from
(select year, count(model) as year_share
from
jobs as j
inner join
vehicle as v
on
v.vin = j.vin
group by year) as a
inner join
(select year, count(model) as year_reopen
from
(select * from jobs
where times_reopened >0) as j
inner join
vehicle as v
on
v.vin = j.vin
group by year) as b
on a.year = b.year
order by perc_reopen desc;

#11. Hours spent by Contractual and Full time employees
select type, sum(hrs_emp)/(select datediff(max(end_datetime) , min(start_datetime)) from jobs) as thours from
(select js.job_id, emp_id, type, service_hours/emp_count as hrs_emp from
(select job_id, ejc.emp_id, emp_count, type from
(select ej.job_id, emp_id, emp_count from
(select * from employee_job) as ej
inner join
(select job_id, count(emp_id) as emp_count
from employee_job
group by job_id) as ec
on ej.job_id = ec.job_id) as ejc
inner join
(select emp_id, type
from employee) as e
on e.emp_id = ejc.emp_id) as ejct
inner join
(select job_id, sum(service_hours) as service_hours
from job_services
group by job_id) as js
on ejct.job_id = js.job_id) as eh
group by type;