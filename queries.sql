-- Använd databasen
USE Nexus_DB;

-- #####################################################################
-- GRUNDKRAV: Hantering och Modifiering av Data
-- #####################################################################

-- 1. Skapa användare/Student (Populera databasen)
INSERT INTO
    Student (
        firstName,
        lastName,
        personNr,
        email,
        registeredDate,
        statusId
    )
VALUES (
        'Kalle',
        'Karlsson',
        '980707-4321',
        'kalle.k@mail.com',
        CURDATE(),
        1
    );

-- 2. Uppdatera data (Modifera)
-- Uppdatera Pelles e-postadress.
UPDATE Student
SET
    email = 'pelle.persson.ny@mail.com'
WHERE
    firstName = 'Pelle'
    AND lastName = 'Persson';

-- 3. Radera specifik data
-- Radera den nyligen tillagda studenten Kalle Karlsson.
DELETE FROM Student
WHERE
    firstName = 'Kalle'
    AND lastName = 'Karlsson';

-- #####################################################################
-- GRUNDKRAV: SELECT-Frågor & SQL-Funktioner
-- #####################################################################

-- 4. Använder sig av SQL Funktioner såsom DATE
SELECT
    CONCAT(
        firstName,
        ' ',
        lastName,
        ' (',
        id,
        ')'
    ) AS studentFullName,
    registeredDate
FROM Student
WHERE
    registeredDate > '2024-11-01'
ORDER BY registeredDate DESC;

-- 5. Använder sig av SQL Funktioner såsom COUNT 
SELECT courseCode, COUNT(studentId) AS studentCount
FROM StudentEnrollment
GROUP BY
    courseCode
ORDER BY studentCount DESC;

-- 6. Fritext sökningar (LIKE)
SELECT code, name FROM Course WHERE name LIKE '%Databaser%';
-- eller 
SELECT code, name FROM Course WHERE name LIKE '%IT%';

-- 7. Frågor som använder LIMIT och OFFSET
SELECT CONCAT(firstName, ' ', lastName) AS fullName, registeredDate
FROM Student
ORDER BY registeredDate DESC
LIMIT 3
OFFSET 1;

-- 8. En JOIN som innefattar minst tre tabeller
SELECT
    S.firstName AS studentFirstName,
    S.lastName AS studentLastName,
    C.name AS courseName,
    CONCAT(T.firstName, ' ', T.lastName) AS responsibleTeacher
FROM
    StudentEnrollment AS SE
    JOIN Student AS S ON SE.studentId = S.id
    JOIN Course AS C ON SE.courseCode = C.code
    JOIN Teacher AS T ON C.responsibleTeacherId = T.id
WHERE
    SE.grade IS NOT NULL;

-- 8b. En JOIN som innefattar minst tre tabeller (Med CONCAT)
SELECT
    CONCAT(S.firstName, ' ', S.lastName) AS studentFullName,
    C.name AS courseName,
    CONCAT(T.firstName, ' ', T.lastName) AS responsibleTeacher
FROM
    StudentEnrollment AS SE
    JOIN Student AS S ON SE.studentId = S.id
    JOIN Course AS C ON SE.courseCode = C.code
    JOIN Teacher AS T ON C.responsibleTeacherId = T.id
WHERE
    SE.grade IS NOT NULL;

-- #####################################################################
-- KRAV: VYER (Views)
-- #####################################################################

-- 9. Skapa en Förenklad Vy för SELECT-frågor
/*
Syfte: Abstraktion av komplexa kopplingar för slutanvändaren.

Beskrivning:
Denna vy sammanställer data från fyra olika tabeller (Student, Status, Kurs, Inskrivning).
Istället för att administratören ska behöva skriva en komplex JOIN-sats varje gång de vill se en students betyg,
kan de enkelt göra en SELECT * mot denna vy. Den visar läsbara namn (t.ex. "Aktiv") istället för kryptiska ID-nummer.
*/
CREATE VIEW v_FullEnrollmentDetails AS
SELECT
    CONCAT(S.firstName, ' ', S.lastName) AS studentFullName,
    St.statusName AS studentStatus,
    C.name AS courseName,
    SE.grade AS grade,
    SE.completionDate AS completionDate
FROM
    StudentEnrollment AS SE
    JOIN Student AS S ON SE.studentId = S.id
    JOIN StudentStatus AS St ON S.statusId = St.id
    JOIN Course AS C ON SE.courseCode = C.code;

