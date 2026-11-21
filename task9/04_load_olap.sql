-- процедуры загрузки данных в olap базу (postgresql)
-- данные приходят из mssql: запросы из 02_source_mssql.sql формируют вызовы этих процедур
-- в каждой процедуре вложенный блок: если строка не загрузилась, она пропускается, остальные грузятся дальше

-- единицы измерения
create or replace procedure load_range(p_external_id bigint, p_name text, p_factor float)
language plpgsql
as $$
begin
    begin
        -- обновляем, если такая единица уже есть
        update dim_ranges set name = p_name, factor = p_factor where external_id = p_external_id;
        if not found then
            insert into dim_ranges (external_id, name, factor) values (p_external_id, p_name, p_factor);
        end if;
    exception
        when others then
            raise notice 'единица % не загружена: %', p_external_id, sqlerrm;
    end;
end
$$;

-- категории (родитель должен быть загружен раньше ребенка, запрос в 02 отдает их в таком порядке)
create or replace procedure load_category(p_external_id bigint, p_name text, p_parent_id bigint)
language plpgsql
as $$
declare
    v_parent_id bigint;
begin
    begin
        if p_parent_id is not null then
            select id into strict v_parent_id from dim_categories where external_id = p_parent_id;
        end if;

        insert into dim_categories (external_id, name, parent_id)
        values (p_external_id, p_name, v_parent_id)
        on conflict (external_id) do update
            set name = excluded.name,
                parent_id = excluded.parent_id;
    exception
        when others then
            raise notice 'категория % не загружена: %', p_external_id, sqlerrm;
    end;
end
$$;

-- номенклатура
create or replace procedure load_product(p_external_id bigint, p_name text, p_category_external_id bigint, p_range_external_id bigint)
language plpgsql
as $$
declare
    v_category_id bigint;
    v_range_id bigint;
begin
    begin
        select id into v_category_id from dim_categories where external_id = p_category_external_id;
        select id into v_range_id from dim_ranges where external_id = p_range_external_id;

        insert into dim_products (external_id, name, category_id, range_id)
        values (p_external_id, p_name, v_category_id, v_range_id)
        on conflict (external_id) do update
            set name = excluded.name,
                category_id = excluded.category_id,
                range_id = excluded.range_id;
    exception
        when others then
            raise notice 'продукт % не загружен: %', p_external_id, sqlerrm;
    end;
end
$$;

-- сотрудники
create or replace procedure load_employee(p_external_id bigint, p_last_name text, p_first_name text)
language plpgsql
as $$
begin
    begin
        insert into dim_employees (external_id, last_name, first_name)
        values (p_external_id, p_last_name, p_first_name)
        on conflict (external_id) do update
            set last_name = excluded.last_name,
                first_name = excluded.first_name;
    exception
        when others then
            raise notice 'сотрудник % не загружен: %', p_external_id, sqlerrm;
    end;
end
$$;

-- поставщики
create or replace procedure load_vendor(p_external_id bigint, p_name text, p_parent_id bigint, p_parent_name text)
language plpgsql
as $$
begin
    begin
        insert into dim_vendors (external_id, name, parent_id, parent_name)
        values (p_external_id, p_name, p_parent_id, p_parent_name)
        on conflict (external_id) do update
            set name = excluded.name,
                parent_id = excluded.parent_id,
                parent_name = excluded.parent_name;
    exception
        when others then
            raise notice 'поставщик % не загружен: %', p_external_id, sqlerrm;
    end;
end
$$;

-- закупки
create or replace procedure load_purchase(p_month date, p_product_external_id bigint, p_vendor_external_id bigint, p_qty numeric, p_amount numeric)
language plpgsql
as $$
declare
    v_time_id bigint;
    v_product_id bigint;
    v_vendor_id bigint;
begin
    begin
        select id into strict v_time_id from dim_time where month_start = p_month;
        select id into strict v_product_id from dim_products where external_id = p_product_external_id;
        select id into strict v_vendor_id from dim_vendors where external_id = p_vendor_external_id;

        insert into fact_purchase (time_id, product_id, vendor_id, qty, amount)
        values (v_time_id, v_product_id, v_vendor_id, p_qty, p_amount)
        on conflict (time_id, product_id, vendor_id) do update
            set qty = excluded.qty, amount = excluded.amount;
    exception
        when others then
            raise notice 'закупка (% / % / %) не загружена: %', p_month, p_product_external_id, p_vendor_external_id, sqlerrm;
    end;
end
$$;

-- продажи
create or replace procedure load_sale(p_month date, p_product_external_id bigint, p_qty numeric, p_amount numeric)
language plpgsql
as $$
declare
    v_time_id bigint;
    v_product_id bigint;
begin
    begin
        select id into strict v_time_id from dim_time where month_start = p_month;
        select id into strict v_product_id from dim_products where external_id = p_product_external_id;

        insert into fact_sale (time_id, product_id, qty, amount)
        values (v_time_id, v_product_id, p_qty, p_amount)
        on conflict (time_id, product_id) do update
            set qty = excluded.qty, amount = excluded.amount;
    exception
        when others then
            raise notice 'продажа (% / %) не загружена: %', p_month, p_product_external_id, sqlerrm;
    end;
end
$$;

-- персонал
create or replace procedure load_personnel(p_month date, p_employee_external_id bigint, p_docs bigint, p_amount numeric)
language plpgsql
as $$
declare
    v_time_id bigint;
    v_employee_id bigint;
begin
    begin
        select id into strict v_time_id from dim_time where month_start = p_month;
        select id into strict v_employee_id from dim_employees where external_id = p_employee_external_id;

        insert into fact_personnel (time_id, employee_id, docs, amount)
        values (v_time_id, v_employee_id, p_docs, p_amount)
        on conflict (time_id, employee_id) do update
            set docs = excluded.docs, amount = excluded.amount;
    exception
        when others then
            raise notice 'персонал (% / %) не загружен: %', p_month, p_employee_external_id, sqlerrm;
    end;
end
$$;

-- остатки
create or replace procedure load_stock(p_week_start date, p_product_external_id bigint, p_qty_in numeric, p_qty_out numeric)
language plpgsql
as $$
declare
    v_product_id bigint;
begin
    begin
        select id into strict v_product_id from dim_products where external_id = p_product_external_id;

        insert into fact_stock (week_start, product_id, qty_in, qty_out)
        values (p_week_start, v_product_id, p_qty_in, p_qty_out)
        on conflict (week_start, product_id) do update
            set qty_in = excluded.qty_in, qty_out = excluded.qty_out;
    exception
        when others then
            raise notice 'остаток (% / %) не загружен: %', p_week_start, p_product_external_id, sqlerrm;
    end;
end
$$;
