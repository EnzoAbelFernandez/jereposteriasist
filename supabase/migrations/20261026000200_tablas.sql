-- =============================================================================
-- 0200 TABLAS DE NEGOCIO
-- =============================================================================
-- Catálogos: se "archivan" (archivado_en) en vez de borrarse, para conservar el historial.
-- Documentos con impacto en stock/caja (compras, gastos, producciones): INMUTABLES una vez
--   registrados; solo se pueden ANULAR (estado 'anulado') y se generan contramovimientos.
-- Libros (movimientos_stock, movimientos_caja): solo INSERT. Corrección = movimiento de anulación.
-- =============================================================================

-- ---------- Clientes ----------
create table public.clientes (
  id uuid primary key default gen_random_uuid(),
  nombre text not null check (length(trim(nombre)) > 0),
  telefono text,
  email text,
  direccion text,
  cumple_dia smallint check (cumple_dia between 1 and 31),
  cumple_mes smallint check (cumple_mes between 1 and 12),
  cumple_anio smallint check (cumple_anio between 1900 and 2100), -- opcional
  preferencias text,
  alergias text,
  notas text,
  -- 'auto' = lo decide habitual_auto; 'si' / 'no' = forzado a mano
  habitual_modo text not null default 'auto' check (habitual_modo in ('auto', 'si', 'no')),
  habitual_auto boolean not null default false, -- SOLO lo escribe el servidor
  archivado_en timestamptz,
  creado_por uuid references public.perfiles (id),
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),
  check ((cumple_dia is null) = (cumple_mes is null))
);

