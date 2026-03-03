#! Rscript

parse_submission_cards <- function(card) {
  spans <- card %>%
    html_nodes("span") %>%
    html_text(trim = TRUE)
  strongs <- card %>%
    html_nodes("strong") %>%
    html_text(trim = TRUE)
  
  strongs[1:length(spans)] <- str_remove(strongs[1:length(spans)], ":")
  out <- as.data.frame(t(spans), stringsAsFactors = FALSE)
  colnames(out) <- strongs[1:length(spans)]
  
  i <- grep("accepted", strongs)
  date <- str_extract(strongs[i], "\\d{1,2}\\/\\d{1,2}\\/\\d{4}")
  out$Approved_Date <- date
  return(out)
}

# Setup

# source rmarkdown_setup.R
#source("~/Setup/rmarkdown_setup.R")

# Load libraries silently
suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(ggplot2)
  library(lubridate)
  library(glue)
  library(chromote)
  library(rvest)
})

options(chromote.headless = "new")
options(chromote.launch.echo_cmd = TRUE)
#chrm <- Chrome$new(
#    path = find_chrome(),
#    args = "--disable-gpu --headless --remote-debugging-port=9222"
#)

#chrome_args <- get_chrome_args()
#set_chrome_args(c(chrome_args, "--disable-gpu", "--headless", "--remote-debugging-port=9222"))

b <- ChromoteSession$new()

# Open a website
url <- "https://arkportal.synapse.org/Data%20Access"  # Replace with the actual URL

# Read the live HTML
live_page <- read_html_live(url)
Sys.sleep(10) # wait for the page to load

# Scroll down by 800 pixels
for (i in 1:8) {
  live_page$scroll_by(top = 12000, left = 0)
  Sys.sleep(2)  # Wait for the page to load more content
}

#live_page$view()

submission_cards <- live_page %>%
  html_nodes("[class='SubmissionInfoCard']")

keep <- seq(1, length(submission_cards), by = 2)
submission_cards <- submission_cards[keep]
results <- purrr::map(submission_cards, parse_submission_cards)
results <- bind_rows(results)

results <- mutate(results, year = year(mdy(Approved_Date)),
                  month_str = month(mdy(Approved_Date), label = TRUE, abbr = TRUE), 
                  month_int = month(mdy(Approved_Date)))
message(glue("There are {nrow(results)} total access requests that have been approved since the inception of the ARK Portal"))

df <- results
df$date <- paste(df$month_str, df$year)
df <- group_by(df, month_int, year, date) %>% tidyr::nest()
df$count <- unlist(purrr::map(df$data, nrow))
df <- arrange(df, year, month_int)
df$date <- forcats::fct_inorder(df$date)

#my_kable_table(tail(select(df, date, count)), cap = "tail of the ARK Portal approved access requests summary")

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

# Save results

#fid <- "../all_approved_requests.csv"
#write.csv(results, fid, row.names = FALSE)

# Session Details

#Print out session info
R.utils::System$getHostname(); 
sessionInfo()
