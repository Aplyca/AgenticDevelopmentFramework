# Guía de Desarrollo Agéntico

> Guía de habilitación para equipos de desarrollo de software que adoptan agentes de IA a lo largo de todo el ciclo de vida. Define principios, metodologías, capacidades y la forma concreta de preparar un repositorio y un flujo de trabajo para que los agentes produzcan código confiable, mantenible y auditable.
> 

## Propósito y a quién va dirigida

Esta guía sirve para llevar a un equipo desde "usamos IA para autocompletar" hasta "operamos con agentes de IA de forma disciplinada en todo el SDLC". No es una lista de herramientas: es un **contrato operativo** sobre cómo trabajamos con agentes, qué responsabilidades no se delegan y cómo dejamos el código y la documentación en un estado que los agentes (y las personas) puedan entender.

La premisa de fondo: los agentes de IA son excelentes colaboradores y pésimos dueños. Aceleran enormemente, pero producen código plausible que puede desviarse de la intención, alucinar APIs y degradarse a medida que el proyecto crece. Nuestra disciplina existe para capturar la velocidad sin heredar esos fallos.

---

## Principios del desarrollo agéntico

1. **AI-First.** La IA es la opción por defecto, no la excepción. Antes de hacer una tarea "a mano", el equipo evalúa si un agente puede hacerla mejor, más rápido o con menor esfuerzo. La pregunta no es "¿puedo usar IA aquí?" sino "¿hay alguna razón para *no* usarla?".
2. **AI-Native.** Estructuramos las aplicaciones y los repositorios pensando en que serán desarrollados *y mantenidos* con agentes: módulos con límites claros, documentación legible por máquinas, convenciones explícitas, archivos de contexto versionados. Un repositorio AI-native es uno donde un agente recién llegado puede orientarse sin preguntar y en donde un desarrollador pueda construir la app usando agentes de IA desde el inicio.
3. **Eficiencia evaluada, no asumida.** El grado de uso de IA en cada tarea se decide explícitamente según cuatro ejes:
    - **Tiempo** — ¿reduce el tiempo total, incluyendo revisión?
    - **Esfuerzo** — ¿reduce la carga cognitiva del desarrollador o solo la traslada a la revisión?
    - **Costo** — tokens, herramientas, infraestructura. Los flujos por fases (ver SDD) consumen más tokens; presupuéstalo.
    - **Complejidad** — tareas ambiguas o críticas necesitan más andamiaje (especificación, gates) o directamente más control humano.
    
    Regla práctica: a mayor autonomía del agente, mayor debe ser la supervisión y el andamiaje.
    
4. **Responsabilidad humana indelegable.** Todo artefacto generado por IA —código, documentación, pruebas, configuración— es responsabilidad de la persona a cargo de la actividad. La autoría asistida no diluye la rendición de cuentas: si lo mergeas, es tuyo.
5. **Supervisión y orquestación por el desarrollador.** El desarrollador deja de ser el que teclea cada línea y pasa a ser quien **dirige, verifica en cada checkpoint y orquesta** a uno o varios agentes. Dirigir es un trabajo activo: no es "pedir y aprobar", es validar en cada punto antes de avanzar a la siguiente fase.
6. **El contexto es un recurso finito y precioso.** Cada token que un agente "ve" compite por su atención. Curar bien la información que entra (y dejar fuera el ruido) influye más en la calidad que cambiar de modelo. Esto es ingeniería de contexto y es una competencia de primer orden (sección 4.6).
7. **Expansión de capacidades (desarrolladores en forma de T):** La IA baja la barrera de entrada a disciplinas adyacentes: un desarrollador backend puede producir frontend básico o intermedio, uno de frontend puede escribir consultas SQL o infraestructura como código, y cualquiera puede abordar tareas fuera de su núcleo con solvencia. Usamos esto a propósito para reducir cuellos de botella y *handoffs*, hacer al equipo más versátil y autónomo, y como vía de **crecimiento profesional**: se le pide al agente que explique, no solo que resuelva, para aprender mientras se produce. Pasamos de especialistas en "I" a perfiles en "T" (un núcleo profundo + amplitud asistida).
    1. **El matiz crítico:** ampliar el  *alcance* no amplía automáticamente el *criterio*. Fuera de tu especialidad tienes más "incógnitas desconocidas" —los errores sutiles de accesibilidad, seguridad, rendimiento o convención que un experto detecta de un vistazo y tú quizá no—. Por eso este principio se empareja siempre con dos obligaciones:
    2. **Construir suficiente juicio para verificar lo que produces.** Si no puedes evaluar si la salida es correcta, no estás expandiendo tu capacidad: estás acumulando riesgo. La IA es un acelerador del aprendizaje, no un reemplazo del conocimiento de dominio (recuérdese: la spec no sustituye saber cómo luce un buen esquema de base de datos).
    3. **Buscar revisión de un especialista para trabajo crítico o de alto riesgo.** La expansión es para desbloquearte y para tareas de riesgo bajo/medio; lo crítico sigue pasando por quien tiene la profundidad.

