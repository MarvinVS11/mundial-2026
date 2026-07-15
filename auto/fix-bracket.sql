-- =====================================================================
-- FIX: emparejamiento correcto de llaves (cuartos → semis → final)
-- Correr una vez en el SQL Editor. Es idempotente.
-- =====================================================================

-- Dieciseisavos: reordenar bloques (lado España pasa a i4..7, lado Brasil a i8..11)
update partidos set a='POR', b='CRO', score_a=2, score_b=1, pens_a=null, pens_b=null, aet=false, d='2026-07-02' where r=0 and i=4;
update partidos set a='ESP', b='AUT', score_a=3, score_b=0, pens_a=null, pens_b=null, aet=false, d='2026-07-02' where r=0 and i=5;
update partidos set a='USA', b='BIH', score_a=2, score_b=0, pens_a=null, pens_b=null, aet=false, d='2026-07-01' where r=0 and i=6;
update partidos set a='BEL', b='SEN', score_a=3, score_b=2, pens_a=null, pens_b=null, aet=true,  d='2026-07-01' where r=0 and i=7;
update partidos set a='BRA', b='JPN', score_a=2, score_b=1, pens_a=null, pens_b=null, aet=false, d='2026-06-29' where r=0 and i=8;
update partidos set a='NOR', b='CIV', score_a=2, score_b=1, pens_a=null, pens_b=null, aet=false, d='2026-06-30' where r=0 and i=9;
update partidos set a='MEX', b='ECU', score_a=2, score_b=0, pens_a=null, pens_b=null, aet=false, d='2026-06-30' where r=0 and i=10;
update partidos set a='ENG', b='COD', score_a=2, score_b=1, pens_a=null, pens_b=null, aet=false, d='2026-07-01' where r=0 and i=11;

-- Octavos: índices corregidos + resultados reales
update partidos set a='POR', b='ESP', score_a=0, score_b=1, pens_a=null, pens_b=null, aet=false, d='2026-07-06' where r=1 and i=2;
update partidos set a='USA', b='BEL', score_a=1, score_b=4, pens_a=null, pens_b=null, aet=false, d='2026-07-06' where r=1 and i=3;
update partidos set a='BRA', b='NOR', score_a=1, score_b=2, pens_a=null, pens_b=null, aet=false, d='2026-07-05' where r=1 and i=4;
update partidos set a='MEX', b='ENG', score_a=2, score_b=3, pens_a=null, pens_b=null, aet=false, d='2026-07-05' where r=1 and i=5;
update partidos set a='ARG', b='EGY', score_a=3, score_b=2, pens_a=null, pens_b=null, aet=false, d='2026-07-07' where r=1 and i=6;
update partidos set a='SUI', b='COL', score_a=0, score_b=0, pens_a=4,   pens_b=3,    aet=false, d='2026-07-07' where r=1 and i=7;

-- Cuartos: resultados reales
update partidos set a='FRA', b='MAR', score_a=2, score_b=0, pens_a=null, pens_b=null, aet=false, d='2026-07-09' where r=2 and i=0;
update partidos set a='ESP', b='BEL', score_a=2, score_b=1, pens_a=null, pens_b=null, aet=false, d='2026-07-10' where r=2 and i=1;
update partidos set a='NOR', b='ENG', score_a=1, score_b=2, pens_a=null, pens_b=null, aet=false, d='2026-07-11' where r=2 and i=2;
update partidos set a='ARG', b='SUI', score_a=3, score_b=1, pens_a=null, pens_b=null, aet=false, d='2026-07-11' where r=2 and i=3;

-- Semifinales: Francia 0-2 España jugada; Inglaterra-Argentina hoy
update partidos set a='FRA', b='ESP', score_a=0, score_b=2, pens_a=null, pens_b=null, aet=false, d='2026-07-14' where r=3 and i=0;
update partidos set a='ENG', b='ARG', score_a=null, score_b=null, pens_a=null, pens_b=null, aet=false, d='2026-07-15' where r=3 and i=1;

-- Final: España espera rival
update partidos set a='ESP', b=null, score_a=null, score_b=null, d='2026-07-19' where r=4 and i=0;

update partidos set updated_at=now() where true;
