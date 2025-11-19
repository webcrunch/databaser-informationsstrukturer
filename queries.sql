-- Använd databasen
USE Nexus_DB;

-- #####################################################################
-- GRUNDKRAV: Hantering och Modifiering av Data
-- #####################################################################

-- 1. Skapa användare/Student (Populera databasen)
-- Vi lägger till en ny student, "Kalle Karlsson". Måste inkludera statusId för att matcha schemat.
INSERT INTO
    Student (
        firstName,
        lastName,
        personNr,
        email,
        registeredDate,
        statusId -- Nödvändigt fält i uppdaterat schema
    )
VALUES (
        'Kalle',
        'Karlsson',
        '980707-4321',
        'kalle.k@mail.com',
        CURDATE(),
        1 -- Sätter status till 'Aktiv'
    );

-- 2. Uppdatera data (Modifera)
-- Uppdatera Pelles e-postadress.
UPDATE Student
SET
    email = 'pelle.persson.ny@mail.com'
WHERE
    firstName = 'Pelle'
    AND lastName = 'Persson';

-- 2. Uppdatera data (Modifera)
-- Uppdatera .
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
-- Hitta alla studenter som registrerade sig i databasen efter ett specifikt datum (t.ex. 1:a november 2024).
SELECT
    CONCAT(
        firstName,
        ' ',
        lastName,
        ' (',
        id,
        ')'
    ) AS StudentFullName,
    registeredDate
FROM Student
WHERE
    registeredDate > '2024-11-01'
ORDER BY registeredDate DESC;

-- 5. Använder sig av SQL Funktioner såsom COUNT
-- Räkna hur många studenter som är inskrivna i varje enskild kurs.
SELECT courseCode, COUNT(studentId) AS AntalStudenter
FROM StudentEnrollment
GROUP BY
    courseCode
ORDER BY AntalStudenter DESC;

-- 6. Fritext sökningar (LIKE)
-- Hitta alla kurser vars namn innehåller ordet 'Databaser'.
SELECT code, name FROM Course WHERE name LIKE '%Databaser%';

-- 7. Frågor som använder LIMIT och OFFSET
-- Visa de 3 senast registrerade studenterna (LIMIT 3) med start från den 2:a studenten i sorteringen (OFFSET 1).
SELECT CONCAT(firstname, ' ', lastname) AS FUllName, registeredDate
FROM Student
ORDER BY registeredDate DESC
LIMIT 3 -- Tar bara tre resultat
OFFSET
    1;
-- Hoppar över 1:a, tar 2:a, 3:e, 4:e

-- 8. En JOIN som innefattar minst tre tabeller
-- Visa namn på studenten, namnet på kursen, och den ansvariga lärarens namn för alla godkända inskrivningar.
SELECT
    S.firstName AS Student_Förnamn,
    S.lastName AS Student_Efternamn,
    C.name AS Kursnamn,
    T.lastName AS Ansvarig_Lärare
FROM
    StudentEnrollment AS SE
    JOIN Student AS S ON SE.studentId = S.id
    JOIN Course AS C ON SE.courseCode = C.code
    JOIN Teacher AS T ON C.responsibleTeacherId = T.id
WHERE
    SE.grade IS NOT NULL;

-- 8b. En JOIN som innefattar minst tre tabeller (Med CONCAT)
-- Samma fråga som 8 men med studentens för- och efternamn sammanfogade (konkatinerade).
SELECT
    CONCAT(S.firstName, ' ', S.lastName) AS Studentens_Namn,
    C.name AS Kursnamn,
    CONCAT(T.firstName, ' ', T.lastName) AS Ansvarig_Lärare
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
-- (Notera: Dessa vyer skapas i schema.sql, men detta visar hur de kan skapas)

-- 9. Skapa en Förenklad Vy för SELECT-frågor
-- Skapar en vy som enkelt visar studentens namn, kursnamn och betyg, samt studentens status.
CREATE VIEW v_FullEnrollmentDetails AS
SELECT
    CONCAT(S.firstname, ' ', S.lastName) AS StudentFullName,
    St.statusName AS StudentStatus, -- StudentStatus inlagd
    C.name AS CourseName,
    SE.grade AS Grade,
    SE.completionDate AS CompletionDate
FROM
    StudentEnrollment AS SE
    JOIN Student AS S ON SE.studentId = S.id
    JOIN StudentStatus AS St ON S.statusId = St.id
    JOIN Course AS C ON SE.courseCode = C.code;

-- Exempelanvändning:
SELECT * FROM v_FullEnrollmentDetails;

-- 10. Skapa en Rapportvy (Kursbeläggning/Topplista)
-- Visar de kurser som har flest inskrivna studenter.
CREATE VIEW v_TopCourses AS
SELECT
    C.code AS CourseCode,
    C.name AS CourseName,
    COUNT(SE.studentId) AS EnrolledStudents
FROM
    Course AS C
    JOIN StudentEnrollment AS SE ON C.code = SE.courseCode
GROUP BY
    C.code,
    C.name
ORDER BY EnrolledStudents DESC;

-- Exempelanvändning:
SELECT * FROM v_TopCourses;

-- #####################################################################
-- VG-KRAV & Avancerade Rapporter
-- #####################################################################

-- 11. Rapport som använder HAVING (VG)
-- Hitta namnet på de studenter som är inskrivna på mer än 30 högskolepoäng (hp) totalt.
SELECT
    CONCAT(S.firstName, ' ', S.lastName) AS StudentFullName,
    SUM(C.credits) AS TotalCredits
