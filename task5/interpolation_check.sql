-- Проверки интерполяции
DO $$
DECLARE
    r        RECORD;
    v_params t_interpolation;
    v_y      NUMERIC;
BEGIN
    -- Проверки 1-4: параметры из таблицы raschet_temperatury и расчёт
    FOR r IN
        SELECT * FROM (VALUES
            (1, 'температура в узле таблицы',  51.00, 324.15),
            (2, 'температура между узлами',    58.75, 331.90),
            (3, 'нижняя граница таблицы',      35.50, 308.65),
            (4, 'верхняя граница таблицы',    113.00, 386.15)
        ) AS t(n, descr, temp, expected)
        ORDER BY n
    LOOP
        v_params := get_interpolation_params(r.temp);
        v_y := calc_interpolation(r.temp, v_params);
        RAISE NOTICE 'Проверка % (%): t=%, x0=%, y0=%, x1=%, y1=% -> y=%, ожидалось % [%]',
            r.n, r.descr, r.temp, v_params.x0, v_params.y0, v_params.x1, v_params.y1,
            ROUND(v_y, 2), r.expected,
            CASE WHEN abs(v_y - r.expected) < 0.0001 THEN 'OK' ELSE 'FAIL' END;
    END LOOP;

    -- Проверки 5-7: расчёт по заданной структуре
    FOR r IN
        SELECT * FROM (VALUES
            (5, 'возрастающая функция', 2.5, 0,   0, 10, 100, 25),
            (6, 'убывающая функция',    4,   0, 100, 10,   0, 60),
            (7, 'x в левом узле',       0,   0,   0, 10, 100,  0)
        ) AS t(n, descr, x, x0, y0, x1, y1, expected)
        ORDER BY n
    LOOP
        v_params := ROW(r.x0, r.y0, r.x1, r.y1)::t_interpolation;
        v_y := calc_interpolation(r.x, v_params);
        RAISE NOTICE 'Проверка % (%): x=%, (%,%)-(%,%) -> y=%, ожидалось % [%]',
            r.n, r.descr, r.x, r.x0, r.y0, r.x1, r.y1,
            ROUND(v_y, 2), r.expected,
            CASE WHEN abs(v_y - r.expected) < 0.0001 THEN 'OK' ELSE 'FAIL' END;
    END LOOP;

    -- Проверки 8-9: температура вне диапазона таблицы должна дать ошибку
    FOR r IN
        SELECT * FROM (VALUES
            (8, 'температура ниже диапазона',  20.00),
            (9, 'температура выше диапазона', 200.00)
        ) AS t(n, descr, temp)
        ORDER BY n
    LOOP
        BEGIN
            v_params := get_interpolation_params(r.temp);
            RAISE NOTICE 'Проверка % (%): t=%, ошибка не возникла [FAIL]', r.n, r.descr, r.temp;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Проверка % (%): t=%, ошибка "%" [OK]', r.n, r.descr, r.temp, SQLERRM;
        END;
    END LOOP;
END $$;
