-- Steg 0: Säkerställ att tabellerna är tomma och återställda
SET FOREIGN_KEY_CHECKS = 0;

SET NAMES 'utf8mb4';

SET CHARACTER SET utf8mb4;

USE Nexus_DB;

TRUNCATE TABLE StudentEnrollment;

TRUNCATE TABLE Student;

TRUNCATE TABLE Course;

TRUNCATE TABLE Teacher;

TRUNCATE TABLE StudentStatus;

SET FOREIGN_KEY_CHECKS = 1;

-- 1. DATA FÖR STUDENTSTATUS
INSERT INTO
    StudentStatus (id, statusName)
VALUES (1, 'Aktiv'),
    (2, 'Examen'),
    (3, 'Utskriven'),
    (4, 'Tjänstledig');

-- 2. DATA FÖR TEACHER
INSERT INTO
    Teacher (
        id,
        firstName,
        lastName,
        email,
        department
    )
VALUES (
        1,
        'Anna',
        'Andersson',
        'anna.a@uni.se',
        'Systemvetenskap'
    ),
    (
        2,
        'Bosse',
        'Berglund',
        'bosse.b@uni.se',
        'Ekonomi'
    ),
    (
        3,
        'Cecilia',
        'Carlsson',
        'cecilia.c@uni.se',
        'Juridik'
    ),
    (
        4,
        'David',
        'Danielsson',
        'david.d@uni.se',
        'Design & Media'
    ),
    (
        5,
        'Elin',
        'Ekström',
        'elin.e@uni.se',
        'Matematik'
    ),
    (
        6,
        'Mattias',
        'Lysell',
        'Matt.Lys@uni.se',
        'Databaser & Säkerhet'
    ),
    (
        7,
        'Sofia',
        'Lindberg',
        'sofia.l@uni.se',
        'Psykologi'
    ),
    (
        8,
        'Markus',
        'Wallin',
        'markus.w@uni.se',
        'Fysik'
    ),
    (
        9,
        'Yasmin',
        'Al-Fayed',
        'yasmin.a@uni.se',
        'Datavetenskap'
    ),
    (
        10,
        'Robert',
        'Johansson',
        'robert.j@uni.se',
        'Historia'
    );

-- 3. DATA FÖR COURSE
INSERT INTO
    Course (
        code,
        name,
        credits,
        responsibleTeacherId
    )
VALUES (
        'DB101',
        'Introduktion till Databaser',
        7.50,
        6
    ),
    (
        'DB205',
        'Avancerad SQL-programmering',
        15.00,
        6
    ),
    (
        'EK100',
        'Ekonomistyrning A',
        7.50,
        2
    ),
    (
        'JU301',
        'Dataskyddslagstiftning',
        15.00,
        3
    ),
    (
        'IT400',
        'Nätverkssäkerhet',
        15.00,
        1
    ),
    (
        'MA500',
        'Diskret Matematik',
        10.00,
        5
    ),
    (
        'DM105',
        'Webbdesign Grund',
        7.50,
        4
    ),
    (
        'EK210',
        'Finansiell Analys',
        22.50,
        2
    ),
    (
        'SY501',
        'Systemutvecklingsmetoder',
        30.00,
        1
    ),
    (
        'BI304',
        'Bygg & Infrastruktur',
        24.00,
        5
    ),
    (
        'AI101',
        'Artificiell Intelligens Grund',
        7.50,
        8
    ),
    (
        'FY200',
        'Kvantmekanik och Relativitet',
        15.00,
        7
    ),
    (
        'PS300',
        'Kognitiv Beteendeterapi C',
        30.00,
        7
    ),
    (
        'HI105',
        'Modern Världshistoria',
        7.50,
        10
    ),
    (
        'CC400',
        'Cloud Computing Architecture',
        20.00,
        8
    );
-- Rättat ID till Yasmin (8) eller behåll (10) om du vill

-- 4. DATA FÖR STUDENT
-- Notera: Jag har lagt till ID 12-16 manuellt här för att matcha din kolumnlista (id, firstName...)
INSERT INTO
    Student (
        id,
        firstName,
        lastName,
        personNr,
        email,
        registeredDate,
        statusId
    )
