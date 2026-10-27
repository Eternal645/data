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
    SELECT p.code, p.tip_oborudovaniya_id, t.name AS equipment_type,
           z.meteo_height, z.temperature, z.pressure,
           z.wind_direction, z.wind_speed, z.drift_range
    FROM pachki p
    JOIN tipy_oborudovaniya t ON t.id = p.tip_oborudovaniya_id
    LEFT JOIN znach z ON z.pachka_id = p.id
),
oshibki AS (
    SELECT *,
           check_parametry(ROW(tip_oborudovaniya_id, meteo_height, temperature, pressure,
                               wind_direction, wind_speed, drift_range)::t_parametry) AS error_text
    FROM proj
)
SELECT code            AS "№",
       equipment_type  AS "Тип оборудования",
       meteo_height    AS "Высота метеопоста",
       temperature     AS "Температура",
       pressure        AS "Давление",
       wind_direction  AS "Направление ветра",
       wind_speed      AS "Скорость ветра",
       drift_range     AS "Дальность сноса пуль",
       (error_text <> '') AS "Флаг: Есть ошибка",
       error_text      AS "Описание ошибки"
FROM oshibki
ORDER BY code;