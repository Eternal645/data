-- структура olap базы данных (postgresql)

do $$
begin

    -- счетчики для внутренних кодов
    create sequence if not exists seq_dim_time;
    create sequence if not exists seq_dim_ranges;
    create sequence if not exists seq_dim_categories;
    create sequence if not exists seq_dim_products;
    create sequence if not exists seq_dim_employees;
    create sequence if not exists seq_dim_vendors;
    create sequence if not exists seq_fact_purchase;
    create sequence if not exists seq_fact_sale;
    create sequence if not exists seq_fact_personnel;
    create sequence if not exists seq_fact_stock;

    -- ресурсы (справочники)
    begin
        -- время
        create table if not exists dim_time
        (
            -- внутренний код
            id bigint primary key default nextval('seq_dim_time'),
            month_start date not null unique,
            month_end date not null,
            month_name varchar(20) not null,
            year bigint not null,
            quarter_number bigint not null,
            quarter_name varchar(30) not null,
            date_add timestamp default now()
        );

        -- ресурсы единицы измерения
        create table if not exists dim_ranges
        (
            -- внутренний код
            id bigint primary key default nextval('public.seq_dim_ranges'),
            external_id bigint,
            name text,
            factor float,
            -- дата добавления
            date_add timestamp default now()
        );

        -- категории (дерево)
        create table if not exists dim_categories
        (
            id bigint primary key default nextval('seq_dim_categories'),
            external_id bigint not null unique,
            name text,
            parent_id bigint references dim_categories (id),
            date_add timestamp default now()
        );

        -- номенклатура
        create table if not exists dim_products
        (
            id bigint primary key default nextval('seq_dim_products'),
            external_id bigint not null unique,
            name text,
            category_id bigint references dim_categories (id),
            range_id bigint references dim_ranges (id),
            date_add timestamp default now()
        );

        -- сотрудники
        create table if not exists dim_employees
        (
            id bigint primary key default nextval('seq_dim_employees'),
            external_id bigint not null unique,
            last_name text,
            first_name text,
            date_add timestamp default now()
        );

        -- поставщики
        create table if not exists dim_vendors
        (
            id bigint primary key default nextval('seq_dim_vendors'),
            external_id bigint not null unique,
            name text,
            parent_id bigint,
            parent_name text,
            date_add timestamp default now()
        );
    exception
        when others then
            raise exception 'не удалось создать справочники: %', sqlerrm;
    end;

    -- таблицы с данными по направлениям
    begin
        -- закупки (шаг месяц)
        create table if not exists fact_purchase
        (
            id bigint primary key default nextval('seq_fact_purchase'),
            time_id bigint not null references dim_time (id),
            product_id bigint not null references dim_products (id),
            vendor_id bigint not null references dim_vendors (id),
            qty numeric(14, 3) not null,
            amount numeric(14, 2) not null,
            date_add timestamp default now(),
            unique (time_id, product_id, vendor_id)
        );

        -- продажи (шаг месяц)
        create table if not exists fact_sale
        (
            id bigint primary key default nextval('seq_fact_sale'),
            time_id bigint not null references dim_time (id),
            product_id bigint not null references dim_products (id),
            qty numeric(14, 3) not null,
            amount numeric(14, 2) not null,
            date_add timestamp default now(),
            unique (time_id, product_id)
        );

        -- персонал (квартал и полугодие считаются через dim_time)
        create table if not exists fact_personnel
        (
            id bigint primary key default nextval('seq_fact_personnel'),
            time_id bigint not null references dim_time (id),
            employee_id bigint not null references dim_employees (id),
            docs bigint not null,
            amount numeric(14, 2) not null,
            date_add timestamp default now(),
            unique (time_id, employee_id)
        );

        -- остатки (шаг неделя)
        create table if not exists fact_stock
        (
            id bigint primary key default nextval('seq_fact_stock'),
            week_start date not null,
            product_id bigint not null references dim_products (id),
            qty_in numeric(14, 3) not null,
            qty_out numeric(14, 3) not null,
            date_add timestamp default now(),
            unique (week_start, product_id)
        );
    exception
        when others then
            raise exception 'не удалось создать таблицы с данными: %', sqlerrm;
    end;

end
$$;