VALUES (
        1,
        'Sara',
        'Svensson',
        '950101-1234',
        'sara.s@mail.com',
        '2024-08-15',
        1
    ),
    (
        2,
        'Erik',
        'Eriksson',
        '900202-5678',
        'erik.e@mail.com',
        '2024-09-01',
        1
    ),
    (
        3,
        'Lisa',
        'Larsson',
        '000303-9012',
        'lisa.l@mail.com',
        '2024-08-15',
        2
    ),
    (
        4,
        'Pelle',
        'Persson',
        '880404-3456',
        'pelle.p@mail.com',
        '2024-10-10',
        4
    ),
    (
        5,
        'Maria',
        'Månsson',
        '020505-7890',
        'maria.m@mail.com',
        '2024-10-10',
        3
    ),
    (
        6,
        'Olle',
        'Olofsson',
        '990606-2109',
        'olle.o@mail.com',
        '2024-11-01',
        1
    ),
    (
        7,
        'Frida',
        'Falk',
        '970707-1122',
        'frida.f@mail.com',
        '2023-01-10',
        1
    ),
    (
        8,
        'Gustav',
        'Gröndahl',
        '850808-3344',
        'gustav.g@mail.com',
        '2023-08-20',
        2
    ),
    (
        9,
        'Hanna',
        'Holm',
        '010909-5566',
        'hanna.h@mail.com',
        '2024-10-05',
        4
    ),
    (
        10,
        'Johan',
        'Jansson',
        '031010-7788',
        'johan.j@mail.com',
        '2024-11-15',
        1
    ),
    (
        11,
        'Valle',
        'Svantesson',
        '960406-5679',
        'Valle.S@mail.com',
        '2025-03-23',
        1
    ),
    -- Nya studenter (fick ID manuellt för att undvika fel):
    (
        12,
        'Alice',
        'Åkesson',
        '010101-9999',
        'alice.a@mail.com',
        '2023-08-15',
        1
    ),
    (
        13,
        'Björn',
        'Berg',
        '950505-8888',
        'bjorn.b@mail.com',
        '2020-01-10',
        2
    ),
    (
        14,
        'Clara',
        'Ceder',
        '030303-7777',
        'clara.c@mail.com',
        CURDATE(),
        1
    ),
    (
        15,
        'Daniel',
        'Dahl',
        '991212-6666',
        'daniel.d@mail.com',
        '2024-01-01',
        3
    ),
    (
        16,
        'Kevin',
        'Kvist',
        '000101-5432',
        'kevin.k@mail.com',
        CURDATE(),
        1
    );

-- 5. DATA FÖR STUDENTENROLLMENT
INSERT INTO
    StudentEnrollment (
        studentId,
        courseCode,
        grade,
        completionDate
    )
VALUES
    -- Sara (ID 1)
    (1, 'DB101', 'A', '2024-10-20'),
    (1, 'EK100', 'B', '2024-11-15'),
    (1, 'DB205', NULL, NULL),

-- Erik (ID 2)
(2, 'DB101', 'B', '2024-10-20'),
(2, 'EK100', 'G', '2024-12-01'),
(2, 'JU301', 'G', '2024-11-10'),
(2, 'MA500', 'A', '2024-12-20'),

-- Lisa (ID 3)
(3, 'DB101', 'A', '2024-10-20'),
(3, 'DB205', 'B', '2024-12-10'),
(3, 'JU301', 'A', '2024-11-10'),
(3, 'IT400', 'C', '2025-01-20'),

-- Pelle (ID 4)
(4, 'DB205', 'C', '2024-12-10'), (4, 'JU301', 'B', '2024-11-10'),

-- Maria (ID 5)
(5, 'DB101', 'G', '2024-10-20'), (5, 'EK100', 'U', '2024-12-01'),

-- Olle (ID 6)
(6, 'DB101', NULL, NULL),
(6, 'DB205', NULL, NULL),
(6, 'DM105', NULL, NULL),

-- Frida (ID 7)
(7, 'EK100', 'A', '2023-03-15'),
(7, 'EK210', 'B', '2024-06-01'),
(7, 'JU301', 'A', '2023-12-10'),
(7, 'SY501', NULL, NULL),

-- Gustav (ID 8)
(8, 'DM105', 'B', '2023-10-25'),
(8, 'IT400', 'A', '2024-01-10'),
(8, 'DB101', 'B', '2023-09-01'),

-- Hanna (ID 9)
(9, 'DB101', NULL, NULL),

-- Johan (ID 10)
(10, 'DB101', NULL, NULL), (10, 'EK100', NULL, NULL),

-- Valle (ID 11)
(11, 'BI304', NULL, NULL),
(
    11,
    'IT400',
    'A',
    '2023-11-29'
),
(
    11,
    'EK210',
    'B',
    '2024-06-01'
),

-- Alice (ID 12)
(12, 'AI101', NULL, NULL), ( 12, 'FY200', 'A', '2024-12-20' ),

-- Björn (ID 13)
(
    13,
    'HI105',
    'B',
    '2022-06-05'
),
(
    13,
    'PS300',
    'A',
    '2023-01-15'
),

-- Clara (ID 14)
(14, 'AI101', NULL, NULL),

-- Daniel (ID 15)
( 15, 'CC400', 'U', '2024-03-10' );

-- Kevin (ID 16) har inga kurser (för att testa fråga 13)