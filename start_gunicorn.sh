#!/bin/bash
source /home/www/code/project/env/bin/activate
exec gunicorn -c '/home/www/code/project/gunicorn_conf.py' project.wsgi
