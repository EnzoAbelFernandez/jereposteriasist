// Pruebas del esquema SQL con PGlite (Postgres real compilado a WASM, sin Docker).
// Uso:  cd tool/sql-test && npm install && npm test
// Aplica prelude.sql (simulación mínima de Supabase) + supabase/migrations/*.sql y corre escenarios.
import { PGlite } from '@electric-sql/pglite';
import fs from 'node:fs';
import path from 'node:path';
import { randomUUID as uuid } from 'node:crypto';
import { fileURLToPath } from 'node:url';

const aqui = path.dirname(fileURLToPath(import.meta.url));
const dirMigraciones = path.resolve(aqui, '../../supabase/migrations');

const db = new PGlite();
await db.exec(fs.readFileSync(path.join(aqui, 'prelude.sql'), 'utf8'));

for (const archivo of fs.readdirSync(dirMigraciones).filter((f) => f.endsWith('.sql')).sort()) {
  let sql = fs.readFileSync(path.join(dirMigraciones, archivo), 'utf8');
  sql = sql.replace(/create extension if not exists pg_cron[^;]*;/i, '-- pg_cron simulado');
  try {
    await db.exec(sql);
    console.log(`✔ migración ${archivo}`);
  } catch (e) {
    console.error(`✘ migración ${archivo}: ${e.message}`);
    process.exit(1);
  }
}

// ---------------- mini framework ----------------
let ok = 0;
let fallas = 0;
const q = async (sql, params = []) => (await db.query(sql, params)).rows;
const uno = async (sql, params = []) => (await q(sql, params))[0];
const afectadas = async (sql, params = []) => (await db.query(sql, params)).affectedRows ?? 0;

async function como(uid, fn) {
  await db.exec(`reset role; select set_config('request.jwt.claim.sub', '${uid ?? ''}', false);`);
  if (uid) await db.exec('set role authenticated;');
  try {
    return await fn();
  } finally {
    await db.exec(`reset role; select set_config('request.jwt.claim.sub', '', false);`);
  }
}

async function test(nombre, fn) {
  try {
    await fn();
    ok++;
    console.log(`  ✔ ${nombre}`);
  } catch (e) {
    fallas++;
    console.error(`  ✘ ${nombre}\n      ${e.message}`);
  }
}

function igual(real, esperado, msg = '') {
  const a = JSON.stringify(real);
  const b = JSON.stringify(esperado);
  if (a !== b) throw new Error(`${msg} esperado ${b}, obtenido ${a}`);
}

async function debeFallar(fn, contiene) {
  try {
    await fn();
  } catch (e) {
    if (contiene && !e.message.includes(contiene)) {
      throw new Error(`falló con otro error: "${e.message}" (se esperaba "${contiene}")`);
    }
    return;
  }
  throw new Error(`se esperaba un error${contiene ? ` con "${contiene}"` : ''}`);
}

// ---------------- datos base ----------------
const JEFE = uuid();
const EMP = uuid(); // empleada de pedidos
const PROD = uuid(); // empleado de producción
await q(`insert into auth.users (id, email, raw_user_meta_data) values ($1, 'jere@x.com', '{"nombre":"Jere"}')`, [JEFE]);
await q(`insert into auth.users (id, email) values ($1, 'ana@x.com')`, [EMP]);
await q(`insert into auth.users (id, email, raw_user_meta_data) values ($1, 'pablo@x.com', '{"nombre":"Pablo"}')`, [PROD]);

console.log('\nPerfiles y permisos');
await test('el primer usuario es jefe y los demás empleados', async () => {
  igual((await uno('select rol, nombre from perfiles where id = $1', [JEFE])), { rol: 'jefe', nombre: 'Jere' });
  igual((await uno('select rol, nombre from perfiles where id = $1', [EMP])), { rol: 'empleado', nombre: 'ana' });
});
await test('jefe: 9 permisos en editar; empleado: 9 en ninguno', async () => {
  igual(Number((await uno(`select count(*) c from permisos where perfil_id = $1 and nivel = 'editar'`, [JEFE])).c), 9);
  igual(Number((await uno(`select count(*) c from permisos where perfil_id = $1 and nivel = 'ninguno'`, [EMP])).c), 9);
});

