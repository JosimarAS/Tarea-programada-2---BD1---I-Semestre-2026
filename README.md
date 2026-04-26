# Control-de-vacaciones---BD1---I-Semestre-2026

Proyecto web para conectar una base de datos de SQL Server a una aplicación en Node.js con funcionalidades para login, consulta de empleados, CRUD de empleados y movimientos de vacaciones.



# Manual de ejecución:


Descargar los documentos del git

Descargar y conectar a SQLServer

Conectar en SQLServer Management Studio a localhost

Abrir el archivo BaseDatos.sql como nuevo query y ejecutar la consulta

Luego abrir el archivo cargadatos.sql como nuevo query y ejecutar la consulta para cargar los datos de prueba



----------------------------------------------------------------------------------------------------------------------------------

# Para las credenciales de la base de datos

En este proyecto las credenciales necesarias para que la API se conecte a la BD ya se crean al final del archivo BaseDatos.sql.

El usuario que utiliza el servidor Node es:

-Usuario: developer_tarea2
-Contraseña: Tarea2_2026!
-Base de datos: ControlVacacionesDB
-Servidor: localhost



----------------------------------------------------------------------------------------------------------------------------------


# Malabares en el SQL Server Configuration Manager y Servicios de Windows:

Como Windows es bastante prohibitivo, hay que tocar algunas cosillas del sistema.

Lo primero es ir a Servicios (el programa de sistema de servicios de Windows), buscar SQL Server Browser --> click derecho --> propiedades, y en "Tipo de inicio" hay que ponerle "Manual" --> "Aplicar" y "Aceptar", y luego nuevamente click derecho --> iniciar

Luego, hay que abrir el SQL Server Configuration Manager, y en SQL Server Network Configuration --> Protocols for MSSQLSERVER --> Click derecho y enable a "Named Pipes" y a "TCP/IP"

Por último, en ese mismo sitio (SQL Server Configuration Manager) entrar a SQL Server Services y darle click derecho y restart a "SQL Server (MSSQLSERVER)"

Listo, con eso en teoría debería de estar correcto



-------------------------------------------------------------------------------------------------------------------------------------


# Ejecutar esto en la consola del proyecto:

Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

npm init -y

npm install express cors mssql

node server.js

Entras a http://localhost:3000, y con eso debería de haber conectado correctamente a la BD



----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------


# Sobre el funcionamiento del proyecto

El proyecto tiene un servidor en Node.js usando Express, cors y mssql.

El archivo server.js es el encargado de levantar la API y conectarse a SQL Server.

El archivo public/index.html es la interfaz web del proyecto.

Desde la página web se puede iniciar sesión, consultar empleados, filtrar empleados, insertar empleados, editar empleados, eliminar empleados y registrar movimientos de vacaciones.

El proyecto utiliza procedimientos almacenados en SQL Server para realizar las operaciones importantes.



----------------------------------------------------------------------------------------------------------------------------------------


# Sobre los archivos SQL

El archivo BaseDatos.sql crea la base de datos ControlVacacionesDB, las tablas, restricciones, procedimientos almacenados y el usuario que utiliza la aplicación para conectarse.

El archivo cargadatos.sql carga los datos iniciales del proyecto, usando el archivo datos/datosCarga.xml.


----------------------------------------------------------------------------------------------------------------------------------------


# Credenciales de prueba para entrar al sistema

Para entrar a la página se puede usar cualquier usuario cargado en los datos de prueba, por ejemplo:

-Usuario: mgarrison

-Contraseña: )*2LnSr^lk



----------------------------------------------------------------------------------------------------------------------------------------


# Sobre conectar a más personas a la BD

Hay que seguir ese mismo procedimiento para quien vaya a hostear la BD y el servidor. Luego, se debe instalar una VPN virtual para conectar ambas personas a la misma "red".

Podríamos recomendar ZeroTier. Una persona crea la red, pasa el ID de la red a la otra persona, y luego aprueba la conexión desde la página de ZeroTier.

Después de eso, la persona que hostea el proyecto corre SQL Server y también corre el servidor desde consola con:

node server.js

La otra persona puede entrar usando la IP que da ZeroTier, usando el puerto 3000.

Por ejemplo:

http://(IP DE ZEROTIER):3000

Si por algún motivo da algún error, bastaría con tocar los Servicios de Windows y/o el SQL Server Configuration Manager en ese otro dispositivo también.

También hay que revisar que el firewall de Windows no esté bloqueando el puerto 3000 ni la conexión con SQL Server.

Para poder iniciar sesión dentro de la página debe tener credenciales válidas de acceso. La página se bloqueará si se intenta muchas veces el acceso fallido, así que cuidado al probar.
