WITH proj AS (
    SELECT polzovatel_id, error_text
    FROM pachki
),
errs AS (
    SELECT proj.polzovatel_id, e.err
    FROM proj,
         unnest(string_to_array(proj.error_text, '; ')) AS e(err)
),
cnt AS (
    SELECT u.id, u.full_name, COUNT(errs.err) AS errors_count
    FROM polzovateli u
    LEFT JOIN errs ON errs.polzovatel_id = u.id
    GROUP BY u.id, u.full_name
)
SELECT RANK() OVER (ORDER BY errors_count) AS "Место",
       full_name                           AS "Пользователь",
       errors_count                        AS "Количество ошибок"
FROM cnt
ORDER BY "Место", full_name;