const C1 = uuid();
await como(JEFE, () => q(`insert into clientes (id, nombre, telefono) values ($1, 'María López', '1155550000')`, [C1]));

await test('empleado sin permisos no ve clientes ni puede crearlos', async () => {
  await como(EMP, async () => {
    igual((await q('select * from clientes')).length, 0);
    await debeFallar(() => q(`insert into clientes (id, nombre) values ($1, 'X')`, [uuid()]), 'row-level security');
  });
});

await como(JEFE, async () => {
  await q(`update permisos set nivel = 'cargar' where perfil_id = $1 and modulo = 'pedidos'`, [EMP]);
  await q(`update permisos set nivel = 'cargar' where perfil_id = $1 and modulo = 'produccion'`, [PROD]);
});

await test('empleado no puede subirse sus propios permisos', async () => {
  await como(EMP, () => q(`update permisos set nivel = 'editar' where perfil_id = $1`, [EMP]));
  igual((await uno(`select nivel from permisos where perfil_id = $1 and modulo = 'pedidos'`, [EMP])).nivel, 'cargar');
});
await test('los permisos del jefe no se pueden bajar', async () => {
  await como(JEFE, () => q(`update permisos set nivel = 'ver' where perfil_id = $1 and modulo = 'caja'`, [JEFE]));
  igual((await uno(`select nivel from permisos where perfil_id = $1 and modulo = 'caja'`, [JEFE])).nivel, 'editar');
});
await test('nadie cambia su propio rol', async () => {
  await como(EMP, () => debeFallar(() => q(`update perfiles set rol = 'jefe' where id = $1`, [EMP]), 'propio rol'));
  await como(JEFE, () => debeFallar(() => q(`update perfiles set rol = 'empleado' where id = $1`, [JEFE]), 'propio rol'));
});
await test('creado_por no se puede falsificar', async () => {
  const id = uuid();
  await como(EMP, () => q(`insert into clientes (id, nombre, creado_por) values ($1, 'Falso', $2)`, [id, JEFE]));
  igual((await uno('select creado_por from clientes where id = $1', [id])).creado_por, EMP);
});

console.log('\nPedidos y caja');
const P1 = uuid();
const SENA = uuid();
await como(EMP, async () => {
  await q(`insert into pedidos (id, cliente_id, fecha_entrega) values ($1, $2, now() + interval '2 days')`, [P1, C1]);
  await q(`insert into pedido_items (id, pedido_id, descripcion, cantidad, precio_unitario_centavos) values ($1, $2, 'Torta chocolate 2 kg', 2, 1500000)`, [uuid(), P1]);
  await q(`insert into movimientos_caja (id, tipo, monto_centavos, medio_pago, concepto, pedido_id) values ($1, 'ingreso', 500000, 'mercado_pago', 'sena', $2)`, [SENA, P1]);
});
await como(JEFE, () => q(`insert into movimientos_caja (id, tipo, monto_centavos, medio_pago, concepto) values ($1, 'ingreso', 100000, 'efectivo', 'otro_ingreso')`, [uuid()]));

await test('el servidor asigna número al pedido', async () => {
  const r = await uno('select numero from pedidos where id = $1', [P1]);
  if (r.numero == null) throw new Error('numero nulo');
});
await test('empleada de pedidos ve la seña pero no el resto de la caja', async () => {
  igual((await como(EMP, () => q('select id from movimientos_caja'))).map((r) => r.id), [SENA]);
});
await test('total y saldo del pedido', async () => {
  const r = await uno('select total_centavos::int t, pagado_centavos::int p from pedidos_totales where pedido_id = $1', [P1]);
  igual(r, { t: 3000000, p: 500000 });
});
await test('pedidos:cargar no puede editar un pedido', async () => {
  igual(await como(EMP, () => afectadas(`update pedidos set notas = 'x' where id = $1`, [P1])), 0);
});
await test('producción puede pasar a en_produccion/listo, nada más', async () => {
  await como(PROD, async () => {
    igual(await afectadas(`update pedidos set estado = 'en_produccion' where id = $1`, [P1]), 1);
    await debeFallar(() => q(`update pedidos set notas = 'hack' where id = $1`, [P1]), 'Solo podés cambiar el estado');
    await debeFallar(() => q(`update pedidos set estado = 'entregado' where id = $1`, [P1]), 'Solo podés cambiar el estado');
  });
});

