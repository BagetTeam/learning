FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY setup_scripts/ setup_scripts/

CMD ["python", "setup_scripts/setup_all.py"]