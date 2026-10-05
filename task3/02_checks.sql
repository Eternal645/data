-- 1. Каждый пользователь имеет одинаковое количество измерений
select u.id, u.username, count(b.id) as batch_count
from users u
left join measurement_batches b on b.user_id = u.id
group by u.id, u.username
order by batch_count;


-- 2. Нет пустых пачек измерения?
select b.id, b.user_id, b.created_at
from measurement_batches b
left join measurements m on m.batch_id = b.id
where m.id is null;


-- 3. Каждая пачка содержит полное количество параметров
select b.id as batch_id, count(m.id) as measurement_count
from measurement_batches b
left join measurements m on m.batch_id = b.id
group by b.id
having count(m.id) <> 5
order by b.id;


-- 4. Все значения корректны и в диапазонах
select m.id, m.batch_id, p.name, m.value, p.min_val, p.max_val
from measurements m
inner join parameters p on p.id = m.parameter_id
where m.value is null
   or m.value < p.min_val
   or m.value > p.max_val
order by m.id;


-- 5. Все единицы измерения верны
select p.id, p.name, p.unit
from parameters p
where (p.id = 1 and p.unit <> 'C')
   or (p.id = 2 and p.unit <> '%')
   or (p.id = 3 and p.unit <> 'mmHg')
   or (p.id = 4 and p.unit <> 'm/s')
   or (p.id = 5 and p.unit <> 'mm');
