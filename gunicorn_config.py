commands = '/home/www/code/project/env/bin/gunicorn'
pythonpath = 'home/www/code/project/project'
bind = '127.0.0.1:8001'
# bind = 'unix:/run/gunicorn.sock'
# worker_class = 'uvicorn.workers.UvicornWorker'
workers = 3 # Количество ядер * 2 + 1
limit_request_fields = 32000
limit_request_fields_size = 0
raw_dnv = 'DJANGO_SETTINGS_MODULE=project.settings'
