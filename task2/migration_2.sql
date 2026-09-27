-- Справочник базовых физических величин
CREATE TABLE bazovye_edinicy_izmereniya (
    id INTEGER PRIMARY KEY,
    base_unit_code VARCHAR(20) UNIQUE NOT NULL,  -- уникальный код величины
    base_unit_name VARCHAR(100) NOT NULL
);
COMMENT ON TABLE bazovye_edinicy_izmereniya IS 'Справочник базовых физических величин (мощность, скорость, давление)';
COMMENT ON COLUMN bazovye_edinicy_izmereniya.base_unit_code IS 'Уникальный код базовой физической величины';
COMMENT ON COLUMN bazovye_edinicy_izmereniya.base_unit_name IS 'Наименование физической величины';

-- Справочник практических единиц измерения
CREATE TABLE edinicy_izmereniya (
    id INTEGER PRIMARY KEY,
    unit_code VARCHAR(20) UNIQUE NOT NULL,   -- уникальный код единицы
    unit_name VARCHAR(50) NOT NULL,
    bazovaya_edinica_id INTEGER NOT NULL REFERENCES bazovye_edinicy_izmereniya(id) -- связь с базовой величиной
);
COMMENT ON TABLE edinicy_izmereniya IS 'Справочник практических единиц измерения (кВт, бар, м/мин)';
COMMENT ON COLUMN edinicy_izmereniya.unit_code IS 'Уникальный код единицы измерения';
COMMENT ON COLUMN edinicy_izmereniya.unit_name IS 'Обозначение единицы измерения';
COMMENT ON COLUMN edinicy_izmereniya.bazovaya_edinica_id IS 'Ссылка на базовую физическую величину';

-- Справочник типов измеряемых параметров оборудования
CREATE TABLE tipy_parametrov (
    id INTEGER PRIMARY KEY,
    parameter_type_code VARCHAR(20) UNIQUE NOT NULL,  -- уникальный код типа параметра
    parameter_type_name VARCHAR(100) NOT NULL,
    edinica_izmereniya_id INTEGER NOT NULL REFERENCES edinicy_izmereniya(id) -- ед. измерения по умолчанию
);
COMMENT ON TABLE tipy_parametrov IS 'Справочник типов измеряемых параметров оборудования';
COMMENT ON COLUMN tipy_parametrov.parameter_type_code IS 'Уникальный код типа параметра';
COMMENT ON COLUMN tipy_parametrov.parameter_type_name IS 'Наименование типа параметра';
COMMENT ON COLUMN tipy_parametrov.edinica_izmereniya_id IS 'Единица измерения по умолчанию для этого типа параметра';

-- заполнение справочников типовыми данными
INSERT INTO bazovye_edinicy_izmereniya VALUES (1, 'BASE-001', 'Мощность');
INSERT INTO bazovye_edinicy_izmereniya VALUES (2, 'BASE-002', 'Скорость');
INSERT INTO bazovye_edinicy_izmereniya VALUES (3, 'BASE-003', 'Давление');

INSERT INTO edinicy_izmereniya VALUES (1, 'UNIT-001', 'кВт', 1);
INSERT INTO edinicy_izmereniya VALUES (2, 'UNIT-002', 'м/мин', 2);
INSERT INTO edinicy_izmereniya VALUES (3, 'UNIT-003', 'бар', 3);

INSERT INTO tipy_parametrov VALUES (1, 'TPR-001', 'Мощность', 1);
INSERT INTO tipy_parametrov VALUES (2, 'TPR-002', 'Скорость', 2);
INSERT INTO tipy_parametrov VALUES (3, 'TPR-003', 'Давление', 3);

-- Изменение таблицы parametry: связка с пачками и типами параметров

-- новые столбцы: привязка к пачке, типу параметра и дата измерения
ALTER TABLE parametry ADD COLUMN pachka_id INTEGER;
ALTER TABLE parametry ADD COLUMN tip_parametra_id INTEGER;
ALTER TABLE parametry ADD COLUMN measurement_date DATE;

-- перенос старых данных в новую структуру
UPDATE parametry
SET pachka_id = (
        SELECT p.id FROM pachki p
        WHERE p.tip_oborudovaniya_id = parametry.tip_oborudovaniya_id
    ),
    measurement_date = (
        SELECT p.created_date FROM pachki p
        WHERE p.tip_oborudovaniya_id = parametry.tip_oborudovaniya_id
    ),
    tip_parametra_id = (
        SELECT tp.id FROM tipy_parametrov tp
        WHERE parametry.parameter_name LIKE tp.parameter_type_name || ',%'
    );

-- удаление старых ненужных структур (DDL): текстовое имя параметра и связь с оборудованием больше не нужны
ALTER TABLE parametry DROP COLUMN parameter_name;
ALTER TABLE parametry DROP COLUMN tip_oborudovaniya_id;

-- обязательность и внешние ключи включаем только после того, как данные уже перенесены
ALTER TABLE parametry ALTER COLUMN pachka_id SET NOT NULL;
ALTER TABLE parametry ALTER COLUMN tip_parametra_id SET NOT NULL;
ALTER TABLE parametry ALTER COLUMN measurement_date SET NOT NULL;
ALTER TABLE parametry ADD CONSTRAINT fk_parametry_pachka
    FOREIGN KEY (pachka_id) REFERENCES pachki(id);       -- измерение относится к пачке
ALTER TABLE parametry ADD CONSTRAINT fk_parametry_tip_parametra
    FOREIGN KEY (tip_parametra_id) REFERENCES tipy_parametrov(id); -- тип измеряемого параметра

COMMENT ON TABLE parametry IS 'Измерения параметров, зафиксированные для конкретной пачки';
COMMENT ON COLUMN parametry.parameter_code IS 'Уникальный код измерения';
COMMENT ON COLUMN parametry.pachka_id IS 'Ссылка на пачку, к которой относится измерение';
COMMENT ON COLUMN parametry.tip_parametra_id IS 'Ссылка на тип измеряемого параметра';
COMMENT ON COLUMN parametry.measurement_date IS 'Дата проведения измерения';
COMMENT ON COLUMN parametry.value IS 'Измеренное значение параметра';

-- Итоговый запрос

SELECT
    pr.measurement_date AS "Дата измерения",
    p.pachka_code AS "Номер пачки",
    u.full_name AS "ФИО сотрудника",
    tp.parameter_type_name || ', ' || ei.unit_name AS "Параметр и ед.измерения",
    pr.value AS "Значение"
FROM parametry pr
JOIN pachki p ON p.id = pr.pachka_id
JOIN polzovateli u ON u.id = p.polzovatel_id
JOIN tipy_parametrov tp ON tp.id = pr.tip_parametra_id
JOIN edinicy_izmereniya ei ON ei.id = tp.edinica_izmereniya_id
ORDER BY pr.measurement_date;