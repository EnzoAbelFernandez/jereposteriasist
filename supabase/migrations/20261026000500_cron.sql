-- =============================================================================
-- 0500 CRON: tareas diarias (alertas de cumpleaños, entregas, tareas vencidas, habituales)
-- =============================================================================
-- 11:00 UTC = 08:00 en Argentina (UTC-3, sin horario de verano).

create extension if not exists pg_cron with schema pg_catalog;

select cron.schedule(
  'tareas-diarias',
  '0 11 * * *',
  $$ select public.tareas_diarias(); $$
);
