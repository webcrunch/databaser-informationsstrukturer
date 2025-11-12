-- Använd den databas du skapade
-- USE CoursePortalDB;

-- #####################################################################
-- GRUNDKRAV: Hantering och Modifiering av Data
-- #####################################################################

-- 1. Skapa användare/Student (Populera databasen)
-- Denna fråga läggs normalt i data.sql, men här är ett exempel på en ny insättning:
-- Vi lägger till en ny student, "Kalle Karlsson".
INSERT INTO
    Student (
        firstName,
        lastName,
        personNr,
        email,
        registeredDate
    )
VALUES (
        'Kalle',
        'Karlsson',
        '980707-4321',
        'kalle.k@mail.com',
        CURDATE()
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
-- Radera den nyligen tillagda studenten Kalle Karlsson (förutsatt att han inte är inskriven på någon kurs).
DELETE FROM Student
WHERE
    firstName = 'Kalle'
    AND lastName = 'Karlsson';

-- #####################################################################
-- GRUNDKRAV: SELECT-Frågor & SQL-Funktioner
-- #####################################################################

-- 4. Använder sig av SQL Funktioner såsom DATE
-- Hitta alla studenter som registrerade sig i databasen efter ett specifikt datum (t.ex. 1:a oktober 2024).
SELECT
    id,
    firstName,
    lastName,
    registeredDate
FROM Student
WHERE
    registeredDate > '2024-10-01';

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
SELECT
    firstName,
    lastName,
    registeredDate
FROM Student
ORDER BY registeredDate DESC
LIMIT 3
OFFSET
    1;
-- Visar student 2, 3, och 4 i sorteringen

-- 8. En JOIN som innefattar minst tre tabeller
-- Visa namn på studenten, namnet på kursen, och den ansvariga lärarens namn för alla godkända inskrivningar.
SELECT
    S.firstName AS Studentens_Förnamn,
    S.lastName AS Studentens_Efternamn,
    C.name AS Kursnamn,
    T.lastName AS Ansvarig_Lärare
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
-- Skapar en vy som enkelt visar studentens namn, kursnamn och betyg, utan att användaren behöver skriva JOINs.
CREATE VIEW V_FullEnrollmentDetails AS
SELECT
    S.firstName AS StudentFirstName,
    S.lastName AS StudentLastName,
    C.name AS CourseName,
    SE.grade AS Grade,
    SE.completionDate AS CompletionDate
FROM
    StudentEnrollment AS SE
    JOIN Student AS S ON SE.studentId = S.id
    JOIN Course AS C ON SE.courseCode = C.code;

-- (Valfritt: Testa vyn)
-- SELECT * FROM V_FullEnrollmentDetails WHERE Grade = 'A';

-- 10. Skapa en Rapportvy (Kursbeläggning/Topplista)
-- Visar de kurser som har flest inskrivna studenter (en Topplista).
CREATE VIEW V_TopCourses AS
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

-- (Valfritt: Testa vyn)
-- SELECT * FROM V_TopCourses;

-- #####################################################################
-- VG-KRAV
-- #####################################################################

-- 11. Rapport som använder HAVING (VG)
-- Hitta namnet på de studenter som är inskrivna på fler än 2 kurser.
SELECT S.firstName, S.lastName, COUNT(SE.courseCode) AS AntalKurser
FROM
    StudentEnrollment AS SE
    JOIN Student AS S ON SE.studentId = S.id
GROUP BY
    S.id,
    S.firstName,
    S.lastName
HAVING
    AntalKurser > 2;
-- Lisa (ID 3) läser 4 kurser, Erik (ID 2) läser 3 kurser.

-- 12. En boolesk / CASE-etikett (VG)
-- Lista alla avklarade kurser och skapa en ny kolumn som visar kursens poäng i ord (Liten, Mellan, Stor).
SELECT
    C.name AS Kursnamn,
    C.credits AS Poäng,
    CASE
        WHEN C.credits <= 7.50 THEN 'Liten Kurs (7.5 hp)'
        WHEN C.credits <= 15.00 THEN 'Mellan Kurs (15 hp)'
        ELSE 'Stor Kurs (> 15 hp)'
    END AS Kursstorlek
FROM
    StudentEnrollment AS SE
    JOIN Course AS C ON SE.courseCode = C.code
WHERE
    SE.completionDate IS NOT NULL -- Visa bara avklarade kurser
GROUP BY
    C.code,
    C.name,
    C.credits;

-- 13. Stored Procedure (t.ex. registrera order/registrering) (VG)
-- En procedur som enkelt registrerar en student på en ny kurs.
-- Syfte: Att säkerställa att registreringar sker korrekt utan manuella fel.

DELIMITER /
/
-- Byter delimiter för att tillåta semikolon i proceduren

CREATE PROCEDURE RegisterStudentToCourse (
    IN p_studentId INT,
    IN p_courseCode VARCHAR(10)
)
BEGIN
    -- Försöker lägga till en rad i StudentEnrollment-tabellen
    INSERT INTO StudentEnrollment (studentId, courseCode)
    VALUES (p_studentId, p_courseCode);
END
/
/

DELIMITER;
-- Återställer delimiter till standard (semikolon)

-- (Valfritt: Anropa proceduren för att testa den)
-- CALL RegisterStudentToCourse(5, 'IT400'); -- Registrerar Maria på IT400