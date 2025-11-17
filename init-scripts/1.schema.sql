-- 1a. Skapa tabellen StudentStatus

USE Nexus_DB;

CREATE TABLE IF NOT EXISTS StudentStatus (
    id INT NOT NULL AUTO_INCREMENT,
    statusName VARCHAR(50) NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

-- 1. Skapa tabellen Student
CREATE TABLE IF NOT EXISTS Student (
    id INT NOT NULL AUTO_INCREMENT,
    firstName VARCHAR(100) NOT NULL,
    lastName VARCHAR(100) NOT NULL,
    personNr VARCHAR(13) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    registeredDate DATE NOT NULL,
    statusId INT NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    FOREIGN KEY (statusId) REFERENCES StudentStatus (id)
);

-- 2. Skapa tabellen Teacher
CREATE TABLE IF NOT EXISTS Teacher (
    id INT NOT NULL AUTO_INCREMENT,
    firstName VARCHAR(100) NOT NULL,
    lastName VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    department VARCHAR(100) NOT NULL,
    PRIMARY KEY (id)
);

-- 3. Skapa tabellen Course
CREATE TABLE IF NOT EXISTS Course (
    code VARCHAR(10) NOT NULL,
    name VARCHAR(255) NOT NULL,
    credits DECIMAL(4, 2) NOT NULL,
    responsibleTeacherId INT NOT NULL,
    PRIMARY KEY (code),
    FOREIGN KEY (responsibleTeacherId) REFERENCES Teacher (id)
);

-- 4. Skapa tabellen StudentEnrollment (Kopplingstabellen)
CREATE TABLE IF NOT EXISTS StudentEnrollment (
    studentId INT NOT NULL,
    courseCode VARCHAR(10) NOT NULL,
    grade VARCHAR(2),
    completionDate DATE,
    PRIMARY KEY (studentId, courseCode),
    FOREIGN KEY (studentId) REFERENCES Student (id) ON DELETE CASCADE,
    FOREIGN KEY (courseCode) REFERENCES Course (code) ON DELETE CASCADE
);

--
-- #####################################################################
-- 5. SKAPA INDEX (NYTT AVSNITT)
-- #####################################################################
--
-- Krav: Minst ett index på en kolumn som ofta söks på.
-- Motivering: Foreign Key-kolumner används i nästan alla JOINs
-- och många WHERE-satser. Att indexera 'Student.statusId'
-- optimerar prestandan dramatiskt när man filtrerar studenter
-- baserat på deras status (t.ex. "visa alla aktiva studenter").

CREATE INDEX idx_student_statusId ON Student (statusId);

--
-- #####################################################################
-- 6. SKAPA VYER (VIEWS)
-- #####################################################################
--
-- Krav: Skapa minst två vyer.

-- 6a. v_StudentStatus: Visar all studentdata inklusive det läsbara statusnamnet.
DROP VIEW IF EXISTS StudentStatusView;
-- Tar bort det gamla namnet
DROP VIEW IF EXISTS v_StudentStatus;

CREATE VIEW v_StudentStatus AS
SELECT S.id, S.firstName, S.lastName, S.personNr, S.email, S.registeredDate, SS.statusName, S.statusId
FROM Student S
    JOIN StudentStatus SS ON S.statusId = SS.id;

-- 6b. v_CourseTeachers: Visar alla kurser med den ansvariga lärarens fullständiga namn.
DROP VIEW IF EXISTS CourseTeacherView;
-- Tar bort det gamla namnet
DROP VIEW IF EXISTS v_CourseTeachers;

CREATE VIEW v_CourseTeachers AS
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

-- 6c. v_StudentEnrollmentOverview: En detaljerad rapportvy över alla registreringar.
DROP VIEW IF EXISTS StudentEnrollmentOverview;

DROP VIEW IF EXISTS v_StudentEnrollmentOverview;

CREATE VIEW v_StudentEnrollmentOverview AS
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