-- ---------- Proveedores ----------
create table public.proveedores (
  id uuid primary key default gen_random_uuid(),
  nombre text not null check (length(trim(nombre)) > 0),
  telefono text,
  email text,
  notas text,
  archivado_en timestamptz,
  creado_por uuid references public.perfiles (id),
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

-- ---------- Insumos (materia prima) ----------
create table public.insumos (
  id uuid primary key default gen_random_uuid(),
  nombre text not null check (length(trim(nombre)) > 0),
  unidad text not null check (unidad in ('g', 'ml', 'u')), -- unidad base
  stock_minimo bigint not null default 0 check (stock_minimo >= 0), -- en unidad base
  categoria text,
  notas text,
  archivado_en timestamptz,
  creado_por uuid references public.perfiles (id),
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

-- ---------- Productos (catálogo de lo que se vende) ----------
create table public.productos (
  id uuid primary key default gen_random_uuid(),
  nombre text not null check (length(trim(nombre)) > 0),
  categoria text not null default 'torta' check (categoria in ('torta', 'tarta', 'mesa_dulce', 'otro')),
  precio_base_centavos bigint check (precio_base_centavos >= 0),
  descripcion text,
  archivado_en timestamptz,
  creado_por uuid references public.perfiles (id),
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

-- ---------- Recetas (fase 2, la tabla existe desde ya) ----------
create table public.recetas (
  id uuid primary key default gen_random_uuid(),
  nombre text not null check (length(trim(nombre)) > 0),
  producto_id uuid references public.productos (id),
  rinde_cantidad int not null default 1 check (rinde_cantidad > 0),
  rinde_descripcion text, -- ej: "1 torta de 24 cm", "30 porciones"
  notas text,
  archivado_en timestamptz,
  creado_por uuid references public.perfiles (id),
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create table public.receta_items (
  id uuid primary key default gen_random_uuid(),
  receta_id uuid not null references public.recetas (id) on delete cascade,
  insumo_id uuid not null references public.insumos (id),
  cantidad bigint not null check (cantidad > 0), -- en unidad base del insumo
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

-- ---------- Pedidos ----------
create sequence public.pedidos_numero_seq;

create table public.pedidos (
  id uuid primary key default gen_random_uuid(),
  -- Número correlativo asignado por el SERVIDOR al sincronizar (el cliente no lo envía).
  numero bigint unique default nextval('public.pedidos_numero_seq'),
  cliente_id uuid not null references public.clientes (id),
  fecha_entrega timestamptz not null,
  tipo_entrega text not null default 'retira' check (tipo_entrega in ('retira', 'envio')),
  direccion_entrega text,
  estado text not null default 'confirmado' check (estado in (
    'presupuesto', 'confirmado', 'en_produccion', 'listo', 'entregado', 'cancelado'
  )),
  descuento_centavos bigint not null default 0 check (descuento_centavos >= 0),
  motivo_descuento text,
  notas text,
  entregado_en timestamptz,
  cancelado_en timestamptz,
  motivo_cancelacion text,
  creado_por uuid references public.perfiles (id),
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);
alter sequence public.pedidos_numero_seq owned by public.pedidos.numero;

-- Total del pedido = sum(cantidad * precio_unitario_centavos) - descuento_centavos (se calcula, no se guarda).
create table public.pedido_items (
  id uuid primary key default gen_random_uuid(),
  pedido_id uuid not null references public.pedidos (id) on delete cascade,
  producto_id uuid references public.productos (id),
  descripcion text not null check (length(trim(descripcion)) > 0),
  cantidad int not null default 1 check (cantidad > 0),
  precio_unitario_centavos bigint not null check (precio_unitario_centavos >= 0),
  notas text,
  orden int not null default 0,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

-- ---------- Compras ----------
create table public.compras (
  id uuid primary key default gen_random_uuid(),
  proveedor_id uuid references public.proveedores (id),
  fecha timestamptz not null default now(),
  medio_pago text not null check (medio_pago in ('efectivo', 'transferencia', 'mercado_pago')),
  estado text not null default 'registrado' check (estado in ('registrado', 'anulado')),
  anulado_en timestamptz,
  motivo_anulacion text,
  notas text,
  creado_por uuid references public.perfiles (id),
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create table public.compra_items (
  id uuid primary key default gen_random_uuid(),
  compra_id uuid not null references public.compras (id) on delete cascade,
  insumo_id uuid not null references public.insumos (id),
  cantidad bigint not null check (cantidad > 0), -- unidad base
  precio_total_centavos bigint not null check (precio_total_centavos >= 0),
  creado_en timestamptz not null default now()
);

-- ---------- Gastos ----------
create table public.categorias_gasto (
  id uuid primary key default gen_random_uuid(),
  nombre text not null check (length(trim(nombre)) > 0),
  archivado_en timestamptz,
  creado_por uuid references public.perfiles (id),
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create table public.gastos (
  id uuid primary key default gen_random_uuid(),
  fecha date not null,
  categoria_id uuid not null references public.categorias_gasto (id),
  descripcion text not null check (length(trim(descripcion)) > 0),
  monto_centavos bigint not null check (monto_centavos > 0),
  medio_pago text not null check (medio_pago in ('efectivo', 'transferencia', 'mercado_pago')),
  estado text not null default 'registrado' check (estado in ('registrado', 'anulado')),
  anulado_en timestamptz,
  motivo_anulacion text,
  notas text,
  creado_por uuid references public.perfiles (id),
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

-- ---------- Producción ----------
create table public.producciones (
  id uuid primary key default gen_random_uuid(),
  fecha timestamptz not null default now(),
  producto_id uuid references public.productos (id),
  descripcion text not null check (length(trim(descripcion)) > 0),
  cantidad int not null default 1 check (cantidad > 0),
  pedido_id uuid references public.pedidos (id),
  receta_id uuid references public.recetas (id),
  estado text not null default 'registrado' check (estado in ('registrado', 'anulado')),
  anulado_en timestamptz,
  motivo_anulacion text,
  notas text,
  creado_por uuid references public.perfiles (id),
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

-- ---------- Libro de stock (stock actual = suma de cantidad por insumo) ----------
create table public.movimientos_stock (
  id uuid primary key default gen_random_uuid(),
  insumo_id uuid not null references public.insumos (id),
  fecha timestamptz not null default now(),
  cantidad bigint not null check (cantidad <> 0), -- + entra / - sale (unidad base)
  tipo text not null check (tipo in ('inicial', 'compra', 'produccion', 'ajuste', 'merma', 'anulacion')),
  compra_id uuid references public.compras (id),
  produccion_id uuid references public.producciones (id),
  anula_id uuid unique references public.movimientos_stock (id),
  nota text,
  creado_por uuid references public.perfiles (id),
  creado_en timestamptz not null default now(),
  check (tipo <> 'compra' or (compra_id is not null and cantidad > 0)),
  check (tipo <> 'produccion' or (produccion_id is not null and cantidad < 0)),
  check (tipo <> 'merma' or cantidad < 0),
  check (tipo <> 'anulacion' or anula_id is not null),
  check (tipo = 'anulacion' or anula_id is null)
);

-- ---------- Libro de caja ----------
create table public.movimientos_caja (
  id uuid primary key default gen_random_uuid(),
  fecha timestamptz not null default now(),
  tipo text not null check (tipo in ('ingreso', 'egreso')),
  monto_centavos bigint not null check (monto_centavos > 0),
  medio_pago text not null check (medio_pago in ('efectivo', 'transferencia', 'mercado_pago')),
  concepto text not null check (concepto in (
    'sena', 'pago_pedido', 'compra', 'gasto', 'otro_ingreso', 'otro_egreso', 'anulacion'
  )),
  descripcion text,
  pedido_id uuid references public.pedidos (id),
  compra_id uuid references public.compras (id),
  gasto_id uuid references public.gastos (id),
  anula_id uuid unique references public.movimientos_caja (id),
  creado_por uuid references public.perfiles (id),
  creado_en timestamptz not null default now(),
  check (concepto not in ('sena', 'pago_pedido') or (pedido_id is not null and tipo = 'ingreso')),
  check (concepto <> 'compra' or (compra_id is not null and tipo = 'egreso')),
  check (concepto <> 'gasto' or (gasto_id is not null and tipo = 'egreso')),
  check (concepto <> 'otro_ingreso' or tipo = 'ingreso'),
  check (concepto <> 'otro_egreso' or tipo = 'egreso'),
  check (concepto <> 'anulacion' or anula_id is not null),
  check (concepto = 'anulacion' or anula_id is null)
);

-- ---------- Tareas ----------
create table public.tareas (
  id uuid primary key default gen_random_uuid(),
  titulo text not null check (length(trim(titulo)) > 0),
  descripcion text,
  tipo text not null default 'otro' check (tipo in ('compra', 'produccion', 'stock', 'gasto', 'pedido', 'limpieza', 'otro')),
  prioridad text not null default 'media' check (prioridad in ('baja', 'media', 'alta')),
  estado text not null default 'pendiente' check (estado in ('pendiente', 'en_progreso', 'hecha', 'cancelada')),
  asignado_a uuid not null references public.perfiles (id),
  fecha_vencimiento date,
  pedido_id uuid references public.pedidos (id),
  completada_en timestamptz,
  creado_por uuid references public.perfiles (id),
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

-- ---------- Alertas (las genera SOLO el servidor) ----------
create table public.alertas (
  id uuid primary key default gen_random_uuid(),
  destinatario_id uuid not null references public.perfiles (id) on delete cascade,
  tipo text not null check (tipo in ('cumpleanos', 'stock_bajo', 'entrega_proxima', 'tarea_asignada', 'tarea_vencida')),
  titulo text not null,
  mensaje text not null,
  entidad_tipo text check (entidad_tipo in ('cliente', 'insumo', 'pedido', 'tarea')),
  entidad_id uuid,
  clave text not null, -- evita duplicados: misma alerta, mismo destinatario
  leida_en timestamptz,
  push_enviada_en timestamptz,
  creado_en timestamptz not null default now(),
  unique (destinatario_id, clave)
);

-- ---------- Dispositivos para push (NO se sincroniza; se escribe online) ----------
create table public.dispositivos (
  id uuid primary key default gen_random_uuid(),
  perfil_id uuid not null references public.perfiles (id) on delete cascade,
  token text not null unique,
  plataforma text not null check (plataforma in ('android', 'windows', 'web')),
  actualizado_en timestamptz not null default now()
);

-- ---------- Auditoría (NO se sincroniza) ----------
create table public.auditoria (
  id bigint generated always as identity primary key,
  tabla text not null,
  registro_id uuid,
  accion text not null,
  usuario_id uuid,
  antes jsonb,
  despues jsonb,
  fecha timestamptz not null default now()
);

-- ---------- Índices ----------
create index clientes_cumple_idx on public.clientes (cumple_mes, cumple_dia) where archivado_en is null;
create index pedidos_cliente_idx on public.pedidos (cliente_id);
create index pedidos_entrega_idx on public.pedidos (fecha_entrega);
create index pedidos_estado_idx on public.pedidos (estado);
create index pedido_items_pedido_idx on public.pedido_items (pedido_id);
create index receta_items_receta_idx on public.receta_items (receta_id);
create index compra_items_compra_idx on public.compra_items (compra_id);
create index compras_fecha_idx on public.compras (fecha);
create index gastos_fecha_idx on public.gastos (fecha);
create index producciones_fecha_idx on public.producciones (fecha);
create index mov_stock_insumo_idx on public.movimientos_stock (insumo_id);
create index mov_stock_compra_idx on public.movimientos_stock (compra_id) where compra_id is not null;
create index mov_stock_produccion_idx on public.movimientos_stock (produccion_id) where produccion_id is not null;
create index mov_caja_fecha_idx on public.movimientos_caja (fecha);
create index mov_caja_pedido_idx on public.movimientos_caja (pedido_id) where pedido_id is not null;
create index mov_caja_compra_idx on public.movimientos_caja (compra_id) where compra_id is not null;
create index mov_caja_gasto_idx on public.movimientos_caja (gasto_id) where gasto_id is not null;
create index tareas_asignado_idx on public.tareas (asignado_a);
create index alertas_destinatario_idx on public.alertas (destinatario_id);
create index auditoria_registro_idx on public.auditoria (tabla, registro_id);

-- ---------- Vistas de apoyo (servidor / reportes) ----------
create view public.stock_actual with (security_invoker = true) as
select i.id as insumo_id, coalesce(sum(m.cantidad), 0)::bigint as cantidad
from public.insumos i
left join public.movimientos_stock m on m.insumo_id = i.id
group by i.id;

create view public.pedidos_totales with (security_invoker = true) as
select
  p.id as pedido_id,
  coalesce((select sum(pi.cantidad * pi.precio_unitario_centavos) from public.pedido_items pi where pi.pedido_id = p.id), 0)
    - p.descuento_centavos as total_centavos,
  coalesce((select sum(case when mc.tipo = 'ingreso' then mc.monto_centavos else -mc.monto_centavos end)
            from public.movimientos_caja mc where mc.pedido_id = p.id), 0) as pagado_centavos
from public.pedidos p;
