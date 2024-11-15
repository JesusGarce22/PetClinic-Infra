# Infraestructura en Azure para Despliegue con Terraform

### Descripción General
La infraestructura definida utiliza **Terraform** para desplegar y configurar recursos en **Microsoft Azure**. Esta infraestructura incluye:
- Un grupo de recursos para organizar los servicios.
- Un clúster de Kubernetes (AKS) para la ejecución de contenedores.
- Un Registro de Contenedores de Azure (ACR) para almacenar y gestionar imágenes de Docker.
- Un Azure Key Vault para almacenar secretos de forma segura.

## Componentes de la Infraestructura

### 1. Grupo de Recursos (Resource Group)
Este es el contenedor en Azure que agrupa todos los recursos necesarios para la aplicación. Define una ubicación (East US) para los recursos, facilitando su organización y administración conjunta.

```hcl
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}
```
### 2. Clúster de Kubernetes (AKS)

El servicio de Kubernetes gestionado de Azure, AKS, permite la ejecución, administración y escalado de los servicios en contenedores. La configuración del clúster especifica:

* **Node Pool:** Define el número y tipo de nodos virtuales para ejecutar los contenedores.
* **Red:** Utiliza el complemento de red de Azure y un balanceador de carga de SKU estándar.
* **Identidad:** Usa una identidad asignada por el sistema para gestionar el acceso a otros recursos de Azure.
```
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  tags = {
    environment = "Production"
  }
}
```
### 3. Registro de Contenedores (ACR)

El **Azure Container Registry (ACR)** almacena y gestiona imágenes de contenedores. ACR permite a AKS acceder de forma segura a las imágenes sin necesidad de autenticación adicional. Se asigna el rol AcrPull al AKS para otorgarle permisos de lectura.
```
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_role_assignment" "aks_acr_role_assignment" {
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}
```

### 4. Azure Key Vault

Azure Key Vault permite almacenar y gestionar secretos de manera segura. En este caso, se usa para guardar credenciales y otros datos sensibles, como claves de acceso o tokens. Un política de acceso específica permite que ciertos usuarios o servicios accedan a los secretos necesarios.
```
resource "azurerm_key_vault" "key_vault" {
  name                     = var.key_vault_name
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  tenant_id                = var.tenant_id
  sku_name                 = "standard"
  purge_protection_enabled = true

  access_policy {
    tenant_id = var.tenant_id
    object_id = "7c8ab49a-20e5-46a5-a434-3ad3ec71335c"
    secret_permissions = ["Get", "List"]
  }

  tags = {
    environment = "Dev"
  }

  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
}
```

# Pipelines CI/CD con github actions

Se crearon 2 pipelines para la integracion y despliegue continuo. 

### [Terraform deploy](/.github/workflows/terraform-deploy.yml)

### 1. **Activadores del Pipeline**
El pipeline se ejecuta bajo las siguientes condiciones:
- **Push a la rama `main`**: El pipeline se activa cuando hay un `push` a la rama `main` del repositorio.
- **Pull Request a la rama `main`**: También se ejecuta cuando se realiza un `pull request` a la rama `main`.
  
Además, el pipeline solo se ejecuta si hay cambios en el archivo `main.tf`, el cual contiene la configuración de infraestructura en Terraform.

### 2. **Variables de Entorno**
El pipeline utiliza varias variables de entorno que se pasan de forma segura a través de los **Secrets de GitHub**, las cuales incluyen:
- **ARM_CLIENT_ID**: El ID del cliente de la aplicación de Azure (Servicio Principal).
- **ARM_CLIENT_SECRET**: La clave secreta del cliente de Azure.
- **ARM_SUBSCRIPTION_ID**: El ID de la suscripción de Azure.
- **ARM_TENANT_ID**: El ID del inquilino de Azure (Tenant ID).
- **RESOURCE_GROUP**: El nombre del grupo de recursos de Azure donde se desplegarán los recursos.
- **AKS_CLUSTER_NAME**: El nombre del clúster de Kubernetes en Azure (AKS).

### 3. **Etapas del Pipeline**

#### 3.1 **Checkout del Código**
El primer paso es realizar un `checkout` del código del repositorio utilizando la acción `actions/checkout@v3`. Esto asegura que el pipeline utilice la versión más reciente del código.

#### 3.2 **Configuración de Terraform**
A continuación, se configura **Terraform** utilizando la acción `hashicorp/setup-terraform@v2`. Esta acción prepara el entorno para ejecutar los comandos de Terraform en la máquina virtual del runner de GitHub Actions.

#### 3.3 **Inicialización de Terraform**
En esta etapa, se ejecuta `terraform init` para inicializar Terraform en el directorio actual. Esto descarga los proveedores necesarios y configura el entorno de trabajo de Terraform.

#### 3.4 **Importación de Recursos Existentes**
Esta etapa importa recursos ya existentes en la infraestructura de Azure para que Terraform los gestione. Se importan los siguientes recursos:
- **Grupo de recursos de Azure**: Importa el recurso del grupo de recursos de Azure.
- **Azure Container Registry (ACR)**: Importa el registro de contenedores de Azure donde se almacenan las imágenes Docker.
- **Azure Key Vault**: Importa el almacén de secretos de Azure.
- **Azure Kubernetes Service (AKS)**: Importa el clúster de Kubernetes gestionado en Azure (AKS).

El script utiliza un bucle para importar estos recursos con el comando `terraform import`. Si un recurso ya está gestionado por Terraform, se omite sin generar errores.

#### 3.5 **Validación de Terraform**
Se ejecuta `terraform validate` para comprobar que la configuración de Terraform es válida y que no hay errores en la definición de los recursos.

