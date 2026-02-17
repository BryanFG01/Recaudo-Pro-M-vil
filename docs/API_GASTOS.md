# Contrato API – Módulo de Gastos

El módulo **Gastos** en la app permite registrar gastos administrativos (combustible, alimentación, etc.) y consultar su estado. Actualmente la pantalla de "Registrar Gasto" funciona con datos locales; para persistir y aprobar gastos en el backend se requieren las siguientes APIs.

---

## APIs a implementar en el backend

### 1. Crear gasto (solicitud de aprobación)

**POST** `/api/expenses`

Permite al usuario registrar un nuevo gasto administrativo. El gasto queda en estado "pendiente de aprobación" hasta que un administrador lo apruebe (similar al flujo de retiros).

**Body (JSON):**
```json
{
  "business_id": "uuid-del-negocio",
  "user_id": "uuid-del-usuario",
  "amount": 50000.00,
  "reason": "Combustible para ruta de recaudo",
  "category": "fuel",
  "notes": "Opcional: detalles adicionales"
}
```

**Categorías sugeridas:** `fuel` (Combustible), `food` (Alimentación). El backend puede extender con más categorías.

**Respuesta esperada (201):**
```json
{
  "id": "uuid-del-gasto",
  "business_id": "...",
  "user_id": "...",
  "amount": 50000.00,
  "reason": "...",
  "category": "fuel",
  "notes": null,
  "is_approved": false,
  "created_at": "2026-02-10T12:00:00Z",
  "approved_at": null
}
```

---

### 2. Listar gastos del usuario

**GET** `/api/expenses/user/:userId`

O bien con query: **GET** `/api/expenses?user_id=:userId`

Devuelve la lista de gastos del usuario (para mostrar en "Mis Gastos" y en reportes).

**Query opcional:** `?business_id=...` para filtrar por negocio.

**Respuesta esperada (200):**
```json
{
  "expenses": [
    {
      "id": "uuid",
      "business_id": "...",
      "user_id": "...",
      "amount": 50000.00,
      "reason": "Combustible",
      "category": "fuel",
      "notes": null,
      "is_approved": false,
      "created_at": "2026-02-10T12:00:00Z",
      "approved_at": null
    }
  ]
}
```

---

### 3. Gastos pendientes de aprobación (administrador)

**GET** `/api/expenses/pending`

O **GET** `/api/expenses?is_approved=false`

Para que el administrador vea "Pre gastos por aprobar" (similar a retiros pendientes) y pueda aprobar o rechazar.

**Respuesta esperada (200):** Lista de gastos con `is_approved: false`.

---

### 4. Aprobar / Rechazar gasto (administrador)

**PATCH** `/api/expenses/:id`

**Body (JSON):**
```json
{
  "is_approved": true
}
```

O para rechazar: `"is_approved": false` (opcionalmente un campo `rejection_reason`).

**Respuesta esperada (200):** Objeto del gasto actualizado con `approved_at` y `is_approved`.

---

### 5. Resumen de gastos (para reportes / caja)

**GET** `/api/expenses/summary?business_id=...&user_id=...&date_from=...&date_to=...`

O incluir en el flujo de sesión de caja (ej. en **GET** `/api/cash-sessions/flow/:id`) un campo:

- `total_expenses` o `gastos`: suma de gastos aprobados en el período.

Así en pantallas como "Caja actual" se puede mostrar la línea **Gastos** (total gastos aprobados) y **Pre gastos por aprobar** (cantidad o monto pendiente).

---

## Resumen

| Método | Ruta | Uso |
|--------|------|-----|
| POST   | `/api/expenses` | Crear gasto (pendiente aprobación) |
| GET    | `/api/expenses/user/:userId` | Listar gastos del usuario |
| GET    | `/api/expenses/pending` | Gastos pendientes (admin) |
| PATCH  | `/api/expenses/:id` | Aprobar o rechazar gasto |
| GET    | `/api/expenses/summary` (opcional) | Resumen para reportes/caja |

Hasta que estas APIs existan, la app muestra el formulario de "Registrar Gasto" y guarda solo en memoria (mensaje de éxito local). Al conectar el backend, se deberá:

1. Crear `ExpenseEntity`, `ExpenseRemoteDataSource`, `ExpenseRepository`, providers y use cases (siguiendo el patrón de retiros en `cash_session_*`).
2. En `ExpensesScreen`: llamar al use case de creación y, opcionalmente, mostrar lista "Mis Gastos" con datos de `GET /api/expenses/user/:userId`.
