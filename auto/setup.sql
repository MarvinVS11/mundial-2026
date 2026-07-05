-- =====================================================================
-- MUNDIAL 2026 · setup.sql
-- Ejecutar en Supabase > SQL Editor (una sola vez)
-- =====================================================================

-- 1) Tabla de partidos (r = ronda 0..4, i = índice del partido en la ronda)
create table if not exists public.partidos (
  r        int  not null,
  i        int  not null,
  d        date not null,
  a        text,            -- código equipo A (null si aún no se define)
  b        text,            -- código equipo B
  score_a  int,
  score_b  int,
  pens_a   int,
  pens_b   int,
  aet      boolean default false,
  updated_at timestamptz default now(),
  primary key (r, i)
);

alter table public.partidos enable row level security;

-- Lectura pública (patrón anon habitual), escritura solo service_role
drop policy if exists "lectura publica" on public.partidos;
create policy "lectura publica" on public.partidos
  for select using (true);

-- 2) Datos iniciales (resultados reales al 4 de julio de 2026)
insert into public.partidos (r,i,d,a,b,score_a,score_b,pens_a,pens_b,aet) values
  (0,0 ,'2026-06-28','CAN','RSA',1,0,null,null,false),
  (0,1 ,'2026-06-29','MAR','NED',1,1,3,2,false),
  (0,2 ,'2026-06-30','FRA','SWE',3,0,null,null,false),
  (0,3 ,'2026-06-29','PAR','GER',1,1,4,3,false),
  (0,4 ,'2026-06-29','BRA','JPN',2,1,null,null,false),
  (0,5 ,'2026-06-30','NOR','CIV',2,1,null,null,false),
  (0,6 ,'2026-06-30','MEX','ECU',2,0,null,null,false),
  (0,7 ,'2026-07-01','ENG','COD',2,1,null,null,false),
  (0,8 ,'2026-07-02','POR','CRO',2,1,null,null,false),
  (0,9 ,'2026-07-02','ESP','AUT',3,0,null,null,false),
  (0,10,'2026-07-01','USA','BIH',2,0,null,null,false),
  (0,11,'2026-07-01','BEL','SEN',3,2,null,null,true),
  (0,12,'2026-07-03','ARG','CPV',3,2,null,null,true),
  (0,13,'2026-07-03','EGY','AUS',1,1,4,2,false),
  (0,14,'2026-07-02','SUI','ALG',2,0,null,null,false),
  (0,15,'2026-07-03','COL','GHA',1,0,null,null,false),
  (1,0 ,'2026-07-04','MAR','CAN',3,0,null,null,false),
  (1,1 ,'2026-07-04','FRA','PAR',1,0,null,null,false),
  (1,2 ,'2026-07-05','BRA','NOR',null,null,null,null,false),
  (1,3 ,'2026-07-05','MEX','ENG',null,null,null,null,false),
  (1,4 ,'2026-07-06','POR','ESP',null,null,null,null,false),
  (1,5 ,'2026-07-06','USA','BEL',null,null,null,null,false),
  (1,6 ,'2026-07-07','ARG','EGY',null,null,null,null,false),
  (1,7 ,'2026-07-07','SUI','COL',null,null,null,null,false),
  (2,0 ,'2026-07-09','MAR','FRA',null,null,null,null,false),
  (2,1 ,'2026-07-11',null ,null ,null,null,null,null,false),
  (2,2 ,'2026-07-10',null ,null ,null,null,null,null,false),
  (2,3 ,'2026-07-11',null ,null ,null,null,null,null,false),
  (3,0 ,'2026-07-14',null ,null ,null,null,null,null,false),
  (3,1 ,'2026-07-15',null ,null ,null,null,null,null,false),
  (4,0 ,'2026-07-19',null ,null ,null,null,null,null,false)
on conflict (r,i) do nothing;

-- 3) Programar la sincronización automática cada 20 minutos
--    (pg_cron + pg_net llaman a la Edge Function "sync-mundial")
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- ⚠️ Reemplazar TU-PROYECTO y TU_SERVICE_ROLE_KEY antes de ejecutar:
select cron.schedule(
  'sync-mundial-cada-20min',
  '*/20 * * * *',
  $$
  select net.http_post(
    url     := 'https://jztvonoiitoyjgecunxj.supabase.co/functions/v1/sync-mundial',
    headers := '{"Authorization": "Bearer TU_SERVICE_ROLE_KEY"}'::jsonb
  );
  $$
);

-- Para detenerlo cuando termine el Mundial:
-- select cron.unschedule('sync-mundial-cada-20min');
