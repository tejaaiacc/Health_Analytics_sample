FROM rocker/shiny-verse

COPY app.R /srv/shiny-server/
ADD data /data

COPY shiny.config /etc/shiny-server/shiny-server.conf
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    rm -rf /var/lib/apt/lists/*
RUN add-apt-repository universe
RUN add-apt-repository multiverse
RUN apt-get update
#RUN apt-get install -y libgdal-dev gdal-bin libproj-dev proj-data proj-bin libgeos-dev libudunits2-dev

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    lbzip2 \
    libfftw3-dev \
    libgdal-dev \
    libgeos-dev \
    libgsl0-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libhdf4-alt-dev \
    libhdf5-dev \
    libjq-dev \
#    liblwgeom-dev \
    libpq-dev \
    libproj-dev \
    libprotobuf-dev \
    libnetcdf-dev \
    libsqlite3-dev \
    libssl-dev \
    libudunits2-dev \
    netcdf-bin \
    postgis \
    protobuf-compiler \
    sqlite3 \
    tk-dev \
    unixodbc-dev

RUN install2.r --error tigris leaflet rgdal sf

#RUN R -e "install.packages('leaflet',dependencies=TRUE, repos='http://cran.rstudio.com/')"
#RUN R -e "install.packages('rgdal', repos='http://cran.us.r-project.org',type='source')"
#RUN R -e "install.packages('sf', repos='http://cran.rstudio.com/')"

EXPOSE 8080

USER shiny 
# avoid s6 initialization
# see https://github.com/rocker-org/shiny/issues/79
CMD ["/usr/bin/shiny-server"]
