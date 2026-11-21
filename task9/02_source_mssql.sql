-- выборка ресурсов из базы front (mssql)
-- каждый запрос возвращает готовые вызовы процедур из 04_load_olap.sql
-- результат запроса копируем в postgresql и выполняем
-- порядок: единицы, категории, поставщики, сотрудники, номенклатура, потом данные по направлениям


-- единицы измерения
select 'call load_range('
    + cast(id as varchar(20)) + ', '''
    + replace(sizeid, '''', '''''') + ''', '
    + cast(coalesce(portionrate, 1) as varchar(30)) + ');' as [sql]
from [size]
order by id;


-- категории
select 'call load_category('
    + cast(id as varchar(20)) + ', '''
    + replace(name, '''', '''''') + ''', '
    + coalesce(cast(parent_id as varchar(20)), 'null') + ');' as [sql]
from
(
    select id, description as name,
           case when coalesce(ParentID, 0) = 0
                then null else ParentID end as parent_id
    from category
) as t1
order by parent_id, name;


-- поставщики
select 'call load_vendor('
    + cast(id as varchar(20)) + ', '''
    + replace(name, '''', '''''') + ''', '
    + cast(parent_id as varchar(20)) + ', '''
    + replace(parent_name, '''', '''''') + ''');' as [sql]
from
(
    select t1.id, t1.clientid as name, t1.clientgroup as parent_id,
           t2.[description] as parent_name
    from vendors t1
    inner join vendorgroup t2 on t1.clientgroup = t2.vendorgroupid
) as t1
order by parent_id, id;


-- сотрудники
select 'call load_employee('
    + cast(personid as varchar(20)) + ', '''
    + replace(coalesce(lastname, ''), '''', '''''') + ''', '''
    + replace(coalesce(firstname, ''), '''', '''''') + ''');' as [sql]
from personnel
order by personid;


-- номенклатура
select 'call load_product('
    + cast(id as varchar(20)) + ', '''
    + replace(description, '''', '''''') + ''', '
    + cast(coalesce(CategoryID, 0) as varchar(20)) + ', '
    + cast(coalesce(SizeID, 0) as varchar(20)) + ');' as [sql]
from product
order by id;


-- закупки по месяцам (документы поступления продуктов)
select 'call load_purchase('''
    + left(t.period, 4) + '-' + right(t.period, 2) + '-01'', '
    + cast(t.product_id as varchar(20)) + ', '
    + cast(t.vendor_id as varchar(20)) + ', '
    + cast(t.qty as varchar(30)) + ', '
    + cast(t.amount as varchar(30)) + ');' as [sql]
from (select s.Period as period,
             s.ProductID as product_id,
             s.VendorID as vendor_id,
             sum(s.[Count]) as qty,
             sum(s.Amount) as amount
      from bm_StorageOperations s
      join bm_JournalBarnetDocs d on d.ID = s.DocumentID
      where s.OperationID = 1
        and d.DocumentTypeID = 4
      group by s.Period, s.ProductID, s.VendorID) t
order by t.period, t.product_id, t.vendor_id;


-- продажи по месяцам
select 'call load_sale('''
    + t.month_start + ''', '
    + cast(t.product_id as varchar(20)) + ', '
    + cast(t.qty as varchar(30)) + ', '
    + cast(t.amount as varchar(30)) + ');' as [sql]
from (select convert(varchar(7), j.dater, 120) + '-01' as month_start,
             p.id as product_id,
             sum(j.quantity) as qty,
             sum(j.amount) as amount
      from journal j
      join product p on p.productid = j.id
      where j.transtype = 101
      group by convert(varchar(7), j.dater, 120), p.id) t
order by t.month_start, t.product_id;


-- работа персонала по месяцам
select 'call load_personnel('''
    + t.month_start + ''', '
    + cast(t.employee_id as varchar(20)) + ', '
    + cast(t.docs as varchar(20)) + ', '
    + cast(t.amount as varchar(30)) + ');' as [sql]
from (select convert(varchar(7), d.Period, 120) + '-01' as month_start,
             d.PersonID as employee_id,
             count(*) as docs,
             sum(d.Amount) as amount
      from bm_JournalBarnetDocs d
      join personnel p on p.personid = d.PersonID
      group by convert(varchar(7), d.Period, 120), d.PersonID) t
order by t.month_start, t.employee_id;


-- остатки по неделям (неделя начинается с понедельника)
select 'call load_stock('''
    + t.week_start + ''', '
    + cast(t.product_id as varchar(20)) + ', '
    + cast(t.qty_in as varchar(30)) + ', '
    + cast(t.qty_out as varchar(30)) + ');' as [sql]
from (select convert(varchar(10), dateadd(day, -(datediff(day, '19000101', d.Period) % 7), cast(d.Period as date)), 120) as week_start,
             s.ProductID as product_id,
             sum(case when s.OperationID = 1 then s.[Count] else 0 end) as qty_in,
             sum(case when s.OperationID = 2 then -s.[Count] else 0 end) as qty_out
      from bm_StorageOperations s
      join bm_JournalBarnetDocs d on d.ID = s.DocumentID
      group by dateadd(day, -(datediff(day, '19000101', d.Period) % 7), cast(d.Period as date)), s.ProductID) t
order by t.week_start, t.product_id;
