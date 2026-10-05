drop table if exists measurements;
drop table if exists measurement_batches;
drop table if exists parameters;
drop table if exists users;

create table users (
    id integer primary key,
    username varchar(50) not null
);

create table measurement_batches (
    id integer primary key,
    user_id integer,
    created_at timestamp
);

create table parameters (
    id integer primary key,
    name varchar(50),
    unit varchar(20),
    min_val numeric(8,2),
    max_val numeric(8,2)
);

create table measurements (
    id integer primary key,
    batch_id integer,
    parameter_id integer,
    value numeric(8,2)
);

insert into users(id, username) values
(1, 'ivanov'),
(2, 'petrov'),
(3, 'sidorov'),
(4, 'kuznetsov');

insert into parameters(id, name, unit, min_val, max_val) values
(1, 'Температура',    'F',    -50, 50),
(2, 'Влажность',      '%',      0, 100),
(3, 'Давление',       'mmHg', 700, 800),
(4, 'Скорость ветра', 'km/h',   0, 30),
(5, 'Осадки',         'mm',     0, 50);

insert into measurement_batches(id, user_id, created_at) values
(1,  1, '2026-08-01 08:00:00'),
(2,  1, '2026-08-02 08:00:00'),
(3,  1, '2026-08-03 08:00:00'),
(4,  2, '2026-08-04 08:00:00'),
(5,  2, '2026-08-05 08:00:00'),
(6,  2, '2026-08-06 08:00:00'),
(7,  3, '2026-08-07 08:00:00'),
(8,  3, '2026-08-08 08:00:00'),
(9,  3, '2026-08-09 08:00:00'),
(10, 4, '2026-08-10 08:00:00'),
(11, 4, '2026-08-11 08:00:00');

insert into measurements(id, batch_id, parameter_id, value) values
(11, 1, 1, 12.50), (12, 1, 2, 65.00), (13, 1, 3, 752.00), (14, 1, 4, 3.20), (15, 1, 5, 0.00);

insert into measurements(id, batch_id, parameter_id, value) values
(21, 2, 1, 75.00), (22, 2, 2, 60.00), (23, 2, 3, 751.00), (24, 2, 4, 4.50), (25, 2, 5, 1.20);

insert into measurements(id, batch_id, parameter_id, value) values
(31, 3, 1, 14.00), (32, 3, 2, 70.00), (33, 3, 3, 750.00), (34, 3, 4, 2.80), (35, 3, 5, 0.00);

insert into measurements(id, batch_id, parameter_id, value) values
(41, 4, 1, 9.50), (42, 4, 2, 120.00), (43, 4, 3, 755.00), (44, 4, 4, 6.00), (45, 4, 5, 5.50);

insert into measurements(id, batch_id, parameter_id, value) values
(51, 5, 1, 11.00), (52, 5, 2, 55.00), (53, 5, 3, 754.00), (54, 5, 4, 7.20), (55, 5, 5, 0.40);

insert into measurements(id, batch_id, parameter_id, value) values
(61, 6, 1, 13.00), (62, 6, 2, 62.00), (63, 6, 3, 1013.00), (64, 6, 4, 5.10), (65, 6, 5, 0.00);

insert into measurements(id, batch_id, parameter_id, value) values
(71, 7, 1, 16.00), (72, 7, 2, 48.00), (73, 7, 3, 749.00), (74, 7, 4, -5.00), (75, 7, 5, 2.00);

insert into measurements(id, batch_id, parameter_id, value) values
(81, 8, 1, 18.00), (82, 8, 2, 52.00), (83, 8, 3, 748.00), (84, 8, 4, 8.40), (85, 8, 5, null);

insert into measurements(id, batch_id, parameter_id, value) values
(91, 9, 1, 15.00), (92, 9, 2, 58.00), (93, 9, 3, 747.00);

insert into measurements(id, batch_id, parameter_id, value) values
(101, 10, 1, 10.00), (102, 10, 2, 80.00), (103, 10, 3, 760.00), (104, 10, 4, 9.00), (105, 10, 5, 3.30);