console.log('\nStock y compras');
const HARINA = uuid();
const COMPRA = uuid();
const MOV_COMPRA = uuid();
const CAJA_COMPRA = uuid();
const stock = async () => Number((await uno('select cantidad from stock_actual where insumo_id = $1', [HARINA])).cantidad);
await como(JEFE, async () => {
  await q(`insert into insumos (id, nombre, unidad, stock_minimo) values ($1, 'Harina 0000', 'g', 5000)`, [HARINA]);
  await q(`insert into movimientos_stock (id, insumo_id, cantidad, tipo) values ($1, $2, 2000, 'inicial')`, [uuid(), HARINA]);
});
await test('alerta de stock bajo al quedar bajo el mínimo (sin duplicar en el día)', async () => {
  await como(JEFE, () => q(`insert into movimientos_stock (id, insumo_id, cantidad, tipo) values ($1, $2, -500, 'merma')`, [uuid(), HARINA]));
  const al = await q(`select mensaje from alertas where tipo = 'stock_bajo' and destinatario_id = $1`, [JEFE]);
  igual(al.length, 1); // la carga inicial (2 kg) ya alertó; la merma no duplica
  igual(al[0].mensaje, 'Quedan 2 kg (mínimo 5 kg).');
  igual((await q(`select 1 from alertas where tipo = 'stock_bajo' and destinatario_id = $1`, [EMP])).length, 0);
});
await como(JEFE, async () => {
  await q(`insert into compras (id, medio_pago) values ($1, 'efectivo')`, [COMPRA]);
  await q(`insert into compra_items (id, compra_id, insumo_id, cantidad, precio_total_centavos) values ($1, $2, $3, 25000, 3000000)`, [uuid(), COMPRA, HARINA]);
  await q(`insert into movimientos_stock (id, insumo_id, cantidad, tipo, compra_id) values ($1, $2, 25000, 'compra', $3)`, [MOV_COMPRA, HARINA, COMPRA]);
  await q(`insert into movimientos_caja (id, tipo, monto_centavos, medio_pago, concepto, compra_id) values ($1, 'egreso', 3000000, 'efectivo', 'compra', $2)`, [CAJA_COMPRA, COMPRA]);
});
await test('la compra suma stock', async () => igual(await stock(), 26500));
await test('compra_items y movimientos son inmutables', async () => {
  igual(await como(JEFE, () => afectadas(`update compra_items set cantidad = 1 where compra_id = $1`, [COMPRA])), 0);
  await debeFallar(() => q(`update movimientos_stock set cantidad = 1 where id = $1`, [MOV_COMPRA]), 'no se pueden modificar');
  await debeFallar(() => q(`delete from movimientos_caja where id = $1`, [CAJA_COMPRA]), 'no se pueden modificar');
});
await test('una compra registrada no se edita', async () => {
  await como(JEFE, () => debeFallar(() => q(`update compras set medio_pago = 'transferencia' where id = $1`, [COMPRA]), 'anulalo'));
});
await test('anular compra: el servidor corrige los contramovimientos', async () => {
  await como(JEFE, async () => {
    await q(`update compras set estado = 'anulado', motivo_anulacion = 'Error de carga' where id = $1`, [COMPRA]);
    // valores "basura" a propósito: el trigger los corrige desde el original
    await q(`insert into movimientos_stock (id, insumo_id, cantidad, tipo, anula_id) values ($1, $2, 1, 'anulacion', $3)`, [uuid(), HARINA, MOV_COMPRA]);
    await q(`insert into movimientos_caja (id, tipo, monto_centavos, medio_pago, concepto, anula_id) values ($1, 'egreso', 1, 'transferencia', 'anulacion', $2)`, [uuid(), CAJA_COMPRA]);
  });
  igual(await stock(), 1500);
  const r = await uno(`select tipo, monto_centavos::int m, medio_pago, compra_id from movimientos_caja where anula_id = $1`, [CAJA_COMPRA]);
  igual(r, { tipo: 'ingreso', m: 3000000, medio_pago: 'efectivo', compra_id: COMPRA });
  igual((await uno('select anulado_en is not null a from compras where id = $1', [COMPRA])).a, true);
});
await test('no se puede anular dos veces ni tocar una compra anulada', async () => {
  await como(JEFE, async () => {
    await debeFallar(() => q(`insert into movimientos_stock (id, insumo_id, cantidad, tipo, anula_id) values ($1, $2, 1, 'anulacion', $3)`, [uuid(), HARINA, MOV_COMPRA]), 'duplicate');
    await debeFallar(() => q(`update compras set notas = 'x' where id = $1`, [COMPRA]), 'anulado');
  });
});

