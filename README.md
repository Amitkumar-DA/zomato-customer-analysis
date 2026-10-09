<h1 align="center">🍽️ Zomato Customer Analytics</h1>

<p align="center">
  <b>Why is growth stalling when customer sign-ups keep rising? 🤔</b><br>
  A SQL case study on 50,000 orders, 4,999 customers and 200 restaurants.
</p>

<p align="center">
  <img alt="SQL Server" src="https://img.shields.io/badge/SQL%20Server-T--SQL-CC2927?logo=microsoftsqlserver&logoColor=white">
  <img alt="Python" src="https://img.shields.io/badge/Python-pandas-3776AB?logo=python&logoColor=white">
  <img alt="Questions" src="https://img.shields.io/badge/Questions-27-F0B04A">
  <img alt="Orders" src="https://img.shields.io/badge/Orders-50%2C000-2EA44F">
  <img alt="Period" src="https://img.shields.io/badge/Period-Jan%202024%20→%20Apr%202026-6E7781">
</p>

---

## 🧭 Quick navigation

| | | |
|---|---|---|
| [🎯 Objective](#-objective) | [🗂️ Dataset](#️-dataset) | [🛠️ Tech stack](#️-tech-stack) |
| [🪜 Approach](#-approach) | [💡 Key insights](#-key-insights) | [🏁 Conclusion](#-conclusion) |
| [⚠️ Notes](#️-notes-and-limitations) | [📁 Repo layout](#-suggested-repository-layout) | |

> 👆 Click a link to jump. 👇 Click any **▶ arrow** below to expand a section.

---

## 🎯 Objective

Zomato's leadership sees the number of registered customers growing, but:

- 📉 revenue growth is inconsistent
- 🔁 customer retention is slipping
- 🏪 some restaurant partners underperform

As the data analyst, the goal is to answer **27 business questions** and turn the results into actions.

| Area | Questions |
|---|:---:|
| 💰 Revenue Analysis | 5 |
| 👥 Customer Analysis | 4 |
| 🏪 Restaurant Performance | 5 |
| 🎟️ Coupon Analysis | 4 |
| ❌ Cancellation & Refund Analysis | 4 |
| 🚪 Customer Churn Analysis | 5 |

---

## 🗂️ Dataset

<details>
<summary><b>▶ Three CSV files, linked by ID</b></summary>

<br>

| File | Rows | Key columns |
|---|---:|---|
| 👤 `Zomato_Customers_Data.csv` | 4,999 | `Customer_id`, `Customer_name`, `City`, `Acquisition_channel`, `Signup_Time` |
| 🧾 `Zomato_Order_Data.csv` | 50,000 | `order_id`, `customer_id`, `restaurant_id`, `order_timestamp`, `order_status`, `order_amount`, `discount_amount`, `delivery_fee`, `payment_mode` |
| 🏪 `Zomato_Restaurants_Data.csv` | 200 | `restaurant_id`, `restaurant_name`, `cuisine`, `city`, `avg_rating` |

📅 Orders run from **1 Jan 2024** to **30 Apr 2026**.

| Order status | Orders |
|---|---:|
| ✅ Delivered | 29,837 |
| ❌ Cancelled | 10,095 |
| 💸 Refunded | 10,068 |

</details>

---

## 🛠️ Tech stack

| | Tool | Used for |
|---|---|---|
| 🗄️ | **SQL Server + SSMS** | Database and query tool |
| 📝 | **T-SQL** | CTEs, window functions (`ROW_NUMBER`), `CASE`, `DATETRUNC`, `DATEADD`, joins |
| 🐍 | **Python (pandas)** | Cross-checking totals, status counts and the date range |

---

## 🪜 Approach

1. 📥 **Load** the three CSVs into SQL Server and join orders to customers (`customer_id`) and restaurants (`restaurant_id`).
2. 📐 **Define the metrics**
   - 💰 **Revenue** counts delivered orders only. The revenue questions use `order_amount`; the customer, restaurant, coupon and churn questions use `order_amount - discount_amount + delivery_fee`.
   - 🚪 **Churn**: a customer has churned if their last delivered order is more than **90 days** before **30 Apr 2026**, or they have no delivered order.
3. ✍️ **Query**: write one T-SQL query for each of the 27 questions.
4. 🔍 **Validate** the results against the raw files.
5. 🚀 **Recommend**: turn the findings into actions.

<details>
<summary><b>▶ 🔎 See a sample query: churn definition</b></summary>

```sql
WITH last_order AS (
  SELECT
    customer_id,
    MAX(order_timestamp) AS last_order_date
  FROM orders
  WHERE order_status = 'Delivered'
  GROUP BY customer_id
)
SELECT
  COUNT(*) AS churned_customers
FROM customers c
LEFT JOIN last_order l
  ON c.Customer_id = l.customer_id
WHERE l.last_order_date < DATEADD(DAY, -90, '2026-04-30')
  OR l.last_order_date IS NULL;
```

</details>

<details>
<summary><b>▶ 🔎 See a sample query: total revenue</b></summary>

```sql
SELECT SUM(order_amount) AS total_revenue
FROM Orders
WHERE order_status = 'Delivered';
```

</details>

---

## 💡 Key insights

<details open>
<summary><b>▼ 💰 Revenue: flat at about ₹1M a month</b></summary>

- 💵 **₹26.86M** from delivered orders; monthly revenue stays between about ₹0.84M and ₹1.04M
- 🛒 Average order value: **₹900**
- 📱 **UPI** brings ₹13.43M, half of all revenue
- 📍 **Noida** earns the most (₹3.60M); Chennai the least (₹3.22M)

</details>

<details>
<summary><b>▶ 👥 Customers: value is spread widely</b></summary>

- 🏆 The top 20 customers bring only **1.03%** of revenue
- 💬 **WhatsApp campaigns** give the highest revenue per customer (₹5,493); Instagram Ads the lowest (₹5,280)
- 🔁 Repeat customers grow from 432 (Feb 2024) to 1,449 (Apr 2025)

</details>

<details>
<summary><b>▶ 🏪 Restaurants: rating does not drive revenue</b></summary>

- 🥇 **KFC (ID 159)** leads on both revenue (₹166.6K) and orders (185)
- 🍛 **North Indian** is the most popular cuisine (5,869 orders); Biryani the least (3,859)
- ⭐ Average revenue stays between **₹128K and ₹140K** across rating bands

</details>

<details>
<summary><b>▶ 🎟️ Coupons: they cost revenue</b></summary>

- 📊 **40.32%** of delivered orders use a coupon
- 💸 Realised revenue per order: **₹854** with a coupon vs **₹937** without
- 🏙️ Noida uses the most coupons (1,600 orders)

</details>

<details>
<summary><b>▶ ❌ Cancellations and refunds: 4 in 10 orders fail</b></summary>

- ❌ **20.19%** of orders are cancelled; 💸 **20.14%** are refunded
- 🔥 Cancellations cost **₹9.09M** of revenue
- 🚨 Worst cancelling restaurant: **Haldiram's (ID 194)** at 27.35%

</details>

<details>
<summary><b>▶ 🚪 Churn: more than half have gone quiet</b></summary>

- 👋 **53.45%** of customers (2,672 of 4,999) have churned
- 💔 They are worth **₹12.98M** of past revenue
- 📍 **Noida** has the highest churn at 55.11%; Hyderabad the lowest at 51.22%

</details>

---

## 🏁 Conclusion

> 🔑 **Fix the leaks before buying more growth.** Sign-ups are not the problem. About four in ten orders fail and more than half of customers have gone quiet, while revenue stays near ₹1M a month.

### ✅ Recommended actions

- [ ] 🚫 **Cut cancellations and refunds**: audit the highest-cancelling restaurants (25% to 27% cancelled) and set cancellation targets for partners
- [ ] 🎁 **Win back high-value churned customers** with reactivation offers, starting with the top spenders
- [ ] 🧪 **Make coupons earn their cost**: they lower realised revenue per order and their effect on retention is unproven, so test offers against a control group
- [ ] 🛡️ **Protect Noida first**: it earns the most and churns the most

---

## ⚠️ Notes and limitations

- 🔸 Restaurant question 5 ("Last 5 restaurants") has a revenue query without a `Delivered` filter, so its revenue figures count every order status.
- 🔸 The repeat-rate comparison for coupon users (99.36%) and non-coupon users (89.12%) rests on only 432 customers who never used a coupon.

---

## 📁 Suggested repository layout

```text
.
├── 📄 README.md
├── 🗂️ data/    # the three CSV files
├── 🧾 sql/     # one .sql file per analysis area
└── 📊 docs/    # case study PDF and presentation deck
```

---

## 👤 Author

✍️ Amit Kumar

<p align="center">⭐ If you find this useful, star the repo!</p>
