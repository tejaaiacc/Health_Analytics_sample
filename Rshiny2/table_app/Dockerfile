FROM rocker/shiny

ADD table_app /srv/shiny-server/
ADD ../data /data

COPY shiny.config /etc/shiny-server/shiny-server.conf

RUN R -e "install.packages('DT',dependencies=TRUE, repos='http://cran.rstudio.com/')"

EXPOSE 8081

USER shiny

# avoid s6 initialization
# see https://github.com/rocker-org/shiny/issues/79
CMD ["/usr/bin/shiny-server"]