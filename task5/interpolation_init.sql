-- Перед запуском должен быть выполнен plpgsql_init.sql из ветки feature/sql-task-4
DO $$
BEGIN
    DROP FUNCTION IF EXISTS calc_interpolation(NUMERIC, t_interpolation);
    DROP FUNCTION IF EXISTS get_interpolation_params(NUMERIC);
    DROP TYPE IF EXISTS t_interpolation;

    -- Тип данных для интерполяции
    CREATE TYPE t_interpolation AS (
        x0 NUMERIC,
        y0 NUMERIC,
        x1 NUMERIC,
        y1 NUMERIC
    );
    COMMENT ON TYPE t_interpolation IS 'Опорные точки для линейной интерполяции';
    COMMENT ON COLUMN t_interpolation.x0 IS 'Аргумент левой опорной точки';
    COMMENT ON COLUMN t_interpolation.y0 IS 'Значение в левой опорной точке';
    COMMENT ON COLUMN t_interpolation.x1 IS 'Аргумент правой опорной точки';
    COMMENT ON COLUMN t_interpolation.y1 IS 'Значение в правой опорной точке';

    -- Функция определения параметров интерполяции:
    -- принимает температуру, возвращает структуру для интерполяции
    CREATE OR REPLACE FUNCTION get_interpolation_params(p_temperature NUMERIC)
    RETURNS t_interpolation
    AS $func$
    DECLARE
        v_x0 NUMERIC;
        v_y0 NUMERIC;
        v_x1 NUMERIC;
        v_y1 NUMERIC;
    BEGIN
        SELECT temp_celsius, temp_kelvin INTO v_x0, v_y0
        FROM raschet_temperatury
        WHERE temp_celsius <= p_temperature
        ORDER BY temp_celsius DESC
        LIMIT 1;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Температура % ниже диапазона таблицы расчёта', p_temperature;
        END IF;

        SELECT temp_celsius, temp_kelvin INTO v_x1, v_y1
        FROM raschet_temperatury
        WHERE temp_celsius >= p_temperature
        ORDER BY temp_celsius ASC
        LIMIT 1;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Температура % выше диапазона таблицы расчёта', p_temperature;
        END IF;

        RETURN ROW(v_x0, v_y0, v_x1, v_y1)::t_interpolation;
    END;
    $func$ LANGUAGE plpgsql;
    COMMENT ON FUNCTION get_interpolation_params(NUMERIC)
        IS 'Определяет опорные точки интерполяции по температуре из таблицы raschet_temperatury';

    -- Функция расчёта интерполяции:
    -- принимает значение x и структуру для интерполяции, возвращает y
    CREATE OR REPLACE FUNCTION calc_interpolation(p_x NUMERIC, p_params t_interpolation)
    RETURNS NUMERIC
    AS $func$
    BEGIN
        IF p_params.x1 = p_params.x0 THEN
            RETURN p_params.y0;
        END IF;
        RETURN p_params.y0
             + (p_x - p_params.x0) * (p_params.y1 - p_params.y0)
             / (p_params.x1 - p_params.x0);
    END;
    $func$ LANGUAGE plpgsql;
    COMMENT ON FUNCTION calc_interpolation(NUMERIC, t_interpolation)
        IS 'Линейная интерполяция: по значению x и опорным точкам возвращает y';
END $$;
