# Dockerfile

FROM rocker/tidyverse:latest

# Set the correct path for xelatex
ENV PATH="$PATH:/root/bin:/usr/local/lib"
# Message daniel on gitter when this doesn't work

# Install tinytex linux dependencies, pandoc, and rmarkdown
# Reference: https://github.com/csdaw/rmarkdown-tinytex/blob/master/Dockerfile
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    wget \
    graphviz \ 
    imagemagick \
    perl && \
    /rocker_scripts/install_pandoc.sh && \
    install2.r rmarkdown 

# Install tinytex
# RUN Rscript -e 'tinytex::install_tinytex()'
RUN Rscript -e 'tinytex::install_tinytex(repository = "illinois")'

# Install R libraries
RUN install2.r --error plumber gridExtra scales boxr bigrquery dplyr \
               epiDisplay lubridate tidyverse knitr gtsummary tidyr \
               googleCloudStorageR data.table reshape listr ggplot2 \
               RColorBrewer stringr plyr janitor expss magrittr arsenal rio \
               RCurl finalfit sqldf gmodels patchwork ggpubr \
               lubridate jsonlite hms magick DBI ggrepel 
              

# These libraries might not be available from install2.R so use CRAN
RUN R -e "install.packages(c('gt', 'vtable', 'pdftools'), dependencies=TRUE, repos='http://cran.rstudio.com/')"

# When I try to use kable extra with a normal installation from CRAN or install2.r
# I get the error:
# Error: package or namespace load failed for 'kableExtra':
# .onLoad failed in loadNamespace() for 'kableExtra', details:
#  call: !is.null(rmarkdown::metadata$output) && rmarkdown::metadata$output %in% 
#  error: 'length = 2' in coercion to 'logical(1)'
# The solution is to install a patched version from github
# https://github.com/haozhu233/kableExtra/issues/750
RUN R -e "devtools::install_github('kupietz/kableExtra')"

# Copy R code to directory in instance
COPY ["./ccc_weekly_metrics_api.R", "./ccc_weekly_metrics_api.R"]
COPY ["./Consolidated_Weekly_Report_4Pipeline_BQupdated_06082023.Rmd", "./Consolidated_Weekly_Report_4Pipeline_BQupdated_06082023.Rmd"]
#COPY ["./consolidated_weekly_report.Rmd", "./consolidated_weekly_report.Rmd"]
#COPY ["./ccc_weekly_metrics.Rmd", "./ccc_weekly_metrics.Rmd"]
COPY ["./download_recruitment_data_from_bq.R", "./download_recruitment_data_from_bq.R"]

# Run R code
ENTRYPOINT ["R", "-e","pr <- plumber::plumb('ccc_weekly_metrics_api.R'); pr$run(host='0.0.0.0', port=as.numeric(Sys.getenv('PORT')))"]
