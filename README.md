# Docker-Mediadrop
#### Mediadrop on Docker with separate Nginx, uWSGI, and MariaDB containers

#### This fork is based on the work of https://github.com/nmarus/docker-mediadrop

### Requirements:

- docker 19*
- docker-compose 1.26*

### Container Descriptions:
This application makes use of docker containerization. This is accomplished across 4 containers.

Their descriptions are outlined as follows:

1. *mediadrop-uwsgi* - Based in debian:buster. On first start it checks if mediadrop has been and installed. If not, it will:
    * Clone the mediadrop repo from my Github fork as of January 1st, 2021
    * Activates python virtual enviroment
    * Installs mediadrop from source
    * Adds customizations to the deployment.ini
    * Configures UWSGI service in socket mode
    * Checks if database is not populated and runs the database scripts and optional database search tables to the connected mediadrop-mariadb container

*Note: See [start.sh](https://github.com/pandel/docker-mediadrop/blob/master/uwsgi/start.sh)*

*Note: I mirrored the original Mediadrop Python dependencies from https://static.mediadrop.video/dependencies/dev/ to https://open-mind.space/mediadrop-repo/ to make them independently available.*

2. *mediadrop-nginx* - Based on official docker nginx image with customized nginx configuration, and self signed certs.

*Note: This fork contains a non-flash based file uploader, so everything should be fine regarding self-signed SSL certificates.*

3. *mediadrop-mariadb* - Based on official docker mariadb image. Uses environment variables defined in the docker-compose.yml to setup the mediadrop database.

### Quick Start:

1. Clone this repository

        $ git clone https://github.com/pandel/docker-mediadrop.git

2. Copy env-example to .env, edit .env to set your own parameters

        $ cp env-example .env

3. Build the images - This script creates the docker images on the connected docker server.

        $ ./build.sh all

4. Run mediadrop - This starts all the images and create appropriate links between each container.

        $ docker-compose up -d

5. Wait approximately 5-10 minutes for the initial build before attempting to access the web interface.

### Advanced:

#### Enable SSL:

1. Set `USE_SSL=true` in `.env`

2. Set `MEDIADROP_FQDN` to servername of your certificate

2. Copy your certificate as `server.crt` (root CA and intermediate certs chained) and your key as `server.key` into the `./nginx` subfolder.

3. Make sure that everything works as expected without SSL, then stop remove and rebuild the nginx container.

        $ docker-compose stop
        $ docker-compose rm mediadrop-nginx

4. Rebuild the nginx image

        $ ./build.sh nginx

5. Restart mediadrop

        $ docker-compose up -d

#### Change Volume Mapping

By default, every data related file is stored under `/opt/docker/mediadrop`. If you want to change this location, simply edit the `CONFIG` parameter in `.env`.

#### Reset everathing, INCLUDING YOUR DATA (BEWARE!)

Just run the following commands inside the `docker-mediadrop` folder:

        $ docker-compose down
        $ sudo ./build.sh reset
        
These commands will remove everything incl. your data, Docker container and Docker images. The only two Docker images that won't be removed are the `debian` and `mariadb` images, as they might be in use on your system already.
