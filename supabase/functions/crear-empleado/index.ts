import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const headers = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type", "Access-Control-Allow-Methods": "POST, OPTIONS", "Content-Type": "application/json" };
const reply = (status: number, error: string) => new Response(JSON.stringify({ error }), { status, headers });
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers });
  if (req.method !== "POST") return reply(405, "Método no permitido.");
  const auth = req.headers.get("Authorization") ?? "";
  if (!auth.startsWith("Bearer ")) return reply(401, "Iniciá sesión nuevamente.");
  const url = Deno.env.get("SUPABASE_URL")!;
  const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false, autoRefreshToken: false } });
  const { data: { user }, error: authError } = await admin.auth.getUser(auth.slice(7));
  if (authError || !user) return reply(401, "Iniciá sesión nuevamente.");
  const { data: perfil, error: perfilError } = await admin.from("perfiles").select("rol,activo").eq("id", user.id).maybeSingle();
  if (perfilError || !perfil || perfil.rol !== "jefe" || !perfil.activo) return reply(403, "Solo un jefe activo puede crear cuentas.");
  let body: Record<string, unknown>;
  try { body = await req.json(); } catch { return reply(400, "Revisá los datos ingresados."); }
  const nombre = typeof body.nombre === "string" ? body.nombre.trim() : "";
  const email = typeof body.email === "string" ? body.email.trim().toLowerCase() : "";
  const password = typeof body.password === "string" ? body.password : "";
  const telefono = typeof body.telefono === "string" ? body.telefono.trim() : "";
  if (!nombre || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || password.length < 8 || password.length > 72 || nombre.length > 120 || telefono.length > 50) return reply(400, "Ingresá nombre, email válido y una contraseña de al menos 8 caracteres.");
  const { data, error } = await admin.auth.admin.createUser({ email, password, email_confirm: true, user_metadata: { nombre } });
  if (error || !data.user) return reply(400, "No se pudo crear la cuenta. Revisá el email o si ya está registrado.");
  if (telefono) {
    const { error: phoneError } = await admin.from("perfiles").update({ telefono }).eq("id", data.user.id);
    if (phoneError) return new Response(JSON.stringify({ id: data.user.id, telefono_guardado: false }), { status: 201, headers });
  }
  return new Response(JSON.stringify({ id: data.user.id, telefono_guardado: true }), { status: 201, headers });
});
