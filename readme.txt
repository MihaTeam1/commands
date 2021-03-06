#[main user and sudo]
ssh-copy-id root@ip
ssh root@ip

apt install sudo
adduser www
usermod -aG sudo www
passwd www

exit

ssh-copy-id www@ip
ssh www@ip

sudo apt-get update
sudo apt-get install -y vim mosh tmux htop git curl wget unzip gcc build-essential make


# Оставляем возможным подключение только по ssh (если не добавил ssh-ключ перед этим то сбрасывать систему)
# [ssh]
sudo vim /etc/ssh/sshd_config
    AllowUsers www
    PermitRootLogin no
    PasswordAuthentication no
    
sudo service ssh restart


# [core installs]
sudo apt-get install libxml2-dev libxslt-dev python-dev python3 zsh tree libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python3-dev python3-lxml libxslt-dev libffi-dev python-dev gnumeric libsqlite3-dev libpq-dev libxml2-dev libxslt1-dev libjpeg-dev libfreetype6-dev libcurl4-openssl-dev python3-venv


# [additional installs]
# Если нужен supervisor
sudo apt-get install supervisor
# Если нужен редис
sudo apt-get install redis-server 
# nginx или другой сервер на выбор
sudo apt-get install nginx
# база данных на выбор
sudo apt-get install postgresql


# смена локалей на ru (в открывшемся окне убрать en_US.UTF-8 и поставить ru_RU.UTF-8 )\
# [locales]
sudo localedef ru_RU.UTF-8 -i ru_RU -fUTF-8 ; \
        export LANGUAGE=ru_RU.UTF-8 ; \
        export LANG=ru_RU.UTF-8 ; \
        export LC_ALL=ru_RU.UTF-8 ; \
        sudo locale-gen ru_RU.UTF-8 ; \
        sudo dpkg-reconfigure locales
        
sudo vim /etc/profile
    export LANGUAGE=ru_RU.UTF-8
    export LANG=ru_RU.UTF-8
    export LC_ALL=ru_RU.UTF-8


# установка oh-my-zsh
# [zsh]
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
chsh -s $(which zsh)


# настройка базы данных (postgres)
# [database]
sudo passwd postgres
su postgres
export PATH=$PATH:/usr/lib/postgresql/11/bin
createdb --encoding UNICODE db_name --username postgres
exit
sudo -u postgres psql
create user db_username with password 'some_password';
ALTER USER db_username CREATEDB;
grant all privileges on database db_name to db_username;
\c db_name 
GRANT ALL ON ALL TABLES IN SCHEMA public to db_name;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public to db_name;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public to db_name;
CREATE EXTENSION pg_trgm;
ALTER EXTENSION pg_trgm SET SCHEMA public;
UPDATE pg_opclass SET opcdefault = true WHERE opcname='gin_trgm_ops';
\q
exit


# загрузка проекта на сервер
# [copy project]
mkdir /home/www/code/project
# Можно scp или git clone, как удобнее
а)git clone gir_repo_url
б)scp path_to_project_folder www@ip:/home/www/code/project


# Создание соккета, если предпочитаем его вместо tcp/ip
[socket]
# Пример файла: https://github.com/MihaTeam1/commands/blob/cf3ca18d25d6a67ae20c7b84e623a7c3dce9d891/gunicorn.socket
sudo vim /etc/systemd/system/gunicorn.socket
    [Unit]
    Description=gunicorn socket

    [Socket]
    ListenStream=/run/gunicorn.sock

    [Install]
    WantedBy=sockets.target
    
# Создание gunicorn конфига
# [gunicorn]
# Пример файла: https://github.com/MihaTeam1/commands/blob/bb433f6bafecc7c10652ff789b16a236e30fd3be/gunicorn_config.py
vim /home/www/code/project/gunicorn_config.py
    commands = '/home/www/code/project/env/bin/gunicorn'
    pythonpath = 'home/www/code/project/project'
    bind = '127.0.0.1:8001'
    # bind = 'unix:/run/gunicorn.sock' # Если предпочтение соккеты а не tcp/ip
    # worker_class = 'uvicorn.workers.UvicornWorker'
    workers = 3 # Количество ядер * 2 + 1
    limit_request_fields = 32000
    limit_request_fields_size = 0
    raw_env = 'DJANGO_SETTINGS_MODULE=project.settings'
    
    
# Создание bash скриптов для запуска наших программ 
# [bash scripts]
# Пример файла: https://github.com/MihaTeam1/commands/blob/91d940b0ed2261db16848c41cb0a06be670b0f2a/start_gunicorn.sh
vim /home/www/code/project/bin/start_gunicorn.sh
    #!/bin/bash
    source /home/www/code/project/env/bin/activate
    exec gunicorn -c '/home/www/code/project/gunicorn_config.py' project.wsgi

# Делаем наш скрипт исполняемым
chmod +x /home/www/code/project/bin/start_gunicorn.sh