-- Exempelanvändning:
/*
Syfte: Administrativt underlag för lärare och administration (Kontaktlista).

Beskrivning:
Till skillnad från vyn ovan som fokuserar på prestation (betyg/kursnamn), fokuserar denna vy på studentens identitet och kontaktuppgifter.
Den är designad för att snabbt kunna generera klasslistor där man ser personnummer och e-postadress kopplat till en specifik kurskod.
Detta underlättar när lärare behöver kontakta alla studenter i en specifik kurs.
*/
SELECT * FROM v_FullEnrollmentDetails;

-- 9b. Enkel vy för klasslistor
CREATE VIEW v_CourseStudents AS
SELECT CONCAT(
        S.firstName, ' ', S.lastName, ' (', S.personNr, ')'
    ) AS studentFullName, S.email, S.registeredDate, ST.courseCode, ST.grade, ST.completionDate, SS.statusName
FROM
    StudentEnrollment AS ST
    INNER JOIN Student AS S ON ST.studentId = S.id
    INNER JOIN StudentStatus AS SS ON S.statusId = SS.id;

-- Exempelanvändning :
SELECT * FROM v_CourseStudents;

-- 10. Skapa en Rapportvy (Kursbeläggning/Topplista)
/*
Syfte: Beslutsunderlag och resursplanering (Statistik).

Beskrivning:
Detta är en aggregerande vy som inte visar enskilda individer, utan statistik på makronivå.
Genom att gruppera på kurs och räkna antalet studenter (COUNT) skapas en topplista över kursbeläggning.
Denna vy är användbar för ledningen för att se vilka kurser som är mest populära eller kräver mest resurser,
utan att de behöver förstå hur man skriver GROUP BY-satser.
*/
CREATE VIEW v_TopCourses AS
SELECT
    C.code AS courseCode,
    C.name AS courseName,
    COUNT(SE.studentId) AS enrolledStudents
FROM
    Course AS C
    JOIN StudentEnrollment AS SE ON C.code = SE.courseCode
GROUP BY
    C.code,
    C.name
ORDER BY enrolledStudents DESC;

-- Exempelanvändning:
SELECT * FROM v_TopCourses;

-- #####################################################################
-- VG-KRAV & Avancerade Rapporter
-- #####################################################################

-- 11. Rapport som använder HAVING (VG)

Syfte: Rapport för att identifiera högpresterande studenter (över 30 hp).
/*
Logik:
1. Jag hämtar alla studenter och deras kurser via JOINs.
2. Jag grupperar datan per student (GROUP BY) för att samla alla kurser en student läst.
3. Jag summerar poängen (SUM) för varje grupp.
4. VIKTIGT: Jag använder HAVING istället för WHERE för filtreringen.
   - WHERE filtrerar rader *innan* summeringen görs (vilket inte går här).
   - HAVING filtrerar *efter* att poängen är summerade, vilket låter mig välja ut de som har > 30 hp.
*/
SELECT
    CONCAT(S.firstName, ' ', S.lastName) AS studentFullName,
    SUM(C.credits) AS totalCredits
FROM
    StudentEnrollment AS SE
    JOIN Student AS S ON SE.studentId = S.id
    JOIN Course AS C ON SE.courseCode = C.code
GROUP BY
    S.id,
    S.firstName,
    S.lastName
HAVING
    totalCredits > 30.00
ORDER BY totalCredits DESC;

-- 12. En boolesk / CASE-etikett (VG)

/*
Syfte: Kategorisera kurser baserat på storlek (poäng) för att göra statistiken mer läsbar.
Logik:
1. Jag använder en CASE-sats för att omvandla numeriska poäng (credits) till textetiketter:
- <= 7.5: Liten kurs
- 8-15: Mellan kurs
- 15-22.5: Stor kurs
- > 22.5: Mycket stor kurs
2. Jag använder WHERE completionDate IS NOT NULL för att endast inkludera data från kurser som faktiskt har avslutats/examinerats.
3. Jag grupperar på kursnivå för att undvika dubbletter om flera studenter läst samma kurs.
*/
SELECT
    C.name AS courseName,
    C.credits AS credits,
    CASE
        WHEN C.credits <= 7.50 THEN 'Liten Kurs (7.5 hp)'
        WHEN C.credits > 7.50
        AND C.credits <= 15.00 THEN 'Mellan Kurs (8-15 hp)'
        WHEN C.credits > 15.00
        AND C.credits <= 22.50 THEN 'Stor Kurs (15-23 hp)'
        ELSE 'Mycket Stor Kurs (> 22.5 hp)'
    END AS courseSize
