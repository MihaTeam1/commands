#!/bin/bash
source /home/www/code/project/env/bin/activate
cd /home/www/code/project/project
exec python -m celery -A project_name worker --beat -l INFO --concurrency=3 --max-tasks-per-child=1
# --concurrency количество потоков у воркера (формула: количество ядер * 2 + 1)
# --max-tasks-per-child максимальное количество задач которое выполнит 1 поток селери перед перезагрузкой
