# Jarvis — Setup completo desde cero

> Guía para configurar Jarvis, el asistente de IA del taller, de principio a fin. No asume nada hecho previamente — si algún paso ya está hecho, sáltalo. Al final, el personal del taller podrá hablar con Jarvis en ChatGPT para consultar y registrar clientes, autos, reparaciones, precios y gastos.

Necesitas: una cuenta de Supabase (gratis) y una cuenta de ChatGPT con acceso a Proyectos y al Plugin Directory.

---

## Paso 1 — Crear el proyecto en Supabase

1. Entra a [supabase.com](https://supabase.com) y crea una cuenta (o inicia sesión) con la cuenta donde quieres que viva la base de datos del taller.
2. Crea un **nuevo proyecto**. Nómbralo algo como `taro-garage`.
3. Elige una contraseña para la base de datos cuando te la pida (es la contraseña del usuario `postgres`, no la de tu cuenta de Supabase — guárdala, no es la que vas a usar después para Jarvis).
4. Elige el **free tier** — es suficiente para el volumen de datos de un taller pequeño.
5. Espera a que el proyecto termine de aprovisionarse (toma uno o dos minutos).

## Paso 2 — Crear las tablas, seguridad y vistas de la base de datos

1. Dentro del proyecto de Supabase, ve a **SQL Editor** (ícono en el menú lateral izquierdo).
2. Abre una consulta nueva ("New query").
3. Abre el archivo `jarvis-schema-setup.sql` (adjunto a este setup) y copia **todo** su contenido.
4. Pégalo en el SQL Editor de Supabase.
5. **Antes de correrlo**, busca la línea que dice:
   ```sql
   create role jarvis_agent login password 'CHANGE_THIS_PASSWORD';
   ```
   y reemplaza `'CHANGE_THIS_PASSWORD'` por una contraseña real y segura. Guárdala en un lugar seguro — la vas a necesitar más adelante solo si configuras una conexión directa con ese rol (ver nota al final de este documento).
6. Dale click a **Run** (o Ctrl/Cmd+Enter) para correr todo el script.
7. Debe terminar sin errores. Esto crea:
   - Las tablas `customers`, `cars`, `repairs`, `price_list` y `expenses`.
   - Una tabla de auditoría (`jarvis_audit_log`) que registra todo lo que se inserta.
   - Un rol de base de datos (`jarvis_agent`) con permisos limitados (solo puede leer e insertar, nunca borrar ni modificar).
   - Varias vistas que le permiten a Jarvis responder preguntas que cruzan información (ej. "qué auto tiene este cliente y cuál fue su última reparación") sin tener que escribir consultas complejas.

## Paso 3 — (Opcional) Cargar datos de prueba

Si quieres probar que todo funciona antes de usar datos reales del taller:

1. En el mismo SQL Editor, abre una consulta nueva.
2. Copia y pega el contenido completo de `jarvis-seed-data.sql`.
3. Dale **Run**.

Esto carga 5 clientes, 7 autos, 8 precios y 12 reparaciones de ejemplo. Es seguro correrlo más de una vez — no duplica datos.

Nota: este seed todavía no incluye gastos de ejemplo (la tabla `expenses` se agregó después). Si quieres probar las preguntas de ganancia mensual, vas a necesitar insertar algunos gastos de prueba a mano, o simplemente usar datos reales una vez que el taller empiece a registrar gastos con Jarvis.

## Paso 4 — Conectar Supabase a ChatGPT

1. En ChatGPT, crea un **Proyecto** nuevo. Nómbralo `Taro Garage` (o el nombre que prefieras para identificarlo).
2. Dentro del proyecto, busca la opción de agregar herramientas/conectores y busca el **plugin oficial de Supabase** en el Plugin Directory de ChatGPT. Instálalo.
3. Autentica el plugin con la cuenta de Supabase donde creaste el proyecto `taro-garage` en el Paso 1, y selecciona ese proyecto específico cuando te lo pida.
4. Confirma que el plugin quedó conectado — normalmente puedes pedirle que liste las tablas disponibles como primera prueba.

## Paso 5 — Configurar las instrucciones del agente

Dentro del Proyecto `Taro Garage` en ChatGPT, busca la sección de **instrucciones personalizadas** (custom instructions) del proyecto y pega exactamente esto:

```
Eres Jarvis, el asistente del taller Taro. Ayudas al personal
del taller a consultar y registrar información sobre clientes, autos,
reparaciones, precios y gastos.

Reglas:
- Toda la información que manejas vive en la base de datos de Supabase
  conectada a este proyecto. Esa base de datos es la única fuente de verdad.
- Nunca inventes datos de clientes, reparaciones, precios o gastos. Si no
  encuentras la información, dilo claramente y pregunta si quieren que se
  registre.
- Los montos se expresan en colones costarricenses (₡).
- Cuando te pidan registrar un trabajo nuevo (reparación, precio nuevo,
  cliente nuevo, gasto nuevo), confirma los datos antes de escribirlos en
  la base de datos.
- Si te piden borrar o modificar en bloque varios registros a la vez, pide
  confirmación explícita antes de ejecutar la acción.
- Para consultas que crucen cliente, auto y/o reparaciones, usa siempre una
  de las vistas (customer_car_history, customer_cars, car_latest_repair) en
  vez de escribir tu propio JOIN entre tablas.
- Para preguntas de ganancia mensual o comparar meses, usa la vista
  monthly_profit; para desglose de gastos por categoría, usa
  monthly_expenses_by_category.
- Responde de forma directa y breve, como lo haría alguien del taller
  hablando con un compañero.
```

Guarda los cambios.

## Paso 6 — Probar que todo funciona

Abre una conversación nueva dentro del Proyecto `Taro Garage` y prueba estas preguntas (si cargaste el seed del Paso 3):

1. **"¿Qué autos tiene el cliente [nombre de un cliente del seed]?"** — debe responder sin pedir que le des la placa tú mismo.
2. **"¿Cuál fue la última reparación de ese auto?"** — debe traer fecha, trabajo hecho y costo.
3. **"Registra un gasto de ₡15,000 en repuestos para [esa misma reparación], descripción: pastillas de freno."** — debe confirmar los datos antes de guardarlos, y después confirmarte que quedó registrado.
4. **"¿Cuál es la ganancia de este mes?"** — debe traer ingresos, gastos y ganancia neta.

Si alguna de estas preguntas da el error *"This tool call was blocked by OpenAI's safety checks"*, probablemente Jarvis está intentando escribir su propia consulta cruzada en vez de usar las vistas — revisa que las instrucciones del Paso 5 quedaron guardadas completas.

## Notas importantes

- **Jarvis nunca puede borrar ni modificar registros existentes** — a nivel de base de datos, no solo por instrucción. Si algo se registró mal, hay que corregirlo manualmente desde el SQL Editor de Supabase.
- **El rol `jarvis_agent` que creaste en el Paso 2 puede no ser el que el plugin usa realmente para conectarse** — en la práctica, el plugin de Supabase en ChatGPT se conecta con la cuenta de Supabase autenticada en el Paso 4, no necesariamente con ese rol dedicado. El rol y sus permisos limitados quedan definidos en la base por si en el futuro se puede forzar esa conexión, pero hoy la protección real contra borrados/modificaciones viene de que simplemente no se le dio esa instrucción a Jarvis, no de los permisos del rol.
- Todo lo que Jarvis inserta queda registrado en la tabla `jarvis_audit_log`, por si hace falta revisar qué se registró y cuándo.
