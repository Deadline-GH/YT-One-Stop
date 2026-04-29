FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    git && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy requirement file (to be added later) and install python deps
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy your processing script (placeholder name)
COPY process_one.py ./

# Default command (can be overridden)
ENTRYPOINT ["python3","/app/process_one.py"]