#### 3.6 **Planificación de Terraform**
En esta etapa, se ejecuta `terraform plan` para generar un plan de ejecución que muestra qué cambios se realizarán en la infraestructura. Este plan se guarda en el archivo `tfplan` y se pasa como entrada al siguiente paso. Además, se pasan las variables `tenant_id` y `subscription_id` a través de parámetros.

#### 3.7 **Aplicación del Plan de Terraform**
Finalmente, se ejecuta `terraform apply -auto-approve tfplan` para aplicar el plan de ejecución previamente generado, lo que implementa los cambios en la infraestructura de Azure. La opción `-auto-approve` asegura que el plan se aplique sin pedir confirmación.

### [AKS deploy](/.github/workflows/deploy-aks.yml)

### 1. **Activadores del Pipeline**
El pipeline se ejecuta cuando:
- Se realiza un **push a la rama `main`** del repositorio.
- Los cambios están contenidos dentro del directorio `aks-files/**`, donde se encuentran los manifiestos de Kubernetes que serán desplegados en el clúster de AKS.

### 2. **Variables de Entorno**
El pipeline utiliza las siguientes variables de entorno que se gestionan a través de los **Secrets de GitHub**:
- **AZURE_CLIENT_ID**: El ID de cliente del servicio principal de Azure.
- **AZURE_CLIENT_SECRET**: La clave secreta del servicio principal de Azure.
- **AZURE_TENANT_ID**: El ID del inquilino (tenant) de Azure.
- **AZURE_SUBSCRIPTION_ID**: El ID de la suscripción de Azure.
- **RESOURCE_GROUP**: El nombre del grupo de recursos en Azure donde reside el clúster de AKS.
- **AKS_CLUSTER_NAME**: El nombre del clúster de AKS al que se va a acceder y desplegar la aplicación.

### 3. **Etapas del Pipeline**

#### 3.1 **Checkout del Código**
El primer paso del pipeline es hacer un `checkout` del código desde el repositorio utilizando la acción `actions/checkout@v3`. Esto asegura que el pipeline trabaje con la versión más reciente del código y los manifiestos de Kubernetes.

#### 3.2 **Configuración de Variables de Azure**
Las variables de Azure, como el `client_id`, `client_secret`, `tenant_id`, `subscription_id`, `resource_group` y `aks_cluster_name`, se configuran y se agregan al entorno de ejecución de GitHub Actions a través de comandos `echo`. Estas variables son esenciales para interactuar con los servicios de Azure en los siguientes pasos del pipeline.

#### 3.3 **Autenticación con Azure CLI**
En este paso, se utiliza el **Azure CLI** para iniciar sesión en Azure con las credenciales proporcionadas por el servicio principal. Se emplea el comando `az login` con el ID del cliente y el secreto del cliente, y luego se establece la suscripción de Azure a la que se va a trabajar con `az account set`.

#### 3.4 **Obtención de Credenciales de AKS**
Este paso permite obtener las credenciales del clúster de AKS, necesarias para que `kubectl` (la herramienta de línea de comandos de Kubernetes) interactúe con el clúster. Se usa el comando `az aks get-credentials`, pasando el grupo de recursos y el nombre del clúster.

#### 3.5 **Instalación de kubectl**
Se instala `kubectl` en el entorno de ejecución para que pueda ser utilizado en los siguientes pasos del pipeline. `kubectl` es la herramienta de línea de comandos que permite interactuar con un clúster de Kubernetes.

#### 3.6 **Eliminación de Deployments Existentes**
Antes de aplicar los nuevos manifiestos, se eliminan todas las implementaciones existentes en el clúster de AKS mediante el comando `kubectl delete deployments --all`. Esto garantiza que los despliegues anteriores sean removidos antes de aplicar las nuevas configuraciones.

#### 3.7 **Aplicación de los Manifiestos de Kubernetes**
Finalmente, se aplican los manifiestos de Kubernetes que se encuentran en el directorio `./aks-files/` mediante el comando `kubectl apply -f ./aks-files`. Este paso crea o actualiza los recursos de Kubernetes (como `Deployments`, `Services`) en el clúster de AKS.

# Configuración del Backend Remoto en Terraform

Esta seccion describe los pasos generales para configurar un backend remoto en Terraform utilizando Azure Storage. Esta configuración centraliza el almacenamiento del archivo de estado de Terraform (`terraform.tfstate`), lo que facilita la colaboración y garantiza la consistencia en la gestión de la infraestructura.

## Proceso General

1. **Creación de Recursos en Azure**: 
   Se utilizó Azure como backend para almacenar el archivo de estado. Para ello, se crearon:
   - Un grupo de recursos que aloja todos los recursos necesarios para el backend.
   - Una cuenta de almacenamiento de Azure, que es donde se almacena el archivo de estado.
   - Un contenedor dentro de la cuenta de almacenamiento, que organiza y almacena el archivo de estado.

2. **Configuración del Backend en Terraform**:
   Una vez creados los recursos, configuramos el backend en Terraform para que el archivo de estado se almacene en el contenedor de almacenamiento. Esto permite que el archivo de estado se comparta y mantenga actualizado de forma centralizada, eliminando conflictos entre los miembros del equipo.

3. **Ejecución de Comandos de Inicialización y Aplicación**:
   Para activar la configuración, ejecutamos `terraform init` y `terraform apply`, asegurándonos de que Terraform use el backend remoto para almacenar el estado.

4. **Solución de Problemas Comunes**:
   Durante la configuración, se encontraron advertencias relacionadas con versiones de proveedores y permisos de registro automático. Solucionamos esto utilizando una opción en el proveedor de Azure para omitir el registro automático de recursos, lo cual evitó problemas de permisos.