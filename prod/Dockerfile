# Dockerfile

FROM rocker/tidyverse:latest

# Install tinytex linux dependencies, pandoc, and rmarkdown
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    wget \
    graphviz \
    perl && \
    /rocker_scripts/install_pandoc.sh 

# Install R libraries
RUN install2.r --error rmarkdown plumber gridExtra scales boxr bigrquery dplyr \
               epiDisplay lubridate tidyverse knitr gtsummary tidyr tinytex \
               googleCloudStorageR data.table reshape listr ggplot2 \
               RColorBrewer stringr plyr janitor expss magrittr arsenal rio \
               RCurl finalfit sqldf gmodels patchwork ggpubr 

# These libraries might not be available from install2.R so use CRAN
RUN R -e "install.packages(c('gt', 'kableExtra','vtable', 'pdftools'), dependencies=TRUE, repos='http://cran.rstudio.com/')"

# Install tinytex
RUN Rscript -e 'tinytex::install_tinytex()'

# Copy R code to directory in instance
COPY ["./ccc_weekly_metrics_api.R", "./ccc_weekly_metrics_api.R"]
COPY ["./ccc_weekly_metrics.Rmd", "./ccc_weekly_metrics.Rmd"]

# Run R code
ENTRYPOINT ["R", "-e","pr <- plumber::plumb('ccc_weekly_metrics_api.R'); pr$run(host='0.0.0.0', port=as.numeric(Sys.getenv('PORT')))"]
