-- Raderar tabellerna i omvänd ordning för att undvika problem med främmande nycklar vid omstart
DROP TABLE IF EXISTS StudentEnrollment;

DROP TABLE IF EXISTS Course;

DROP TABLE IF EXISTS Teacher;

DROP TABLE IF EXISTS Student;

-- 1. Skapa tabellen Student
-- Lagrar information om studenten. Använder en surrogatnyckel (id) som PK.
CREATE TABLE Student (
    id INT NOT NULL AUTO_INCREMENT,
    firstName VARCHAR(100) NOT NULL,
    lastName VARCHAR(100) NOT NULL,
    personNr VARCHAR(13) NOT NULL UNIQUE, -- Unik, men inte PK
    email VARCHAR(255) NOT NULL UNIQUE,
    registeredDate DATE NOT NULL,
    status VARCHAR(50) NOT NULL, -- Lade till status från tidigare version
    PRIMARY KEY (id)
);

-- 2. Skapa tabellen Teacher
-- Lagrar information om lärare. Har en unik e-postadress.
CREATE TABLE Teacher (
    id INT NOT NULL AUTO_INCREMENT,
    firstName VARCHAR(100) NOT NULL,
    lastName VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    department VARCHAR(100) NOT NULL,
    PRIMARY KEY (id)
);

-- 3. Skapa tabellen Course
-- Innehåller kursinformation. Etablerar 1-M-relationen till Teacher.
CREATE TABLE Course (
    code VARCHAR(10) NOT NULL,
    name VARCHAR(255) NOT NULL,
    credits DECIMAL(4, 2) NOT NULL, -- DECIMAL för exakta poäng (t.ex. 7.50)
    responsibleTeacherId INT NOT NULL, -- FOREIGN KEY till Teacher
    PRIMARY KEY(code),

-- Etablerar 1-M relationen: Teacher (1) -> Course (M)
FOREIGN KEY (responsibleTeacherId) REFERENCES Teacher(id) );

-- 4. Skapa tabellen StudentEnrollment (Kopplingstabellen)
-- Löser M-M-relationen mellan Student och Course.
CREATE TABLE StudentEnrollment (
    studentId INT NOT NULL,
    courseCode VARCHAR(10) NOT NULL,
    grade VARCHAR(2), -- Kan vara NULL tills betyg är satt (t.ex. 'A', 'U', 'G')
    completionDate DATE, -- Kan vara NULL tills kursen är klar

-- SAMMANSATT PRIMARY KEY: Garanterar att en student bara kan registreras en gång per kurs
PRIMARY KEY (studentId, courseCode),

-- FOREIGN KEY 1: Kopplar till Student
FOREIGN KEY (studentId) REFERENCES Student (id),

-- FOREIGN KEY 2: Kopplar till Course
FOREIGN KEY (courseCode) REFERENCES Course(code) );

-- Infoga Testdata ---------------------------------------------

-- 2. Teacher Data (3 lärare)
INSERT INTO
    Teacher (
        firstName,
        lastName,
        email,
        department
    )
VALUES (
        'Mikael',
        'Larsson',
        'mikael.l@univ.se',
        'IT'
    ), -- ID 1
    (
        'Sofia',
        'Berglund',
        'sofia.b@univ.se',
        'Design'
    ), -- ID 2
    (
        'Oscar',
        'Ekman',
        'oscar.e@univ.se',
        'Ekonomi'
    );
-- ID 3

-- 1. Student Data (12 studenter - anpassad till den nya schemat)
INSERT INTO
    Student (
        firstName,
        lastName,
        personNr,
        email,
        registeredDate,
        status
    )
VALUES (
        'Anna',
        'Svensson',
        '19950101-1234',
        'anna.s@example.com',
        '2023-09-01',
        'Active'
    ), -- ID 1
    (
        'Bo',
        'Karlsson',
        '19800515-5678',
        'bo.k@example.com',
        '2022-01-15',
        'On Leave'
    ), -- ID 2
    (
        'Cecilia',
        'Nilsson',
        '20001122-9012',
        'cecilia.n@example.com',
        '2024-03-20',
        'Active'
    ), -- ID 3
    (
        'David',
        'Johansson',
        '19750304-3456',
        'david.j@example.com',
        '2021-10-10',
        'Graduated'
    ), -- ID 4
    (
        'Eva',
        'Lindqvist',
        '19980710-7890',
        'eva.l@example.com',
        '2023-11-25',
        'Active'
    ), -- ID 5
    (
        'Filip',
        'Andersson',
        '19851201-1098',
        'filip.a@example.com',
        '2022-08-05',
        'Active'
    ), -- ID 6
    (
        'Greta',
        'Svensson',
        '20020202-6543',
        'greta.s@example.com',
        '2024-01-01',
        'On Leave'
    ), -- ID 7
    (
        'Hugo',
        'Bengtsson',
        '19900909-2109',
        'hugo.b@example.com',
        '2023-05-18',
        'Graduated'
    ), -- ID 8
    (
        'Ida',
        'Pettersson',
        '19960412-8765',
        'ida.p@example.com',
        '2024-02-14',
        'Active'
    ), -- ID 9
    (
        'Jens',
        'Karlsson',
        '19880620-4321',
        'jens.k@example.com',
        '2023-03-03',
        'Active'
    ), -- ID 10
    (
        'Karin',
        'Johansson',
        '19700101-0987',
        'karin.j@example.com',
        '2022-09-29',
        'Graduated'
    ), -- ID 11
    (
        'Lars',
        'Nilsson',
        '19931111-5432',
        'lars.n@example.com',
        '2024-04-10',
        'Active'
    );
-- ID 12

-- 3. Course Data (4 kurser, länkade till lärare)
INSERT INTO
    Course (
        code,
        name,
        credits,
        responsibleTeacherId
    )
VALUES (
        'PROG101',
        'Introduktion till Programmering',
        7.50,
        1
    ), -- Mikael (IT)
    (
        'DBA202',
        'Databasteknik och SQL',
        7.50,
        1
    ), -- Mikael (IT)
    (
        'UX301',
        'Användarupplevelse och Design',
        5.00,
        2
    ), -- Sofia (Design)
    (
        'NET404',
        'Nätverkssäkerhet',
        10.00,
        3
    );
-- Oscar (Ekonomi)

-- 4. StudentEnrollment Data (Registreringar)
INSERT INTO
    StudentEnrollment (
        studentId,
        courseCode,
        grade,
        completionDate
    )
VALUES
    -- Anna (ID 1)
    (
        1,
        'PROG101',
        'A',
        '2023-12-20'
    ),
    (
        1,
        'DBA202',
        'B',
        '2024-03-10'
    ),
    -- Cecilia (ID 3)
    (3, 'PROG101', NULL, NULL), -- Pågående
    (3, 'UX301', NULL, NULL), -- Pågående
    -- David (ID 4 - Examinerad)
    (
        4,
        'DBA202',
        'C',
        '2022-01-15'
    ),
    (
        4,
        'NET404',
        'B',
        '2022-05-20'
    ),
    -- Eva (ID 5)
    (
        5,
        'PROG101',
        'A',
        '2024-01-15'
    ),
    (5, 'UX301', 'A', '2024-03-30'),
    -- Filip (ID 6)
    (6, 'NET404', NULL, NULL), -- Pågående
    -- Karin (ID 11 - Examinerad)
    (
        11,
        'DBA202',
        'A',
        '2023-01-15'
    ),
    (
        11,
        'NET404',
        'C',
        '2023-05-15'
    );