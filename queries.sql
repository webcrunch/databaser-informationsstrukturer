-- -- Använd den databas du skapade
-- -- USE Nexus_DB;

-- -- #####################################################################
-- -- GRUNDKRAV: Hantering och Modifiering av Data
-- -- #####################################################################

-- -- 1. Skapa användare/Student (Populera databasen)
-- -- Denna fråga läggs normalt i data.sql, men här är ett exempel på en ny insättning:
-- -- Vi lägger till en ny student, "Kalle Karlsson".
-- INSERT INTO
--     Student (
--         firstName,
--         lastName,
--         personNr,
--         email,
--         registeredDate
--     )
-- VALUES (
--         'Kalle',
--         'Karlsson',
--         '980707-4321',
--         'kalle.k@mail.com',
--         CURDATE()
--     );

-- -- 2. Uppdatera data (Modifera)
-- -- Uppdatera Pelles e-postadress.
-- UPDATE Student
-- SET
--     email = 'pelle.persson.ny@mail.com'
-- WHERE
--     firstName = 'Pelle'
--     AND lastName = 'Persson';

-- -- 3. Radera specifik data
-- -- Radera den nyligen tillagda studenten Kalle Karlsson (förutsatt att han inte är inskriven på någon kurs).
-- DELETE FROM Student
-- WHERE
--     firstName = 'Kalle'
--     AND lastName = 'Karlsson';

-- -- #####################################################################
-- -- GRUNDKRAV: SELECT-Frågor & SQL-Funktioner
-- -- #####################################################################

-- -- 4. Använder sig av SQL Funktioner såsom DATE
-- -- Hitta alla studenter som registrerade sig i databasen efter ett specifikt datum (t.ex. 1:a oktober 2024).
-- SELECT
--     id,
--     firstName,
--     lastName,
--     registeredDate
-- FROM Student
-- WHERE
--     registeredDate > '2024-10-01';

-- -- 5. Använder sig av SQL Funktioner såsom COUNT
-- -- Räkna hur många studenter som är inskrivna i varje enskild kurs.
-- SELECT courseCode, COUNT(studentId) AS AntalStudenter
-- FROM StudentEnrollment
-- GROUP BY
--     courseCode
-- ORDER BY AntalStudenter DESC;

-- -- 6. Fritext sökningar (LIKE)
-- -- Hitta alla kurser vars namn innehåller ordet 'Databaser'.
-- SELECT code, name FROM Course WHERE name LIKE '%Databaser%';

-- -- 7. Frågor som använder LIMIT och OFFSET
-- -- Visa de 3 senast registrerade studenterna (LIMIT 3) med start från den 2:a studenten i sorteringen (OFFSET 1).
-- SELECT
--     firstName,
--     lastName,
--     registeredDate
-- FROM Student
-- ORDER BY registeredDate DESC
-- LIMIT 3
-- OFFSET
--     1;
-- -- Visar student 2, 3, och 4 i sorteringen

-- -- 8. En JOIN som innefattar minst tre tabeller
-- -- Visa namn på studenten, namnet på kursen, och den ansvariga lärarens namn för alla godkända inskrivningar.
-- SELECT
--     S.firstName AS Studentens_Förnamn,
--     S.lastName AS Studentens_Efternamn,
--     C.name AS Kursnamn,
--     T.lastName AS Ansvarig_Lärare
-- FROM
--     StudentEnrollment AS SE
--     JOIN Student AS S ON SE.studentId = S.id
--     JOIN Course AS C ON SE.courseCode = C.code
--     JOIN Teacher AS T ON C.responsibleTeacherId = T.id
-- WHERE
--     SE.grade IS NOT NULL;

-- -- 8b. En JOIN som innefattar minst tre tabeller
-- -- Visa namn på studenten, namnet på kursen, och den ansvariga lärarens namn för alla godkända inskrivningar.koncatinerar ihop för och efternamn
-- SELECT
--     CONCAT(S.firstName, ' ', S.lastName) AS Students_Name,
--     C.name AS Kursnamn,
--     T.lastName AS Ansvarig_Lärare
-- FROM
--     StudentEnrollment AS SE
--     JOIN Student AS S ON SE.studentId = S.id
--     JOIN Course AS C ON SE.courseCode = C.code
--     JOIN Teacher AS T ON C.responsibleTeacherId = T.id
-- WHERE
--     SE.grade IS NOT NULL

-- -- #####################################################################
-- -- KRAV: VYER (Views)
-- -- #####################################################################