# Patrones de desarrollo agéntico:

- Prompt pattern: Las instrucciones a ejecutar por los agentes
- Context pattern: Los inputs que alimentan el modelo
- Harness pattern: Las condiciones y herramientas en las que se apoya el modelo
- Loop pattern: Las verificaciones para guiar al agente
- Graph pattern: el flujo de trabajo (grafo) definido en el que múltiples agentes interactúan para lograr una tarea compleja.

## Roles del desarrollador en un flujo agéntico

| Rol | Qué hace | Qué NO delega |
| --- | --- | --- |
| **Especificador** | Traduce la intención de negocio en una especificación con criterios de aceptación, alcance y restricciones | La definición de "qué es correcto" |
| **Orquestador** | Asigna tareas a agentes, define el orden, ejecuta corridas paralelas o nocturnas | La decisión de qué se ejecuta de forma autónoma |
| **Verificador** | Revisa código, ejecuta y lee pruebas, valida seguridad/desempeño/accesibilidad | La aprobación final de merge |
| **Curador de contexto** | Mantiene `AGENTS.md`, specs, skills y reglas actualizados | La definición de convenciones y antipatrones |

Una persona suele jugar los cuatro roles; el patrón **Coordinador / Implementador / Verificador** también puede repartirse entre varios agentes con un humano supervisando.

---

## 4. Metodologías

### 4.1 Vibe coding — solo para prototipado

Prompteo libre, iterativo, sin especificación. Excelente para explorar, descartable por diseño. **Nunca** llega a producción tal cual. Su fallo característico —código que funciona pero "se siente ajeno" al resto del proyecto y se degrada al escalar— es exactamente lo que las demás metodologías corrigen.

### 4.2 Spec-Driven Development (SDD) — responsabilidad del desarrollador

La especificación, versionada y estructurada, es la **fuente de verdad**; el código es la salida que se genera y regenera contra ella. SDD nace como respuesta directa a tres fallos del prompteo con LLMs:

- **Desviación de intención** ("agrega login" está enormemente subespecificado).
- **Decaimiento de contexto** (el agente "olvida" decisiones viejas y se contradice al crecer el código).
- **Salida no verificable** (sin criterios de aceptación explícitos no hay forma de saber si está bien).

Una buena especificación define seis elementos: **resultados esperados, límites de alcance, restricciones, decisiones previas, desglose de tareas y criterios de verificación**. Las specs se guardan en el repositorio (`/specs`) y se editan cuando cambian los requisitos; luego se regenera la parte de código afectada.

**Flujo canónico de SDD** (alineado con herramientas como GitHub Spec Kit):

```
constitution → specify → (clarify) → (checklist) → plan → tasks → (analyze) → implement
```

| Fase | Artefacto | Propósito |
| --- | --- | --- |
| **Constitution** | `constitution.md` | Principios no negociables del proyecto (testing obligatorio, CLI-first, seguridad por defecto, stack permitido). Se define una vez y se enmienda. Cada fase posterior lo verifica como un *gate*. |
| **Specify** | `spec.md` | Qué y por qué, sin tecnología. Requisitos, historias de usuario, criterios de aceptación, casos borde. |
| **Clarify** (opcional/recomendado) | actualiza `spec.md` | Escaneo estructurado de ambigüedades; el agente hace preguntas dirigidas y escribe las respuestas de vuelta en la spec. |
| **Plan** | `plan.md`, `data-model.md`, `contracts/` | Cómo: stack, arquitectura, modelo de datos, contratos de API. Verifica cumplimiento de la constitución. |
| **Tasks** | `tasks.md` | Lista de tareas atómicas, ordenadas por dependencias, con marcadores de paralelizables y trazabilidad a historias de usuario. |
| **Analyze** (gate) | reporte de consistencia | Análisis de solo lectura: huecos de cobertura, ambigüedades, duplicaciones, violaciones de la constitución, *antes* de implementar. |
| **Implement** | código | El agente ejecuta las tareas; el desarrollador verifica en cada checkpoint. |

