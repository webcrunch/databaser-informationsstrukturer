-- #####################################################################
-- SCHEMADEFINITION: Skolplattform (Nexus DB)
-- Beskrivning: Skapar alla nödvändiga tabeller, index och vyer.
-- #####################################################################

USE Nexus_DB;

-- Tvinga UTF-8 för denna session
SET NAMES 'utf8mb4';

SET CHARACTER SET utf8mb4;

-- 1. Skapa tabell: StudentStatus
CREATE TABLE IF NOT EXISTS StudentStatus (
    id INT NOT NULL AUTO_INCREMENT,
    statusName VARCHAR(50) NOT NULL UNIQUE,
    PRIMARY KEY (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 2. Skapa tabell: Student
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
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 3. Skapa tabell: Teacher
CREATE TABLE IF NOT EXISTS Teacher (
    id INT NOT NULL AUTO_INCREMENT,
    firstName VARCHAR(100) NOT NULL,
    lastName VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    department VARCHAR(100) NOT NULL,
    PRIMARY KEY (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 4. Skapa tabell: Course
CREATE TABLE IF NOT EXISTS Course (
    code VARCHAR(10) NOT NULL,
    name VARCHAR(255) NOT NULL,
    credits DECIMAL(4, 2) NOT NULL,
    responsibleTeacherId INT NOT NULL,
    PRIMARY KEY (code),
    FOREIGN KEY (responsibleTeacherId) REFERENCES Teacher (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 5. Skapa tabell: StudentEnrollment
CREATE TABLE IF NOT EXISTS StudentEnrollment (
    studentId INT NOT NULL,
    courseCode VARCHAR(10) NOT NULL,
    grade VARCHAR(2),
    completionDate DATE,
    PRIMARY KEY (studentId, courseCode),
    FOREIGN KEY (studentId) REFERENCES Student (id) ON DELETE CASCADE,
    FOREIGN KEY (courseCode) REFERENCES Course (code) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- #####################################################################
-- 6. SKAPA INDEX
-- #####################################################################
CREATE INDEX idx_student_statusId ON Student (statusId);

-- #####################################################################
-- 7. SKAPA VYER (VIEWS)
-- #####################################################################

DROP VIEW IF EXISTS v_StudentEnrollmentOverview;

DROP VIEW IF EXISTS v_CourseTeachers;

DROP VIEW IF EXISTS v_StudentStatus;

-- 7a. v_StudentStatus
CREATE VIEW v_StudentStatus AS
SELECT S.id, S.firstName, S.lastName, S.personNr, S.email, S.registeredDate, SS.statusName, S.statusId
FROM Student S
    JOIN StudentStatus SS ON S.statusId = SS.id;

-- 7b. v_CourseTeachers
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

-- 7c. v_StudentEnrollmentOverview
CREATE VIEW v_StudentEnrollmentOverview AS
SELECT
    CONCAT(
        S.firstName,
        ' ',
        S.lastName,
        '(Student ID: ',
        SE.studentId,
        ' )'
    ) AS studentFullName,
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
    JOIN Teacher T ON C.responsibleTeacherId = T.id
ORDER BY SE.courseCode