import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/entities/collection_entity.dart';
import '../../domain/entities/credit_entity.dart';
import '../../domain/services/credit_rules.dart';
import '../../core/utils/currency_format.dart';

class PrintPreviewDialog extends StatelessWidget {
  final ClientEntity client;
  final CreditEntity credit;
  final List<CollectionEntity> collections;
  final double? pendingPaymentAmount;
  final String? paymentMethod;
  final bool isFullPayment;
  /// En Visita Cliente no se muestra "Cuotas Atrasadas"; en otras vistas puede mostrarse.
  final bool showOverdueInstallments;

  const PrintPreviewDialog({
    super.key,
    required this.client,
    required this.credit,
    required this.collections,
    this.pendingPaymentAmount,
    this.paymentMethod,
    this.isFullPayment = false,
    this.showOverdueInstallments = true,
  });

  /// Saldo y cuota con todos los pagos (más el pago en pantalla si aún no se guardó): el listado
  /// de créditos no trae el saldo real. Mismo cálculo en la vista previa y en el PDF.
  ReceiptFigures get _figures => receiptFigures(
        totalAmount: credit.totalAmount,
        totalInterest: credit.totalInterest,
        installmentAmount: credit.installmentAmount,
        totalInstallments: credit.totalInstallments,
        paid: collections.fold<double>(0, (sum, c) => sum + c.amount) + (pendingPaymentAmount ?? 0),
      );

  static String _installmentText(ReceiptFigures f) => f.installmentNumber == 0
      ? 'Sin pagos'
      : 'Cuota ${f.installmentNumber} de ${f.totalInstallments}${f.isPartialInstallment ? ' (abono)' : ''}';

  /// Filas del crédito (etiqueta, valor, en negrita) comunes a la vista previa y al PDF.
  List<(String, String, bool)> _creditRows(ReceiptFigures f) {
    final formatter = AppCurrency.formatter;
    return [
      ('Monto Prestado:', formatter.format(credit.totalAmount), true),
      if ((credit.totalInterest ?? 0) > 0) ('Interés:', formatter.format(credit.totalInterest), false),
      ('Total a Pagar:', formatter.format(f.totalToPay), false),
      ('Total Pagado:', formatter.format(f.paid), false),
      ('Valor Cuota:', formatter.format(credit.installmentAmount), false),
      ('Cuota Pagada:', _installmentText(f), true),
      ('Cuotas Pendientes:', '${f.pendingInstallments}', false),
    ];
  }

