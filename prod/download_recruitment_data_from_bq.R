
#' Wrapper around bq_table_download
#'
#' @description
#' This function downloads a bq_table and reduces the automatically chosen page
#' size if the download fails.
#'
#' @param .bq_table A bq_table object as provided by bq_project_query
#' @param .page_size Integer: Page size argument for downloading data
#' @param .quiet Flag if function should send messages. FALSE necessary for
#' reducing page_size
#' @param .tries Integer: Amount of times the tryCatch should reduce page_size
#'
#' @return
#' A `tibble` object containing the requested data from BigQuery

bq_download_retry <- function(.bq_table,
                              .page_size,
                              .bigint="integer64",
                              .quiet = FALSE,
                              .tries = 4) {
  results <- NULL
  try <- 1
  
  while(is.null(results) & try < .tries) {
    tryCatch(
      {
        logs <- ""
        # WithCallingHandlers can manage Errors/Messages displayed by code. Is used
        # here to capturing the messages displayed by the function
        withCallingHandlers(
          {
            try <- try + 1
            results <- bigrquery::bq_table_download(
              x         = .bq_table,
              bigint    = .bigint,
              page_size = .page_size,
              quiet     = .quiet
            )
          },
          message = function(msg) {
            # <<- (Super assignment operator) used as logs need to be used in different
            # environment
            logs <<- paste(logs, msg)
          }
        )
      },
      error = function(err) {
        .page_size <<- stringr::str_extract(
          stringr::str_flatten(logs),
          "(?<=\\(up\\sto\\)\\s)\\d+[:punct:]?\\d+"
        ) %>%
          stringr::str_replace("[:punct:]", "") %>%
          as.integer() %>%
          "*"(0.5) %>%
          round()
        
        message("Download failed: Page size will be reduced! \n", err)
        message("Start try ", try, ". Page size set to ", .page_size, ".")
      }
    )
  }
  
  return(results)
}

download_recruitment_data_from_bq <- function() {
  project <- "nih-nci-dceg-connect-prod-6d04"
  billing <-
    "nih-nci-dceg-connect-prod-6d04" ##project and billing should be consistent
  
  recr_var <-
    bq_project_query(project, query = "SELECT * FROM  `nih-nci-dceg-connect-prod-6d04.FlatConnect`.INFORMATION_SCHEMA.COLUMN_FIELD_PATHS WHERE table_name='participants_JP'")
  recrvar <-
    bigrquery::bq_table_download(recr_var, bigint = "integer64")
  recrvar_d <- recrvar[grepl("d_", recrvar$column_name), ]
  recrvar$last.CID <-
    ifelse(
      grepl("D_", recrvar$field_path),
      substring(sapply(
        strsplit(recrvar$field_path, "D_"), tail, 1
      ), 1, 9),
      ifelse(grepl("d_", recrvar$field_path), substring(sapply(
        strsplit(recrvar$field_path, "d_"), tail, 1
      ), 1, 9), NA)
    )
  
  
  pii_cid <- y$conceptId.3[which(y$PII == "Yes")]
  recrvar_pii <-
    recrvar$column_name[which(recrvar$last.CID %in% pii_cid)]
  
  nvar = floor((length(recrvar_d$column_name)) / 8) ##to define the number of variables in each sql extract from GCP
  nvar
  
  # Start column for each split data frame
  start = seq(1, length(recrvar_d$column_name), nvar)
  end <- length(recrvar_d$column_name)
  
  recrbq <- list()
  
  for (i in (1:length(start)))  {
    select <-
      paste(recrvar_d$column_name[start[i]:(min(start[i] + nvar - 1, end))], collapse =
              ",")
    tmp <-
      eval(parse(
        text = paste(
          "bq_project_query(project, query=\"SELECT token,Connect_ID,",
          select,
          "FROM  `nih-nci-dceg-connect-prod-6d04.FlatConnect.participants_JP` Where d_512820379 != '180583933' or d_821247024='197316935' \")",
          sep = " "
        )
      ))
    
    # recrbq[[i]] <- bq_table_download(tmp, bigint="integer64")
    print(paste0("Downloading column group ", i, " of ", length(start)))
    page_size <- 12
    recrbq[[i]] <-
      bq_download_retry(tmp, page_size, .bigint = "integer64")
  }
  
  recr_noinact_wl <-
    recrbq %>% reduce(inner_join, by = c("token", "Connect_ID"))
}

data <- download_recruitment_data_from_bq()
print("Recruitment data has been successfully downloaded")
saveRDS(data, file="data.RDS")
data <- readRDS("data.RDS")