console.log('\nCliente habitual');
const C2 = uuid();
await como(JEFE, async () => {
  for (let i = 0; i < 3; i++) {
    await q(`insert into pedidos (id, cliente_id, fecha_entrega, estado) values ($1, $2, now() - interval '10 days', 'entregado')`, [uuid(), C1]);
  }
  await q(`insert into clientes (id, nombre) values ($1, 'Cliente antiguo')`, [C2]);
  for (let i = 0; i < 3; i++) {
    await q(`insert into pedidos (id, cliente_id, fecha_entrega, estado, entregado_en) values ($1, $2, now() - interval '13 months', 'entregado', now() - interval '13 months')`, [uuid(), C2]);
  }
});
const habitual = async (id) => (await uno('select habitual_auto from clientes where id = $1', [id])).habitual_auto;
await test('3 pedidos entregados en 12 meses => habitual', async () => igual(await habitual(C1), true));
await test('3 pedidos pero de hace más de 12 meses => no habitual', async () => igual(await habitual(C2), false));
await test('el cliente no puede escribir habitual_auto', async () => {
  await como(JEFE, () => q('update clientes set habitual_auto = false where id = $1', [C1]));
  igual(await habitual(C1), true);
});
await test('cambiar la ventana a 24 meses lo vuelve habitual', async () => {
  await como(JEFE, () => q('update configuracion set habitual_meses = 24'));
  await q('select recalcular_habitual(null)');
  igual(await habitual(C2), true);
  await como(JEFE, () => q('update configuracion set habitual_meses = 12'));
  await q('select recalcular_habitual(null)');
});

console.log('\nAlertas programadas');
await test('29/02 en año no bisiesto => 28/02', async () => {
  igual((await uno(`select proximo_cumple(29, 2, '2027-01-10')::text d`)).d, '2027-02-28');
  igual((await uno(`select proximo_cumple(29, 2, '2028-01-10')::text d`)).d, '2028-02-29');
  igual((await uno(`select proximo_cumple(5, 1, '2027-12-20')::text d`)).d, '2028-01-05');
});
await test('cumpleaños en 3 días: alerta al jefe, no a quien no tiene clientes; sin duplicar', async () => {
  const C3 = uuid();
  await como(JEFE, () => q(`insert into clientes (id, nombre, cumple_dia, cumple_mes)
    select $1, 'Lucía', extract(day from hoy_ar() + 3), extract(month from hoy_ar() + 3)`, [C3]));
  await q('select generar_alertas_cumpleanos()');
  const al = await q(`select destinatario_id, mensaje from alertas where tipo = 'cumpleanos' and entidad_id = $1`, [C3]);
  igual(al.map((a) => a.destinatario_id), [JEFE]);
  if (!al[0].mensaje.startsWith('Faltan 3 días')) throw new Error(al[0].mensaje);
  igual((await uno('select generar_alertas_cumpleanos() n')).n, 0);
});
await test('cumpleaños fuera de la ventana de 7 días no avisa', async () => {
  const C4 = uuid();
  await como(JEFE, () => q(`insert into clientes (id, nombre, cumple_dia, cumple_mes)
    select $1, 'Lejano', extract(day from hoy_ar() + 20), extract(month from hoy_ar() + 20)`, [C4]));
  await q('select generar_alertas_cumpleanos()');
  igual((await q(`select 1 from alertas where entidad_id = $1`, [C4])).length, 0);
});
await test('entrega de mañana: avisa a pedidos y producción', async () => {
  const P = uuid();
  await como(JEFE, () => q(`insert into pedidos (id, cliente_id, fecha_entrega)
    values ($1, $2, ((hoy_ar() + 1) + time '15:00') at time zone 'America/Argentina/Buenos_Aires')`, [P, C1]));
  await q('select generar_alertas_entregas()');
  const dest = (await q(`select destinatario_id from alertas where entidad_id = $1`, [P])).map((r) => r.destinatario_id).sort();
  igual(dest, [JEFE, EMP, PROD].sort());
});

