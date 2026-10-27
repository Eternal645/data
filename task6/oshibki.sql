DO $$
BEGIN
    DROP FUNCTION IF EXISTS check_parametry(t_parametry);
    DROP FUNCTION IF EXISTS meteo_ddchchm(TIMESTAMP);
    DROP FUNCTION IF EXISTS meteo_vvvv(NUMERIC);
    DROP FUNCTION IF EXISTS meteo_bbbbtt(NUMERIC, NUMERIC);
    DROP TYPE IF EXISTS t_parametry;
    DROP TABLE IF EXISTS parametry_pachek;

    -- Расширение DDL: значения входных параметров пачек
    CREATE TABLE parametry_pachek (
        id           INTEGER PRIMARY KEY,
        pachka_id    INTEGER NOT NULL REFERENCES pachki (id),
        konstanta_id INTEGER NOT NULL REFERENCES konstanty_proverki (id),
        value        NUMERIC NOT NULL,
        CONSTRAINT uq_parametry_pachek UNIQUE (pachka_id, konstanta_id)
    );
    COMMENT ON TABLE parametry_pachek IS 'Значения входных параметров пачек';
    COMMENT ON COLUMN parametry_pachek.id IS 'Идентификатор значения';
    COMMENT ON COLUMN parametry_pachek.pachka_id IS 'Ссылка на пачку';
    COMMENT ON COLUMN parametry_pachek.konstanta_id IS 'Ссылка на параметр (konstanty_proverki)';
    COMMENT ON COLUMN parametry_pachek.value IS 'Значение параметра';

    -- Новый тип данных: список параметров
    CREATE TYPE t_parametry AS (
        equipment_type_id INTEGER,
        meteo_height      NUMERIC,
        temperature       NUMERIC,
        pressure          NUMERIC,
        wind_direction    NUMERIC,
        wind_speed        NUMERIC,
        drift_range       NUMERIC
    );
    COMMENT ON TYPE t_parametry IS 'Список входных параметров пачки';

    -- Функция проверки: на входе список параметров, на выходе строка со списком ошибок.
    CREATE FUNCTION check_parametry(p t_parametry)
    RETURNS TEXT
    AS $func$
    DECLARE
        v_errors TEXT[] := ARRAY[]::TEXT[];
        r        RECORD;
        d        t_diapazon;
    BEGIN
        IF p.equipment_type_id IS NULL THEN
            v_errors := v_errors || get_tekst_oshibki('EQUIPMENT_TYPE_NOT_SET');
        END IF;

        FOR r IN
            SELECT k.code, k.name, v.val
            FROM (VALUES
                ('HEIGHT',         p.meteo_height),
                ('TEMPERATURE',    p.temperature),
                ('PRESSURE',       p.pressure),
                ('WIND_DIRECTION', p.wind_direction),
                ('WIND_SPEED',     p.wind_speed),
                ('DRIFT_RANGE',    p.drift_range)
            ) AS v(code, val)
            JOIN konstanty_proverki k ON k.code = v.code
            ORDER BY k.id
        LOOP
            d := get_diapazon(r.code);
            IF r.val IS NULL THEN
                v_errors := v_errors || format(get_tekst_oshibki('NOT_SET'), r.name);
            ELSIF r.val < d.min_value OR r.val > d.max_value THEN
                v_errors := v_errors || format(get_tekst_oshibki('OUT_OF_RANGE'),
                                               r.name, r.val, d.min_value, d.max_value);
            END IF;
        END LOOP;

        RETURN array_to_string(v_errors, '; ');
    END;
    $func$ LANGUAGE plpgsql;
    COMMENT ON FUNCTION check_parametry(t_parametry)
        IS 'Проверяет параметры и возвращает строку со списком ошибок (пустая строка, если ошибок нет)';

    -- Тестовые данные: корректные и некорректные значения
    INSERT INTO parametry_pachek (id, pachka_id, konstanta_id, value)
    SELECT ROW_NUMBER() OVER (ORDER BY p.code, k.id), p.id, k.id, v.val
    FROM (VALUES
        ('PCH-001', 'HEIGHT',         150), ('PCH-001', 'TEMPERATURE',     18),
        ('PCH-001', 'PRESSURE',      1013), ('PCH-001', 'WIND_DIRECTION', 270),
        ('PCH-001', 'WIND_SPEED',       4), ('PCH-001', 'DRIFT_RANGE',   1200),
        ('PCH-002', 'HEIGHT',         220), ('PCH-002', 'TEMPERATURE',     75),
        ('PCH-002', 'PRESSURE',       650), ('PCH-002', 'WIND_DIRECTION',  90),
        ('PCH-002', 'WIND_SPEED',       7), ('PCH-002', 'DRIFT_RANGE',    800),
        ('PCH-003', 'HEIGHT',          80), ('PCH-003', 'TEMPERATURE',    -12),
        ('PCH-003', 'PRESSURE',       995), ('PCH-003', 'WIND_DIRECTION', 400),
        ('PCH-003', 'DRIFT_RANGE',   6000)
    ) AS v(pcode, kcode, val)
    JOIN pachki p ON p.code = v.pcode
    JOIN konstanty_proverki k ON k.code = v.kcode;

    -- Метео приближенный: ДДЧЧМ
    CREATE FUNCTION meteo_ddchchm(p_datetime TIMESTAMP)
    RETURNS TEXT
    AS $func$
    BEGIN
        RETURN to_char(p_datetime, 'DDHH24')
            || (EXTRACT(MINUTE FROM p_datetime)::INTEGER / 10)::TEXT;
    END;
    $func$ LANGUAGE plpgsql;
    COMMENT ON FUNCTION meteo_ddchchm(TIMESTAMP) IS 'Метео приближенный: группа ДДЧЧМ';

    -- Метео приближенный: ВВВВ (высота метеопоста, 4 цифры)
    CREATE FUNCTION meteo_vvvv(p_height NUMERIC)
    RETURNS TEXT
    AS $func$
    BEGIN
        RETURN lpad(ROUND(p_height)::INTEGER::TEXT, 4, '0');
    END;
    $func$ LANGUAGE plpgsql;
    COMMENT ON FUNCTION meteo_vvvv(NUMERIC) IS 'Метео приближенный: группа ВВВВ';

    -- Метео приближенный: ББББТТ (давление 4 цифры, температура 2 цифры; для минуса +50)
    CREATE FUNCTION meteo_bbbbtt(p_pressure NUMERIC, p_temperature NUMERIC)
    RETURNS TEXT
    AS $func$
    DECLARE
        v_tt INTEGER := ROUND(ABS(p_temperature));
    BEGIN
        IF p_temperature < 0 THEN
            v_tt := v_tt + 50;
        END IF;
        RETURN lpad(ROUND(p_pressure)::INTEGER::TEXT, 4, '0') || lpad(v_tt::TEXT, 2, '0');
    END;
    $func$ LANGUAGE plpgsql;
    COMMENT ON FUNCTION meteo_bbbbtt(NUMERIC, NUMERIC) IS 'Метео приближенный: группа ББББТТ';
END $$;