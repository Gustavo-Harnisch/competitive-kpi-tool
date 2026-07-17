# Solicitud maestra de transformación de repositorio

Actúa como arquitecto de software senior, ingeniero de automatización, mantenedor open source, consultor de GitHub Projects y especialista en **Herramienta KPI para programacion competitiva**.

## Datos

- Tema: Herramienta KPI para programacion competitiva
- Objetivo: crear una aplicacion para registar, y recordar al usuario que vuelva a ejercitarce para realizar x cantidad de ejercic diarios con la intencion de que siempre realize x cantidad de ejercicios para subir de elo en icpc tiene que ser una app que se conecte bien a otras erramientas, eso si que cumpla como la idea de gnu linux hcaerlo una vez y hacerlo bienn
- Tecnologías: object pascal lazarus, slq lite csv / excel la intencion es usar algo con base de datos o hojas de calculo para demostrar a los reclutadores seguridad de lo que hago
- Repositorio actual: competitive-kpi-tool
- Usuario GitHub: Gustavo-Harnisch
- Repositorio esperado: Gustavo-Harnisch/competitive-kpi-tool
- Público: estudiantes y reclutadores
- Nivel técnico: profesional y educativo
- Plataformas: multiplataforma, por eso escogi lazarus, quiero que sea ejeutable en macos, windows y linux pero solo pc no en celulares solo pc
- Restricciones: no tengo avanze en este trabajo
- Referencias: Sin documentos adicionales
- Roadmap: 24
- Horas semanales: 4
- Nivel del propietario: basico
- Objetivo profesional: portfolio demostrable ademas de buen manego de base de datos para demostrar a empresas ademas de funcionar local 100% admeas de que se pueda genera un sql o un csv con la intencion de manejar los datos bien y dar seguridad de que se sabe manejar con seguridad y experiencia el las herraminetas
- Prioridad técnica: mantenciony demostrar rubustes y buenas practicas degando limpio el camino para que otros desarrolladores puedan escalar con el proyecto
- Dependencias: preferir bibiotecas estandar y bajo uso de dependencias para evitar errores por compatibilidad
- Licencia: MIT
- Idioma del código: INGLES
- Idioma de documentación: INGLES

## Contrato de trabajo

Inspecciona realmente el ZIP adjunto. No inventes archivos ni resultados. Distingue entre hechos observados, errores confirmados, riesgos, recomendaciones y decisiones propuestas.

### 1. Diagnóstico

Analiza estructura, código, archivos vacíos, duplicación, errores lógicos o matemáticos, compilación, dependencias, documentación, pruebas, seguridad, memoria, portabilidad, precisión numérica y deuda técnica.

Entrega una tabla con componente, estado, problema, severidad, consecuencia y acción. Usa Critical, High, Medium, Low e Informational.

### 2. Definición del proyecto

Propón de tres a cinco nombres, selecciona uno y crea descripción corta de GitHub, descripción técnica, alcance, fuera de alcance, usuarios, casos de uso, propuesta de valor, topics, licencia, versionado y releases.

### 3. Arquitectura

Diseña módulos, capas, API pública y privada, estructuras de datos, manejo de errores y memoria, logging, configuración, pruebas, documentación, benchmarking, seguridad y extensibilidad.

Para cada módulo especifica responsabilidad, archivos, funciones, dependencias, errores y pruebas. Cuando corresponda, documenta precondiciones, postcondiciones, invariantes, complejidad, estabilidad numérica y tolerancias.

### 4. Estructura objetivo

Propón el árbol completo del repositorio y un plan de migración incremental que preserve el código existente y cree copias de seguridad.

### 5. Roadmap

Crea fases, epics, milestones, Issues, subtareas, dependencias, riesgos y entregables desde el estado actual hasta v1.0.

Cada Issue debe incluir identificador, título, objetivo, contexto, tareas, criterios de aceptación, archivos afectados, dependencias, riesgos, pruebas, documentación, estimación, prioridad, milestone, labels, fecha inicial y fecha objetivo.

Incluye Foundation, Architecture, Core implementation, Testing, Documentation, Examples, Performance, Security, CI y Release preparation.

### 6. GitHub Projects

Diseña campos Status, Priority, Phase, Module, Work type, Track, Complexity, Estimate, Start date, Target date, Risk y Version. Diseña vistas Master Table, Development Board, Roadmap, Current Sprint, Critical Work, Testing, Documentation, Applications y Release 1.0.

### 7. Automatización ejecutable

Genera un ZIP con:

```text
automation-package/
├── README.md
├── setup_project.sh
├── scripts/sync_project.py
├── planning/project.json
└── .github/workflows/sync-project.yml
```

`project.json` será la fuente de verdad. El script debe comprobar GitHub CLI y autenticación, solicitar scope `project`, crear o reutilizar Project, repositorio, labels, milestones, campos e Issues, añadir Issues al Project y asignar campos.

Debe ser idempotente, admitir `--dry-run`, `--limit` y reanudación, detectar duplicados y detenerse claramente ante errores.

Requisitos técnicos obligatorios:

- usar `--method GET` en consultas `gh api` con parámetros cuando corresponda;
- reconocer tipos GraphQL como `ProjectV2SingleSelectField`;
- usar `--single-select-option-id` para single select;
- usar `--date`, `--number` y `--text` según el tipo;
- validar JSON y Python;
- no usar pseudocódigo en archivos finales.

### 8. GitHub Actions

Crea workflow con `workflow_dispatch`, activación por cambios en `planning/project.json`, secreto `PROJECTS_TOKEN`, permisos mínimos y protección contra ejecuciones duplicadas.

### 9. Validación

Valida sintaxis, permisos, rutas, referencias, fechas, duplicados, comandos GitHub CLI e idempotencia. Ejecuta o simula `--dry-run --limit 5`. Explica honestamente qué no pudo probarse sin autenticación.

### 10. Entrega

Entrega resumen ejecutivo, diagnóstico, problemas críticos, arquitectura, árbol, roadmap, diseño del Project, cantidades de epics/milestones/Issues, instalación, ejecución, riesgos, limitaciones y ZIP descargable.

No copies extensamente material protegido. No sustituyas la automatización por instrucciones manuales. Comienza inspeccionando el ZIP adjunto.
