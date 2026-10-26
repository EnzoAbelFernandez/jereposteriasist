import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jereposteria/data/data.dart';

void main() {
  group('Dinero y Unidad', () {
    test('Dinero parsea y formatea montos en centavos enteros', () {
      expect(Dinero.parsear('15000'), const Dinero(1500000));
      expect(Dinero.parsear('15.000'), const Dinero(1500000));
      expect(Dinero.parsear('15.000,50'), const Dinero(1500050));
      expect(const Dinero(1500000).formatear(), r'$ 15.000');
      expect(const Dinero(1500050).formatear(), r'$ 15.000,50');
    });

    test('Unidad formatea gramos, mililitros y unidades', () {
      expect(Unidad.gramos.formatear(500), '500 g');
      expect(Unidad.gramos.formatear(2500), '2,5 kg');
      expect(Unidad.gramos.formatear(3000), '3 kg');
      expect(Unidad.mililitros.formatear(1500), '1,5 l');
      expect(Unidad.unidades.formatear(12), '12 u.');
    });
  });

  group('Operaciones de negocio offline (Repositorios)', () {
    test(
      'Compra impacta stock y caja, y su anulación revierte ambos',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final insumosRepo = container.read(insumosRepositorioProvider);
        final comprasRepo = container.read(comprasRepositorioProvider);
        final cajaRepo = container.read(cajaRepositorioProvider);

        final insumoId = await insumosRepo.crear(
          InsumoDatos(
            nombre: 'Chocolate cobertura',
            unidad: Unidad.gramos,
            stockMinimo: 2000,
          ),
          stockInicial: 1000,
        );

        final compraId = await comprasRepo.registrar(
          CompraDatos(
            fecha: DateTime(2026, 10, 26),
            medioPago: MedioPago.efectivo,
            items: [
              CompraItemDatos(
                insumoId: insumoId,
                cantidad: 3000,
                precioTotal: Dinero.pesos(18000),
              ),
            ],
          ),
        );

        final conStock = await insumosRepo.observarPorId(insumoId).first;
        expect(conStock?.stock, 4000);

        final filtroCaja = FiltroCaja(
          desde: DateTime(2026, 10, 1),
          hasta: DateTime(2026, 10, 31, 23, 59, 59),
        );
        final resumenCaja = await cajaRepo.observarResumen(filtroCaja).first;
        expect(resumenCaja.egresos, Dinero.pesos(18000));

        await comprasRepo.anular(compraId, motivo: 'Error de carga');

        final stockTrasAnular = await insumosRepo.observarPorId(insumoId).first;
        expect(stockTrasAnular?.stock, 1000);

        final cajaTrasAnular = await cajaRepo.observarResumen(filtroCaja).first;
        expect(cajaTrasAnular.saldo, Dinero.cero);
      },
    );

    test('Cliente pasa a habitual automáticamente con 3 pedidos entregados en 12 meses', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final clientesRepo = container.read(clientesRepositorioProvider);
      final pedidosRepo = container.read(pedidosRepositorioProvider);

      final clienteId = await clientesRepo.crear(
        ClienteDatos(nombre: 'Lucía Gómez', telefono: '1155554444'),
      );

      for (var i = 0; i < 3; i++) {
        final pedidoId = await pedidosRepo.crear(
          PedidoDatos(
            clienteId: clienteId,
            fechaEntrega: DateTime.now().add(Duration(days: i + 1)),
            items: [
              PedidoItemDatos(
                descripcion: 'Torta personalizada #${i + 1}',
                cantidad: 1,
                precioUnitario: Dinero.pesos(25000),
              ),
            ],
          ),
          sena: PagoDatos(
            monto: Dinero.pesos(10000),
            medioPago: MedioPago.transferencia,
          ),
        );
        await pedidosRepo.cambiarEstado(pedidoId, EstadoPedido.listo);
        await pedidosRepo.cambiarEstado(pedidoId, EstadoPedido.entregado);
      }

      final cliente = await clientesRepo.observarPorId(clienteId).first;
      expect(cliente?.habitualAuto, isTrue);
      expect(cliente?.esHabitual, isTrue);

      await clientesRepo.actualizar(
        clienteId,
        ClienteDatos(
          nombre: 'Lucía Gómez',
          telefono: '1155554444',
          habitualModo: HabitualModo.no,
        ),
      );
      final trasOverride = await clientesRepo.observarPorId(clienteId).first;
      expect(trasOverride?.esHabitual, isFalse);
    });

    test('Recetas calculan costo del producto y compras sugeridas según pedidos activos', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final insumosRepo = container.read(insumosRepositorioProvider);
      final comprasRepo = container.read(comprasRepositorioProvider);
      final productosRepo = container.read(productosRepositorioProvider);
      final recetasRepo = container.read(recetasRepositorioProvider);
      final clientesRepo = container.read(clientesRepositorioProvider);
      final pedidosRepo = container.read(pedidosRepositorioProvider);
      final reportesRepo = container.read(reportesRepositorioProvider);

      final harinaId = await insumosRepo.crear(
        InsumoDatos(
          nombre: 'Harina 0000',
          unidad: Unidad.gramos,
          stockMinimo: 1000,
        ),
      );

      await comprasRepo.registrar(
        CompraDatos(
          fecha: DateTime.now(),
          medioPago: MedioPago.efectivo,
          items: [
            CompraItemDatos(
              insumoId: harinaId,
              cantidad: 1000,
              precioTotal: Dinero.pesos(2000),
            ),
          ],
        ),
      );

      final prodId = await productosRepo.crear(
        ProductoDatos(
          nombre: 'Torta Clásica',
          categoria: CategoriaProducto.torta,
          precioBase: Dinero.pesos(10000),
        ),
      );

      await recetasRepo.crear(
        RecetaDatos(
          nombre: 'Receta Torta Clásica',
          productoId: prodId,
          rindeCantidad: 1,
          items: [RecetaItemDatos(insumoId: harinaId, cantidad: 500)],
        ),
      );

      final costo = await recetasRepo.observarCostoDeProducto(prodId).first;
      expect(costo?.costoUnitario, Dinero.pesos(1000));
      expect(costo?.margenPorcentaje, 90);

      final cliId = await clientesRepo.crear(
        ClienteDatos(nombre: 'Cliente Test'),
      );
      await pedidosRepo.crear(
        PedidoDatos(
          clienteId: cliId,
          fechaEntrega: DateTime.now().add(const Duration(days: 2)),
          items: [
            PedidoItemDatos(
              productoId: prodId,
              descripcion: 'Torta Clásica',
              cantidad: 2,
              precioUnitario: Dinero.pesos(10000),
            ),
          ],
        ),
      );

      final sugeridas = await reportesRepo
          .observarComprasSugeridas(diasHorizonte: 7)
          .first;
      expect(sugeridas.items.length, 1);
      expect(sugeridas.items.first.requeridoPorPedidos, 1000);
      expect(sugeridas.items.first.sugeridoComprar, 1000);
      expect(sugeridas.costoTotalEstimado, Dinero.pesos(2000));
    });
  });
}
