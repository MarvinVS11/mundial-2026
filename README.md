# Mundial 2026 ⚽🏆

Bracket animado de la fase eliminatoria del Mundial 2026. Muestra el avance día a día:
los ganadores avanzan por las llaves hacia el trofeo y los eliminados quedan en gris.

## Estructura

- `index.html` — la app completa (single-file). Banderas emoji, trofeo real incrustado en base64, cero dependencias.
- `auto/setup.sql` — crea la tabla `partidos` en Supabase, carga los resultados reales y programa el cron cada 20 min.
- `auto/sync-mundial.ts` — Edge Function que consulta football-data.org y actualiza los resultados al terminar cada partido, propagando ganadores a la siguiente llave.

## Configuración

1. En `index.html`, completar `SUPABASE_URL` y `SUPABASE_ANON_KEY` (si quedan vacías, usa los datos incrustados).
2. Correr `auto/setup.sql` en el SQL Editor de Supabase (reemplazar `TU-PROYECTO` y `TU_SERVICE_ROLE_KEY` en la sección del cron).
3. Desplegar la función: `supabase functions deploy sync-mundial` y agregar el secreto `FOOTBALL_DATA_KEY` (gratis en football-data.org).
4. Deploy en Vercel: importar el repo y listo.

## Uso

- ▶ reproduce el avance del torneo día por día.
- ‹ › navegan entre fechas.
- ⤢ alterna entre vista completa y zoom 100 %.
- Los partidos del día aparecen abajo con marcadores, penales y tiempo extra.
