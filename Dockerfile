# Dockerfile

FROM rocker/tidyverse:latest

# Install tinytex linux dependencies, pandoc, and rmarkdown
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    wget \
    graphviz \
    perl && \
    /rocker_scripts/install_pandoc.sh && \
    install2.r rmarkdown

# Install tinytex
RUN Rscript -e 'tinytex::install_tinytex()'

# Install R libraries
RUN install2.r --error plumber gridExtra scales boxr bigrquery dplyr gmodels \
               epiDisplay lubridate tidyverse knitr gtsummary tidyr tinytex \
               googleCloudStorageR data.table reshape listr ggplot2 ggpubr \
               RColorBrewer stringr plyr rmarkdown janitor finalfit expss \
               magrittr arsenal patchwork rio sqldf 

# These libraries might not be available from install2.R so use CRAN
RUN R -e "install.packages(c('gt', 'kableExtra','vtable', 'summarytools', 'magick', 'pdftools'), dependencies=TRUE, repos='http://cran.rstudio.com/')"

# Copy R code to directory in instance
COPY ["./ccc_weekly_metrics_api.R", "./ccc_weekly_metrics_api.R"]
COPY ["./ccc_weekly_metrics.Rmd", "./ccc_weekly_metrics.Rmd"]

# Run R code
ENTRYPOINT ["R", "-e","pr <- plumber::plumb('ccc_weekly_metrics_api.R'); pr$run(host='0.0.0.0', port=as.numeric(Sys.getenv('PORT')))"]
