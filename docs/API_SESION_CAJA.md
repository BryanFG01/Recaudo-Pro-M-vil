# Contrato API – Sesión de caja

## Flujo GET /api/cash-sessions/flow/:id

La vista (p. ej. `cash_flow_by_session`) debe incluir:

- **total_credits**: suma de los préstamos desembolsados en esta sesión (créditos con `cash_session_id` = :id). Por ejemplo: `SUM(credits.total_amount)` o el monto efectivamente entregado al crear cada crédito. La app descuenta este valor del saldo inicial restante y del saldo disponible (el dinero que sale de caja al dar el préstamo).

Sin `total_credits` correcto, la sesión de caja no refleja el descuento por préstamos y el saldo disponible queda sobreevaluado.

## Regla obligatoria: no perder recaudo al cambiar saldo inicial

Al **actualizar** o **ingresar** un nuevo **saldo inicial** (`initial_balance`) en una sesión de caja (por ejemplo vía PATCH/POST en `/api/cash-sessions/:id` o equivalente):

1. **Solo** debe modificarse el campo `initial_balance` de la sesión existente.
2. **No** se debe borrar, reiniciar ni recalcular a cero el recaudo (`total_collected`, tablas de collections/recaudos).
3. **No** se debe crear una sesión nueva que reemplace la actual (eso haría que el recaudo ya registrado deje de estar asociado a la sesión activa).

Si el backend reemplaza la sesión o limpia el recaudo al cambiar el saldo inicial, el usuario pierde el historial de lo recaudado. La app espera que el recaudo se conserve siempre.

### Resumen

- **Saldo inicial** = base de efectivo al abrir/actualizar la sesión.
- **Recaudo** = suma de los abonos (collections) de esa sesión; es independiente del saldo inicial.
- **Al actualizar saldo inicial:** actualizar solo `initial_balance`; no tocar `total_collected` ni las filas de recaudo.