  /// Fila "etiqueta ........ valor" del comprobante.
  static pw.Widget _receiptRow(String label, String value, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 1),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
            pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: bold ? pw.FontWeight.bold : null)),
          ],
        ),
      );

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    final formatter = AppCurrency.formatter;
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final timeFormatter = DateFormat('HH:mm');

    // Calcular información adicional
    final lastCollection = collections.isNotEmpty ? collections.first : null;
    final paymentAmount = pendingPaymentAmount ?? 0.0;
    final isOverdue = credit.overdueInstallments > 0;
    final isLargerThanInstallment = paymentAmount > credit.installmentAmount;
    final figures = _figures;

    pdf.addPage(
      pw.Page(
        // Ancho de 100 mm y alto según el contenido (rollo de impresora térmica): no se corta
        pageFormat: const PdfPageFormat(
            100 * PdfPageFormat.mm, double.infinity,
            marginAll: 3 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              // Encabezado
              pw.Center(
                child: pw.Text(
                  'RECAUDO PRO',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Comprobante de Pago',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(height: 1),
              pw.SizedBox(height: 4),

              // Información del Cliente
              pw.Text(
                'Cliente:',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                client.name,
                style: const pw.TextStyle(fontSize: 9),
              ),
              if (client.documentId != null) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'ID: ${client.documentId!}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
              pw.SizedBox(height: 4),

              // Información del Crédito
              pw.Text(
                'Información del Crédito:',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              for (final (label, value, bold) in _creditRows(figures)) _receiptRow(label, value, bold: bold),
              pw.SizedBox(height: 3),
              // Lo que el cliente debe después de este pago, destacado
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.8)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      figures.isPaidOff ? 'CRÉDITO PAGADO' : 'SALDO PENDIENTE:',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      formatter.format(figures.balance),
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (showOverdueInstallments && isOverdue) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'Cuotas Atrasadas: ${credit.overdueInstallments}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.red,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
              pw.SizedBox(height: 4),

              // Último Pago
              if (lastCollection != null) ...[
                pw.Text(
                  'Último Pago:',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      dateFormatter.format(lastCollection.paymentDate),
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      formatter.format(lastCollection.amount),
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
                if (lastCollection.paymentMethod != null) ...[
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'Método: ${lastCollection.paymentMethod}',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ],
                pw.SizedBox(height: 4),
              ],

              // Pago Actual
              if (paymentAmount > 0) ...[
                pw.Divider(height: 1),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Pago Actual:',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      isFullPayment ? 'Cuota Completa' : 'Abono',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      formatter.format(paymentAmount),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (paymentMethod != null) ...[
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'Método: $paymentMethod',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ],
                if (isLargerThanInstallment && !isFullPayment) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Abono mayor a la cuota',
                    style: pw.TextStyle(
                      fontSize: 7,
                      color: PdfColors.green,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
                pw.SizedBox(height: 4),
              ],

              // Información adicional
              pw.Divider(height: 1),
              pw.SizedBox(height: 2),
              pw.Text(
                'Fecha: ${dateFormatter.format(DateTime.now())} ${timeFormatter.format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 7),
              ),
              pw.SizedBox(height: 3),
              pw.Center(
                child: pw.Text(
                  'Gracias por su pago',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    return Uint8List.fromList(pdfBytes);
  }

  Widget _buildPreviewContent(BuildContext context) {
    final formatter = AppCurrency.formatter;
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final timeFormatter = DateFormat('HH:mm');

    // Calcular información adicional
    final lastCollection = collections.isNotEmpty ? collections.first : null;
    final paymentAmount = pendingPaymentAmount ?? 0.0;
    final isOverdue = credit.overdueInstallments > 0;
    final isLargerThanInstallment = paymentAmount > credit.installmentAmount;
    final figures = _figures;

    // El papel del comprobante se mantiene blanco: es la vista previa de un impreso.
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        border: Border.all(color: AppColors.divider(context)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            const Center(
              child: Column(
                children: [
                  Text(
                    'RECAUDO PRO',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Comprobante de Pago',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 6),

            // Información del Cliente
            const Text(
              'Cliente:',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              client.name,
              style: const TextStyle(fontSize: 9, color: Colors.black),
            ),
            if (client.documentId != null) ...[
              const SizedBox(height: 2),
              Text(
                'ID: ${client.documentId!}',
                style: const TextStyle(fontSize: 8, color: Colors.black),
              ),
            ],
            const SizedBox(height: 6),

            // Información del Crédito
            const Text(
              'Información del Crédito:',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            for (final (label, value, bold) in _creditRows(figures))
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 8, color: Colors.black)),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.black,
                        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            // Lo que el cliente debe después de este pago, destacado
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 0.8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    figures.isPaidOff ? 'CRÉDITO PAGADO' : 'SALDO PENDIENTE:',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Text(
                    formatter.format(figures.balance),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ],
              ),
            ),
            if (showOverdueInstallments && isOverdue) ...[
              const SizedBox(height: 2),
              Text(
                'Cuotas Atrasadas: ${credit.overdueInstallments}',
                style: const TextStyle(
                  fontSize: 8,
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 6),

            // Último Pago
            if (lastCollection != null) ...[
              const Text(
                'Último Pago:',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormatter.format(lastCollection.paymentDate),
                    style: const TextStyle(fontSize: 8, color: Colors.black),
                  ),
                  Text(
                    formatter.format(lastCollection.amount),
                    style: const TextStyle(fontSize: 8, color: Colors.black),
                  ),
                ],
              ),
              if (lastCollection.paymentMethod != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Método: ${lastCollection.paymentMethod}',
                  style: const TextStyle(fontSize: 7, color: Colors.black),
                ),
              ],
              const SizedBox(height: 6),
            ],

            // Pago Actual
            if (paymentAmount > 0) ...[
              const Divider(height: 1),
              const SizedBox(height: 4),
              const Text(
                'Pago Actual:',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isFullPayment ? 'Cuota Completa' : 'Abono',
                    style: const TextStyle(fontSize: 8, color: Colors.black),
                  ),
                  Text(
                    formatter.format(paymentAmount),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              if (paymentMethod != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Método: $paymentMethod',
                  style: const TextStyle(fontSize: 7, color: Colors.black),
                ),
              ],
              if (isLargerThanInstallment && !isFullPayment) ...[
                const SizedBox(height: 2),
                const Text(
                  'Abono mayor a la cuota',
                  style: TextStyle(
                    fontSize: 7,
                    color: AppColors.success,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 6),
            ],

            // Información adicional
            const Divider(height: 1),
            const SizedBox(height: 4),
            Text(
              'Fecha: ${dateFormatter.format(DateTime.now())} ${timeFormatter.format(DateTime.now())}',
              style: const TextStyle(fontSize: 7, color: Colors.black),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text(
                'Gracias por su pago',
                style: TextStyle(
                  fontSize: 8,
                  fontStyle: FontStyle.italic,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface(context),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Previsualización de impresión',
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildPreviewContent(context),
            ),
            const SizedBox(height: 12),
            // Botones en fila con mejor distribución
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary(context),
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusControl),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final pdfBytes = await _generatePdf();
                        await Printing.sharePdf(
                          bytes: pdfBytes,
                          filename:
                              'comprobante_pago_${client.name.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Comprobante compartido exitosamente'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error al compartir: ${e.toString()}',
                              ),
                              backgroundColor: AppColors.error,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceLight(context),
                      foregroundColor: AppColors.textPrimary(context),
                      elevation: 0,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusControl),
                      ),
                    ),
                    child: const Icon(Icons.share, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final pdfBytes = await _generatePdf();
                        await Printing.layoutPdf(
                          onLayout: (format) async => pdfBytes,
                        );
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error al imprimir. Asegúrate de ejecutar "flutter pub get" y reiniciar la app.\n$e',
                              ),
                              backgroundColor: AppColors.error,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusControl),
                      ),
                    ),
                    child: const Text(
                      'Imprimir',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
