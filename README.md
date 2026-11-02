### **Texas Spending and the 2026 Strait of Hormuz Oil Shock**



##### **Question**



How did the closure of the Hormuz Strait in late February of 2026 affect oil and gas production and prices, and how did this affect spending in Texas counties that are oil heavy and non-oil heavy?



##### **Summary of Findings**



* The price of crude oil showed a spike in pricing after the closure of the Hormuz Straight in February of 2026. Due to this pricing shock, the gas prices at pumps in the United States also increased sharply and closely followed the price increase in crude oil.
* When looking at the effect of the increase in crude oil prices in Texas counties that are oil-heavy versus counties that are non oil-heavy, we see that the comparison counties exhibit a higher average in sales of gasoline compared to the oil-heavy counties.
* When calculating the difference-in-difference between oil-heavy and non oil-heavy counties, we get a value of -4.04. What this value represents is that the comparison counties (non oil-heavy) experienced a greater increase in average oil sales compared to the oi-heavy counties post price shock.
* These findings go against the original hypothesis that the oil-heavy counties would experience a greater increase in oil sales due to the pricing shock.
* This conclusion shows that the initial model could potentially contain mistakes. 

  * The sample of oil-heavy and comparison counties could contain one or two counties that drastically skew the data and drive the results.
  * The threshold for choosing each county such as population and oil share percentage is not strict enough, making the data non-robust.
* When correcting for driving counties such as Upton county and Reeves county, which were both oil-heavy counties that showed a drastic decrease in oil sales post shock, and replacing them with counties such as Ector and Ward, the new calculated difference-in-difference comes out to a value of 0.84. This shows that the oil-heavy counties experienced greater growth in average oil sales post shock than the comparison counties. 
* This new value is still close to zero, meaning that the growth of the oil-heavy and comparison counties are extremely similar. Future tests and corrections could include higher thresholds for population and oil share per county.



##### **Data Sources**



All data files are kept in "Raw" and listed with contents in "Source Log".



|**Data**|**Source**|**Series**|
|-|-|-|
|Brent crude, WTI crude, Henry Hub gas|FRED (from EIA)|DCOILBRENTEU, DCOILWTICO, DHHNGSP|
|Retail gasoline and diesel (U.S.)|FRED (from EIA)|GASREGW, GASDESW|
|U.S. and Texas crude production, gas gross withdrawals|EIA|MCRFPUS1, MCRFPTX1, N9010US2, N9010TX2|
|Local sales tax allocations (county)|Texas Comptroller|Sales Tax Allocation, City-County file|
|Employment by county and industry|BLS QCEW|NAICS 211, 213111, 213112, and all-industries total|





##### **Parameters**



* Event start: March 2, 2026.
* Event window: March 2 to August 31, 2026.
* Baseline period: March 2025 to February 2026.
* Comparison method: year-over-year growth in each month.
* Timing adjustments: Sales tax allocations lag actual sales so allocation months are shifted back by one month.
* Oil-heavy counties: Texas counties where oil and gas employment share is at least 5%.
* Comparison group: Non-oil heavy counties where oil share is under 1%.



##### **Method**



1. Raw data files are imported into SQLite and used to create staging tables for each respective file where they are then manipulated into four final tables (prices, production, sales\_tax, and areas).
2. Once each of the tables are created and finished, take the county totals and create views that provide monthly sales, year-over-year sales growth, average monthly pricing, and the difference-in-difference between the oil-heavy and comparison counties.
3. Export the data from step 2 and create their respective pivot tables and charts as well as a summary describing each result. Using these results and the difference-in-difference, make an overall conclusion and compare the result to the original hypothesis.
4. Give limitations and possible weak areas with data collection. Then revise queries with new method and create the new graphs and calculate new difference-in-difference.
5. Compare new result to old result.



##### **Results**



|Specification|Estimate (%)|Set in Advance?|
|-|-|-|
|DiD (original)|-4.04|Yes|
|DiD (New Oil-Heavy Counties)|0.84|No|



##### **Limitations**



1. Numbers are not adjusted for inflation.
2. County group used for analysis is small, so data can easily be skewed or favored by one or two counties.
3. Thresholds in oil share percentage and employment may need to be increased for a stronger set of counties when calculating for the difference-in-difference.
4. The range for this project was set for a six-month period and covers an ongoing issue with no defined end date. While the results may be accurate for this six-month period, they may not represent the issue as a whole or be accurate in the future.



##### **SQL File Contents**



|**File**|**Contents**|
|-|-|
|Raw|Raw and unbothered data collected from online databases|
|SQL|Executable scripts|
|Database|Entire project database including tables and views|
|Excel|Analysis and exported CSV files|



##### **Reproduce**



1. **Download files from Raw.**
2. **Import into DB Browser for SQLite and create a staging table for each.**
3. **From the SQL file, run each script to create the tables and views.**
4. **Export these tables from SQL into Excel along with their respective views.**

