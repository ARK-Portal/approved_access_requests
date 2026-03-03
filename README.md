# Approved Access Requests

This repo is home to code that scrapes the ARK Portal Data Access page to catalog 
and track all approved access requests. This is used because the team does 
not have access to the ACT log and Snowflake tables that contain this information.

# Reporting

`utils/scrape_approved_access_page.R` is executed in the parent directory of the 
repo and reads in `all_approved_requests.csv` to catalog new approved access requests 
and track renewals. 

`approved_requests.monthly_report.log` tracks the full history of report logs 
and is also read in by `utils/scrape_approved_access_page.R`.

`ARK Portal Approved Access Requests.png` is updated with each execution of 
`utils/scrape_approved_access_page.R` to have a readily accessible plot that can 
be distributed as needed.

<img src="./ARK Portal Approved Access Requests.png">

# Analyses

End-of-year reporting and additional analyses are saved under `analyses/`.