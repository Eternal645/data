-- Тестовый скрипт расчета
do $$
declare
	var_row record;
begin

	-- ДМК (пример 2 из ТЗ)
	raise notice 'ДМК';
	for var_row in select * from fn_calc_corrections(row(100, 25, 765, 15, 6, 0)::calc_input_params, 1) loop
		raise notice 'H=%  TT=%  HH=%  CC=%',
			var_row.height_m, var_row.temperature_corr, var_row.wind_direction_corr, var_row.wind_speed_corr;
	end loop;

	-- ВР
	raise notice 'ВР';
	for var_row in select * from fn_calc_corrections(row(100, 25, 765, 15, 0, 75)::calc_input_params, 2) loop
		raise notice 'H=%  TT=%  HH=%  CC=%',
			var_row.height_m, var_row.temperature_corr, var_row.wind_direction_corr, var_row.wind_speed_corr;
	end loop;

end $$;