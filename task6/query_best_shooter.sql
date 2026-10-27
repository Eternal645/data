WITH znach AS (
    SELECT pp.pachka_id,
           MAX(CASE WHEN k.code = 'HEIGHT'         THEN pp.value END) AS meteo_height,
           MAX(CASE WHEN k.code = 'TEMPERATURE'    THEN pp.value END) AS temperature,
           MAX(CASE WHEN k.code = 'PRESSURE'       THEN pp.value END) AS pressure,
           MAX(CASE WHEN k.code = 'WIND_DIRECTION' THEN pp.value END) AS wind_direction,
           MAX(CASE WHEN k.code = 'WIND_SPEED'     THEN pp.value END) AS wind_speed,
           MAX(CASE WHEN k.code = 'DRIFT_RANGE'    THEN pp.value END) AS drift_range
    FROM parametry_pachek pp
    JOIN konstanty_proverki k ON k.id = pp.konstanta_id
    GROUP BY pp.pachka_id
),
proj AS (
    SELECT p.polzovatel_id, p.tip_oborudovaniya_id,
           z.meteo_height, z.temperature, z.pressure,
           z.wind_direction, z.wind_speed, z.drift_range
    FROM pachki p
    LEFT JOIN znach z ON z.pachka_id = p.id
),
oshibki AS (
    SELECT polzovatel_id,
           check_parametry(ROW(tip_oborudovaniya_id, meteo_height, temperature, pressure,
                               wind_direction, wind_speed, drift_range)::t_parametry) AS error_text
    FROM proj
),
cnt AS (
    SELECT u.id, u.full_name,
           COALESCE(SUM(cardinality(string_to_array(o.error_text, '; '))), 0) AS errors_count
    FROM polzovateli u
    LEFT JOIN oshibki o ON o.polzovatel_id = u.id
    GROUP BY u.id, u.full_name
)
SELECT RANK() OVER (ORDER BY errors_count) AS "Место",
       full_name                           AS "Пользователь",
       errors_count                        AS "Количество ошибок"
FROM cnt
ORDER BY "Место", full_name;