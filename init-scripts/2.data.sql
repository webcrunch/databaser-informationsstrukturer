-- Steg 0: Säkerställ att tabellerna är tomma för att kunna köra skriptet flera gånger
-- Detta kräver att du har kört schema.sql först.
SET FOREIGN_KEY_CHECKS = 0;

SET NAMES 'utf8mb4';

SET CHARACTER SET utf8mb4;

USE Nexus_DB;

TRUNCATE TABLE `StudentEnrollment`;

TRUNCATE TABLE `Student`;

TRUNCATE TABLE `Course`;

TRUNCATE TABLE `Teacher`;

TRUNCATE TABLE `StudentStatus`;

SET FOREIGN_KEY_CHECKS = 1;

-- 1. DATA FÖR STUDENTSTATUS (Måste köras först)
INSERT INTO
    `StudentStatus` (`id`, `statusName`)
VALUES (1, 'Aktiv'),
    (2, 'Examen'),
    (3, 'Utskriven'),
    (4, 'Tjänstledig');

-- 2. DATA FÖR TEACHER (Lärare)
-- Utökad lista med fler lärare (ID 1 till 5).
-- Sätter in id för att ha kontroll över vilken teacher som kopplas till vilken kurs.
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
        'Mathias',
        'Thyssel',
        'Math.Thy@uni.se',
        'Databaser & Säkerhet'
    );

-- 3. DATA FÖR COURSE (Kurser)
-- Utökad lista med varierade credits och nya kurser.
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
    );

-- 4. DATA FÖR STUDENT (Studenter)
-- Utökad lista med fler studenter (ID 1 till 11) och varierad status.
-- Sätter in id för att ha kontroll över vilken student som kopplas till vilken kurs.
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
    ), -- Aktiv
    (
        2,
        'Erik',
        'Eriksson',
        '900202-5678',
        'erik.e@mail.com',
        '2024-09-01',
        1
    ), -- Aktiv
    (
        3,
        'Lisa',
        'Larsson',
        '000303-9012',
        'lisa.l@mail.com',
        '2024-08-15',
        2
    ), -- Examen
    (
        4,
        'Pelle',
        'Persson',
        '880404-3456',
        'pelle.p@mail.com',
        '2024-10-10',
        4
    ), -- Tjänstledig
    (
        5,
        'Maria',
        'Månsson',
        '020505-7890',
        'maria.m@mail.com',
        '2024-10-10',
        3
    ), -- Utskriven
    (
        6,
        'Olle',
        'Olofsson',
        '990606-2109',
        'olle.o@mail.com',
        '2024-11-01',
        1
    ), -- Aktiv
    (
        7,
        'Frida',
        'Falk',
        '970707-1122',
        'frida.f@mail.com',
        '2023-01-10',
        1
    ), -- Aktiv
    (
        8,
        'Gustav',
        'Gröndahl',
        '850808-3344',
        'gustav.g@mail.com',
        '2023-08-20',
        2
    ), -- Examen
    (
        9,
        'Hanna',
        'Holm',
        '010909-5566',
        'hanna.h@mail.com',
        '2024-10-05',
        4
    ), -- Tjänstledig
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
    );
-- 5. DATA FÖR STUDENTENROLLMENT (Inskrivningar)
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
    (1, 'DB205', NULL, NULL), -- Pågående

-- Erik (ID 2)
(2, 'DB101', 'B', '2024-10-20'),
(2, 'EK100', 'G', '2024-12-01'),
(2, 'JU301', 'G', '2024-11-10'),
(2, 'MA500', 'A', '2024-12-20'),

-- Lisa (ID 3) - Examen
(3, 'DB101', 'A', '2024-10-20'),
(3, 'DB205', 'B', '2024-12-10'),
(3, 'JU301', 'A', '2024-11-10'),
(3, 'IT400', 'C', '2025-01-20'),

-- Pelle (ID 4) - Tjänstledig
(4, 'DB205', 'C', '2024-12-10'), (4, 'JU301', 'B', '2024-11-10'),

-- Maria (ID 5) - Utskriven
(5, 'DB101', 'G', '2024-10-20'), (5, 'EK100', 'U', '2024-12-01'),

-- Olle (ID 6) - Aktiv
(6, 'DB101', NULL, NULL), -- Pågående
(6, 'DB205', NULL, NULL), -- Pågående
(6, 'DM105', NULL, NULL), -- Pågående

-- Frida (ID 7) - Aktiv
(7, 'EK100', 'A', '2023-03-15'),
(7, 'EK210', 'B', '2024-06-01'),
(7, 'JU301', 'A', '2023-12-10'),
(7, 'SY501', NULL, NULL), -- Pågående

-- Gustav (ID 8) - Examen
(8, 'DM105', 'B', '2023-10-25'),
(8, 'IT400', 'A', '2024-01-10'),
(8, 'DB101', 'B', '2023-09-01'),

-- Hanna (ID 9) - Tjänstledig
(9, 'DB101', NULL, NULL),

-- Johan (ID 10) - Aktiv
(10, 'DB101', NULL, NULL), (10, 'EK100', NULL, NULL);

-- Valle (ID 11 ) -Aktiv
(11, 'BI304', NULL, NULL) -- Pågående
,
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
)