# 1. Base image
FROM python:3.10-slim AS base

# 2. Sistem bağımlılıkları
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 3. Çalışma dizini
WORKDIR /app

# 4. Sadece requirements.txt önce kopyala
COPY requirements.txt .

# 5. Python paketlerini kur
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# 6. Uygulama dosyalarını kopyala
COPY . .

# 7. Uvicorn ile API’yi başlat
CMD ["uvicorn", "app.main:asgi_app", "--host", "0.0.0.0", "--port", "5000"]
