#!/bin/bash
source /home/www/code/project/env/bin/activate
cd /home/www/code/project/project
exec python -m celery -A project_name worker --beat -l INFO --concurrency=3 --max-tasks-pre-child=1
