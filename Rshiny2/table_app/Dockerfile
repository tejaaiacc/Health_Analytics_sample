FROM rocker/shiny-verse

ADD data /data

COPY *.R /srv/shiny-server/
COPY shiny.config /etc/shiny-server/shiny-server.conf

#RUN R -e "install.packages('DT',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN install2.r --error DT shinydashboard tidyverse

EXPOSE 8081

USER shiny

# avoid s6 initialization
# see https://github.com/rocker-org/shiny/issues/79
CMD ["/usr/bin/shiny-server"]