FROM
    StudentEnrollment AS SE
    JOIN Course AS C ON SE.courseCode = C.code
WHERE
    SE.completionDate IS NOT NULL
GROUP BY
    C.code,
    C.name,
    C.credits
ORDER BY C.credits DESC;

-- 13. Avancerad fråga: Hitta studenter utan pågående inskrivningar
/*
Syfte: Identifiera "spökstudenter" – dvs. studenter som är registrerade som 'Aktiv' men inte har någon pågående kurs.

Logik (Left Anti-Join):
1. Jag hämtar alla studenter.
2. Jag gör en LEFT JOIN mot Enrollment, MEN med ett specifikt krav: jag letar bara efter kurser där completionDate IS NULL (pågående kurser).
3. LEFT JOIN innebär att om studenten INTE har någon pågående kurs, behåller databasen ändå raden men sätter alla Enrollment-värden till NULL.
4. I WHERE-satsen filtrerar jag fram just dessa rader (SE.studentId IS NULL).
Resultatet är de aktiva studenter som "misslyckades" med att matcha mot en pågående kurs.
*/
SELECT S.id, S.firstName, S.lastName, ST.statusName
FROM
    Student AS S
    JOIN StudentStatus AS ST ON S.statusId = ST.id
    LEFT JOIN StudentEnrollment AS SE ON S.id = SE.studentId
    AND SE.completionDate IS NULL
WHERE
    ST.statusName = 'Aktiv'
    AND SE.studentId IS NULL;

-- 14. Avancerad fråga: Genomsnittligt betyg per kurs

/*
Syfte: Skapa ett statistiskt underlag för lärare genom att beräkna medelbetyg per kurs.

Logik:
1. Transformation: Eftersom betyg lagras som bokstäver (Kvalitativ data: A-F) kan de inte beräknas matematiskt direkt.
2. Jag använder en CASE-sats inuti aggregeringsfunktionen för att "översätta" bokstäverna till siffror (A=5, B=4, etc.) on-the-fly.
3. Filtrering: Jag exkluderar underkända betyg ('U') för att få ett rättvisande snitt på godkända resultat.
4. Aggregering: AVG() beräknar snittet på de transformerade siffrorna, och ROUND() snyggar till decimalerna.
*/
SELECT
    CONCAT(C.name, ' (', C.code, ')') AS courseInfo,
    CONCAT(T.firstName, ' ', T.lastName) AS responsibleTeacher,
    ROUND(
        AVG(
            CASE
                WHEN SE.grade = 'A' THEN 5
                WHEN SE.grade = 'B' THEN 4
                WHEN SE.grade = 'C' THEN 3
                WHEN SE.grade = 'G'
                OR SE.grade = 'D' THEN 2
                ELSE NULL
            END
        ),
        2
    ) AS averageGrade
FROM
    StudentEnrollment AS SE
    JOIN Course AS C ON SE.courseCode = C.code
    JOIN Teacher AS T ON C.responsibleTeacherId = T.id
WHERE
    SE.grade IS NOT NULL
    AND SE.grade != 'U'
GROUP BY
    C.code,
    C.name,
    T.firstName,
    T.lastName
ORDER BY averageGrade DESC;

-- #####################################################################
-- 16. Stored Procedures (VG)
-- #####################################################################

-- Procedur 1: Registrera en student
DELIMITER /
/

CREATE PROCEDURE RegisterStudentToCourse (
    IN p_studentId INT,
    IN p_courseCode VARCHAR(10)
)
BEGIN
    INSERT INTO StudentEnrollment (studentId, courseCode)
    VALUES (p_studentId, p_courseCode);
END
/
/

DELIMITER;

-- Exempel:
CALL RegisterStudentToCourse (10, 'IT400');

-- Procedur 2: Ge betyg

DELIMITER //

CREATE PROCEDURE GraduateStudentToCourse (
    IN p_studentId INT,
    IN p_courseCode VARCHAR(10),
    IN p_courseGrade VARCHAR(2),
    IN p_completionDate DATE
)
BEGIN
    UPDATE StudentEnrollment 
    SET grade = p_courseGrade, completionDate = p_completionDate
    WHERE studentId = p_studentId AND courseCode = p_courseCode;
END
//

DELIMITER ;

-- Exempel:
CALL GraduateStudentToCourse ( 10, 'IT400', 'B', '2025-11-10' );