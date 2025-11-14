Slutrapport: Nexus_DB - Student- och Kursadministrationssystem

1. Domän och Syfte

Domän: Projektet avser en relationsdatabas för hantering av studenter, lärare, kurser och kursregistreringar inom en universitetsmiljö (Kursportal).

Syfte: Att skapa en databasmodell som är effektiv, skalbar och upprätthåller hög dataintegritet. Systemet ska kunna hantera de centrala enheterna (Student, Teacher, Course) och den komplexa Many-to-Many-relationen mellan studenter och kurser.

2. Databasöversikt och Modell

Databasen består av fyra tabeller som representerar de centrala entiteterna och deras relationer. Vi använder konsekvent Surrogatnycklar (id med AUTO_INCREMENT) för flexibilitet i entitetstabellerna (Student, Teacher).

2.1 Tabellstruktur och Nycklar

Tabellnamn

Beskrivning

Primär Nyckel (PK)

Främmande Nycklar (FK)

Student

Lagrar unik studentinformation.

id (INT, Auto-Increment)

Inga

Teacher

Lagrar unik lärarinformation.

id (INT, Auto-Increment)

Inga

Course

Lagrar kursdetaljer.

code (VARCHAR)

responsibleTeacherId (FK till Teacher.id)

StudentEnrollment

Löser Många-till-Många relationen.

Sammansatt: (studentId, courseCode)

studentId, courseCode

3. Relationer och Motivering

3.1 One-to-Many (1-M) Relation

Relation: Teacher (1) till Course (M). En lärare kan ansvara för flera kurser, men varje kurs har endast en ansvarig lärare.

Implementering: Detta realiseras genom den främmande nyckeln responsibleTeacherId i tabellen Course, som pekar på primärnyckeln i Teacher.

Motivering: Denna separering minskar dataredundans. Istället för att duplicera lärarens information (namn, e-post, avdelning) för varje kurs de ansvarar för, lagras endast en liten integer-nyckel.

3.2 Many-to-Many (M-M) Relation

Relation: Student (M) till Course (M). En student kan läsa flera kurser, och varje kurs har flera studenter.

Implementering: Denna relation löses upp med hjälp av kopplingstabellen StudentEnrollment.

Motivering: Kopplingstabellen är absolut nödvändig. Den hanterar inte bara själva kopplingen, utan lagrar också data som är beroende av båda entiteterna, nämligen grade och completionDate. Den sammansatta primärnyckeln (studentId, courseCode) garanterar att varje registrering är unik.

4. Normalisering (Minst Tredje Normalformen – 3NF)

Databasmodellen har designats för att uppfylla minst Tredje Normalformen (3NF). Vi har valt att stanna vid 3NF då det ger den bästa balansen mellan dataintegritet och frågeprestanda.

1NF (Första Normalformen): Uppfylls genom att alla kolumner är atomiska. Exempelvis lagras inte en lista med kurser i en kolumn i Student-tabellen.

2NF (Andra Normalformen): Uppfylls i vår kopplingstabell StudentEnrollment. De icke-nyckelattributen (grade och completionDate) är beroende av hela den sammansatta primärnyckeln (studentId, courseCode).

3NF (Tredje Normalformen): Uppfylls genom att inga transitiva beroenden finns.

I Student-tabellen beror t.ex. firstName och email direkt på PK:n (id), och inte på ett annat icke-nyckelattribut som t.ex. personNr.

Alla lärarens detaljer är flyttade till Teacher-tabellen, vilket eliminerar transitiva beroenden i Course-tabellen.

Slutsats: Genom att separera data i fyra dedikerade tabeller eliminerar vi redundans och säkerställer dataintegritet, vilket är målet med 3NF. Inga medvetna avsteg från normaliseringen har gjorts.

5. Val av Datatyper

Valet av datatyper är avgörande för att optimera lagring, prestanda och korrekthet.

Kolumn

Datatyp

Motivering

id (Student/Teacher)

INT, AUTO_INCREMENT

Standard för surrogatnycklar. Ger snabb sökning och sortering. AUTO_INCREMENT säkerställer unika värden utan manuell hantering.

firstName, lastName

VARCHAR(100)

Tillåter variabla längder för text och sparar därmed utrymme jämfört med CHAR. Längden 100 är generös nog för de flesta namn.

personNr

VARCHAR(13)

Lagras som text för att inkludera bindestreck och undvika problem med inledande nollor som kan uppstå med INT. Längden 13 är fixerad (ÅÅMMDD-XXXX).

email, name (Course)

VARCHAR(255)

Standardiserad längd för e-postadresser och kursnamn. Ger tillräckligt utrymme för långa strängar.

credits (Course)

DECIMAL(4, 2)

Nödvändigt för att lagra exakta numeriska värden, såsom poäng (t.ex. 7.50 eller 30.00). DECIMAL är att föredra framför FLOAT för finansiella eller exakta mått.

registeredDate

DATE

Optimerad datatyp för lagring av datum utan tidskomponent, vilket är lämpligt för en registreringsdag.

grade (Enrollment)

VARCHAR(2)

Lämpligt för korta betygskoder (t.ex. 'A', 'U', 'G').

6. Dataintegritet och Säkerhetsaspekter

Dataintegritet har säkerställts på databasnivå genom att tillämpa strikta begränsningar. Detta är den första och viktigaste försvarslinjen mot felaktig eller ofullständig data.

6.1 Unikhetsbegränsningar (UNIQUE)

Student.personNr: Garanterar att ingen student kan registreras med ett dubblerat personnummer.

Student.email: Garanterar att varje student har en unik kontaktadress.

Teacher.email: Garanterar att varje lärare har en unik kontaktadress.

6.2 Inte-Null Begränsningar (NOT NULL)

Alla kärnattribut som är väsentliga för en entitet, såsom namn, personnummer, kurskod och poäng, har begränsningen NOT NULL. Detta säkerställer att ingen student eller kurs kan skapas utan fullständig grundinformation.

Exempel: Student.firstName, Course.name, Teacher.department måste alltid ha ett värde.

6.3 Främmande Nycklar (Foreign Keys – FK)

Främmande nycklar (responsibleTeacherId, studentId, courseCode) används för att upprätthålla referensintegritet.

Detta förhindrar att en kurs registreras med en responsibleTeacherId som inte existerar i Teacher-tabellen, och förhindrar att studentregistreringar kopplas till studenter eller kurser som inte finns.

Detta skyddar mot "hängande referenser" (orphaned records) och är ett fundamentalt krav för en relationsdatabas.