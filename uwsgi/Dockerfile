FROM debian:buster

#setup apt
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

#install packages
RUN DEBIAN_FRONTEND=noninteractive apt-get -y update && \
    apt-get -y install apt-utils && \
    apt-get -y install curl git mariadb-client && \
    apt-get -y install libjpeg-dev zlib1g-dev libfreetype6-dev libmariadb-dev libmariadb-dev-compat && \
    apt-get -y install build-essential python-dev python-cookies python-pip python-setuptools python-virtualenv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#install uwsgi
RUN pip install uwsgi
RUN pip install uwsgitop

#startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Startup
CMD ["/start.sh"]
