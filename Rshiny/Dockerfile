FROM rocker/shiny

ADD table_app /srv/shiny-server/table_app/
ADD maps_app /srv/shiny-server/maps_app/
ADD data /data

COPY shiny.config /etc/shiny-server/shiny-server.conf

RUN R -e "install.packages('DT',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('tidyverse',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('leaflet',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('sf',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('tigris',dependencies=TRUE, repos='http://cran.rstudio.com/')"


EXPOSE 8080

USER shiny

# avoid s6 initialization
# see https://github.com/rocker-org/shiny/issues/79
CMD ["/usr/bin/shiny-server"]