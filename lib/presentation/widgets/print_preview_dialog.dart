import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/entities/collection_entity.dart';
import '../../domain/entities/credit_entity.dart';

class PrintPreviewDialog extends StatelessWidget {
  final ClientEntity client;
  final CreditEntity credit;
  final List<CollectionEntity> collections;
  final double? pendingPaymentAmount;
  final String? paymentMethod;
  final bool isFullPayment;

  const PrintPreviewDialog({
    super.key,
    required this.client,
    required this.credit,
    required this.collections,
    this.pendingPaymentAmount,
    this.paymentMethod,
    this.isFullPayment = false,
  });

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final timeFormatter = DateFormat('HH:mm');

    // Calcular información adicional
    final lastCollection = collections.isNotEmpty ? collections.first : null;
    final paymentAmount = pendingPaymentAmount ?? 0.0;
    final isOverdue = credit.overdueInstallments > 0;
    final isLargerThanInstallment = paymentAmount > credit.installmentAmount;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
            100 * PdfPageFormat.mm, 100 * PdfPageFormat.mm,
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
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Monto Prestado:',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    formatter.format(credit.totalAmount),
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Monto Restante:',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    formatter.format(credit.totalBalance),
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Valor Cuota:',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    formatter.format(credit.installmentAmount),
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
              if (isOverdue) ...[
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
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final timeFormatter = DateFormat('HH:mm');

    // Calcular información adicional
    final lastCollection = collections.isNotEmpty ? collections.first : null;
    final paymentAmount = pendingPaymentAmount ?? 0.0;
    final isOverdue = credit.overdueInstallments > 0;
    final isLargerThanInstallment = paymentAmount > credit.installmentAmount;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Center(
              child: Column(
                children: [
                  const Text(
                    'RECAUDO PRO',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monto Prestado:',
                  style: TextStyle(fontSize: 8, color: Colors.black),
                ),
                Text(
                  formatter.format(credit.totalAmount),
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monto Restante:',
                  style: TextStyle(fontSize: 8, color: Colors.black),
                ),
                Text(
                  formatter.format(credit.totalBalance),
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Valor Cuota:',
                  style: TextStyle(fontSize: 8, color: Colors.black),
                ),
                Text(
                  formatter.format(credit.installmentAmount),
                  style: const TextStyle(fontSize: 8, color: Colors.black),
                ),
              ],
            ),
            if (isOverdue) ...[
              const SizedBox(height: 2),
              Text(
                'Cuotas Atrasadas: ${credit.overdueInstallments}',
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.red,
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
                    color: Colors.green,
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
      backgroundColor: AppColors.surface,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Previsualización de Impresión',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
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
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