> **Niveles de adopción** (de menor a mayor radicalidad): *spec-first* (la spec genera, el código se mantiene), *spec-anchored* (spec y código coexisten) y *spec-as-source* (la spec es el único artefacto). La mayoría de equipos empiezan en spec-first.
> 

> **Advertencias honestas:** SDD brilla en greenfield y en features bien acotadas; en *brownfield* grande puede generar "trabajo sobre el trabajo" y volumen más que fidelidad. La spec no reemplaza el conocimiento de dominio: sigues necesitando saber cómo luce un buen esquema de base de datos y reconocer bugs sutiles. Úsalo como herramienta, no como bala de plata.
> 

### 4.3 Test-Driven Development (TDD) — apalancado en agentes

Los agentes son particularmente buenos escribiendo y manteniendo pruebas. Patrón recomendado: la persona define los criterios de aceptación en la spec; el agente genera primero las pruebas que los codifican, luego el código que las hace pasar. Las pruebas se vuelven un *gate* ejecutable que limita lo que el agente puede entregar. TDD y SDD se complementan: SDD verifica violaciones de arquitectura y de contratos que las pruebas unitarias no pueden capturar estructuralmente.

### 4.4 Documentation-First Development — responsabilidad del desarrollador

Se documenta la intención *antes* de implementar. En un mundo agéntico la documentación tiene un segundo lector: el agente. Documentación clara y versionada es, a la vez, especificación y contexto.

### 4.5 Uso de Skills y MCP

- **Skills**: capacidades empaquetadas y reutilizables (una carpeta con un `SKILL.md` y recursos opcionales) que el agente descubre y carga según la tarea. Encapsulan conocimiento especializado y flujos repetibles. Es la forma de "enseñarle" al agente cómo hacemos las cosas una vez y reutilizarlo en todo el equipo.
- **MCP (Model Context Protocol)**: estándar abierto para conectar agentes a servicios y datos externos (repos, issue trackers, bases de datos, observabilidad). Las herramientas expuestas vía MCP deben ser autocontenidas, robustas ante errores y con parámetros descriptivos e inequívocos —igual que una buena función.
- **Slash commands / comandos**: disparan flujos de varios pasos de forma estandarizada (p. ej. el pipeline de SDD).

Tanto MCP como el estándar de instrucciones de agentes son hoy estándares abiertos bajo gobernanza de fundación neutral; preferirlos reduce el *lock-in* de proveedor.

### 4.6 Context Engineering (Ingeniería de Contexto)

Disciplina de curar **todo** el entorno informativo del agente: instrucciones de sistema, definiciones de herramientas, historial, documentos recuperados, contexto del código, historia de git y estándares del equipo. No es "escribir el prompt"; es decidir qué entra a la ventana de contexto, qué se comprime, qué se recupera bajo demanda y qué se descarta.

Cinco estrategias núcleo: **selección, compresión, ordenamiento, aislamiento y optimización de formato**. Buenas prácticas concretas:

- **Específico y con ejemplos.** "Usa buenas prácticas" no le sirve a un agente. Bloques `## Preferido` / `## Evitar` con código real son de lo más efectivo.
- **Progressive disclosure.** Metadatos al inicio de cada archivo de contexto (`owner`, `last_updated`, `scope`) para que el agente decida si vale la pena leerlo y para que los humanos sepan a quién llamar cuando el contexto se vuelve obsoleto.
- **Evitar el inflado.** Contexto sucio (historial rancio, resultados de herramientas en crudo) degrada el rendimiento más rápido que un modelo más débil.
- **ContextOps.** Define las convenciones una vez en un lugar gobernado y versionado, y distribúyelas al formato de cada herramienta; cuando una convención cambia, cambia en un solo lugar.