-- -- 9. Skapa en Förenklad Vy för SELECT-frågor
-- -- Skapar en vy som enkelt visar studentens namn, kursnamn och betyg, utan att användaren behöver skriva JOINs.
-- CREATE VIEW V_FullEnrollmentDetails AS
-- SELECT
--     S.firstName AS StudentFirstName,
--     S.lastName AS StudentLastName,
--     C.name AS CourseName,
--     SE.grade AS Grade,
--     SE.completionDate AS CompletionDate
-- FROM
--     StudentEnrollment AS SE
--     JOIN Student AS S ON SE.studentId = S.id
--     JOIN Course AS C ON SE.courseCode = C.code;

-- -- (Valfritt: Testa vyn)
-- -- SELECT * FROM V_FullEnrollmentDetails WHERE Grade = 'A';

-- -- 10. Skapa en Rapportvy (Kursbeläggning/Topplista)
-- -- Visar de kurser som har flest inskrivna studenter (en Topplista).
-- CREATE VIEW V_TopCourses AS
-- SELECT
--     C.code AS CourseCode,
--     C.name AS CourseName,
--     COUNT(SE.studentId) AS EnrolledStudents
-- FROM
--     Course AS C
--     JOIN StudentEnrollment AS SE ON C.code = SE.courseCode
-- GROUP BY
--     C.code,
--     C.name
-- ORDER BY EnrolledStudents DESC;

-- -- (Valfritt: Testa vyn)
-- -- SELECT * FROM V_TopCourses;

-- -- #####################################################################
-- -- VG-KRAV
-- -- #####################################################################

-- -- 11. Rapport som använder HAVING (VG)
-- -- Hitta namnet på de studenter som är inskrivna på fler än 2 kurser.
-- SELECT S.firstName, S.lastName, COUNT(SE.courseCode) AS AntalKurser
-- FROM
--     StudentEnrollment AS SE
--     JOIN Student AS S ON SE.studentId = S.id
-- GROUP BY
--     S.id,
--     S.firstName,
--     S.lastName
-- HAVING
--     AntalKurser > 2;
-- -- Lisa (ID 3) läser 4 kurser, Erik (ID 2) läser 3 kurser.

-- -- 12. En boolesk / CASE-etikett (VG)
-- -- Lista alla avklarade kurser och skapa en ny kolumn som visar kursens poäng i ord (Liten, Mellan, Stor).
-- SELECT
--     C.name AS Kursnamn,
--     C.credits AS Poäng,
--     CASE
--         WHEN C.credits <= 7.50 THEN 'Liten Kurs (7.5 hp)'
--         WHEN C.credits <= 15.00 THEN 'Mellan Kurs (15 hp)'
--         ELSE 'Stor Kurs (> 15 hp)'
--     END AS Kursstorlek
-- FROM
--     StudentEnrollment AS SE
--     JOIN Course AS C ON SE.courseCode = C.code
-- WHERE
--     SE.completionDate IS NOT NULL -- Visa bara avklarade kurser
-- GROUP BY
--     C.code,
--     C.name,
--     C.credits;

-- -- 13. Stored Procedure (t.ex. registrera order/registrering) (VG)
-- -- En procedur som enkelt registrerar en student på en ny kurs.
-- -- Syfte: Att säkerställa att registreringar sker korrekt utan manuella fel.

-- DELIMITER /
-- /
-- -- Byter delimiter för att tillåta semikolon i proceduren

-- CREATE PROCEDURE RegisterStudentToCourse (
--     IN p_studentId INT,
--     IN p_courseCode VARCHAR(10)
-- )
-- BEGIN
--     -- Försöker lägga till en rad i StudentEnrollment-tabellen
--     INSERT INTO StudentEnrollment (studentId, courseCode)
--     VALUES (p_studentId, p_courseCode);
-- END
-- /
-- /

-- DELIMITER;
-- -- Återställer delimiter till standard (semikolon)

-- -- (Valfritt: Anropa proceduren för att testa den)
-- -- CALL RegisterStudentToCourse(5, 'IT400'); -- Registrerar Maria på IT400

-- Använd den databas du skapade
-- USE Nexus_DB;

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
    id,
    firstName,
    lastName,
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
SELECT
    firstName,
    lastName,
    registeredDate
FROM Student
ORDER BY registeredDate DESC
LIMIT 3
OFFSET
    1;

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

-- 8b. En JOIN som innefattar minst tre tabeller (Med CONCAT)
-- Samma fråga som 8 men med studentens för- och efternamn sammanfogade (konkatinerade).
SELECT
    CONCAT(S.firstName, ' ', S.lastName) AS Studentens_Namn,
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
-- Skapar en vy som enkelt visar studentens namn, kursnamn och betyg, samt studentens status.
CREATE VIEW V_FullEnrollmentDetails AS
SELECT
    S.firstName AS StudentFirstName,
    S.lastName AS StudentLastName,
    St.statusName AS StudentStatus, -- StudentStatus inlagd
    C.name AS CourseName,
    SE.grade AS Grade,
    SE.completionDate AS CompletionDate