# Если в проекте используется celery
# Пример файла: https://github.com/MihaTeam1/commands/blob/91d940b0ed2261db16848c41cb0a06be670b0f2a/start_celery.sh
vim /home/www/code/project/bin/start_celery.sh
    #!/bin/bash
    source /home/www/code/project/env/bin/activate
    cd /home/www/code/project/project
    exec python -m celery -A project_name worker --beat -l INFO --concurrency=3 --max-tasks-per-child=1
    # --concurrency количество потоков у воркера (формула: количество ядер * 2 + 1)
    # --max-tasks-per-child максимальное количество задач которое выполнит 1 поток селери перед перезагрузкой

# Делаем наш скрипт исполняемым
chmod +x /home/www/code/project/bin/start_celery.sh

# далее выбор, если предпочтение supervisor ниже также распишу про вариант с systemd
# [supervisor]
vim /etc/supervisor/project.conf
	[program:gunicorn]
	command=/home/www/code/project/bin/start_gunicorn.sh
	user=www
	process_name=%(program_name)s
	numprocs=1
	autostart=true
	autorestart=true
	redirect_stderr=true
    
    #Если в проекте используется celery
	[program:celery]
	command=/home/www/code/project/bin/start_celery.sh
	user=www
	process_name=%(program_name)s
	numprocs=1
	autostart=true
	autorestart=true
	redirect_stderr=true
    
    #Если в проекте больше одной программы
    [group:project]
    programs=gunicorn, celery
    
sudo service supervisor stop
sudo supervisorctl reread
sudo supervisorctl update
sudo service supervisor start


#далее как и обещал systemd
# [systemd]
# Пример файла: https://github.com/MihaTeam1/commands/blob/2e293ba8ead38b573b5c330f92bd3b5322484307/gunicorn.service
vim /etc/systemd/system/gunicorn.service
    [Unit]
    Description=gunicorn daemon
    # gunicorn.socket указываем в том случае если используем его
    Requires=gunicorn.socket
    # Если необходим редис или любая другая программа
    # Requires=gunicorn.socket redis.service
    After=network.target
    # Если необходим редис или любая другая программа
    # After=network.target redis.service

    [Service]
    User=www
    Group=www-data
    WorkingDirectory=/home/www/code/project
    ExecStart=/home/www/code/project/bin/start_gunicorn.sh
    Restart=always

    [Install]
    WantedBy=multi-user.target
    # Если необходим редис или любая другая программа
    # WantedBy=multi-user.target redis.service
    
    
# Запускаем соккет и активируем симилинки указанные в [Install]
sudo systemctl daemon-reload
sudo systemctl start gunicorn.socket
sudo systemctl enable gunicorn.socket
sudo systemctl restart gunicorn.socket

sudo sytemctl start gunicorn.service
sudo sytemctl enable gunicorn.service
sudo sytemctl restart gunicorn.service
    
# Практически аналогичный файл для если необходим celery
# Пример файла: https://github.com/MihaTeam1/commands/blob/2e293ba8ead38b573b5c330f92bd3b5322484307/celery.service
vim /etc/systemd/system/celery.service
    [Unit]
    Description=celery daemon
    # redis или любой другой броке для селери
    Requires=redis.service
    # redis или любой другой броке для селери
    After=network.target redis.service

    [Service]
    User=www
    Group=www-data
    WorkingDirectory=/home/www/code/project
    ExecStart=/home/www/code/project/bin/start_celery.sh
    Restart=always

    [Install]
    # redis или любой другой броке для селери
    WantedBy=multi-user.target redis.service
    
sudo sytemctl start celery.service
sudo sytemctl enable celery.service
sudo sytemctl restart celery.service


# Настройка nginx
# [nginx]
vim /etc/nginx/sites-enabled/default
    location / {
        include proxy_params;
        proxy_pass http://unix:/run/gunicorn.sock;
        proxy_set_header X-Forwarded-Host $server_name;
	proxy_set_header X-real-IP $remote_addr;
	add_header P3P 'CP="ALL DSP COR PSAa PSDa OUR NOR ONL UNI COM NAV"';
	add_header Access-Control-Allow-Origin *;   
    }
    
    location /static/ {
    	root /home/www/code/project/; # /home/www/code/project + /static/
	autoindex off;
    }
    
    location ~ /\. {
    	deny all;
    }

sudo systemctl reload nginx
sudo systemctl restart nginx


# Дополнительные ситуативные блоки
# [Additional]

# [swapfile]
# Проверить наличие свопа
sudo swapon --show
free -h

# Проверить место на диске
df -h

# Создать swapfile
# Множитель от оперативной памяти 0.25x 0.5x 0.75x 1x 1.25x 1.5x 2x
sudo fallocate -l 1G /swapfile

# Доступ к swapfile только руту
sudo chmod 600 /swapfile

# Активация
sudo mkswap /swapfile
sudo swapon /swapfile

# Резервное копирование
sudo cp /etc/fstab /etc/fstab.bak

# Автозапуск свопа
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Проверка процента перехода в swapfile
cat /proc/sys/vm/swappiness

# Если отличное от необходимого (обычно 10)
sudo sysctl vm.swappiness=10
sudo vim /etc/sysctl.conf
	vm.swappiness=10
