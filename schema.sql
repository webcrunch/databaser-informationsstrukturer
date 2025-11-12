-- 1. Skapa tabellen Student
-- Lagrar information om studenten. Använder en surrogatnyckel (id) som PK.
CREATE TABLE IF NOT EXISTS `Student` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `firstName` VARCHAR(100) NOT NULL,
    `lastName` VARCHAR(100) NOT NULL,
    `personNr` VARCHAR(13) NOT NULL UNIQUE, -- Unik, men inte PK, för säkerhet och flexibilitet
    `email` VARCHAR(255) NOT NULL UNIQUE,
    `registeredDate` DATE NOT NULL,
    `statusId` INT NOT NULL, -- NY KOLUMN: Främmande nyckel till StudentStatus
    PRIMARY KEY (`id`),

-- NY FK: Etablerar 1-M relationen: StudentStatus (1) -> Student (M)
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

-- FOREIGN KEY 1: Kopplar till Student
FOREIGN KEY (`studentId`) REFERENCES `Student` (`id`),

-- FOREIGN KEY 2: Kopplar till Course
FOREIGN KEY (`courseCode`) REFERENCES `Course`(`code`) );

-- 5. NY TABELL: StudentStatus
-- Definierar alla möjliga studentstatusar (lookup-tabell)
CREATE TABLE IF NOT EXISTS `StudentStatus` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `statusName` VARCHAR(50) NOT NULL UNIQUE,
    PRIMARY KEY (`id`)
);

-- Valfritt: Skapa ett index för snabbare sökningar på kurskod i registreringstabellen
CREATE INDEX idx_courseCode_enrollment ON StudentEnrollment (courseCode);

-- Exempeldata: Lägg till grundläggande statusar
-- Obs! Dessa måste läggas in FÖRE du lägger till studenter
INSERT IGNORE INTO
    `StudentStatus` (`statusName`)
VALUES ('Aktiv'),
    ('Examen'),
    ('Utskriven'),
    ('Tjänstledig');

-- Nu kan du lägga till nya studenter med en giltig status, t.ex. statusId = 1 (Aktiv)
-- Exempel: INSERT INTO `Student` (firstName, lastName, personNr, email, registeredDate, statusId)
-- VALUES ('Anna', 'Andersson', '19950101-1234', 'anna.a@skola.se', '2023-08-20', 1);