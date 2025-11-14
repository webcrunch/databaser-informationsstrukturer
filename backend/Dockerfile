# Använd en officiell Python-image som bas
FROM python:3.11-slim

# Sätt arbetsmappen i containern
WORKDIR /app

# Kopiera beroendefilen in i containern
COPY requirements.txt .

# Installera Python-beroendena
RUN pip install --no-cache-dir -r requirements.txt

# Kopiera resten av applikationskoden in i containern
COPY . .

# EXPLICIT ANROP TILL FILNAMNET
# Sätt miljövariabeln FLASK_APP till namnet på din Python-fil
ENV FLASK_APP=backend.py

# Exponera port 5000 (standard Flask-port)
EXPOSE 5000

# Definiera kommandot för att starta appen
# Vi använder gunicorn eller liknande för produktion, men för enkelhet:
CMD ["flask", "run", "--host", "0.0.0.0"]
