# 💾 Databasteknik: Kursmiljö och Projektstack (Docker Compose)

Detta arkiv innehåller den Docker Compose-fil (`docker-compose.yml`) som används för att sätta upp den fullständiga databasstacken för kursen Databasteknik.

Miljön inkluderar **relationsdatabaser** (PostgreSQL, MySQL), **NoSQL-databaser** (MongoDB, Redis) samt **webbaserade administrationsverktyg** och **modelleringsverktyg** för att täcka alla kursmoment.

---

## 🚀 Kom igång

### Krav
* Docker Desktop (eller Docker Engine)
* Docker Compose (ofta inbyggt i Docker Desktop)

### Steg 1: Starta alla tjänster
Öppna terminalen i samma mapp som filen `docker-compose.yml` och kör kommandot:

```bash
```

docker compose up -d

Detta startar fyra databaser och tre GUI-verktyg. Flaggan -d (detach) låter dem köras i bakgrunden.

Steg 2: Stoppa alla tjänster
När du är klar med arbetet, stoppa och städa upp alla containers (volymerna behålls):

docker compose down

📊 Databasöversikt och Anslutningar
Alla tjänster körs på localhost. Använd portnumret nedan för att ansluta via valfritt externt GUI-verktyg (t.ex. DBeaver, MySQL Workbench, Redis Desktop Manager).

1. Relationsdatabaser (RDBMS)
Dessa används för SQL-övningar, normalisering och det individuella projektet.

Tjänst

Port

Användare

Lösenord

Databas

Webbläsarens GUI

PostgreSQL

5432

user

password

main_database

Nås via pgAdmin

MySQL 8.0

3306

user

password

main_database

Inget dedikerat GUI i denna stack

pgAdmin (PostgreSQL GUI)
URL: http://localhost:5050

Inloggning: admin@example.com / verysecurepassword

Obs! PostgreSQL-databasen är redan registrerad i pgAdmin efter uppstart.

2. NoSQL-databaser (Översikt)
Dessa används primärt för att studera NoSQL-paradigmer och uppnå kursens översiktsmål.

Tjänst

Port

Typ

Webbläsarens GUI

MongoDB

27017

Dokumentdatabas

Nås via Mongo Express

Redis

6379

Key-Value Store

Nås via RedisInsight

Mongo Express (MongoDB GUI)
URL: http://localhost:8081

Inloggning: mongo_user / mongo_password

RedisInsight (Redis GUI)
URL: http://localhost:8001

Setup: När du loggar in första gången behöver du lägga till Redis-databasen manuellt.

Välj "Add Redis Database".

Välj "Connect to a Redis OSS instance".

Ange följande anslutningsdetaljer:

Host: redis_cache (Detta är servicenamnet i Docker-nätverket)

Port: 6379

Name: Kurs Redis Cache

Klicka på "Add Redis Database". Du är nu ansluten!

🛠 Framtida Applikationsintegration
Denna stack är förberedd för att inkludera din egna applikationskod (t.ex. Python, Java, C#) i en container, vilket är nödvändigt för projektets integrationsdel.

Anslutning inifrån app-containern
När du avkommenterar app_server i docker-compose.yml, använd tjänstenamnet som host i din applikationskod:

Om du använder...

Använd detta som DB Host

PostgreSQL

postgres_db

MySQL

mysql_db

MongoDB

mongo_db