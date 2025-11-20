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
SELECT
    C.name AS courseName,
    C.credits AS credits,
    CASE
        WHEN C.credits <= 7.50 THEN 'Liten Kurs (7.5 hp)'
        WHEN C.credits <= 15.00 THEN 'Mellan Kurs (10-15 hp)'
        WHEN C.credits <= 22.50 THEN 'Stor Kurs (> 15 hp)'
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