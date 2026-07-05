// =====================================================================
// MUNDIAL 2026 · Edge Function "sync-mundial"
// Consulta football-data.org y actualiza public.partidos cuando un
// partido termina. La ejecuta pg_cron cada 20 minutos (ver setup.sql).
//
// Desplegar:
//   supabase functions deploy sync-mundial --no-verify-jwt=false
// Secretos requeridos (Dashboard > Edge Functions > Secrets):
//   FOOTBALL_DATA_KEY  -> API key gratis de https://www.football-data.org
//   (SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY ya vienen inyectados)
// =====================================================================

import { createClient } from "npm:@supabase/supabase-js@2";

// Mapa nombre/TLA de football-data.org -> código usado en la app
const CODES: Record<string, string> = {
  RSA: "RSA", CAN: "CAN", NED: "NED", MAR: "MAR", FRA: "FRA", SWE: "SWE",
  GER: "GER", PAR: "PAR", BRA: "BRA", JPN: "JPN", CIV: "CIV", NOR: "NOR",
  MEX: "MEX", ECU: "ECU", ENG: "ENG", COD: "COD", POR: "POR", CRO: "CRO",
  ESP: "ESP", AUT: "AUT", USA: "USA", BIH: "BIH", BEL: "BEL", SEN: "SEN",
  ARG: "ARG", CPV: "CPV", EGY: "EGY", AUS: "AUS", SUI: "SUI", ALG: "ALG",
  COL: "COL", GHA: "GHA",
  // variantes por nombre, por si el TLA difiere
  "South Africa": "RSA", "Netherlands": "NED", "Germany": "GER",
  "Ivory Coast": "CIV", "Côte d'Ivoire": "CIV", "DR Congo": "COD",
  "Congo DR": "COD", "Cape Verde": "CPV", "Cabo Verde": "CPV",
  "Switzerland": "SUI", "Algeria": "ALG", "England": "ENG",
  "Spain": "ESP", "Portugal": "POR", "Croatia": "CRO", "Austria": "AUT",
  "Belgium": "BEL", "Senegal": "SEN", "Argentina": "ARG", "Egypt": "EGY",
  "Australia": "AUS", "Colombia": "COL", "Ghana": "GHA", "Brazil": "BRA",
  "Japan": "JPN", "Norway": "NOR", "Mexico": "MEX", "Ecuador": "ECU",
  "France": "FRA", "Sweden": "SWE", "Paraguay": "PAR", "Morocco": "MAR",
  "Canada": "CAN", "United States": "USA",
};

const STAGE_TO_R: Record<string, number> = {
  LAST_32: 0, ROUND_OF_32: 0,
  LAST_16: 1, ROUND_OF_16: 1,
  QUARTER_FINALS: 2,
  SEMI_FINALS: 3,
  FINAL: 4,
};

function codeOf(team: any): string | null {
  return CODES[team?.tla] ?? CODES[team?.name] ?? CODES[team?.shortName] ?? null;
}

Deno.serve(async (_req) => {
  const supa = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // 1) Traer partidos terminados del Mundial desde football-data.org
  const api = await fetch(
    "https://api.football-data.org/v4/competitions/WC/matches?status=FINISHED",
    { headers: { "X-Auth-Token": Deno.env.get("FOOTBALL_DATA_KEY")! } },
  );
  if (!api.ok) {
    return new Response(`football-data error ${api.status}`, { status: 502 });
  }
  const { matches } = await api.json();

  // 2) Estado actual de nuestra tabla
  const { data: filas, error } = await supa.from("partidos").select("*");
  if (error) return new Response(error.message, { status: 500 });

  let cambios = 0;

  for (const m of matches ?? []) {
    const r = STAGE_TO_R[m.stage];
    if (r === undefined) continue; // fase de grupos u otra

    const home = codeOf(m.homeTeam);
    const away = codeOf(m.awayTeam);
    if (!home || !away) continue;

    // Buscar nuestro partido: por pareja de equipos dentro de la ronda,
    // o por la fila de esa ronda que aún no tiene equipos definidos.
    const fila =
      filas!.find((f) => f.r === r &&
        ((f.a === home && f.b === away) || (f.a === away && f.b === home))) ??
      filas!.find((f) => f.r === r && f.a === null && f.b === null);
    if (!fila) continue;

    const ft = m.score?.fullTime ?? {};
    const pen = m.score?.penalties ?? {};
    const dur = m.score?.duration; // REGULAR | EXTRA_TIME | PENALTY_SHOOTOUT

    const nuevo = {
      a: home,
      b: away,
      score_a: ft.home,
      score_b: ft.away,
      pens_a: dur === "PENALTY_SHOOTOUT" ? pen.home : null,
      pens_b: dur === "PENALTY_SHOOTOUT" ? pen.away : null,
      aet: dur === "EXTRA_TIME",
      updated_at: new Date().toISOString(),
    };

    // Solo escribir si algo cambió (evita updates innecesarios)
    if (
      fila.score_a !== nuevo.score_a || fila.score_b !== nuevo.score_b ||
      fila.a !== nuevo.a || fila.b !== nuevo.b ||
      fila.pens_a !== nuevo.pens_a || fila.pens_b !== nuevo.pens_b
    ) {
      const { error: e2 } = await supa.from("partidos")
        .update(nuevo).eq("r", fila.r).eq("i", fila.i);
      if (!e2) cambios++;
    }
  }

  // 3) Propagar ganadores a las llaves siguientes (define a/b futuros)
  const { data: todo } = await supa.from("partidos").select("*").order("r").order("i");
  const win = (f: any) => {
    if (f.score_a == null) return null;
    if (f.score_a !== f.score_b) return f.score_a > f.score_b ? f.a : f.b;
    if (f.pens_a != null) return f.pens_a > f.pens_b ? f.a : f.b;
    return null;
  };
  for (const f of todo ?? []) {
    if (f.r === 0) continue;
    const h1 = todo!.find((x) => x.r === f.r - 1 && x.i === f.i * 2);
    const h2 = todo!.find((x) => x.r === f.r - 1 && x.i === f.i * 2 + 1);
    const na = h1 ? win(h1) : null, nb = h2 ? win(h2) : null;
    if ((na && f.a !== na) || (nb && f.b !== nb)) {
      await supa.from("partidos")
        .update({ a: na ?? f.a, b: nb ?? f.b }).eq("r", f.r).eq("i", f.i);
      cambios++;
    }
  }

  return new Response(JSON.stringify({ ok: true, cambios }), {
    headers: { "Content-Type": "application/json" },
  });
});
