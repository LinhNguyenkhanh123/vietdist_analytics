# Sales Performance Analysis Dashboard

> A Power BI dashboard for an FMCG distributor that tracks revenue against changing sales plans and analyzes customers, products and sales team performance.

---

## 1. Project Overview

This dashboard helps sales managers answer 4 questions:

- Are we hitting our revenue targets, and how does revenue change month by month?
- Which sales reps, teams and regions are ahead or behind their targets?
- Which customers and products bring in the most revenue?
- Are we keeping our customers, and how healthy is the sales team?

The data covers one full year (2024) for a distribution business selling beverages, food, household products and personal care products to supermarkets, convenience stores, canteens, restaurants, online sellers and grocery stores across three regions (North, Central, South).

**Special features**
- **Plan versions:** Sales targets were revised during the year (plan v1 for Jan–Jun, plan v2 for Jul–Dec). Users can compare actual revenue against any plan version, or let the dashboard apply the latest plan automatically.
- **Employee history:** Each employee's position, team and region changes are tracked with effective dates, so performance can be viewed by position, tenure and age.

### Data Model

| Type | Tables |
|---|---|
| Fact | Orders/sales, `fact_targets` (target revenue by plan version and effective dates), returns |
| Dimension | `dim_date`, `dim_employees` (position, team, region, effective from/to), `dim_customers` (customer type, region, province), `dim_products` (category, sub-category, product) |
| Supporting | `_Measures` and selector tables (Plan Version, Revenue Metrics, Sales Breakdown, Revenue/Metrics Breakdown) |

**Key measures:** Actual Revenue, Target Revenue, Revenue Achievement %, Forecast Revenue, Forecast Achievement %, MoM Growth, Revenue Variance, Active / New / Returning / Churned Customers, Orders Count, AOV, Quantity Sold, Return Requests.

---

## 2. Report Structure

| Page | What it shows |
|---|---|
| **Sales Performance Overview** | Headline KPIs (Actual Revenue, Target, Achievement, Forecast, Active Customers), monthly actual vs. target with MoM growth, active customers vs. revenue, and revenue and achievement by employee |
| **Sales Performance by Plan Version** | Actual vs. target for the selected plan version, applied plan version by month, average monthly target, and achievement and variance by employee |
| **Customers & Products Analysis** | Customer and order KPIs, revenue by category, top 5 sub-categories, bottom 5 products by quantity, revenue by customer type and region, customer trend, and top 10 customers |
| **Employee Journey & Performance** | Revenue by position, tenure or age, contribution by region and team, orders and returns trend, and employee history table |
| **Drill-through & tooltip pages** | Customer Revenue Details, Subcategory Details, Category Details, Plan History and Career Stage |

---

## 3. Main Visualizations
- Sales Performance Overview
  - KPI Cards <img width="1058" height="147" alt="image" src="https://github.com/user-attachments/assets/0e986854-64a7-423c-a053-f9ea6c4d9ef9" />
  - Trend of key metrics <img width="1058" height="266" alt="image" src="https://github.com/user-attachments/assets/c913bee8-09bf-4501-aeef-be856cfecc01" />
  - Revenue Achievement <img width="1056" height="253" alt="image" src="https://github.com/user-attachments/assets/9efc6826-7045-4987-a9d2-167ce57089ad" />
- Sales performance by Plan version
  - Key metrics by Plan version <img width="1067" height="278" alt="image" src="https://github.com/user-attachments/assets/90c7dd6f-4440-4fac-97fd-7b13a742f75a" />
  - Details of Plan versions <img width="1064" height="317" alt="image" src="https://github.com/user-attachments/assets/00033c82-6ce4-45eb-ac61-7187dfeebade" />
- Customers & Products Analysis
  - Product Revenue Breakdown & Ranking <img width="1077" height="254" alt="image" src="https://github.com/user-attachments/assets/7224cbde-bc0e-4a74-8101-36702bf0b18a" />
  - Customer Trend, Revenue Breakdown and Ranking <img width="1074" height="272" alt="image" src="https://github.com/user-attachments/assets/1f9a8f96-7137-47d0-beee-c642aee4b828" />
  - Product Revenue Breakdown (tooltip) <img width="794" height="395" alt="image" src="https://github.com/user-attachments/assets/55854eeb-ec85-4147-ba76-7a125369886d" />
  - Subcategory Details drill-through <img width="1306" height="665" alt="image" src="https://github.com/user-attachments/assets/5659cf3c-fbba-4be1-b8c1-0440a35686c0" />
  - Customer Details drill-through <img width="1312" height="561" alt="image" src="https://github.com/user-attachments/assets/380837a2-8d76-47f9-8e25-f6658cc47daa" />