### 4.7 SDLC completo con IA

La IA no es solo para "generar código": atraviesa todo el ciclo. Ver sección 5.

---

## 5. Capacidades con IA a lo largo del SDLC

| Etapa | Qué hace el agente | Qué verifica el humano |
| --- | --- | --- |
| **Especificación** (diseño, arquitectura) | Convierte ideas vagas en specs estructuradas, propone arquitecturas, identifica casos borde y huecos | Coherencia con negocio, decisiones arquitectónicas clave |
| **Generación de código** | Implementa contra spec/tasks, siguiendo convenciones del repo | Que respete patrones existentes y no introduzca deuda |
| **Debugging** | Reproduce, aísla y propone correcciones | Causa raíz real vs. parche superficial |
| **Documentación** (usuario final y técnica) | Redacta y mantiene docs sincronizadas con el código | Exactitud y completitud |
| **Pruebas** | Genera y mantiene unitarias, integración, E2E | Cobertura significativa, no solo verde |
| **Verificaciones** | Ejecuta chequeos de **seguridad, desempeño y accesibilidad** | Que los hallazgos se resuelvan de verdad |

> **Dato de calibración:** distintos estudios reportan que los LLM generan código con vulnerabilidades en un rango aproximado de 10 % a 42 % de los casos según el benchmark. Por eso las verificaciones de seguridad no son opcionales y el código generado por IA pasa por los mismos chequeos automáticos y revisión humana que cualquier otro.
> 

---

## 6. Habilitar una aplicación para desarrollo agéntico

### 6.1 Estructura de archivos mínima

```
repo/
├── README.md                 # Para humanos: qué es, cómo correrlo, cómo contribuir
├── AGENTS.md                 # Para agentes: el "README del agente" (ver 6.2)
├── CLAUDE.md                 # Opcional: config más rica específica de Claude Code
├── /docs                     # Documentación técnica y de usuario final
│   ├── architecture.md
│   └── decisions/            # ADRs (registros de decisiones de arquitectura)
├── /specs                    # Especificaciones versionadas (fuente de verdad SDD)
│   └── 001-feature-x/
│       ├── spec.md
│       ├── plan.md
│       ├── tasks.md
│       └── contracts/
├── /.specify
│   └── memory/constitution.md  # Principios no negociables del proyecto
└── (código del proyecto, con AGENTS.md anidados donde aporten)
```

### 6.2 `AGENTS.md` — el contrato de instrucciones para agentes

`AGENTS.md` es un formato Markdown abierto y neutral de proveedor: un "README para agentes". Lo leen de forma nativa Codex, Cursor, Copilot, Windsurf, Aider, Gemini (vía su propio archivo) y muchos más; Claude Code también lo lee, manteniendo `CLAUDE.md` como su formato nativo más rico. Está pensado para que **un solo archivo** funcione en todas las herramientas y evite que el conocimiento institucional quede atrapado en el historial de chat.

**Qué incluir** (no hay campos obligatorios; estas secciones son las recomendadas):

- **Overview**: qué hace el proyecto y su propósito.
- **Stack**: lenguajes, frameworks, versiones, base de datos, auth.
- **Convenciones**: estilo de exportación, organización de carpetas, naming.
- **Comandos**: cómo construir, correr y probar (`npm run lint && npm run test`, etc.).
- **Instrucciones de pruebas**: dónde está el plan de CI, cómo correr el set de un paquete.
- **Límites / antipatrones**: lo que el agente **no** debe tocar ("no modificar `/legacy`, está congelado") y dónde el repo se aparta a propósito de los patrones estadísticamente comunes. Esta sección es "programación defensiva para la colaboración con IA".
- **Seguridad**: prácticas y consideraciones.

**Buenas prácticas:**

- Sé **específico**, no exhaustivo: no vuelques toda la documentación dentro. Mantén el archivo raíz enfocado y **enlaza** a documentos más profundos (estándares de código, arquitectura).
- **Jerarquía / anidamiento**: en repos grandes, coloca `AGENTS.md` anidados por módulo o feature. Los agentes leen automáticamente el más cercano al archivo editado; el contexto escala de lo general (raíz) a lo local (módulo) a casos borde (feature). El más cercano gana, y un prompt explícito del usuario en el chat sobreescribe todo.
- Para config específica de herramienta, usa los archivos propios de cada una (`CLAUDE.md`, `.cursor/rules/`) y deja en `AGENTS.md` lo compartido.

