import 'package:flutter/material.dart';

/// Categorías de gastos con id, nombre e icono para el selector.
class ExpenseCategory {
  final String id;
  final String name;
  final IconData icon;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}

const List<ExpenseCategory> expenseCategories = [
  ExpenseCategory(
      id: '1', name: 'Transporte Público', icon: Icons.directions_bus),
  ExpenseCategory(id: '2', name: 'Gasolina', icon: Icons.local_gas_station),
  ExpenseCategory(id: '3', name: 'Parqueadero', icon: Icons.local_parking),
  ExpenseCategory(id: '4', name: 'Peajes', icon: Icons.toll),
  ExpenseCategory(
      id: '5',
      name: 'Mantenimiento de Vehículo',
      icon: Icons.build_circle_outlined),
  ExpenseCategory(
      id: '6', name: 'Alquiler de Vehículo/Moto', icon: Icons.two_wheeler),
  ExpenseCategory(id: '7', name: 'Alimentación', icon: Icons.restaurant),
  ExpenseCategory(id: '8', name: 'Refrigerios', icon: Icons.coffee),
  ExpenseCategory(id: '9', name: 'Recargas Celular', icon: Icons.phone_android),
  ExpenseCategory(id: '10', name: 'Internet/Datos Móviles', icon: Icons.wifi),
  ExpenseCategory(
      id: '11', name: 'Papelería y Útiles', icon: Icons.description),
  ExpenseCategory(
      id: '12', name: 'Fotocopias e Impresiones', icon: Icons.print),
  ExpenseCategory(
      id: '13', name: 'Material de Identificación', icon: Icons.badge),
  ExpenseCategory(id: '14', name: 'Hospedaje', icon: Icons.hotel),
  ExpenseCategory(
      id: '15',
      name: 'Viáticos Generales',
      icon: Icons.account_balance_wallet_outlined),
  ExpenseCategory(
      id: '16', name: 'Comisiones Bancarias', icon: Icons.account_balance),
  ExpenseCategory(
      id: '17',
      name: 'Propinas/Gratificaciones',
      icon: Icons.volunteer_activism),
  ExpenseCategory(id: '18', name: 'Equipos de Trabajo', icon: Icons.computer),
  ExpenseCategory(id: '19', name: 'Reparación de Equipos', icon: Icons.build),
  ExpenseCategory(id: '20', name: 'Pago de Aplicación', icon: Icons.apps),
  // pago a  cobrador
  ExpenseCategory(id: '21', name: 'Pago a Cobrador', icon: Icons.person),
];