- Employee Journey & Performance
  - Key metrics Breakdown by Demographic characteristics & Regions <img width="1108" height="296" alt="image" src="https://github.com/user-attachments/assets/e0c1a769-496f-42f8-8034-0f69bff4c319" />
  - Employee Details & Journey <br> <img width="728" height="618" alt="image" src="https://github.com/user-attachments/assets/7478eeaf-bbec-4265-9f40-b8f95e982735" />

---

## 4. Main Findings

### Target achievement
1. **Revenue reached only about 50% of the target.** Actual revenue was **138.72bn** against a **280.00bn** target, so achievement was **49.54%**.
2. **The gap is structural, not seasonal.** Monthly achievement stays around **48–52%** all year, and actual revenue is below target in every month.
3. **Revenue has a clear seasonal pattern.** There is a sharp dip in **February** (about 8bn), a rebound in March, and the highest revenue in **December** (about 15bn). The February dip may be linked to the Tet holiday.
4. **Revenue and Orders follows active customers.** Monthly active customers (about 900–1,200) rise and fall together with revenue, so customer activity is the main driver. However, Revenue Achievement shows slightly different pattern, suggesting that the sales force cannot utilize the increasing number of customer.

### Sales team
1. **A few reps far exceed their targets.** Ngô Minh An (**340.5%**, 11.19bn) and Phạm Thanh Bình (**336.5%**, 8.96bn) lead, and together bring in about **14.5%** of total revenue.
2. **Individual targets look similar across reps** (about 2.5–3.6bn each), while actual revenue ranges from about 2bn to 11bn. Targets may not reflect each rep's territory or customer potential.
3. **Senior Sales Representatives bring in 60% of revenue** (84bn) and Sales Representatives 39% (54bn).
4. **Revenue is concentrated in mid-tenure and younger reps.** Reps with **5–10 years** of tenure generate about 77% of revenue, and the **25–34** age group about 68%. Almost no revenue comes from the 1–3 year and 10+ year tenure groups.
5. **Central Region leads.** **Team Trung 1** alone generates **34.37bn** (about 25% of revenue and 25% of orders), with 395 active customers, compared with about 170–215 active customers in teams such as Team Nam 3, Team Nam 4 and Team Bắc 2.

### Customers
1. **The customer base is about 2,000 customers, with about 1,800 active in the year** (see Data Notes).
2. **Sales are well spread across customer types.** Supermarkets lead (**30.46bn**, about 22%), followed by convenience stores (23.51bn), canteens (23.07bn), restaurants (22.13bn), online sellers (20.91bn) and grocery stores (19.72bn).
3. **There is some customer concentration.** The top 10 customers bring in about **27.6bn (about 20%)** of revenue, and the top 2 supermarkets (Hồ Minh Lan 8.62bn and Ngô Thanh Lộc 5.64bn) alone account for about 10%.
4. **Average order value is about 2.9M** across **48.04K orders**.

### Products
1. **Beverages lead.** Beverages bring in **52bn (about 37%)**, followed by food (38bn), household (25bn) and personal care (25bn).
2. **The top 5 sub-categories generate about 46.5% of revenue:** bottled drinks (17.08bn), energy drinks (14.47bn), instant porridge (12.47bn), milk (11.57bn) and shampoo (8.97bn).
3. **Sales volume is very even across products.** Even the 5 lowest-selling products (including premium spices and family-pack detergent) sell about 66–67K units, close to the average of about 71K per product (92 products). Differences in revenue therefore come mostly from price and product mix, not volume.

### Returns
**There are about 3.7K return requests, roughly 7.6% of orders**, which is high enough to deserve attention.

---

## 4. Main Recommendations

1. **Review the sales target.** Achievement has stayed near 50% all year, so check whether 280bn is realistic. Set targets by territory and customer potential instead of near-equal targets per rep, and use a rolling forecast.
2. **Coach reps below target.** Learn from the best reps (Ngô Minh An, Phạm Thanh Bình) by sharing their account plans and selling methods, and give targeted coaching to reps at 70–90%. Avoid depending on a few star performers.
3. **Plan for seasonality.** Prepare stock, promotions and staffing for the February dip and the December peak, and set monthly targets (such as January's high target) that match real demand patterns.
4. **Protect and grow key accounts.** Create account plans and backup contacts for the top 10 customers, especially the two largest supermarkets. At the same time, grow smaller segments such as grocery stores and online sellers to reduce concentration.
5. **Keep beverages strong and lift other categories.** Secure supply and promotions for bottled and energy drinks. Because volumes are even across products, grow revenue through better pricing and mix (for example, premium products and cross-selling household and personal care items).
6. **Reduce returns.** Investigate which products, customer types and teams drive return requests, then fix product quality, delivery or order accuracy.
7. **Spread good practice across teams.** Study what Team Trung 1 does well (customer coverage and order volume) and apply it to teams in the South and North, and review how customers are allocated between teams.
8. **Build the talent pipeline.** Revenue relies on mid-tenure and younger reps, so plan for junior onboarding, mentoring and retention of experienced reps.
