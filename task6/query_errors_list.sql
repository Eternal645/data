WITH proj AS (
    SELECT p.code,
           t.name AS equipment_type,
           p.meteo_height, p.temperature, p.pressure,
           p.wind_direction, p.wind_speed, p.drift_range,
           p.has_error, p.error_text
    FROM pachki p
    JOIN tipy_oborudovaniya t ON t.id = p.tip_oborudovaniya_id
)
SELECT code            AS "№",
       equipment_type  AS "Тип оборудования",
       meteo_height    AS "Высота метеопоста",
       temperature     AS "Температура",
       pressure        AS "Давление",
       wind_direction  AS "Направление ветра",
       wind_speed      AS "Скорость ветра",
       drift_range     AS "Дальность сноса пуль",
       has_error       AS "Флаг: Есть ошибка",
       error_text      AS "Описание ошибки"
FROM proj
ORDER BY code;
