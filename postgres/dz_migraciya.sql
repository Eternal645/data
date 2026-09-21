DROP TABLE IF EXISTS pachki;
DROP TABLE IF EXISTS parametry;
DROP TABLE IF EXISTS polzovateli;
DROP TABLE IF EXISTS tipy_oborudovaniya;
DROP TABLE IF EXISTS dolzhnosti;

CREATE TABLE dolzhnosti (
    id INTEGER PRIMARY KEY,
    position_code VARCHAR(20) UNIQUE NOT NULL,
    position_name VARCHAR(100) NOT NULL
);

CREATE TABLE tipy_oborudovaniya (
    id INTEGER PRIMARY KEY,
    equipment_type_code VARCHAR(20) UNIQUE NOT NULL,
    equipment_type_name VARCHAR(100) NOT NULL
);

CREATE TABLE polzovateli (
    id INTEGER PRIMARY KEY,
    user_code VARCHAR(20) UNIQUE NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    dolzhnost_id INTEGER NOT NULL REFERENCES dolzhnosti(id)
);

CREATE TABLE parametry (
    id INTEGER PRIMARY KEY,
    parameter_code VARCHAR(20) UNIQUE NOT NULL,
    parameter_name VARCHAR(100) NOT NULL,
    value VARCHAR(100) NOT NULL,
    tip_oborudovaniya_id INTEGER NOT NULL REFERENCES tipy_oborudovaniya(id)
);

CREATE TABLE pachki (
    id INTEGER PRIMARY KEY,
    pachka_code VARCHAR(20) UNIQUE NOT NULL,
    pachka_name VARCHAR(100) NOT NULL,
    polzovatel_id INTEGER NOT NULL REFERENCES polzovateli(id),
    tip_oborudovaniya_id INTEGER NOT NULL REFERENCES tipy_oborudovaniya(id),
    created_date DATE NOT NULL
);

INSERT INTO dolzhnosti VALUES (1, 'POS-001', 'Инженер');
INSERT INTO dolzhnosti VALUES (2, 'POS-002', 'Мастер участка');
INSERT INTO dolzhnosti VALUES (3, 'POS-003', 'Кладовщик');

INSERT INTO tipy_oborudovaniya VALUES (1, 'EQT-001', 'Станок токарный');
INSERT INTO tipy_oborudovaniya VALUES (2, 'EQT-002', 'Конвейер');
INSERT INTO tipy_oborudovaniya VALUES (3, 'EQT-003', 'Пресс гидравлический');

INSERT INTO polzovateli VALUES (1, 'USR-001', 'Иванов Иван Иванович', 1);
INSERT INTO polzovateli VALUES (2, 'USR-002', 'Петров Петр Петрович', 2);
INSERT INTO polzovateli VALUES (3, 'USR-003', 'Сидорова Анна Сергеевна', 3);

INSERT INTO parametry VALUES (1, 'PAR-001', 'Мощность, кВт', '15', 1);
INSERT INTO parametry VALUES (2, 'PAR-002', 'Скорость, м/мин', '2.5', 2);
INSERT INTO parametry VALUES (3, 'PAR-003', 'Давление, бар', '200', 3);

INSERT INTO pachki VALUES (1, 'PCH-001', 'Партия №1', 1, 1, DATE '2026-09-01');
INSERT INTO pachki VALUES (2, 'PCH-002', 'Партия №2', 2, 2, DATE '2026-09-10');
INSERT INTO pachki VALUES (3, 'PCH-003', 'Партия №3', 3, 3, DATE '2026-09-15');

SELECT p.pachka_code AS "Код пачки", p.pachka_name AS "Пачка", p.created_date AS "Дата создания",
       u.user_code AS "Код пользователя", u.full_name AS "Пользователь",
       d.position_code AS "Код должности", d.position_name AS "Должность",
       t.equipment_type_code AS "Код оборудования", t.equipment_type_name AS "Тип оборудования",
       pr.parameter_code AS "Код параметра", pr.parameter_name AS "Параметр", pr.value AS "Значение"
FROM pachki p
JOIN polzovateli u ON u.id = p.polzovatel_id
JOIN dolzhnosti d ON d.id = u.dolzhnost_id
JOIN tipy_oborudovaniya t ON t.id = p.tip_oborudovaniya_id
JOIN parametry pr ON pr.tip_oborudovaniya_id = t.id
ORDER BY p.pachka_code;