FROM
    StudentEnrollment AS SE
    JOIN Student AS S ON SE.studentId = S.id
    JOIN Course AS C ON SE.courseCode = C.code
GROUP BY
    S.id,
    S.firstName,
    S.lastName
HAVING
    TotalCredits > 30.00 -- Mer än 30 poäng
ORDER BY TotalCredits DESC;

-- 12. En boolesk / CASE-etikett (VG)
-- Lista alla avklarade kurser och skapa en ny kolumn som visar kursens poäng i ord (Liten, Mellan, Stor, Mycket Stor).
SELECT
    C.name AS Kursnamn,
    C.credits AS Credits,
    CASE
        WHEN C.credits <= 7.50 THEN 'Liten Kurs (7.5 hp)'
        WHEN C.credits <= 15.00 THEN 'Mellan Kurs (10-15 hp)'
        WHEN C.credits <= 22.50 THEN 'Stor Kurs (> 15 hp)'
        ELSE 'Mycket Stor Kurs (> 22.5 hp)'
    END AS CourseSize
FROM
    StudentEnrollment AS SE
    JOIN Course AS C ON SE.courseCode = C.code
WHERE
    SE.completionDate IS NOT NULL -- Visa bara avklarade kurser
GROUP BY
    C.code,
    C.name,
    C.credits
ORDER BY C.credits DESC;

/* 13. Avancerad fråga: Hitta studenter utan pågående inskrivningar
* Använder LEFT JOIN för att hitta studenter som har status "Aktiv" (statusId=1) men ingen inskriven kurs utan betyg.
* "Hämta alla studenter som är 'Aktiva'. Försök hitta en pågående kurs för dem.
* Om du inte hittar någon pågående kurs (resultatet blev NULL), visa den studenten." */
SELECT S.id, S.firstName, S.lastName, ST.statusName
FROM
    Student AS S
    JOIN StudentStatus AS ST ON S.statusId = ST.id
    LEFT JOIN StudentEnrollment AS SE ON S.id = SE.studentId
    AND SE.completionDate IS NULL
WHERE
    ST.statusName = 'Aktiv' -- Endast aktiva studenter
    AND SE.studentId IS NULL;
-- Hitta de studenter som inte matchade någon pågående kurs

-- 14. Avancerad fråga: Genomsnittligt betyg per kurs (Rapport för lärare)
-- Konverterar betygen (A=5, B=4, C=3, G/D=2) för att beräkna ett numeriskt snitt.
SELECT
    CONCAT(C.name, ' (', C.code, ')') AS KursInformation,
    CONCAT(T.firstName, ' ', T.lastName) AS Ansvarig_Lärare,

-- Beräkna medelbetyget
ROUND(
    AVG(
        CASE
            WHEN SE.grade = 'A' THEN 5
            WHEN SE.grade = 'B' THEN 4
            WHEN SE.grade = 'C' THEN 3
            WHEN SE.grade = 'G'
            OR SE.grade = 'D' THEN 2
            -- 'U' (Underkänd) räknas inte med i snittet
            ELSE NULL
        END
    ),
    2
) AS Genomsnittligt_Betyg
FROM
    StudentEnrollment AS SE
    JOIN Course AS C ON SE.courseCode = C.code
    JOIN Teacher AS T ON C.responsibleTeacherId = T.id
WHERE
    SE.grade IS NOT NULL
    AND SE.grade != 'U' -- Exkludera icke-godkända/Underkända för ett mer meningsfullt G-snitt
GROUP BY
    C.code, -- Nödvändig eftersom vi aggregerar per kurs
    C.name,
    T.firstName,
    T.lastName
ORDER BY Genomsnittligt_Betyg DESC;

-- 15. Avancerad fråga: De bästa studenterna i en specifik kurs (Använder Subquery)
-- Hitta studenterna vars betyg är högre än genomsnittet för kursen 'DB101'.

-- #####################################################################
-- 16. Stored Procedures (VG)
-- #####################################################################

-- Procedur 1: Registrera en student på en kurs (sätter pågående status)
DELIMITER /
/

CREATE PROCEDURE RegisterStudentToCourse (
    IN p_studentId INT,
    IN p_courseCode VARCHAR(10)
)
BEGIN
    -- Försöker lägga till en rad i StudentEnrollment-tabellen
    -- grade och completionDate är NULL initialt
    INSERT INTO StudentEnrollment (studentId, courseCode)
    VALUES (p_studentId, p_courseCode);
END
/
/

DELIMITER;

-- Exempelanvändning:
-- CALL RegisterStudentToCourse (10, 'IT400'); -- lägger till studentid 10 -> Johan Jansson till cource IT400

-- Procedur 2: Ge betyg/slutföra en kurs för en student
DELIMITER /
/

CREATE PROCEDURE GraduateStudentToCourse (
    IN p_studentId INT,
    IN p_courseCode VARCHAR(10),
    IN p_courseGrade VARCHAR(2),
    IN p_completionDate DATE
)
BEGIN
    -- Uppdaterar en befintlig registrering med betyg och datum
    UPDATE StudentEnrollment 
    SET 
        grade = p_courseGrade, 
        completionDate = p_completionDate
    WHERE 
        studentId = p_studentId 
        AND courseCode = p_courseCode;
END
/
/

DELIMITER;

-- Exempelanvändning:
-- CALL GraduateStudentToCourse (10, 'IT400', 'B', '2025-11-10');