### 6.3 Workflow de desarrollo agéntico (paso a paso)

1. **Define o actualiza la constitución** del proyecto (una sola vez, luego se enmienda).
2. **Escribe la especificación** del feature (qué y por qué). Itera con el agente usando una fase de *clarify* para eliminar ambigüedad.
3. **Genera el plan** (cómo) y verifica que respete la constitución.
4. **Desglosa en tareas** atómicas y ordenadas por dependencia.
5. **Corre el análisis de consistencia** (gate de solo lectura) antes de implementar: huecos de cobertura, contradicciones, violaciones de la constitución.
6. **Implementa por fases** (Setup → Fundación → Historias de usuario → Pruebas → Pulido). Para features grandes, valida el núcleo antes de añadir incrementalmente, para no saturar el contexto del agente.
7. **Verifica en cada checkpoint**: ejecuta, lee las pruebas, revisa seguridad/desempeño/accesibilidad.
8. **Revisión humana + chequeos automáticos** antes del merge (sección 7).
9. **Actualiza specs y docs** si la implementación reveló cambios: la spec sigue viva.

> Patrón de trabajo asíncrono: escribir specs de día y dejar agentes corriendo de noche funciona **solo** si la spec está bien definida, porque el agente no podrá hacer preguntas aclaratorias durante la corrida.
> 

---

## 7. Gobernanza, calidad y seguridad

La autonomía es poderosa y potencialmente peligrosa; los controles se construyen desde el inicio, no después.

- **Nunca se mergea código que no se ha leído.** Regla de oro, sin excepciones, y más estricta cuanto más autónomo sea el agente.
- **Todo PR generado por agente pasa por el proceso estándar**: revisión humana **+** chequeos de seguridad automáticos antes de integrar.
- **Verifica el PR, no solo el diff.** Estudios recientes muestran inconsistencia entre la descripción y el código en PRs de agentes (cambios "fantasma" o descripciones que no corresponden). Chequeos rápidos: que el diff no esté vacío, que la descripción no sea demasiado breve para el volumen de cambio, y cuidado con marcadores de plantilla tipo `[WIP]`.
- **Calibra la confianza en las sugerencias.** La evidencia indica que las sugerencias de agentes se adoptan a menor tasa que las humanas y, cuando se adoptan, tienden a aumentar más la complejidad y el tamaño del código. Revisa con ojo crítico el impacto en mantenibilidad.
- **Donde el humano sigue siendo imprescindible**: entender la *intención* de diseño, transferir conocimiento del proyecto y razonar sobre lógica de negocio crítica. Los agentes destacan en detección de defectos y mejoras puntuales; complementa, no sustituyas.
- **Scoping y guardrails**: limita privilegios y entornos de los agentes; gobierna las dependencias que sugieren (no aceptes paquetes a ciegas).
- **Prompts y contexto como artefactos versionados y auditables**, no improvisados en el chat. Repos de prompts/skills compartidos garantizan consistencia entre desarrolladores.
- **Cumplimiento**: las especificaciones empiezan a tratarse como evidencia regulatoria. Si el proyecto cae bajo regímenes como la EU AI Act, las specs versionadas y los gates de verificación son parte del expediente de cumplimiento.

---

## 8. Métricas para evaluar la adopción

- Tiempo de ciclo por feature (incluyendo revisión), antes y después de la adopción.
- Defectos detectados temprano (en gates) vs. post-release.
- Tasa de adopción de sugerencias de agentes y su efecto en complejidad/tamaño.
- Cobertura de pruebas significativa (no solo porcentaje verde).
- Frescura del contexto: % de `AGENTS.md`/specs revisados en los últimos N meses.
- Costo de tokens por feature (los flujos por fases consumen más; vigílalo).

Estrategia de rollout: empieza con un equipo o feature piloto, confirma que aporta valor sin disrupción, y luego extiende a más repos.

---

## 9. Checklist de "repo listo para agentes"

