---
name: clean-code
description: Principios Clean Code y separación de responsabilidades para RecaudoPro-movil (Flutter + Riverpod + go_router, Clean Architecture). Úsalo SIEMPRE antes de crear, modificar o refactorizar screens, widgets, providers, usecases o repositorios en lib/, al revisar código, o cuando el usuario pida limpiar, refactorizar o eliminar código muerto.
---

# Clean Code — RecaudoPro-movil (Flutter)

## La Regla de Oro: Separación de Responsabilidades

> **Los widgets (`screens/` y `widgets/`) son exclusivamente de presentación (UI).**
> La lógica vive en **providers/notifiers** (equivalente a los hooks), **usecases**, **funciones puras** de dominio/utils y **repositorios**.

| Capa | Ubicación | Qué contiene | Qué NO contiene |
|---|---|---|---|
| **Screens** | `lib/presentation/screens/<feature>/*_screen.dart` | `build()`, composición de widgets, `ref.watch`, navegación | `http`, `SharedPreferences`, cálculos de saldos o fechas, validaciones de negocio, `try/catch` de red |
| **Widgets** | `lib/presentation/widgets/` o `screens/<feature>/widgets/` | Piezas de UI reutilizables y sin estado de negocio | Acceso a datos |
| **Providers** | `lib/presentation/providers/*_provider.dart` | `Notifier`/`AsyncNotifier`: estado de pantalla, llama a usecases, expone `AsyncValue` | Widgets, `BuildContext`, llamadas HTTP directas |
| **Usecases** | `lib/domain/usecases/<feature>/*.dart` | Una acción de negocio (`CreateCollection`, `CloseCashSession`) | Flutter, HTTP |
| **Entidades y reglas** | `lib/domain/entities/`, `lib/domain/services/` (o `core/utils/`) | Entidades inmutables y **funciones puras** (fechas de cobro sin domingos, saldo, cuota) | Flutter, IO |
| **Repositorios (contrato)** | `lib/domain/repositories/` | Interfaces abstractas | Implementación |
| **Datos** | `lib/data/{datasources,models,repositories}` | HTTP (cliente central con token y timeout), JSON ↔ modelo, implementación de los repositorios | Reglas de negocio, widgets |
| **Core** | `lib/core/{config,constants,utils}` | Configuración, constantes, utilidades genéricas | Lógica de un feature concreto |

### Ejemplo

```dart
// ❌ MAL — lógica de negocio y de red en el widget
class NewCollectionScreen extends StatefulWidget { ... }
class _State extends State<NewCollectionScreen> {
  Future<void> _save() async {
    final res = await http.post(Uri.parse('$base/api/collections'), body: {...});
    final remaining = widget.credit.total - widget.credit.paid - amount;
    if (remaining < 0) { /* ... */ }
  }
}

// ✅ BIEN — el widget solo pinta y delega
class NewCollectionScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(newCollectionProvider);
    return state.when(
      data: (s) => CollectionForm(onSubmit: ref.read(newCollectionProvider.notifier).submit),
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: e.toString()),
    );
  }
}
```
```dart
// lib/domain/services/credit_rules.dart — función pura y testeable
double remainingBalance({required double total, required double paid}) => total - paid;
bool exceedsBalance(double amount, double remaining) => amount > remaining;
```

## Principios Clean Code Aplicados

1. **Funciones pequeñas y puras**
   - Un método hace una cosa. Objetivo ≤ 20 líneas, máximo 40.
   - Las reglas de negocio son puras, sin `DateTime.now()` interno: la fecha se recibe por parámetro.
2. **Widgets pequeños**
   - `build()` con más de ~60 líneas o un archivo de pantalla con más de ~300 líneas se dividen en widgets privados o en su propio archivo.
   - Preferir `StatelessWidget`/`ConsumerWidget` y usar `const` siempre que se pueda.
3. **Estado en Riverpod, no en `setState`**
   - `setState` solo para estado efímero de UI (expandir, animar).
   - El estado de negocio va en un Notifier.
4. **Un solo cliente HTTP**
   - Se crea en `data/datasources`, con base URL, `Authorization: Bearer`, timeout y mapeo de errores.
   - Ningún otro archivo usa `http` directamente.
5. **Persistencia aislada**
   - `SharedPreferences` y `flutter_secure_storage` solo se usan dentro de datasources locales, nunca en screens.
6. **Nombres que explican**
   - Archivos en `snake_case`, clases en `PascalCase`, booleanos `isX/hasX`.
   - Los usecases se nombran con un verbo: `GetClients`, `RegisterPayment`.
7. **Inmutabilidad y tipado**
   - Entidades con `freezed` o `final`. Sin `dynamic` salvo en el borde JSON.
8. **`BuildContext` seguro**
   - Comprobar `if (!context.mounted) return;` después de cada `await`.
9. **Sin ruido**
   - Sin `print`. `debugPrint` solo detrás de `kDebugMode`.
   - Sin código comentado ni APIs deprecadas (`withOpacity` → `withValues`).

## Código Sucio: lo que no funciona se limpia

Si algo está muerto, roto o duplicado, **se elimina, no se comenta**. Pendientes conocidos:

- [ ] Archivos web en la raíz de un proyecto Flutter: `package.json`, `tailwind.config.js`, `postcss.config.js`, `tsconfig.json`.
- [ ] Logs de la JVM: `hs_err_pid*.log` y `replay_pid*.log` (en la raíz y en `android/`).
- [ ] `CONFIGURACION_SUPABASE_COMPLETA.md` y el README del panel web (la app ya no usa Supabase).
- [ ] Pantallas gigantes que se deben dividir: `new_client_screen.dart` (~1.279 líneas), `client_visit_screen.dart`, `my_wallet_screen.dart`.
- [ ] 29 avisos de `flutter analyze` (deprecados, `use_build_context_synchronously`).
- [ ] `debugPrint` fuera de `kDebugMode`.

Sesión (no romper): el único cliente HTTP es `lib/data/datasources/api_client.dart` (token, renovación
única ante 401, timeout). Los tokens viven en `flutter_secure_storage` (`session_local_datasource.dart`).
Nunca usar `http` directo en un datasource ni guardar la contraseña.

## Refactorización Limpia: Separación Estricta

1. **Identifica** dentro de la screen qué es UI, qué es estado, qué es red o persistencia y qué es regla de negocio.
2. **Extrae las reglas** a funciones puras en `domain/services/` (o `core/utils/`) y escríbeles un test.
3. **Mueve la red y la persistencia** al datasource y al repositorio. Exponlas con un usecase.
4. **Crea o ajusta el Notifier** que llame al usecase y exponga `AsyncValue`.
5. **Divide la screen** en widgets pequeños (`_Header`, `_PaymentForm`, `_ClientCard`) y deja `build()` legible de un vistazo.
6. **Refactor y feature van en commits separados.** El comportamiento no cambia en el refactor.
7. **Verifica:** `flutter analyze` sin errores nuevos, `flutter test` en verde y la pantalla funciona igual.

## Checklist antes de terminar

- [ ] Ninguna screen o widget importa `package:http`, `shared_preferences` ni datasources.
- [ ] Los cálculos (saldos, cuotas, fechas) están en funciones puras con test.
- [ ] Los métodos son cortos y los archivos de pantalla miden ≤ ~300 líneas.
- [ ] Hay `context.mounted` después de cada `await`. No hay `print`.
- [ ] El código muerto tocado quedó eliminado.
- [ ] `flutter analyze` pasa.