console.log('\nTareas y alertas');
const T1 = uuid();
await test('empleado no asigna tareas a otros', async () => {
  await como(EMP, () => debeFallar(() => q(`insert into tareas (id, titulo, asignado_a) values ($1, 'X', $2)`, [uuid(), JEFE]), 'Solo el jefe'));
});
await test('jefe asigna tarea => alerta al empleado', async () => {
  await como(JEFE, () => q(`insert into tareas (id, titulo, tipo, asignado_a, fecha_vencimiento) values ($1, 'Comprar manteca', 'compra', $2, hoy_ar() - 1)`, [T1, EMP]));
  igual((await q(`select 1 from alertas where tipo = 'tarea_asignada' and destinatario_id = $1`, [EMP])).length, 1);
});
await test('tarea vencida => alerta', async () => {
  await q('select generar_alertas_tareas_vencidas()');
  igual((await q(`select 1 from alertas where tipo = 'tarea_vencida' and entidad_id = $1`, [T1])).length, 1);
});
await test('empleado asignado solo cambia el estado', async () => {
  await como(EMP, async () => {
    await q(`update tareas set estado = 'hecha' where id = $1`, [T1]);
    await debeFallar(() => q(`update tareas set titulo = 'otro' where id = $1`, [T1]), 'Solo podés cambiar el estado');
  });
  igual((await uno('select completada_en is not null c from tareas where id = $1', [T1])).c, true);
});
await test('alertas: cada uno ve las suyas y solo puede marcarlas leídas', async () => {
  await como(EMP, async () => {
    const mias = await q('select destinatario_id from alertas');
    if (mias.some((a) => a.destinatario_id !== EMP)) throw new Error('ve alertas ajenas');
    igual(await afectadas('update alertas set leida_en = now()'), mias.length);
    await debeFallar(() => q(`update alertas set titulo = 'x'`), 'leída');
  });
});
await test('desactivar un empleado le quita todos los permisos', async () => {
  await como(JEFE, () => q('update perfiles set activo = false where id = $1', [PROD]));
  igual(Number((await uno(`select count(*) c from permisos where perfil_id = $1 and nivel <> 'ninguno'`, [PROD])).c), 0);
});
await test('tareas_diarias corre completo', async () => {
  const r = await uno('select tareas_diarias() r');
  if (!('cumpleanos' in r.r)) throw new Error(JSON.stringify(r));
});
await test('formatear_cantidad', async () => {
  igual((await uno(`select formatear_cantidad(2500, 'g') a, formatear_cantidad(3000, 'g') b, formatear_cantidad(500, 'g') c, formatear_cantidad(12, 'u') d`)),
    { a: '2,5 kg', b: '3 kg', c: '500 g', d: '12 u.' });
});

console.log(`\n${ok} ok, ${fallas} con error`);
process.exit(fallas ? 1 : 0);
