-- ресурс (метрика) время
-- месяцы с января 2013 по декабрь 2023 (в этот период попадают все данные базы front)

do $$
declare
    month_names text[] := array['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
                                'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'];
    quarter_names text[] := array['Первый квартал', 'Второй квартал', 'Третий квартал', 'Четвертый квартал'];
    d date := date '2013-01-01';
begin
    while d <= date '2023-12-01' loop
        -- вложенный блок: ошибка в одном месяце не ломает остальные
        begin
            insert into dim_time (month_start, month_end, month_name, year, quarter_number, quarter_name)
            values (d,
                    (d + interval '1 month - 1 day')::date,
                    month_names[extract(month from d)::int],
                    extract(year from d)::bigint,
                    extract(quarter from d)::bigint,
                    quarter_names[extract(quarter from d)::int])
            on conflict (month_start) do nothing;
        exception
            when others then
                raise notice 'месяц % не добавлен: %', d, sqlerrm;
        end;

        d := (d + interval '1 month')::date;
    end loop;
end
$$;
