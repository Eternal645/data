DO $$
BEGIN

    -- Вложенная транзакция 1. Таблицы и счётчики
    BEGIN
        DROP TABLE IF EXISTS raschet_temperatury CASCADE;
        DROP TABLE IF EXISTS pachki CASCADE;
        DROP TABLE IF EXISTS polzovateli CASCADE;
        DROP TABLE IF EXISTS tipy_oborudovaniya CASCADE;
        DROP TABLE IF EXISTS dolzhnosti CASCADE;

        DROP SEQUENCE IF EXISTS seq_raschet_temperatury;
        DROP SEQUENCE IF EXISTS seq_pachki;
        DROP SEQUENCE IF EXISTS seq_polzovateli;
        DROP SEQUENCE IF EXISTS seq_tipy_oborudovaniya;
        DROP SEQUENCE IF EXISTS seq_dolzhnosti;

        CREATE SEQUENCE seq_dolzhnosti;
        CREATE SEQUENCE seq_tipy_oborudovaniya;
        CREATE SEQUENCE seq_polzovateli;
        CREATE SEQUENCE seq_pachki;
        CREATE SEQUENCE seq_raschet_temperatury;

        CREATE TABLE dolzhnosti (
            id    INTEGER PRIMARY KEY DEFAULT nextval('seq_dolzhnosti'),
            code  VARCHAR(20)  NOT NULL,
            name  VARCHAR(100) NOT NULL
        );

        CREATE TABLE tipy_oborudovaniya (
            id    INTEGER PRIMARY KEY DEFAULT nextval('seq_tipy_oborudovaniya'),
            code  VARCHAR(20)  NOT NULL,
            name  VARCHAR(100) NOT NULL
        );

        CREATE TABLE polzovateli (
            id            INTEGER PRIMARY KEY DEFAULT nextval('seq_polzovateli'),
            code          VARCHAR(20)  NOT NULL,
            full_name     VARCHAR(150) NOT NULL,
            dolzhnost_id  INTEGER      NOT NULL
        );

        CREATE TABLE pachki (
            id                    INTEGER PRIMARY KEY DEFAULT nextval('seq_pachki'),
            code                  VARCHAR(20)  NOT NULL,
            name                  VARCHAR(100) NOT NULL,
            polzovatel_id         INTEGER      NOT NULL,
            tip_oborudovaniya_id  INTEGER      NOT NULL,
            created_date          DATE         NOT NULL
        );

        CREATE TABLE raschet_temperatury (
            id            INTEGER PRIMARY KEY DEFAULT nextval('seq_raschet_temperatury'),
            code          VARCHAR(20)  NOT NULL,
            pachka_id     INTEGER      NOT NULL,
            temp_celsius  NUMERIC(6,2) NOT NULL,
            temp_kelvin   NUMERIC(6,2) NOT NULL,
            calc_date     DATE         NOT NULL
        );

        -- счётчики принадлежат своим столбцам
        ALTER SEQUENCE seq_dolzhnosti          OWNED BY dolzhnosti.id;
        ALTER SEQUENCE seq_tipy_oborudovaniya  OWNED BY tipy_oborudovaniya.id;
        ALTER SEQUENCE seq_polzovateli         OWNED BY polzovateli.id;
        ALTER SEQUENCE seq_pachki              OWNED BY pachki.id;
        ALTER SEQUENCE seq_raschet_temperatury OWNED BY raschet_temperatury.id;

        -- комментарии к таблицам и столбцам
        COMMENT ON TABLE dolzhnosti IS 'Справочник должностей сотрудников';
        COMMENT ON COLUMN dolzhnosti.id IS 'Идентификатор должности (счётчик seq_dolzhnosti)';
        COMMENT ON COLUMN dolzhnosti.code IS 'Уникальный код должности';
        COMMENT ON COLUMN dolzhnosti.name IS 'Название должности';

        COMMENT ON TABLE tipy_oborudovaniya IS 'Справочник типов оборудования';
        COMMENT ON COLUMN tipy_oborudovaniya.id IS 'Идентификатор типа оборудования (счётчик seq_tipy_oborudovaniya)';
        COMMENT ON COLUMN tipy_oborudovaniya.code IS 'Уникальный код типа оборудования';
        COMMENT ON COLUMN tipy_oborudovaniya.name IS 'Название типа оборудования';

        COMMENT ON TABLE polzovateli IS 'Пользователи (сотрудники), работающие с пачками';
        COMMENT ON COLUMN polzovateli.id IS 'Идентификатор пользователя (счётчик seq_polzovateli)';
        COMMENT ON COLUMN polzovateli.code IS 'Уникальный код пользователя';
        COMMENT ON COLUMN polzovateli.full_name IS 'ФИО пользователя';
        COMMENT ON COLUMN polzovateli.dolzhnost_id IS 'Ссылка на должность пользователя';

        COMMENT ON TABLE pachki IS 'Пачки оборудования';
        COMMENT ON COLUMN pachki.id IS 'Идентификатор пачки (счётчик seq_pachki)';
        COMMENT ON COLUMN pachki.code IS 'Уникальный код пачки';
        COMMENT ON COLUMN pachki.name IS 'Название пачки';
        COMMENT ON COLUMN pachki.polzovatel_id IS 'Ссылка на пользователя, создавшего пачку';
        COMMENT ON COLUMN pachki.tip_oborudovaniya_id IS 'Ссылка на тип оборудования';
        COMMENT ON COLUMN pachki.created_date IS 'Дата создания пачки';

        COMMENT ON TABLE raschet_temperatury IS 'Расчет температуры по пачкам (таблица 1)';
        COMMENT ON COLUMN raschet_temperatury.id IS 'Идентификатор расчёта (счётчик seq_raschet_temperatury)';
        COMMENT ON COLUMN raschet_temperatury.code IS 'Уникальный код расчёта';
        COMMENT ON COLUMN raschet_temperatury.pachka_id IS 'Ссылка на пачку, для которой выполнен расчёт';
        COMMENT ON COLUMN raschet_temperatury.temp_celsius IS 'Температура, °C';
        COMMENT ON COLUMN raschet_temperatury.temp_kelvin IS 'Температура, K (Цельсий + 273.15)';
        COMMENT ON COLUMN raschet_temperatury.calc_date IS 'Дата расчёта';
    END;

    -- Вложенная транзакция 2. Тестовые данные
    DECLARE
        i         INTEGER;
        v_celsius NUMERIC(6,2);
    BEGIN
        INSERT INTO dolzhnosti (code, name) VALUES
            ('POS-001', 'Инженер'),
            ('POS-002', 'Мастер участка'),
            ('POS-003', 'Кладовщик');

        INSERT INTO tipy_oborudovaniya (code, name) VALUES
            ('EQT-001', 'Станок токарный'),
            ('EQT-002', 'Конвейер'),
            ('EQT-003', 'Пресс гидравлический');

        INSERT INTO polzovateli (code, full_name, dolzhnost_id) VALUES
            ('USR-001', 'Иванов Иван Иванович', 1),
            ('USR-002', 'Петров Петр Петрович', 2),
            ('USR-003', 'Сидорова Анна Сергеевна', 3);

        INSERT INTO pachki (code, name, polzovatel_id, tip_oborudovaniya_id, created_date) VALUES
            ('PCH-001', 'Партия №1', 1, 1, DATE '2026-09-01'),
            ('PCH-002', 'Партия №2', 2, 2, DATE '2026-09-10'),
            ('PCH-003', 'Партия №3', 3, 3, DATE '2026-09-15');

        -- расчёт температуры: цикл формирует 6 замеров, Кельвины = Цельсий + 273.15
        FOR i IN 1..6 LOOP
            v_celsius := 20 + i * 15.5;
            INSERT INTO raschet_temperatury (code, pachka_id, temp_celsius, temp_kelvin, calc_date)
            VALUES ('TMP-' || LPAD(i::TEXT, 3, '0'),
                    ((i - 1) % 3) + 1,
                    v_celsius,
                    v_celsius + 273.15,
                    DATE '2026-09-20' + i);
        END LOOP;
    END;

    -- Вложенная транзакция 3. Связи и ограничения
    BEGIN
        ALTER TABLE dolzhnosti          ADD CONSTRAINT uq_dolzhnosti_code          UNIQUE (code);
        ALTER TABLE tipy_oborudovaniya  ADD CONSTRAINT uq_tipy_oborudovaniya_code  UNIQUE (code);
        ALTER TABLE polzovateli         ADD CONSTRAINT uq_polzovateli_code         UNIQUE (code);
        ALTER TABLE pachki              ADD CONSTRAINT uq_pachki_code              UNIQUE (code);
        ALTER TABLE raschet_temperatury ADD CONSTRAINT uq_raschet_temperatury_code UNIQUE (code);

        ALTER TABLE polzovateli ADD CONSTRAINT fk_polzovateli_dolzhnost
            FOREIGN KEY (dolzhnost_id) REFERENCES dolzhnosti (id);
        ALTER TABLE pachki ADD CONSTRAINT fk_pachki_polzovatel
            FOREIGN KEY (polzovatel_id) REFERENCES polzovateli (id);
        ALTER TABLE pachki ADD CONSTRAINT fk_pachki_tip_oborudovaniya
            FOREIGN KEY (tip_oborudovaniya_id) REFERENCES tipy_oborudovaniya (id);
        ALTER TABLE raschet_temperatury ADD CONSTRAINT fk_raschet_pachka
            FOREIGN KEY (pachka_id) REFERENCES pachki (id);

        -- температура в Кельвинах не может быть отрицательной
        ALTER TABLE raschet_temperatury ADD CONSTRAINT ck_raschet_kelvin
            CHECK (temp_kelvin >= 0);
    END;

END $$;