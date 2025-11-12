-- Använd den databas du skapade (ersätt "CoursePortalDB" med ditt valda namn)
-- USE CoursePortalDB;

-- ---------------------------------
-- STEG 1: Lägg till Lärare (Teacher)
-- ---------------------------------
-- Lärare (ID 1, 2, 3) kommer att refereras av kurser.
INSERT INTO
    Teacher (
        firstName,
        lastName,
        email,
        department
    )
VALUES (
        'Anna',
        'Andersson',
        'anna.a@uni.se',
        'Systemvetenskap'
    ), -- ID 1
    (
        'Bosse',
        'Berglund',
        'bosse.b@uni.se',
        'Ekonomi'
    ), -- ID 2
    (
        'Cecilia',
        'Carlsson',
        'cecilia.c@uni.se',
        'Juridik'
    );
-- ID 3

-- ---------------------------------
-- STEG 2: Lägg till Kurser (Course)
-- ---------------------------------
-- Visa 1-M-relation: Anna ansvarar för två kurser (DB101, DB205).
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
        1
    ),
    (
        'DB205',
        'Avancerad SQL-programmering',
        15.00,
        1
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
    );
-- Anna har nu 3 kurser

-- ---------------------------------
-- STEG 3: Lägg till Studenter (Student)
-- ---------------------------------
-- Skapa en blandning av studenter med olika registreringsdatum.
INSERT INTO
    Student (
        firstName,
        lastName,
        personNr,
        email,
        registeredDate
    )
VALUES (
        'Sara',
        'Svensson',
        '950101-1234',
        'sara.s@mail.com',
        '2024-08-15'
    ), -- ID 1
    (
        'Erik',
        'Eriksson',
        '900202-5678',
        'erik.e@mail.com',
        '2024-09-01'
    ), -- ID 2
    (
        'Lisa',
        'Larsson',
        '000303-9012',
        'lisa.l@mail.com',
        '2024-08-15'
    ), -- ID 3
    (
        'Pelle',
        'Persson',
        '880404-3456',
        'pelle.p@mail.com',
        '2024-10-10'
    ), -- ID 4
    (
        'Maria',
        'Månsson',
        '020505-7890',
        'maria.m@mail.com',
        '2024-10-10'
    ), -- ID 5
    (
        'Olle',
        'Olofsson',
        '990606-2109',
        'olle.o@mail.com',
        '2024-11-01'
    );
-- ID 6

-- ---------------------------------
-- STEG 4: Lägg till Inskrivningar (StudentEnrollment)
-- ---------------------------------
-- Detta är testdata för M-M-relationen och VG-kraven!
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
    (1, 'DB205', NULL, NULL), -- Inskriven, ej klar

-- Erik (ID 2)
(2, 'DB101', 'B', '2024-10-20'),
(2, 'EK100', 'G', '2024-12-01'),
(2, 'JU301', 'G', '2024-11-10'),

-- Lisa (ID 3)
(3, 'DB101', 'A', '2024-10-20'),
(3, 'DB205', 'B', '2024-12-10'),
(3, 'JU301', 'A', '2024-11-10'),
(3, 'IT400', NULL, NULL), -- Inskriven, ej klar (4 kurser totalt)

-- Pelle (ID 4)
(4, 'DB205', 'C', '2024-12-10'), (4, 'JU301', 'B', '2024-11-10'),

-- Maria (ID 5)
(5, 'DB101', 'G', '2024-10-20'),

-- Olle (ID 6)
(6, 'DB101', NULL, NULL), -- Inskriven, ej klar
(6, 'DB205', NULL, NULL);
-- Inskriven, ej klar