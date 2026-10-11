import 'package:flutter/material.dart';

import 'diesel/tela_diesel.dart';
import 'fretes/tela_fretes.dart';
import 'gastos/tela_gastos.dart';
import 'resumo/tela_resumo.dart';
import 'vales/tela_vales.dart';

/// As cinco abas de baixo.
class Casca extends StatefulWidget {
  const Casca({super.key, this.abaInicial = 0});

  final int abaInicial;

  @override
  State<Casca> createState() => _CascaState();
}

class _CascaState extends State<Casca> {
  late int _aba = widget.abaInicial;

  static const _telas = [TelaResumo(), TelaFretes(), TelaDiesel(), TelaGastos(), TelaVales()];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _aba == 0,
      onPopInvokedWithResult: (saiu, _) {
        if (!saiu && _aba != 0) setState(() => _aba = 0);
      },
      child: Scaffold(
        body: IndexedStack(index: _aba, children: _telas),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _aba,
          onDestinationSelected: (i) => setState(() => _aba = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.signpost_outlined),
              selectedIcon: Icon(Icons.signpost),
              label: 'Resumo',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined),
              selectedIcon: Icon(Icons.local_shipping),
              label: 'Fretes',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_gas_station_outlined),
              selectedIcon: Icon(Icons.local_gas_station),
              label: 'Diesel',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Gastos',
            ),
            NavigationDestination(
              icon: Icon(Icons.payments_outlined),
              selectedIcon: Icon(Icons.payments),
              label: 'Vales',
            ),
          ],
        ),
      ),
    );
  }
}
