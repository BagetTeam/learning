FROM python:3.12-slim

WORKDIR /app

# Copy the whole project (needed for pip install -e .)
COPY . .

# Install the package in editable mode
RUN pip install --no-cache-dir -e .

# Default command runs the setup script
CMD ["python", "setup_scripts/setup_all.py"]