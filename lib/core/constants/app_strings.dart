class AppStrings {
  // Login Screen
  static const String welcomeBack = 'Bienvenido de nuevo';
  static const String loginSubtitle =
      'Inicia sesión para continuar con tu cuenta.';
  static const String email = 'Correo electrónico';
  static const String userNumber = 'Número de usuario';
  static const String enterUserNumber = 'Ingresa tu número de usuario';
  static const String password = 'Contraseña';
  static const String enterEmail = 'Ingresa tu correo electrónico';
  static const String enterPassword = 'Ingresa tu contraseña';
  static const String forgotPassword = '¿Olvidaste tu contraseña ?';
  static const String login = 'Iniciar sesión';
  static const String orLoginWith = 'O inicia sesión con';
  static const String noAccount =
      '¿No tienes una cuenta? Comunícate con el administrador';

  /// Mensaje cuando el usuario está inactivo (is_active: false) en la API.
  static const String userInactiveMessage =
      'Tu cuenta no está activa. Debe comunicarse con el administrador del negocio para poder ingresar.';

  // Dashboard
  static const String hello = 'Hola';
  static const String dailyCollection = 'Recaudo del día';
  static const String todaySummary = 'Tu resumen de hoy.';
  static const String sales = 'Ventas';
  static const String clients = 'Clientes';
  static const String collection = 'Recaudo';
  static const String recharges = 'Recargas';
  static const String raffles = 'Rifas';
  static const String store = 'Tienda';
  static const String newCollection = 'Nuevo';
  static const String home = 'Inicio';
  static const String reports = 'Reportes';
  static const String help = 'Ayuda';
  static const String newClient = 'Crear nuevo cliente';

  // Statistics Dashboard
  static const String collectionSummary = 'Resumen de recaudo';
  static const String today = 'Hoy';
  static const String week = 'Semana';
  static const String month = 'Mes';
  static const String totalCollected = 'Total recaudado';
  static const String totalAcumulado = 'Total acumulado';
  static const String activeCredits = 'Créditos activos';
  static const String clientsInArrears = 'Clientes en mora';
  static const String weeklyCollection = 'Recaudo semanal';
  static const String creditStatus = 'Estado de créditos';
  static const String upToDate = 'Al día';
  static const String overdue = 'Vencido';
  static const String lastPaymentsReceived = 'Últimos abonos recibidos';
  static const String minutesAgo = 'Hace %d minutos';
  static const String hoursAgo = 'Hace %d hora(s)';

  // Credit List
  static const String myWallet = 'Mi cartera';
  static const String searchByNameOrId = 'Buscar por nombre o cédula...';
  static const String lastPayment = 'Último abono';
  static const String installmentValue = 'Valor cuota';
  static const String overdueInstallments = 'Cuotas atrasadas';
  static const String totalBalance = 'Saldo total';
  static const String totalLoanAmount = 'Saldo total del préstamo';
  static const String remainingBalance = 'Saldo restante';
  static const String lastPayments = 'Últimos abonos';

  // Client Visit
  static const String visitClient = 'Visita: Cliente';
  static const String collectionManagement = 'Gestión de recaudo';
  static const String clientInformation = 'Información del cliente';
  static const String locate = 'Ubicar';
  static const String name = 'Nombre';
  static const String clientId = 'ID de Cliente';
  static const String address = 'Dirección';
  static const String amountToCollectToday = 'Monto a recaudar hoy';
  static const String dueDate = 'Fecha de vencimiento';
  static const String paymentAmount = 'Monto del abono';
  static const String enterSpecificAmount = 'Ingrese un monto específico';
  static const String makePayment = 'Realizar un Abono';
  static const String payFullInstallment = 'Pagar cuota completa';

  // New Client Screen
  static const String createNewClient = 'Crear nuevo cliente';
  static const String firstName = 'Nombre';
  static const String lastName = 'Apellido';
  static const String enterFirstName = 'Ingrese el nombre';
  static const String enterLastName = 'Ingrese el apellido';
  static const String phone = 'Número de teléfono';
  static const String enterPhone = 'Ej: 300 123 4567';
  static const String enterAddress = 'Ingrese la dirección';
  static const String emailOptional = 'Email (Opcional)';
  static const String enterEmail2 = 'ejemplo@correo.com';
  static const String documentIdOptional = 'Cédula / ID (Opcional)';
  static const String enterDocumentId = 'Número de identificación';
  static const String documentFileUrlOptional = 'URL del documento (Opcional)';
  static const String enterDocumentFileUrl =
      'https://storage.../documento.pdf o .jpg';
  static const String takeDocumentPhoto = 'Tomar foto del documento';
  static const String documentPhotoCaptured = 'Foto del documento capturada';
  static const String cameraNotAvailableOnWeb =
      'La cámara no está disponible en la versión web. Usa la app en un dispositivo móvil (Android o iOS).';
  static const String cameraPluginNotLinked =
      'La cámara no está disponible. Cierra la app por completo, ábrela de nuevo e intenta otra vez. Si usas emulador, prueba en un dispositivo físico.';
  static const String saveClient = 'Guardar cliente';
  static const String clientCreatedSuccessfully = 'Cliente creado exitosamente';

  // Credit Details in New Client
  static const String creditDetails = 'Detalles del crédito';
  static const String creditAmount = 'Monto del crédito';
  static const String enterCreditAmount = '\$ 0.00';
  static const String startDate = 'Fecha de inicio';
  static const String endDate = 'Fecha final';
  static const String interest = 'Intereses';
  static const String interestRate = '%';
  static const String dailyInstallment = 'Cuota diaria';
  static const String calculatedDailyInstallment = 'Cuota diaria calculada';
  static const String totalDays = 'Días totales';
  static const String saveClientAndCredit = 'Guardar cliente y crédito';
  static const String clientAndCreditCreated =
      'Cliente y crédito creados exitosamente';

  // My Wallet Screen
  static const String lastPaymentLabel = 'Último abono';
  static const String installmentValueLabel = 'Valor cuota';
  static const String overdueInstallmentsLabel = 'Cuotas atrasadas';
  static const String totalBalanceLabel = 'Saldo total';

  // New Collection Screen
  static const String newCollectionTitle = 'Nuevo recaudo';
  static const String client = 'Cliente';
  static const String selectClient = 'Seleccionar un cliente';
  static const String amountToCollect = 'Monto a recaudar';
  static const String collectionType = 'Tipo de abono';
  static const String regularPayment = 'Abono a cuota';
  static const String extraPayment = 'Abono extra';
  static const String notes = 'Notas (Opcional)';
  static const String addNote = 'Agrega una nota sobre el recaudo...';
  static const String saveCollection = 'Guardar recaudo';
  static const String collectionSavedSuccessfully =
      'Recaudo guardado exitosamente';
  static const String pleaseSelectClient = 'Por favor selecciona un cliente';
  static const String pleaseEnterAmount = 'Por favor ingresa un monto válido';

  // Business Selection Screen
  static const String selectBusiness = 'Seleccionar negocio';
  static const String searchBusinessByNameOrNumber =
      'Buscar negocio por nombre o número';
  static const String searchBusiness = 'Buscar negocio';
  static const String enter = 'Entrar';
  static const String noBusinessFound = 'No se encontraron negocios';
  static const String pleaseSelectBusiness = 'Por favor selecciona un negocio';

  // Collection History
  static const String collectionHistory = 'Historial de recaudos';
  static const String remainingLoanAmount = 'Monto préstamo restante';
  static const String total = 'Total';
  static const String installmentAmount = 'Monto de la Cuota';
  static const String fullNameOfClient = 'Nombre completo del cliente';
  static const String registerPayment = 'Registrar abono';

  // Credit Renewal
  static const String noOutstandingBalance = 'Sin saldo pendiente';
  static const String clientPaidOff = 'El cliente ya está sin saldo pendiente';
  static const String renewCredit = 'Renovar crédito';
  static const String renewCreditConfirmation = '¿Deseas renovar el crédito?';
  static const String renewCreditMessage =
      'Se renovará el crédito por el mismo monto original. Si hay deuda pendiente, se descontará del nuevo crédito.';
  static const String creditRenewedSuccessfully =
      'Crédito renovado exitosamente';
  static const String cancel = 'Cancelar';
  static const String confirm = 'Confirmar';

  // Sesión de caja / Retiros
  static const String cashSession = 'Retiros';
  static const String cashSessionAndWithdrawals = 'Retiros';
  static const String cashSessionSubtitle = 'Retiros y saldo';
  static const String noActiveCashSession =
      'No hay sesión de caja activa. Contacta al administrador.';
  static const String initialBalance = 'Saldo inicial';
  static const String saldoDisponible = 'Saldo disponible';
  static const String cajaInicialRestante = 'Saldo inicial restante';
  static const String withdrawal = 'Retiro';
  static const String newWithdrawal = 'Nuevo retiro';
  static const String amount = 'Monto';
  static const String reason = 'Motivo';
  static const String enterAmount = 'Ingrese el monto';
  static const String enterReason = 'Ej: Pago a proveedor';
  static const String requestWithdrawal = 'Solicitar retiro';
  static const String withdrawalRequested =
      'Retiro solicitado. Pendiente de aprobación del administrador.';
  static const String withdrawalApproved =
      'Tu retiro fue aprobado por el administrador.';
  static const String myWithdrawals = 'Mis retiros';
  static const String noWithdrawals = 'No hay retiros';
  static const String pendingApproval = 'Pendiente de aprobación';
  static const String approved = 'Aprobado';
  static const String pendingWithdrawalsAlert =
      'Tienes retiros pendientes de aprobación del administrador.';
  static const String withdrawalApprovedNotification =
      'Tu retiro fue aprobado por el administrador.';
  static String withdrawalsApprovedCount(int n) => n == 1
      ? 'Tu retiro fue aprobado por el administrador.'
      : 'Tienes $n retiros aprobados por el administrador.';

  // Reportes - Caja inicial, Retiros, Gastos
  static const String initialCash = 'Caja inicial';
  static const String withdrawalsReport = 'Retiros';
  static const String withdrawalsReportSubtitle = 'Reporte de retiros y saldo';
  static const String expenses = 'Gastos';
  static const String expensesSubtitle = 'Registrar gastos administrativos';
  static const String registerExpense = 'Registrar gasto';
  static const String expenseAmount = 'Monto del gasto';
  static const String expenseReason = 'Motivo del gasto';
  static const String expenseReasonHint =
      'Describe brevemente la razón del gasto...';
  static const String category = 'Categoría';
  static const String categoryFuel = 'Combustible';
  static const String categoryFood = 'Alimentación';
  static const String expenseInfoMessage =
      'Completa los detalles a continuación para solicitar la aprobación de un nuevo gasto administrativo.';
  static const String expenseRegistered = 'Gasto registrado correctamente.';
}
