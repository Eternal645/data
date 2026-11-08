-- Итоговый расчет. Включает учебный скрипт 20261102.sql с исправлениями
do $$
begin

	-- Создаем новые структуры
	begin

		-- Таблица стандартных высот
		create sequence calc_correction_height_seq;
		create table calc_correction_heights
		(
		        id integer primary key not null default nextval('public.calc_correction_height_seq'),
		        height integer not null
		);

		insert into calc_correction_heights(height)
		values(200),(400),(800),(1200),(1600),(2000),(2400),(3000),(4000);

		comment on table calc_correction_heights is 'Таблица стандартных высот';
		comment on column calc_correction_heights.id is 'Уникальный код';
		comment on column calc_correction_heights.height is 'Высота';

		-- НОВОЕ: отдельная таблица для хранения заголовков
		create sequence calc_correction_header_seq;
		create table calc_correction_headers
		(
		        id integer not null primary key default nextval('public.calc_correction_header_seq'),
		        header_values integer[] not null
		);

		-- Справочник типов таблиц корректировок
		-- ИЗМЕНЕНО: вместо массива header_values - ссылка на справочник заголовков (header_id)
		create sequence calc_correction_types_seq;
		create table calc_correction_types
		(
		        id integer not null primary key default nextval('public.calc_correction_types_seq'),
		        parent_id integer,
		        measurment_equipment_id integer,
		        description text not null,
		        header_id integer references calc_correction_headers(id)
		);

		comment on table calc_correction_types is 'Справочник типов таблиц с собственными заголовками';
		comment on column calc_correction_types.id is 'Уникальный код';
		comment on column calc_correction_types.parent_id is 'Уникальный код владельца - тип таблицы';
		comment on column calc_correction_types.measurment_equipment_id is 'Тип оборудования';
		comment on column calc_correction_types.description is 'Описание к таблице';
		comment on column calc_correction_types.header_id is 'Код заголовка таблицы';

		-- Универсальная таблица корректировок
		create sequence calc_correction_seq;
		create table calc_correction
		(
		        id integer not null primary key default nextval('public.calc_correction_seq'),
		        height_id integer not null,
		        type_id integer not null,
		        row_values integer[]
		);

		comment on table calc_correction is 'Универсальная таблица корректировок';
		comment on column calc_correction.id is 'Уникальный код';
		comment on column calc_correction.height_id is 'Код высоты';
		comment on column calc_correction.type_id is 'Код типа таблиц';
		comment on column calc_correction.row_values is 'Значения с корректировками';

	end;

	-- Добавляем данные
	begin

		-- Заголовки
		-- ИСПРАВЛЕНО: в заголовке Таблицы 2 было два значения 8, вместо второго должно быть 9
		insert into calc_correction_headers(header_values)
		values(array[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50]),                    -- 1 Таблица 2
		(array[40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]),                      -- 2 Таблица 3 (ВР)
		(array[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]);                               -- 3 Таблица 3 (ДМК)

		insert into calc_correction_types(description, header_id)
		values( 'Таблица 2', 1),                                    -- 1
		( 'Таблица 3, скорость среднего ветра', null),              -- 2
		( 'Таблица 3, направление среднего ветра', null);           -- 3

		insert into calc_correction_types( description, parent_id, measurment_equipment_id, header_id)
		values
		('Таблица 3, Скорость среднего ветра (ВР)', 2, 2, 2),       -- 4
		('Таблица 3, Направление среднего ветра (ВР)',3, 2, 2),     -- 5
		('Таблица 3, Скорость среднего ветра (ДМК)',2, 1, 3),       -- 6
		('Таблица 3, Направление среднего ветра (ДМК)',3, 1, 3);    -- 7

		insert into calc_correction_types( description, parent_id)
		values('Таблица 2, Положительные температуры', 1 ),         -- 8
		('Таблица 2, Отрицательные температуры', 1 );               -- 9

		-- ИСПРАВЛЕНО: отрицательные значения были записаны с типом 8, положительные - с типом 7.
		-- Правильно: положительные - 8, отрицательные - 9.
		-- ИСПРАВЛЕНО: в строки добавлено значение для заголовка 0 (поправка 0), чтобы число значений совпадало с заголовком (15).
		-- ДОБАВЛЕНО: в положительных значениях отсутствовали значения для заголовков 40 и 50.
		insert into calc_correction(height_id, type_id, row_values )
		-- Таблица 2, отрицательные значения
		values(1, 9, array[0, -1, -2, -3, -4, -5, -6, -7, -8, -8, -9, -20, -29, -39, -49]), -- 200
		(2, 9, array[0, -1, -2, -3, -4, -5, -6, -6, -7, -8, -9, -19, -29, -39, -48]), -- 400
		(3, 9, array[0, -1, -2, -3, -4, -5, -6, -6, -7, -7, -8, -18, -28, -37, -46]), -- 800
		(4, 9, array[0, -1, -2, -3, -4, -4, -5, -5, -6, -7, -8, -17, -26, -35, -44]), -- 1200
		-- Таблица 2, положительные значения
		(1, 8, array[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50]), -- 200
		(2, 8, array[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50]), -- 400
		(3, 8, array[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50]), -- 800
		(4, 8, array[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50]), -- 1200
		-- Таблица 3, Скорость среднего ветра (ВР)
		(1, 4, array[3, 4, 5, 6, 7, 7, 8, 9, 10, 11, 12, 12]), -- 200
		(2, 4, array[4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 ,15]), -- 400
		(3, 4, array[4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15 ,16]), -- 800
		(4, 4, array[4, 5, 7, 8, 8, 9, 11, 12, 13, 15 ,15, 16]), -- 1200
		-- Таблица 3, Направление среднего ветра (ВР)
		(1, 5, array[0]), -- 200
		(2, 5, array[1]), -- 400
		(3, 5, array[2]), -- 800
		(4, 5, array[2]), -- 1200
		-- Таблица 3, Скорость среднего ветра (ДМК)
		(1, 6, array[4,6,8,9,10,12,14,15,16,18,20,21,22]), -- 200
		(2, 6, array[5,7,10,11,12,14,17,18,20,22,23,25,27]), -- 400
		(3, 6, array[5,8,10,11,13,15,18,19,21,23,25,27,28]), -- 800
		(4, 6, array[5,8,11,12,13,16,19,20,23,24,26,28,30]), -- 1200
		-- Таблица 3, Направление среднего ветра (ДМК)
		(1, 7, array[1]), -- 200
		(2, 7, array[2]), -- 400
		(3, 7, array[3]), -- 800
		(4, 7, array[3]) -- 1200
		;

	end;

	-- Прочее
	begin
		-- Наименование подправлю
		if to_regclass('public.calc_temperature_correction') is not null then
			alter table public.calc_temperature_correction rename to calc_correction_temperature;
		end if;

		-- Таблица 1 (виртуальная поправка), с ней работает fn_calc_temperature_interpolation
		-- (создается, только если ее нет в базе)
		if to_regclass('public.calc_correction_temperature') is null then
			create table public.calc_correction_temperature
			(
				temperature numeric not null primary key,
				correction numeric not null
			);

			insert into public.calc_correction_temperature(temperature, correction)
			values(-58, 0), (0, 0), (5, 0.5), (10, 1), (15, 1), (20, 1.5), (25, 2), (30, 3.5), (40, 4.5), (58, 4.5);
		end if;

		-- Объекты интерполяции из предыдущих занятий (создаются, только если их нет в базе)
		if to_regtype('public.interpolation_type') is null then
			create type public.interpolation_type as
			(
				x0 numeric,
				y0 numeric,
				x1 numeric,
				y1 numeric
			);
		end if;

		if to_regprocedure('public.fn_calc_interpolation(numeric, public.interpolation_type)') is null then
			create function public.fn_calc_interpolation(
				par_x numeric,
				par_interpolation public.interpolation_type)
			    returns numeric
			    language plpgsql
			as $F$
			begin
				return par_interpolation.y0
					+ (par_x - par_interpolation.x0) * (par_interpolation.y1 - par_interpolation.y0)
					/ (par_interpolation.x1 - par_interpolation.x0);
			end;
			$F$;
		end if;

		CREATE OR REPLACE FUNCTION public.fn_calc_temperature_interpolation(
			par_temperature numeric)
		    RETURNS numeric
		    LANGUAGE 'plpgsql'
		    COST 100
		    VOLATILE PARALLEL UNSAFE
		AS $BODY$
				        declare 
				                var_interpolation interpolation_type;
				                var_result numeric(8,2) default 0;
				                var_min_temparure numeric(8,2) default 0;
				                var_max_temperature numeric(8,2) default 0;
				                var_denominator numeric(8,2) default 0;
				        begin

				                raise notice 'Расчет интерполяции для температуры %', par_temperature;

				                -- Проверим, возможно температура совпадает со значением в справочнике
				                if exists (select 1 from public.calc_correction_temperature where temperature = par_temperature ) then
				                begin
				                        select correction 
				                        into  var_result 
				                        from  public.calc_correction_temperature
				                        where 
				                                temperature = par_temperature;
				                end;
				                else    
				                begin
				                        -- Получим диапазон в котором работают поправки
				                        select min(temperature), max(temperature) 
				                        into var_min_temparure, var_max_temperature
				                        from public.calc_correction_temperature;

				                        if par_temperature < var_min_temparure or   
				                           par_temperature > var_max_temperature then

				                                raise exception 'Некорректно передан параметр! Невозможно рассчитать поправку. Значение должно укладываться в диаппазон: %, %',
				                                        var_min_temparure, var_max_temperature;
				                        end if;   

				                        -- Получим граничные параметры

				                        select x0, y0, x1, y1 
				                                                 into var_interpolation.x0, var_interpolation.y0, var_interpolation.x1, var_interpolation.y1
				                        from
				                        (
				                                select t1.temperature as x0, t1.correction as y0
				                                from public.calc_correction_temperature as t1
				                                where t1.temperature <= par_temperature
				                                order by t1.temperature desc
				                                limit 1
				                        ) as leftPart
				                        cross join
				                        (
				                                select t1.temperature as x1, t1.correction as y1
				                                from public.calc_correction_temperature as t1
				                                where t1.temperature >= par_temperature
				                                order by t1.temperature 
				                                limit 1
				                        ) as rightPart;

				                        raise notice 'Граничные значения %', var_interpolation;
				                        var_result :=  fn_calc_interpolation( par_temperature,  var_interpolation);

				                end;
				                end if;

				                return var_result;

				end;

		$BODY$;

		COMMENT ON FUNCTION public.fn_calc_temperature_interpolation(numeric)
		    IS 'Функция для расчета интерполяции для метео приближенный';
	end;

	-- Расчет
	begin

		-- Тип "входящие параметры"
		create type calc_input_params as
		(
			height integer,         -- высота метеопоста
			temperature numeric,    -- температура
			pressure integer,       -- давление
			wind_direction integer, -- направление ветра
			wind_speed integer,     -- скорость ветра (ДМК)
			drift_range integer     -- дальность сноса пуль (ВР)
		);

		-- Значение поправки для одного типа таблицы и одной высоты (с интерполяцией по заголовку)
		CREATE OR REPLACE FUNCTION public.fn_calc_correction_value(
			par_value numeric,
			par_type_id integer,
			par_height_id integer)
		    RETURNS numeric
		    LANGUAGE 'plpgsql'
		AS $BODY$
		declare
			var_headers integer[];
			var_values integer[];
			var_interpolation interpolation_type;
			var_i integer;
		begin
			select row_values into var_values
			from public.calc_correction
			where type_id = par_type_id and height_id = par_height_id;

			-- Одно значение на высоту (направление ветра) - интерполяция не нужна
			if array_length(var_values, 1) = 1 then
				return var_values[1];
			end if;

			-- Заголовок берется у типа, а если его нет - у владельца
			select h.header_values into var_headers
			from public.calc_correction_types as t
			left join public.calc_correction_types as p on p.id = t.parent_id
			join public.calc_correction_headers as h on h.id = coalesce(t.header_id, p.header_id)
			where t.id = par_type_id;

			for var_i in 1 .. array_length(var_headers, 1) - 1 loop
				if par_value = var_headers[var_i] then
					return var_values[var_i];
				end if;

				if par_value < var_headers[var_i + 1] then
					var_interpolation.x0 := var_headers[var_i];
					var_interpolation.y0 := var_values[var_i];
					var_interpolation.x1 := var_headers[var_i + 1];
					var_interpolation.y1 := var_values[var_i + 1];
					return fn_calc_interpolation(par_value, var_interpolation);
				end if;
			end loop;

			return var_values[array_upper(var_headers, 1)];
		end;
		$BODY$;

		-- Расчет по каждой типовой высоте: высота, отклонение температуры (TT), направление ветра (HH), скорость ветра (CC)
		-- par_equipment_id: 1 - ДМК, 2 - ВР
		CREATE OR REPLACE FUNCTION public.fn_calc_corrections(
			par_input calc_input_params,
			par_equipment_id integer)
		    RETURNS TABLE(height_m integer, temperature_corr integer, wind_direction_corr integer, wind_speed_corr integer)
		    LANGUAGE 'plpgsql'
		AS $BODY$
		declare
			var_delta integer;
			var_temperature_type_id integer;
			var_speed_type_id integer;
			var_direction_type_id integer;
			var_wind integer;
			var_min_wind integer;
		begin
			-- Отклонение приземной виртуальной температуры: T0 = t0 + поправка (таблица 1), отклонение = T0 - 15,9
			var_delta := round(par_input.temperature + fn_calc_temperature_interpolation(par_input.temperature) - 15.9);

			-- Таблица 2: положительные или отрицательные значения
			var_temperature_type_id := case when var_delta >= 0 then 8 else 9 end;

			-- Таблица 3: типы для выбранного оборудования
			select id into var_speed_type_id
			from public.calc_correction_types
			where parent_id = 2 and measurment_equipment_id = par_equipment_id;

			select id into var_direction_type_id
			from public.calc_correction_types
			where parent_id = 3 and measurment_equipment_id = par_equipment_id;

			-- ДМК: скорость ветра, ниже 3 ветер равен нулю. ВР: дальность сноса пуль, ниже 40 ветер равен нулю
			if par_equipment_id = 1 then
				var_wind := par_input.wind_speed;
				var_min_wind := 3;
			else
				var_wind := par_input.drift_range;
				var_min_wind := 40;
			end if;

			return query
			select h.height,
				case when t.value < 0 then -t.value + 50 else t.value end,
				case when var_wind < var_min_wind then 0
				     else mod(par_input.wind_direction + round(fn_calc_correction_value(var_wind, var_direction_type_id, h.id))::integer, 60) end,
				case when var_wind < var_min_wind then 0
				     else round(fn_calc_correction_value(var_wind, var_speed_type_id, h.id))::integer end
			from public.calc_correction_heights as h
			cross join lateral
			(
				-- отклонение раскладывается на десятки и единицы, значения из таблицы 2 складываются
				select round(
					fn_calc_correction_value((abs(var_delta) / 10) * 10, var_temperature_type_id, h.id) +
					fn_calc_correction_value(abs(var_delta) % 10, var_temperature_type_id, h.id))::integer as value
			) as t
			where exists (select 1 from public.calc_correction as c
			              where c.height_id = h.id and c.type_id = var_temperature_type_id)
			order by h.height;
		end;
		$BODY$;

	end;

	commit;

end $$;