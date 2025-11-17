

# 🌐 Kursportal API (Nexus DB)

Detta är ett RESTful API byggt med Flask och Flask-RESTX för att hantera studenter, lärare, kurser, statusar och kursregistreringar mot en MySQL-databas.

API:et är komplett med fullständiga CRUD-operationer samt avancerade databasfunktioner (Stored Procedures och Batch Queries).

## 🚀 Komma Igång (Förutsatt Docker Compose)

För att köra systemet, se till att du har Docker och Docker Compose installerat.

Starta applikationen och databasen:
```bash
docker-compose up -d 
```

Öppna API-dokumentationen:
När containrarna har startat, är API:et tillgängligt på:

Swagger UI (Dokumentation): http://localhost:5000/apidocs

Bas-URL: http://localhost:5000/

## 🛠️ Databasadministration (Adminer)

Adminer är ett lättviktsverktyg för databashantering som körs i en separat Docker-container i din miljö. Du kan använda det för att bläddra i tabeller, köra SQL-frågor och validera data direkt.

### 1. Öppna Adminer

Öppna Adminer i din webbläsare:

http://localhost:8080/


### 2. Logga in

Använd följande inloggningsuppgifter. Dessa matchar de miljövariabler som definierats för mysql och adminer i din docker-compose.yml.

#### För att arbeta med Nexus databasen: 

| Fält | Värde |
| :--- | :--- |
| System | MySQL (Välj från rullgardinsmenyn) |
| Server | mysql_nexus_db (Namnet på databastjänsten i Docker) |
| Användare | nexusUser |
| Lösenord | anotherPassword |
| Databas | Nexus_DB |

#### För att arbeta med test databasen: 

| Fält | Värde |
| :--- | :--- |
| System | MySQL (Välj från rullgardinsmenyn) |
| Server | mysql__db (Namnet på databastjänsten i Docker) |
| Användare | user |
| Lösenord | password |
| Databas |  |


#### 📊 Databasmodell

API:et interagerar med följande tabeller:

| Tabell | Beskrivning | Relationer |
| :--- | :--- | :--- |
| Student | Studentinformation. | M:1 till StudentStatus, 1:M till StudentEnrollment |
| StudentStatus | Lookup-tabell för studentens tillstånd (Aktiv, Examen, etc.). | 1:M till Student |
| Teacher | Lärarinformation och avdelning. | 1:M till Course |
| Course | Kursdetaljer, inklusive ansvarig lärare. | M:1 till Teacher, 1:M till StudentEnrollment |
| StudentEnrollment | Kopplingstabell mellan Student och Course, lagrar betyg (grade) och slutförandedatum (completionDate). | M:M mellan Student och Course |

⚙️ API Endpoints (Sammanfattning)

Alla endpoints är grupperade i Namespaces (t.ex. /students, /courses) och dokumenterade i Swagger UI (/apidocs).

1. Studenthantering (/students)

| Metod | Route | Beskrivning |
| :--- | :--- | :--- |
| GET | /students/ | Hämta alla studenter. |
| POST | /students/ | Skapa en ny student. |
| GET | /students/<id> | Hämta student baserat på ID. |
| PUT | /students/<id> | Uppdatera studentinformation. |
| DELETE | /students/<id> | Radera en student. |

### 2. Lärarhantering (/teachers)

| Metod | Route | Beskrivning |
| :--- | :--- | :--- |
| GET | /teachers/ | Hämta alla lärare. |
| POST | /teachers/ | Skapa en ny lärare. |
| GET | /teachers/<id> | Hämta lärare baserat på ID. |
| PUT | /teachers/<id> | Uppdatera lärarinformation. |
| DELETE | /teachers/<id> | Radera en lärare (misslyckas om ansvarig för kurs). |

### 3. Kurshantering (/courses)

| Metod | Route | Beskrivning |
| :--- | :--- | :--- |
| GET | /courses/ | Hämta alla kurser. |
| POST | /courses/ | Skapa en ny kurs. |
| GET | /courses/<code string> | Hämta kurs baserat på kurskod. |
| PUT | /courses/<code string> | Uppdatera kursinformation. |
| DELETE | /courses/<code string> | Radera en kurs (misslyckas om studenter är inskrivna). |
| GET | /courses/enrollment_counts | AVANCERAD: Lista alla kurser och antalet inskrivna studenter i varje kurs (Batch Query). |

### 4. Registreringshantering (/enrollments)

| Metod | Route | Beskrivning |
| :--- | :--- | :--- |
| GET | /enrollments/ | Hämta alla registreringar. |
| POST | /enrollments/ | Skapa en ny manuell registrering. |
| POST | /enrollments/register | AVANCERAD: Registrera student på kurs med en Stored Procedure (RegisterStudentToCourse). Kräver studentId och courseCode. |
| GET | /enrollments/<studentId>/<courseCode> | Hämta en specifik registrering. |
| PUT | /enrollments/<studentId>/<courseCode> | Uppdatera betyg och/eller slutförandedatum. |
| DELETE | /enrollments/<studentId>/<courseCode> | Radera en specifik registrering. |

### 5. Statushantering (/statuses)

| Metod | Route | Beskrivning |
| :--- | :--- | :--- |
| GET | /statuses/ | Hämta alla tillgängliga statusar. |
| POST | /statuses/ | Skapa en ny status (t.ex. 'Permitterad'). |
| GET | /statuses/<id> | Hämta specifik status. |
| DELETE | /statuses/<id> | Radera en status (misslyckas om den används av studenter). |

Radera en status (misslyckas om den används av studenter).

## 🔑 Avancerade Funktioner

Detta API har implementerat stöd för att hantera komplex databaslogik direkt via SQL-filer:

### 1. Stored Procedure (Effektiv registrering)

Endpointen POST /enrollments/register använder den lagrade proceduren RegisterStudentToCourse för att kapsla in databaslogik och säkerställa en atomisk registrering.

### 2. Batch Query (Statistik)

Endpointen GET /courses/enrollment_counts exekverar en komplex JOIN och GROUP BY-fråga för att generera en översikt av kursregistreringar i en enda databasoperation.