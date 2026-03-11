# Approved Access Requests

This repo is home to code that scrapes the [ARK Portal Data Access](https://arkportal.synapse.org/Data%20Access) 
page to catalog and track all approved access requests. This is used because the team does 
not have access to the ACT log and Snowflake tables that contain this information.

# Files

- **utils/scrape_approved_access_page.R**: R script that scrapes the ARK Portal Data Access page
- **all_approved_requests.csv**: CSV file that contains the full history of approved access requests scraped by `scrape_approved_access_page.R`
  - includes three main columns: project lead, institution, and approval date
- **approved_requests.monthly_report.log**: Log file that contains the full history of logs reported from `scrape_approved_access_page.R`

# Reporting

Use `approved_requests.monthly_report.log` to update the AMP AIM Steering Committee Monthly reporting slide deck.

`ARK Portal Approved Access Requests.png` is updated with each execution of 
`utils/scrape_approved_access_page.R` to have a readily accessible plot that can 
be distributed as needed.

<img src="./ARK Portal Approved Access Requests.png">

# Process

The monthly-reporting-cron GH Actions workflow is configured to run automatically 
on the **second day of each month**. This workflow can also be manually triggered to 
run on demand, BUT note that the log report and the png will only report up to the 
last complete month. 

This workflow executes `utils/scrape_approved_access_page.R` which reads in 
`all_approved_requests.csv` and `approved_requests.monthly_report.log` and updates 
each accordingly.

For local execution, run `Rscript utils/scrape_approved_access_page.R` from the root of this repo.

# Analyses

End-of-year reporting and additional analyses are saved under `analyses/`.