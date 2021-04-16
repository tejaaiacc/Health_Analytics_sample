FROM rocker/shiny

ADD data /data

COPY app.R /srv/shiny-server/
COPY shiny.config /etc/shiny-server/shiny-server.conf

# RUN R -e "install.packages('leaflet',dependencies=TRUE, repos='http://cran.rstudio.com/')"
# RUN R -e "install.packages('sf',dependencies=TRUE, repos='http://cran.rstudio.com/')"

RUN install2.r --error \
    sf \
    tigris


EXPOSE 8080

USER shiny

# avoid s6 initialization
# see https://github.com/rocker-org/shiny/issues/79
CMD ["/usr/bin/shiny-server"]