FROM
    StudentEnrollment AS SE
    JOIN Student AS S ON SE.studentId = S.id
    JOIN StudentStatus AS St ON S.statusId = St.id
    JOIN Course AS C ON SE.courseCode = C.code;

-- 10. Skapa en Rapportvy (Kursbeläggning/Topplista)
-- Visar de kurser som har flest inskrivna studenter.
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

-- #####################################################################
-- VG-KRAV & Avancerade Rapporter
-- #####################################################################

-- 11. Rapport som använder HAVING (VG)
-- Hitta namnet på de studenter som är inskrivna på mer än 30 högskolepoäng (hp) totalt.
SELECT S.firstName, S.lastName, SUM(C.credits) AS TotalCredits
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
    C.credits AS Poäng,
    CASE
        WHEN C.credits <= 7.50 THEN 'Liten Kurs (7.5 hp)'
        WHEN C.credits <= 15.00 THEN 'Mellan Kurs (10-15 hp)'
        WHEN C.credits <= 22.50 THEN 'Stor Kurs (> 15 hp)'
        ELSE 'Mycket Stor Kurs (> 22.5 hp)'
    END AS Kursstorlek
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

-- NYTT! 13. Avancerad fråga: Hitta studenter utan pågående inskrivningar
-- Använder LEFT JOIN för att hitta studenter som har status "Aktiv" (statusId=1) men ingen inskriven kurs utan betyg (dvs. de är i riskzonen för att vara inaktiva).
SELECT S.id, S.firstName, S.lastName, ST.statusName
FROM
    Student AS S
    JOIN StudentStatus AS ST ON S.statusId = ST.id
    LEFT JOIN StudentEnrollment AS SE ON S.id = SE.studentId
    AND SE.completionDate IS NULL
WHERE
    ST.statusName = 'Aktiv' -- Endast aktiva studenter
    AND SE.studentId IS NULL;
-- Hitta de studenter som inte matchade någon pågående kurs (NULL completionDate)
-- Resultat: Olle, Sara, Erik, Frida, Johan (om de inte har några pågående kurser)

-- NYTT! 14. Avancerad fråga: Genomsnittligt betyg per kurs (Rapport för lärare)
-- Konverterar betygen (A=5, B=4, C=3, G/D=2, U=1) för att beräkna ett numeriskt snitt.
SELECT
    C.code,
    C.name AS Kursnamn,
    T.lastName AS Ansvarig_Lärare,
    -- Beräkna medelbetyget
    ROUND(
        AVG(
            CASE
                WHEN SE.grade = 'A' THEN 5
                WHEN SE.grade = 'B' THEN 4
                WHEN SE.grade = 'C' THEN 3
                WHEN SE.grade = 'G'
                OR SE.grade = 'D' THEN 2
                WHEN SE.grade = 'U' THEN 1
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
    C.code,
    C.name,
    T.lastName
ORDER BY Genomsnittligt_Betyg DESC;

-- NYTT! 15. Avancerad fråga: De bästa studenterna i en specifik kurs (Använder Subquery)
-- Hitta studenterna vars betyg är högre än genomsnittet för kursen 'DB101'.
SELECT S.firstName, S.lastName, SE.grade AS DB101_Betyg
FROM
    StudentEnrollment AS SE
    JOIN Student AS S ON SE.studentId = S.id
WHERE
    SE.courseCode = 'DB101'
    -- Använd ett numeriskt värde för betyget (A=5, B=4, C=3, G/D=2, U=1)
    AND (
        CASE
            WHEN SE.grade = 'A' THEN 5
            WHEN SE.grade = 'B' THEN 4
            WHEN SE.grade = 'C' THEN 3
            WHEN SE.grade = 'G'
            OR SE.grade = 'D' THEN 2
            ELSE 1
        END
    ) > (
        -- Subquery: Beräkna det genomsnittliga numeriska betyget för DB101
        SELECT AVG(
                CASE
                    WHEN grade = 'A' THEN 5
                    WHEN grade = 'B' THEN 4
                    WHEN grade = 'C' THEN 3
                    WHEN grade = 'G'
                    OR grade = 'D' THEN 2
                    ELSE NULL
                END
            )
        FROM StudentEnrollment
        WHERE
            courseCode = 'DB101'
            AND grade IS NOT NULL
            AND grade != 'U'
    );

-- 16. Stored Procedure (t.ex. registrera order/registrering) (VG)
-- En procedur som enkelt registrerar en student på en ny kurs.
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

-- (Valfritt: Anropa proceduren för att testa den)
-- CALL RegisterStudentToCourse(10, 'IT400');