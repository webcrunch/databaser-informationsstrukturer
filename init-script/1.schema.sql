-- 1a. Skapa tabellen StudentStatus
-- Lagrar de möjliga statusarna en student kan ha (t.ex. 'Aktiv', 'Pausad', 'Avklarad').
CREATE TABLE IF NOT EXISTS `StudentStatus` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `statusName` VARCHAR(50) NOT NULL UNIQUE,
    PRIMARY KEY (`id`)
);

-- FÖRSLAG: Lägg till standardstatusar här för att databasen ska fungera direkt
INSERT IGNORE INTO
    StudentStatus (id, statusName)
VALUES (1, 'Aktiv'),
    (2, 'Pausad'),
    (3, 'Avklarad');

-- 1. Skapa tabellen Student (UPPDATERAD)
-- Lagrar information om studenten. Använder en surrogatnyckel (id) som PK.
CREATE TABLE IF NOT EXISTS `Student` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `firstName` VARCHAR(100) NOT NULL,
    `lastName` VARCHAR(100) NOT NULL,
    `personNr` VARCHAR(13) NOT NULL UNIQUE, -- Unik, men inte PK, för säkerhet och flexibilitet
    `email` VARCHAR(255) NOT NULL UNIQUE,
    `registeredDate` DATE NOT NULL,
    `statusId` INT NOT NULL DEFAULT 1, -- Foreign Key till StudentStatus
    PRIMARY KEY (`id`),

-- Etablerar M-1 relationen: Student (M) -> StudentStatus (1)
FOREIGN KEY (`statusId`) REFERENCES `StudentStatus`(`id`) );

-- 2. Skapa tabellen Teacher
-- Lagrar information om lärare. Har en unik e-postadress.
CREATE TABLE IF NOT EXISTS `Teacher` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `firstName` VARCHAR(100) NOT NULL,
    `lastName` VARCHAR(100) NOT NULL,
    `email` VARCHAR(255) NOT NULL UNIQUE,
    `department` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`id`)
);

-- 3. Skapa tabellen Course
-- Innehåller kursinformation. Etablerar 1-M-relationen till Teacher.
CREATE TABLE IF NOT EXISTS `Course` (
    `code` VARCHAR(10) NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `credits` DECIMAL(4, 2) NOT NULL, -- DECIMAL för exakta poäng (t.ex. 7.50)
    `responsibleTeacherId` INT NOT NULL, -- FOREIGN KEY till Teacher
    PRIMARY KEY(`code`),

-- Etablerar 1-M relationen: Teacher (1) -> Course (M)
FOREIGN KEY (`responsibleTeacherId`) REFERENCES `Teacher`(`id`) );

-- 4. Skapa tabellen StudentEnrollment (Kopplingstabellen)
-- Löser M-M-relationen mellan Student och Course.
-- PK är en sammansatt nyckel av studentId och courseCode.
CREATE TABLE IF NOT EXISTS `StudentEnrollment` (
    `studentId` INT NOT NULL,
    `courseCode` VARCHAR(10) NOT NULL,
    `grade` VARCHAR(2), -- Kan vara NULL tills betyg är satt (t.ex. 'A', 'U', 'G')
    `completionDate` DATE, -- Kan vara NULL tills kursen är klar

-- SAMMANSATT PRIMARY KEY: Garanterar att en student bara kan registreras en gång per kurs
PRIMARY KEY (`studentId`, `courseCode`),

-- Etablerar M-1 relationer: StudentEnrollment (M) -> Student (1)
FOREIGN KEY (`studentId`) REFERENCES `Student` (`id`) ON DELETE CASCADE, -- Om studenten raderas, raderas registreringen också

-- Etablerar M-1 relationer: StudentEnrollment (M) -> Course (1)
FOREIGN KEY (`courseCode`) REFERENCES `Course`(`code`)
    ON DELETE CASCADE -- Om kursen raderas, raderas registreringen också
);

--
-- #####################################################################
-- 5. SKAPA VYER (VIEWS)
-- #####################################################################
--
-- Vyer förenklar komplexa JOINs och gör applikationskoden renare.

-- 5a. StudentStatusView: Visar all studentdata inklusive det läsbara statusnamnet.
DROP VIEW IF EXISTS StudentStatusView;

CREATE VIEW StudentStatusView AS
SELECT S.id, S.firstName, S.lastName, S.personNr, S.email, S.registeredDate, SS.statusName, S.statusId -- Behåll FK för referens/intern användning
FROM Student S
    JOIN StudentStatus SS ON S.statusId = SS.id;

-- 5b. CourseTeacherView: Visar alla kurser med den ansvariga lärarens fullständiga namn.
DROP VIEW IF EXISTS CourseTeacherView;

CREATE VIEW CourseTeacherView AS
SELECT
    C.code,
    C.name,
    C.credits,
    T.id AS responsibleTeacherId,
    CONCAT(T.firstName, ' ', T.lastName) AS responsibleTeacherName,
    T.email AS teacherEmail,
    T.department
FROM Course C
    JOIN Teacher T ON C.responsibleTeacherId = T.id;

-- 5c. StudentEnrollmentOverview: En detaljerad view över alla registreringar (Student, Kurs, Betyg, Lärare).
DROP VIEW IF EXISTS StudentEnrollmentOverview;

CREATE VIEW StudentEnrollmentOverview AS
SELECT
    SE.studentId,
    CONCAT(S.firstName, ' ', S.lastName) AS studentFullName,
    S.personNr,
    S.email AS studentEmail,
    SS.statusName AS studentStatus,
    SE.courseCode,
    C.name AS courseName,
    C.credits AS courseCredits,
    SE.grade,
    SE.completionDate,
    T.id AS responsibleTeacherId,
    CONCAT(T.firstName, ' ', T.lastName) AS responsibleTeacherFullName
FROM
    StudentEnrollment SE
    JOIN Student S ON SE.studentId = S.id
    JOIN StudentStatus SS ON S.statusId = SS.id
    JOIN Course C ON SE.courseCode = C.code
    JOIN Teacher T ON C.responsibleTeacherId = T.id;