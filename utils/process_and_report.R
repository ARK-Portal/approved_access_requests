

## Setup
suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(ggplot2)
  library(lubridate)
  library(glue)
})

# read in catalog of all previously scraped approved requests
fid <- "all_approved_requests.csv"
all_approved <- read.csv(fid, check.names = FALSE)
all_approved$date <- paste(all_approved$month_str, all_approved$year)

today_date <- today()
last_month <- today_date - months(1)
last_month_str <- month(ymd(last_month), label = TRUE, abbr = FALSE)
filter_date <- paste(month(last_month, label = TRUE, abbr = TRUE), year(last_month))

# read in report log
report_log <- scan("approved_requests.monthly_report.log", what = "character", sep = "\n", quiet = TRUE)
session_log <- c("--------------", 
                 glue("log date: {Sys.time()}"))


# format info of interest into df
results <- read.csv("temp_results.csv", check.names = FALSE)
results$Institution <- str_replace(results$Institution, "BIDMC", "Beth Israel Deaconess Medical Center")
results$Institution <- str_remove(results$Institution, 
                                  "Division of Rheumatology and Immunology, Department of Internal Medicine, ")
results <- mutate(results,
                  year = year(ymd_hms(Datetime)),
                  month_str = month(ymd_hms(Datetime), label = TRUE, abbr = TRUE), 
                  month_int = month(ymd_hms(Datetime)))
results$Approved_Date <- unlist(purrr::map(results$Datetime, function(x){
  out <- paste(c(month(ymd_hms(x)), 
                 day(ymd_hms(x)), 
                 year(ymd_hms(x))),
               collapse = "/")
}))
results$date <- paste(results$month_str, results$year)

results <- bind_rows(all_approved, results) %>% unique()
n <- nrow(unique(select(results, `Project Lead`, Institution)))
session_log <- c(session_log, 
                 glue("{n} total (unique) access requests have been approved for the ARK Portal"))

# assess renewed DUCs
renewed_DUC <- select(results, `Project Lead`, Institution, date) %>% unique() %>%
  group_by(`Project Lead`, Institution) %>% tidyr::nest()
test <- unlist(lapply(renewed_DUC$data, nrow))
idx <- which(test > 1)
renewed_DUC <- renewed_DUC[idx, ]
renewed_DUC <- tidyr::unnest(renewed_DUC, cols = c(data))

session_log <- c(session_log,
                 glue("{length(idx)} access requests have been renewed >1 time."))

# measure stats for the last complete month
n <- filter(results, date == filter_date) %>% select(`Project Lead`, Institution) %>% unique() %>% nrow()
y <- filter(renewed_DUC, date == filter_date) %>% nrow()
session_log <- c(session_log, glue("In {last_month_str} {year(last_month)}, there were {n-y} new access requests approved and {y} that were renewed."))

# Summarize and viz extracted data up to last complete month
df <- filter(results, mdy(Approved_Date) < ym(format(today_date, "%Y-%m")))
#df$date <- paste(df$month_str, df$year)
df <- select(df, `Project Lead`, Institution, month_int, year, date) %>% unique() %>% group_by(month_int, year, date) %>% tidyr::nest()
df$count <- unlist(purrr::map(df$data, nrow))
df <- arrange(df, year, month_int)
df$date <- forcats::fct_inorder(df$date)
df <- ungroup(df)

## Create Bargraph
df$year <- as.character(df$year)
#yrcols <- c("grey85", "grey40", "black")
yrcols <- rev(pals::ocean.gray(n = length(unique(df$year))))
yrcols[1] <- "grey85"
names(yrcols) <- unique(df$year)

p <- ggplot(df, aes(x = date, y = count, fill = year)) +
  geom_col() + theme_minimal() +
  scale_fill_manual(values = yrcols) +
  theme(text = element_text(size = 8),
        axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1, size = 6), 
        title = element_text(size = 10)) +
  ggtitle("ARK Portal Approved Access Requests")

w = nrow(df)*50
fid <- "ARK Portal Approved Access Requests.png"
png(fid, width = w, height = 750, res = 250)
print(p)
invisible(dev.off())

# reporting
report_log <- c(session_log, report_log)
fid <- "approved_requests.monthly_report.log"
writeLines(report_log, fid, sep = "\n")

out_message <- paste(session_log, collapse = "\n")
message(out_message)
message("Scrape completed!")

## END