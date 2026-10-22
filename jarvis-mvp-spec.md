# Jarvis — Especificación MVP (v0.0.1)

> Documento de trabajo. Sujeto a cambios conforme avance el proyecto.

## 1. Resumen del proyecto

Jarvis es un agente de IA para un taller automotriz, pensado para que el personal del taller (2 usuarios internos) pueda consultar y registrar información del negocio en lenguaje natural, sin depender de archivos manuales.

Punto de entrada único: un **Proyecto de ChatGPT**, conectado a una base de datos en **Supabase** que actúa como fuente única de verdad.

## 2. Descripción del agente (para las instrucciones del Proyecto en ChatGPT)

```
Eres Jarvis, el asistente del taller Taro. Ayudas al personal
del taller a consultar y registrar información sobre clientes, autos,
reparaciones y precios.

Reglas:
- Toda la información que manejas vive en la base de datos de Supabase
  conectada a este proyecto. Esa base de datos es la única fuente de verdad.
- Nunca inventes datos de clientes, reparaciones o precios. Si no encuentras
  la información, dilo claramente y pregunta si quieren que se registre.
- Los montos se expresan en colones costarricenses (₡).
- Cuando te pidan registrar un trabajo nuevo (reparación, precio nuevo,
  cliente nuevo), confirma los datos antes de escribirlos en la base de datos.
- Si te piden borrar o modificar en bloque varios registros a la vez, pide
  confirmación explícita antes de ejecutar la acción.
- Responde de forma directa y breve, como lo haría alguien del taller
  hablando con un compañero.
```

## 3. Alcance

**Lo que SÍ hace Jarvis (v0.0.1):**
- Consultar historial de reparaciones por cliente, auto o rango de fechas.
- Consultar la lista de precios vigente (trabajos recurrentes y nuevos).
- Consultar qué autos están asociados a qué cliente.
- Registrar reparaciones nuevas, clientes nuevos y precios nuevos a partir de lo que le dicte el personal del taller.

**Lo que NO hace Jarvis (v0.0.1):**
- No es accesible para clientes finales del taller — uso exclusivamente interno, 2 usuarios.
- No reemplaza ningún sistema o archivo existente del taller — es una solución nueva, construida desde cero sobre Supabase.
- No hace borrados o modificaciones masivas sin confirmación explícita.
- No maneja pagos, facturación formal ni integraciones contables (fuera de alcance del MVP).
- No tiene autenticación por cliente ni control de acceso granular — asume que ambos usuarios internos tienen la misma visibilidad sobre todos los datos.

## 4. Arquitectura de datos

**Supabase como single source of truth.**

- Toda lectura y escritura de Jarvis pasa por la base de datos Postgres de Supabase, vía el app/plugin oficial de Supabase instalado en ChatGPT (basado en MCP por debajo, publicado en el Plugin Directory de ChatGPT, no un custom connector armado a mano).
- No existen archivos intermedios (Excel, CSV) que haya que mantener sincronizados manualmente — el objetivo explícito de este rediseño es eliminar el paso de "actualizar y resubir archivos".
- Tier inicial: free tier de Supabase (suficiente para el volumen de datos esperado de un taller pequeño).
- Jarvis **sí tiene permiso de escritura** (confirmado): puede insertar clientes, autos, reparaciones y precios nuevos directamente. Pendiente de verificar en la práctica si la escritura vía el plugin funciona con el plan de ChatGPT actualmente en uso, o si requiere upgrade — validar directamente en la cuenta.
- Manejo de fotos/PDFs de facturas: **no es el objetivo principal del MVP**, pero se deja la puerta abierta para una fase futura (usaría el file storage de Supabase, con su propio límite de 1 GB en el free tier, separado del límite de la base de datos).

## 5. Sketch inicial de tablas

> Esquema preliminar — nombres, tipos y relaciones sujetos a ajuste cuando se defina el modelo final.

### `clientes`
| Atributo | Tipo | Notas |
|---|---|---|
| id | uuid / serial | Llave primaria |
| nombre | text | |
| telefono | text | |
| email | text | Opcional |
| creado_en | timestamp | |

### `autos`
| Atributo | Tipo | Notas |
|---|---|---|
| id | uuid / serial | Llave primaria |
| cliente_id | fk → clientes.id | |
| marca | text | |
| modelo | text | |
| anio | int | |
| placa | text | |
| creado_en | timestamp | |

### `reparaciones`
| Atributo | Tipo | Notas |
|---|---|---|
| id | uuid / serial | Llave primaria |
| auto_id | fk → autos.id | |
| fecha | date | |
| trabajo_realizado | text | Descripción del trabajo |
| costo | numeric | En colones (₡) |
| notas | text | Opcional |
| creado_en | timestamp | |

### `lista_precios`
| Atributo | Tipo | Notas |
|---|---|---|
| id | uuid / serial | Llave primaria |
| trabajo | text | Nombre del trabajo/servicio |
| precio | numeric | En colones (₡) |
| categoria | text | Ej. "recurrente" / "nuevo" |
| notas | text | Opcional |
| actualizado_en | timestamp | |

## 6. Seguridad: rol acotado + Row Level Security (RLS)

Decisión tomada: Jarvis escribe directamente en la base de datos, pero con dos capas de protección en vez de usar las credenciales de owner/admin del proyecto.

**Capa 1 — Rol de Postgres dedicado (`jarvis_agent`)**
- Rol de login propio para el plugin de Supabase, distinto de la cuenta de owner y del `service_role`.
- Permisos otorgados (`GRANT`): `SELECT` e `INSERT` únicamente, sobre `clientes`, `autos`, `reparaciones` y `lista_precios`.
- Explícitamente **sin `UPDATE` ni `DELETE`**, y sin acceso a ninguna otra tabla o al esquema — esto es un piso duro a nivel de base de datos, imposible de saltar aunque una política de RLS esté mal escrita.

**Capa 2 — Políticas de RLS por tabla**
- RLS activado en las 4 tablas.
- Política de `SELECT` abierta (`USING (true)`) y política de `INSERT` abierta (`WITH CHECK (true)`) para `jarvis_agent` en cada tabla.
- Al no existir políticas de `UPDATE`/`DELETE` para ese rol, esas operaciones quedan bloqueadas automáticamente.
- Con 2 usuarios internos sin necesidad de segmentar datos por cliente, las políticas empiezan simples; si en el futuro se abre acceso a clientes finales, aquí es donde se añadiría la lógica de "cada quien ve solo lo suyo".

**Capa opcional — Auditoría**
- Tabla `auditoria_jarvis` + triggers `AFTER INSERT` en las 4 tablas, que registran tabla afectada, datos insertados y timestamp.
- Da trazabilidad de qué escribió Jarvis y cuándo, útil para detectar un registro mal interpretado sin tener que confiar solo en la memoria del equipo.

Implementación: ver `jarvis-rls-setup.sql` (script listo para correr en el SQL Editor de Supabase).

## 7. Pendientes / decisiones abiertas

- Verificar en la práctica si la escritura (INSERT) vía el plugin de Supabase funciona con el plan actual de ChatGPT, o si requiere upgrade de plan.
- Definir diseño final del esquema (relaciones, campos obligatorios, índices) antes de correr el script de RLS contra las tablas reales.
- Evaluar en una fase futura si se habilita el manejo de fotos/PDFs de facturas vía el file storage de Supabase.