- [ ]  `README.md` para humanos y `AGENTS.md` para agentes, ambos vigentes.
- [ ]  `constitution.md` con principios no negociables.
- [ ]  Directorio `/specs` con specs versionadas y criterios de aceptación.
- [ ]  Directorio `/docs` con arquitectura y ADRs.
- [ ]  Comandos de build/test/lint documentados y ejecutables por el agente.
- [ ]  Skills y servidores MCP relevantes configurados y versionados.
- [ ]  `AGENTS.md` anidados en módulos complejos.
- [ ]  Sección explícita de límites y antipatrones.
- [ ]  Pipeline de CI con chequeos de seguridad obligatorios antes de merge.
- [ ]  Política escrita: ningún merge sin revisión humana.

---

## 10. Antipatrones a evitar

- **Vibe coding hacia producción.** Prototipa con él; no lo entregues.
- **Sobre-automatizar sin revisar.** Asume que el código generado tiene errores hasta probar lo contrario.
- **`AGENTS.md` como vertedero.** Si contiene todo, no guía nada. Enfócalo y enlaza.
- **Contexto genérico.** "Sigue buenas prácticas" no es una restricción accionable; da ejemplos y reglas específicas del repo.
- **Contexto obsoleto.** Sin `owner` ni `last_updated`, el contexto se pudre en silencio.
- **Tratar la spec como burocracia.** SDD no es waterfall ni documentos que nadie lee; es comunicar intención de forma verificable.
- **Confundir "pasa las pruebas" con "es correcto".** Las unitarias no capturan violaciones de arquitectura ni de contratos.

# Niveles de Desarrollo agéntico

- Asistido por IA: Consulta con prompt. Similar a Google/Stackoverflow
- Vibe Coding: Prompts sueltos. Uso de Agent Coding
- Contexto y Harness: archivo para desarrollo agéntico
    - agentes
    - Skils
    - MCP
    - AGENTS.md
- Loop: SDD y TDD
    - Specs
    - Slices
    - Verificación
    - pruebas
- Graph: SDLC completo y automatizado
    - Requerimientos (agente)
    - Arquitectura (agente)
    - Specs (SDD) (agente)
    - Documentación
    - Plan
        - Tareas
        - Elaboración de pruebas (TDD) (agente)
    - Ejecución por tarea
        - Ejecución de pruebas: deben fallar
        - Codificación
        - Ejecución Pruebas: deben pasar
    - Commit

---

## 11. Glosario

- **Agente de IA**: sistema que toma una instrucción de alto nivel, planifica, escribe, prueba y modifica código con intervención humana acotada.
- **SDD (Spec-Driven Development)**: metodología donde la especificación versionada es la fuente de verdad y el código se deriva de ella.
- **Context Engineering**: disciplina de curar todo el entorno informativo que ve el agente.
- **AGENTS.md**: formato Markdown abierto y neutral para instruir a agentes de código.
- **MCP (Model Context Protocol)**: estándar abierto para conectar agentes a herramientas y datos externos.
- **Skill**: capacidad empaquetada y reutilizable (carpeta con `SKILL.md`) que el agente carga según la tarea.
- **Constitución**: documento de principios no negociables que todo flujo de SDD verifica como gate.
- **Brownfield / Greenfield**: código existente y heredado vs. proyecto nuevo desde cero.
- **Gate**: punto de verificación que debe pasarse antes de avanzar de fase.

---

## Referencias

- AGENTS.md — formato abierto para agentes de código (agents.md; stewardship de la Agentic AI Foundation / Linux Foundation).
- GitHub Spec Kit — toolkit de Spec-Driven Development (github/spec-kit; documentación de quickstart y comandos).
- Anthropic — *Effective context engineering for AI agents* (anthropic.com/engineering).
- *Spec-Driven Development: From Code to Contract in the Age of AI* (arXiv, feb. 2026) y guías de Augment Code / BCMS sobre SDD.
- *Human-AI Synergy in Agentic Code Review* y *Analyzing Message-Code Inconsistency in AI Coding Agent-Authored Pull Requests* (arXiv, 2026).
- Guías de gobernanza de coding agents (Google Cloud, Apiiro, Real Python) sobre supervisión humana y revisión obligatoria.
- Packmind / Faros — buenas prácticas de context engineering y ContextOps para equipos.