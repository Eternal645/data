DO $$
BEGIN
    DROP FUNCTION IF EXISTS get_diapazon(TEXT);
    DROP TYPE IF EXISTS t_diapazon;
    DROP TABLE IF EXISTS konstanty_proverki;

    -- Таблица констант
    CREATE TABLE konstanty_proverki (
        id         INTEGER PRIMARY KEY,
        code       VARCHAR(30)  UNIQUE NOT NULL,
        name       VARCHAR(100) NOT NULL,
        min_value  NUMERIC      NOT NULL,
        max_value  NUMERIC      NOT NULL
    );
    COMMENT ON TABLE konstanty_proverki IS 'Допустимые диапазоны входных параметров (константы проверки)';
    COMMENT ON COLUMN konstanty_proverki.id IS 'Идентификатор константы';
    COMMENT ON COLUMN konstanty_proverki.code IS 'Уникальный код параметра';
    COMMENT ON COLUMN konstanty_proverki.name IS 'Наименование параметра и единица измерения';
    COMMENT ON COLUMN konstanty_proverki.min_value IS 'Минимально допустимое значение';
    COMMENT ON COLUMN konstanty_proverki.max_value IS 'Максимально допустимое значение';

    INSERT INTO konstanty_proverki (id, code, name, min_value, max_value) VALUES
        (1, 'HEIGHT',         'Высота метеопоста, м',      0,   5000),
        (2, 'TEMPERATURE',    'Температура, °C',         -49,     49),
        (3, 'PRESSURE',       'Давление, гПа',           800,   1100),
        (4, 'WIND_DIRECTION', 'Направление ветра, °',      0,    359),
        (5, 'WIND_SPEED',     'Скорость ветра, м/с',      0,     50),
        (6, 'DRIFT_RANGE',    'Дальность сноса пуль, м',  0,   3000);

    -- Структура для хранения диапазона
    CREATE TYPE t_diapazon AS (
        min_value NUMERIC,
        max_value NUMERIC
    );
    COMMENT ON TYPE t_diapazon IS 'Допустимый диапазон значений параметра';

    -- Функция получения диапазона по коду параметра
    CREATE FUNCTION get_diapazon(p_code TEXT)
    RETURNS t_diapazon
    AS $func$
    DECLARE
        v_min NUMERIC;
        v_max NUMERIC;
    BEGIN
        SELECT min_value, max_value INTO v_min, v_max
        FROM konstanty_proverki
        WHERE code = p_code;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Константа проверки % не найдена', p_code;
        END IF;
        RETURN ROW(v_min, v_max)::t_diapazon;
    END;
    $func$ LANGUAGE plpgsql;
    COMMENT ON FUNCTION get_diapazon(TEXT) IS 'Возвращает допустимый диапазон параметра по его коду';
END $$;
