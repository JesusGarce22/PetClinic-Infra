# Propuesta de Estrategia DevOps para Spring Petclinic Microservices en Azure

Desarrollado por:
- [David Dulce](https://github.com/arkantrust)
- [Jesús Garces](https://github.com/JesusGarce22)

## Resumen Ejecutivo

Nuestra propuesta para la implementación de Spring Petclinic Microservices en Azure se centra en una arquitectura moderna y escalable, con un enfoque en la seguridad, la calidad del código y la eficiencia operativa. Utilizamos las mejores prácticas de DevOps para minimizar la fricción en el despliegue y maximizar el valor entregado a los usuarios.

## Arquitectura y Componentes Principales

- **Microservicios**: customers-service, visits-service, vets-service y api-gateway conforman el núcleo del sistema de negocio.
- **Servicios de Soporte**: config-server y discovery-server para la configuración centralizada y el descubrimiento de servicios.
- **Base de Datos**: Azure Database for MySQL - Flexible Server con esquemas separados para vets, customers y visits services.
- **Contenedorización**: Todas las aplicaciones se despliegan como contenedores Docker.
- **Orquestación**: Azure Kubernetes Service (AKS) con Linkerd para service mesh y Knative para optimización de costos.

## Estrategia de Desarrollo y Operaciones

### Control de Versiones y Flujo de Trabajo
- **Versionamiento**: Seguimos SemVer (Semantic Versioning) para un control preciso de las versiones.
- **Estrategia de Branching**: 
  - Desarrollo: GitHub Flow para integración continua.
  - Operaciones: GitOps en un directorio dedicado del monorepo para cambios de infraestructura.

### Integración y Despliegue Continuo (CI/CD)
- **Pipelines**: Implementados en GitHub Actions para CI y CD.
- **Registro de Imágenes**: GitHub Packages para almacenamiento y gestión de imágenes Docker.

### Calidad y Seguridad
- **Análisis Estático**: SonarQube para escaneo de código antes de mergear a main.
- **Seguridad de Contenedores**: Trivy para escanear imágenes Docker antes del despliegue en AKS.
- **Cobertura de Pruebas**: Mínimo 40% de test coverage en cada servicio, verificado con JaCoCo.

### Gestión de Proyectos y Metodología
- **Metodología**: Kanban para una entrega continua y flexible.
- **Herramienta**: GitHub Projects para la gestión del backlog y la vinculación directa con el código.

## Infraestructura y Operaciones

### Infraestructura como Código (IaC)
- **Herramienta**: Terraform para definir y gestionar toda la infraestructura en Azure.
- **Gestión de Estado**: Almacenamiento del estado de Terraform en Azure Storage con bloqueo para prevenir conflictos.
- **Modularización**: Uso de módulos de Terraform para componentes reutilizables como AKS, MySQL, y redes.

### Despliegue y Escalabilidad
- **Plataforma de Contenedores**: Azure Kubernetes Service (AKS) con auto-scaling.
- **Optimización**: Knative para escalar a cero y reducir costos en períodos de baja demanda.

### Gestión de Secretos y Configuración
- **Secretos**: Azure Key Vault para almacenamiento seguro y centralizado de secretos.

### Monitoreo y Observabilidad
- **Métricas**: Prometheus para la recolección de métricas.
- **Visualización**: Grafana para dashboards y alertas.
- **Trazabilidad**: Jaeger para distributed tracing.

### Base de Datos
- **Servicio**: Azure Database for MySQL - Flexible Server.
- **Optimización**: Auto-scaling y Burstable Performance Tiers para equilibrar rendimiento y costos.
- **Estrategia de Backup**: 
  - Backups automáticos diarios gestionados por Azure.
  - Retención de backups por 7 días para optimizar costos.
  - Punto de restauración de hasta 5 minutos utilizando la funcionalidad de restauración a un punto en el tiempo.

### Documentación de API
- **Herramienta**: Swagger UI integrado en cada microservicio.
- **Generación**: Documentación de API generada automáticamente a partir de anotaciones en el código.
- **Accesibilidad**: Endpoints de Swagger UI expuestos a través del API Gateway para fácil acceso y pruebas.

### Pruebas de Resiliencia
- **Herramienta**: Azure Chaos Studio para simular fallos y probar la resiliencia del sistema.
- **Escenarios**: Implementación de experimentos de caos que simulen:
  - Fallos de nodos en AKS
  - Latencia en la red
  - Caída de servicios individuales
- **Integración**: Experimentos de caos programados regularmente como parte del pipeline de CI/CD.

## Conclusión

Nuestra solución está diseñada para proporcionar un entorno de desarrollo y operación ágil, seguro y eficiente. Al minimizar la fricción en el despliegue y adoptar prácticas modernas de DevOps, permitimos que el equipo de desarrollo se enfoque en entregar valor a los usuarios finales de manera rápida y consistente. La implementación de Terraform para IaC, Swagger UI para documentación de API, Azure Chaos Studio para pruebas de resiliencia, y una estrategia de backup robusta para la base de datos, fortalece aún más nuestra propuesta, asegurando una infraestructura reproducible, APIs bien documentadas, un sistema resistente a fallos, y datos seguros y recuperables.