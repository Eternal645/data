DO $$
BEGIN
    DROP FUNCTION IF EXISTS check_parametry(t_parametry);
    DROP FUNCTION IF EXISTS meteo_ddchchm(TIMESTAMP);
    DROP FUNCTION IF EXISTS meteo_vvvv(NUMERIC);
    DROP FUNCTION IF EXISTS meteo_bbbbtt(NUMERIC, NUMERIC);
    DROP TYPE IF EXISTS t_parametry;

    -- Расширение DDL: входные параметры и информация об ошибках
    ALTER TABLE pachki ADD COLUMN IF NOT EXISTS meteo_height    NUMERIC;
    ALTER TABLE pachki ADD COLUMN IF NOT EXISTS temperature     NUMERIC;
    ALTER TABLE pachki ADD COLUMN IF NOT EXISTS pressure        NUMERIC;
    ALTER TABLE pachki ADD COLUMN IF NOT EXISTS wind_direction  NUMERIC;
    ALTER TABLE pachki ADD COLUMN IF NOT EXISTS wind_speed      NUMERIC;
    ALTER TABLE pachki ADD COLUMN IF NOT EXISTS drift_range     NUMERIC;
    ALTER TABLE pachki ADD COLUMN IF NOT EXISTS has_error       BOOLEAN NOT NULL DEFAULT FALSE;
    ALTER TABLE pachki ADD COLUMN IF NOT EXISTS error_text      TEXT;
    COMMENT ON COLUMN pachki.meteo_height   IS 'Высота метеопоста, м';
    COMMENT ON COLUMN pachki.temperature    IS 'Температура, °C';
    COMMENT ON COLUMN pachki.pressure       IS 'Давление, гПа';
    COMMENT ON COLUMN pachki.wind_direction IS 'Направление ветра, °';
    COMMENT ON COLUMN pachki.wind_speed     IS 'Скорость ветра, м/с';
    COMMENT ON COLUMN pachki.drift_range    IS 'Дальность сноса пуль, м';
    COMMENT ON COLUMN pachki.has_error      IS 'Флаг: в параметрах есть ошибка';
    COMMENT ON COLUMN pachki.error_text     IS 'Описание ошибок параметров (через "; ")';

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

    -- Функция проверки: на входе список параметров, на выходе строка со списком ошибок
    CREATE FUNCTION check_parametry(p t_parametry)
    RETURNS TEXT
    AS $func$
    DECLARE
        v_errors TEXT[] := ARRAY[]::TEXT[];
        r        RECORD;
        d        t_diapazon;
    BEGIN
        IF p.equipment_type_id IS NULL THEN
            v_errors := v_errors || 'Тип оборудования: не задан';
        END IF;

        FOR r IN
            SELECT * FROM (VALUES
                ('HEIGHT',         'Высота метеопоста',  p.meteo_height),
                ('TEMPERATURE',    'Температура',        p.temperature),
                ('PRESSURE',       'Давление',           p.pressure),
                ('WIND_DIRECTION', 'Направление ветра',  p.wind_direction),
                ('WIND_SPEED',     'Скорость ветра',     p.wind_speed),
                ('DRIFT_RANGE',    'Дальность сноса пуль', p.drift_range)
            ) AS t(code, name, val)
        LOOP
            d := get_diapazon(r.code);
            IF r.val IS NULL THEN
                v_errors := v_errors || (r.name || ': не задано');
            ELSIF r.val < d.min_value OR r.val > d.max_value THEN
                v_errors := v_errors || format('%s: значение %s вне диапазона от %s до %s',
                                               r.name, r.val, d.min_value, d.max_value);
            END IF;
        END LOOP;

        RETURN array_to_string(v_errors, '; ');
    END;
    $func$ LANGUAGE plpgsql;
    COMMENT ON FUNCTION check_parametry(t_parametry)
        IS 'Проверяет параметры и возвращает строку со списком ошибок (пустая строка, если ошибок нет)';

    -- Тестовые значения параметров
    UPDATE pachki SET meteo_height = 150, temperature = 18, pressure = 1013,
                      wind_direction = 270, wind_speed = 4, drift_range = 1200
    WHERE code = 'PCH-001';
    UPDATE pachki SET meteo_height = 220, temperature = 75, pressure = 650,
                      wind_direction = 90, wind_speed = 7, drift_range = 800
    WHERE code = 'PCH-002';
    UPDATE pachki SET meteo_height = 80, temperature = -12, pressure = 995,
                      wind_direction = 400, wind_speed = NULL, drift_range = 6000
    WHERE code = 'PCH-003';

    -- Заполнение информации об ошибках
    UPDATE pachki
    SET error_text = check_parametry(ROW(tip_oborudovaniya_id, meteo_height, temperature,
                                         pressure, wind_direction, wind_speed, drift_range)::t_parametry);
    UPDATE pachki SET has_error = (error_text <> '');

    -- Метео приближенный: ДДЧЧМ (день, час, десятки минут)
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
