-- Задание 2: метаданные схемы public в формате / № / Наименование / Тип /
SELECT ROW_NUMBER() OVER (ORDER BY m.type_order, m.name) AS "№",
       m.name AS "Наименование",
       m.type AS "Тип"
FROM (
    SELECT table_name AS name, 'Таблица' AS type, 1 AS type_order
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE'

    UNION ALL

    SELECT sequence_name, 'Последовательность', 2
    FROM information_schema.sequences
    WHERE sequence_schema = 'public'

    UNION ALL

    SELECT constraint_name,
           CASE constraint_type
               WHEN 'PRIMARY KEY' THEN 'Первичный ключ'
               WHEN 'FOREIGN KEY' THEN 'Внешний ключ'
               WHEN 'UNIQUE'      THEN 'Уникальное ограничение'
               WHEN 'CHECK'       THEN 'Ограничение CHECK'
           END,
           3
    FROM information_schema.table_constraints
    WHERE constraint_schema = 'public'
      AND constraint_name NOT LIKE '%not_null'
) m
ORDER BY 1;
