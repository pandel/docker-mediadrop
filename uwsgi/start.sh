#!/bin/bash

set -e

init_mediadrop() {

    #clear directory contents
    find /wsgi -mindepth 1 -depth -exec rm -rf {} ';'
    find /mediadrop -mindepth 1 -depth -exec rm -rf {} ';'
    find /venv -mindepth 1 -depth -exec rm -rf {} ';'

    #install python virtual environment
    (cd /venv && virtualenv --distribute --no-site-packages mediadrop)

    #download knyar/mediadrop fork from 06.01.2021
    echo "Cloning mediadrop from https://github.com/pandel/mediadrop.git..."
    git clone https://github.com/pandel/mediadrop.git /mediadrop
    cd /mediadrop
    git checkout svitle
    cd ..

    #activate python virtual environment
    source /venv/mediadrop/bin/activate

    #install mediadrop
    cd /mediadrop
    # fix package versions, newer lead to errors
    sed -i.bak '/^Paste /s/>.*/== 1.7.5.1/' requirements.txt
    sed -i.bak '/^PasteScript /s/>.*/== 1.7.5/' requirements.txt
    sed -i.bak '/^PasteDeploy /s/>.*/== 1.5.0/' requirements.txt
    sed -i.bak '/^find_links =/s#=.*#= https://open-mind.space/mediadrop-repo/#' setup.cfg
    pip install aniso8601==1.0.0
    python /mediadrop/setup.py develop

    cd /wsgi
    paster make-config MediaDrop deployment.ini
    sed -i 's,email_to = you@yourdomain.com,email_to = '${SMTP_FROM}'@'${SMTP_DOMAIN}',' deployment.ini
    sed -i 's,smtp_server = localhost,smtp_server = '${SMTP_SERVER}',' deployment.ini
    sed -i 's,error_email_from = paste@localhost,error_email_from = '${SMTP_FROM}'@'${SMTP_DOMAIN}',' deployment.ini
    sed -i 's,mysql://username:pass@localhost/dbname,mysql://'${MYSQL_USER}':'${MYSQL_PASSWORD}'@'${MYSQL_SERVER}'/'${MYSQL_DATABASE}',' deployment.ini
    sed -i 's,file_serve_method = default,file_serve_method = nginx_redirect,' deployment.ini
    sed -i 's,# nginx_serve_path = __mediadrop_serve__,nginx_serve_path = __mediadrop_serve__,' deployment.ini
    sed -i 's,static_files = true,static_files = false,' deployment.ini
    sed -i 's,enable_gzip = true,enable_gzip = false,' deployment.ini
    sed -i 's,cache_dir = %(here)s/data,cache_dir = /wsgi/data/,' deployment.ini
    sed -i 's,image_dir = %(here)s/data/images,image_dir = /wsgi/data/images/,' deployment.ini
    sed -i 's,media_dir = %(here)s/data/media,media_dir = /wsgi/data/media/,' deployment.ini
    sed -i 's,sqlalchemy.pool_recycle = 3600,sqlalchemy.pool_recycle = 200,' deployment.ini
    
    #setup directory and permissions
    cp -a /mediadrop/data .
    chmod -R 777 /wsgi/data
    #wsgi config
    echo '' >> deployment.ini
    echo '[uwsgi]' >> deployment.ini
    echo 'socket = :9000' >> deployment.ini
    echo 'master = true' >> deployment.ini
    echo 'processes = 2' >> deployment.ini
    echo 'virtualenv = /venv/mediadrop' >> deployment.ini
    echo 'stats = 127.0.0.1:9191' >> deployment.ini

    #fix crossdomain policy
    (cd /mediadrop/mediadrop/public && sed -i 's,\.cooliris\.com" secure="false",",' crossdomain.xml)
}

#check if volume has been initialized
if [ ! -f /wsgi/deployment.ini ]; then
    init_mediadrop
fi

#check if database has and tables defined
TESTDB="select count(*) from information_schema.tables where table_type = 'BASE TABLE' and table_schema = \"${MYSQL_DATABASE}\""
if [ $(mysql -ss --host=${MYSQL_SERVER} -u root -p${MYSQL_ROOT_PASSWORD} -e "${TESTDB}") == "0" ]; then
    cd /wsgi
    #activate python virtual environment
    source /venv/mediadrop/bin/activate

    #setup database
    paster setup-app deployment.ini

    #setup advanced seach
    mysql --host=${MYSQL_SERVER} -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE} < /mediadrop/setup_triggers.sql
fi

#run uwsgi daemon
(cd /wsgi && uwsgi --ini-paste deployment.ini)
