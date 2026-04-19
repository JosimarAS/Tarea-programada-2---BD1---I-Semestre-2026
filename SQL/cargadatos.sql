USE ControlVacacionesDB
GO

-- Carga de los datos de prueba
-- Los catalogos se cargan directamente porque da igual la fecha
-- Empleados y movimientos se procesan uno a uno con iteración, por fecha
  
-- Catalogos
  
DECLARE @xml XML
DECLARE @vIdUsuarioScripts INT

SET @xml = N'<Datos>
	<Puestos>
		<Puesto Nombre="Cajero" SalarioxHora="11.00"/>
		<Puesto Nombre="Camarero" SalarioxHora="10.00"/>
		<Puesto Nombre="Cuidador" SalarioxHora="13.50"/>
		<Puesto Nombre="Conductor" SalarioxHora="15.00"/>
		<Puesto Nombre="Asistente" SalarioxHora="11.00"/>
		<Puesto Nombre="Recepcionista" SalarioxHora="12.00"/>
		<Puesto Nombre="Fontanero" SalarioxHora="13.00"/>
		<Puesto Nombre="Niñera" SalarioxHora="12.00"/>
		<Puesto Nombre="Conserje" SalarioxHora="11.00"/>
		<Puesto Nombre="Albañil" SalarioxHora="10.50"/>
	</Puestos>
	<TiposEvento>
		<TipoEvento Id="1" Nombre="Login Exitoso"/>
		<TipoEvento Id="2" Nombre="Login No Exitoso"/>
		<TipoEvento Id="3" Nombre="Login deshabilitado"/>
		<TipoEvento Id="4" Nombre="Logout"/>
		<TipoEvento Id="5" Nombre="Insercion no exitosa"/>
		<TipoEvento Id="6" Nombre="Insercion exitosa"/>
		<TipoEvento Id="7" Nombre="Update no exitoso"/>
		<TipoEvento Id="8" Nombre="Update exitoso"/>
		<TipoEvento Id="9" Nombre="Intento de borrado"/>
		<TipoEvento Id="10" Nombre="Borrado exitoso"/>
		<TipoEvento Id="11" Nombre="Consulta con filtro de nombre"/>
		<TipoEvento Id="12" Nombre="Consulta con filtro de cedula"/>
		<TipoEvento Id="13" Nombre="Intento de insertar movimiento"/>
		<TipoEvento Id="14" Nombre="Insertar movimiento exitoso"/>
	</TiposEvento>
	<TiposMovimientos>
		<TipoMovimiento Id="1" Nombre="Cumplir mes" TipoAccion="Credito"/>
		<TipoMovimiento Id="2" Nombre="Bono vacacional" TipoAccion="Credito"/>
		<TipoMovimiento Id="3" Nombre="Reversion Debito" TipoAccion="Credito"/>
		<TipoMovimiento Id="4" Nombre="Disfrute de vacaciones" TipoAccion="Debito"/>
		<TipoMovimiento Id="5" Nombre="Venta de vacaciones" TipoAccion="Debito"/>
		<TipoMovimiento Id="6" Nombre="Reversion de Credito" TipoAccion="Debito"/>
	</TiposMovimientos>
	<Usuarios>
		<usuario Id="1" Nombre="UsuarioScripts" Pass="UsuarioScripts"/>
		<usuario Id="2" Nombre="mgarrison" Pass=")*2LnSr^lk"/>
		<usuario Id="3" Nombre="jgonzalez" Pass="3YSI0HtiXI"/>
		<usuario Id="4" Nombre="zkelly" Pass="X4US4aLam@"/>
		<usuario Id="5" Nombre="andersondeborah" Pass="732F34xo%S"/>
		<usuario Id="6" Nombre="hardingmicheal" Pass="himB9Dzd%_"/>
		<usuario Id="7" Nombre="martinezlisa" Pass="7Kp9vQ2mT1"/>
		<usuario Id="8" Nombre="floresdaniel" Pass="H4s8Nq3xL6"/>
		<usuario Id="9" Nombre="perezmaria" Pass="R2m7Bv5cZ8"/>
		<usuario Id="10" Nombre="torresluis" Pass="J9t6Wk4pS3"/>
	</Usuarios>
	<Error>
		<error Codigo="50001" Descripcion="Username no existe"/>
		<error Codigo="50002" Descripcion="Password no existe"/>
		<error Codigo="50003" Descripcion="Login deshabilitado"/>
		<error Codigo="50004" Descripcion="Empleado con ValorDocumentoIdentidad ya existe en inserción"/>
		<error Codigo="50005" Descripcion="Empleado con mismo nombre ya existe en inserción"/>
		<error Codigo="50006" Descripcion="Empleado con ValorDocumentoIdentidad ya existe en actualizacion"/>
		<error Codigo="50007" Descripcion="Empleado con mismo nombre ya existe en actualización"/>
		<error Codigo="50008" Descripcion="Error de base de datos"/>
		<error Codigo="50009" Descripcion="Nombre de empleado no alfabético"/>
		<error Codigo="50010" Descripcion="Valor de documento de identidad no alfabético"/>
		<error Codigo="50011" Descripcion="Monto del movimiento rechazado pues si se aplicar el saldo seria negativo."/>
	</Error>
</Datos>
'

BEGIN TRY
    BEGIN TRANSACTION

        INSERT INTO dbo.Puesto (Nombre, SalarioxHora)
        SELECT X.N.value('@Nombre', 'VARCHAR(64)'),
               X.N.value('@SalarioxHora', 'MONEY')
        FROM @xml.nodes('/Datos/Puestos/Puesto') AS X(N)

        INSERT INTO dbo.TipoEvento (Id, Nombre)
        SELECT X.N.value('@Id', 'INT'),
               X.N.value('@Nombre', 'VARCHAR(64)')
        FROM @xml.nodes('/Datos/TiposEvento/TipoEvento') AS X(N)

        INSERT INTO dbo.TipoMovimiento (Id, Nombre, TipoAccion)
        SELECT X.N.value('@Id', 'INT'),
               X.N.value('@Nombre', 'VARCHAR(64)'),
               X.N.value('@TipoAccion', 'VARCHAR(16)')
        FROM @xml.nodes('/Datos/TiposMovimientos/TipoMovimiento') AS X(N)

        INSERT INTO dbo.Usuario (Id, Username, Password)
        SELECT X.N.value('@Id', 'INT'),
               X.N.value('@Nombre', 'VARCHAR(64)'),
               X.N.value('@Pass', 'VARCHAR(64)')
        FROM @xml.nodes('/Datos/Usuarios/usuario') AS X(N)

        INSERT INTO dbo.Error (Codigo, Descripcion)
        SELECT X.N.value('@Codigo', 'INT'),
               X.N.value('@Descripcion', 'VARCHAR(256)')
        FROM @xml.nodes('/Datos/Error/error') AS X(N)

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION

    INSERT INTO dbo.DBErrors (UserName, Number, State, Severity, [Line], [Procedure], [Message])
    VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE())

    RAISERROR('Error cargando catalogos desde XML.', 16, 1)
END CATCH
GO

-- Empleados (Iterativo)
  
DECLARE @xml XML

SET @xml = N'<Datos>
	<Empleados>
		<empleado Puesto="Camarero" ValorDocumentoIdentidad="6993943" Nombre="Kaitlyn Jensen" FechaContratacion="2017-12-07"/>
		<empleado Puesto="Albañil" ValorDocumentoIdentidad="1896802" Nombre="Robert Buchanan" FechaContratacion="2020-09-20"/>
		<empleado Puesto="Cajero" ValorDocumentoIdentidad="5095109" Nombre="Christina Ward" FechaContratacion="2015-09-13"/>
		<empleado Puesto="Fontanero" ValorDocumentoIdentidad="8403646" Nombre="Bradley Wright" FechaContratacion="2020-01-27"/>
		<empleado Puesto="Conserje" ValorDocumentoIdentidad="6019592" Nombre="Robert Singh" FechaContratacion="2017-02-01"/>
		<empleado Puesto="Asistente" ValorDocumentoIdentidad="4510358" Nombre="Ryan Mitchell" FechaContratacion="2018-06-08"/>
		<empleado Puesto="Asistente" ValorDocumentoIdentidad="7517662" Nombre="Candace Fox" FechaContratacion="2013-12-17"/>
		<empleado Puesto="Asistente" ValorDocumentoIdentidad="8326328" Nombre="Allison Murillo" FechaContratacion="2020-04-19"/>
		<empleado Puesto="Cuidador" ValorDocumentoIdentidad="2161775" Nombre="Jessica Murphy" FechaContratacion="2017-04-12"/>
		<empleado Puesto="Fontanero" ValorDocumentoIdentidad="2918773" Nombre="Nancy Newton PhD" FechaContratacion="2016-11-22"/>
		<empleado Puesto="Conductor" ValorDocumentoIdentidad="9772211" Nombre="Alicia Ortega" FechaContratacion="2021-05-14"/>
		<empleado Puesto="Recepcionista" ValorDocumentoIdentidad="6641189" Nombre="Pedro Salas" FechaContratacion="2019-03-21"/>
		<empleado Puesto="Niñera" ValorDocumentoIdentidad="3389054" Nombre="Sofía Herrera" FechaContratacion="2022-08-09"/>
	</Empleados>
</Datos>
'

DECLARE @EmpleadosCarga TABLE
(
    IdCarga     INT IDENTITY(1, 1),
    Puesto      VARCHAR(64),
    Documento   VARCHAR(32),
    Nombre      VARCHAR(128),
    FechaContratacion DATE,
    Procesado   BIT DEFAULT 0
)

INSERT INTO @EmpleadosCarga (Puesto, Documento, Nombre, FechaContratacion)
SELECT X.N.value('@Puesto', 'VARCHAR(64)'),
       X.N.value('@ValorDocumentoIdentidad', 'VARCHAR(32)'),
       X.N.value('@Nombre', 'VARCHAR(128)'),
       X.N.value('@FechaContratacion', 'DATE')
FROM @xml.nodes('/Datos/Empleados/empleado') AS X(N)

DECLARE @vIdCargaEmp INT
DECLARE @vPuesto     VARCHAR(64)
DECLARE @vDocEmp     VARCHAR(32)
DECLARE @vNombreEmp  VARCHAR(128)
DECLARE @vFechaContr DATE
DECLARE @vIdPuesto   INT

WHILE EXISTS (SELECT 1 FROM @EmpleadosCarga WHERE Procesado = 0)
BEGIN
    SET @vIdPuesto = NULL

    SELECT TOP 1
           @vIdCargaEmp = EC.IdCarga,
           @vPuesto     = EC.Puesto,
           @vDocEmp     = EC.Documento,
           @vNombreEmp  = EC.Nombre,
           @vFechaContr = EC.FechaContratacion
    FROM @EmpleadosCarga AS EC
    WHERE EC.Procesado = 0
    ORDER BY EC.FechaContratacion ASC, EC.IdCarga ASC

    SELECT @vIdPuesto = P.Id
    FROM dbo.Puesto AS P
    WHERE P.Nombre = @vPuesto

    IF (@vIdPuesto IS NULL)
    BEGIN
        PRINT 'Empleado no cargado: puesto no encontrado. Nombre=' + ISNULL(@vNombreEmp, '') + ' Puesto=' + ISNULL(@vPuesto, '')

        UPDATE @EmpleadosCarga
        SET Procesado = 1
        WHERE IdCarga = @vIdCargaEmp

        CONTINUE
    END

    BEGIN TRY
        BEGIN TRANSACTION

            INSERT INTO dbo.Empleado
            (
                IdPuesto,
                ValorDocumentoIdentidad,
                Nombre,
                FechaContratacion,
                SaldoVacaciones,
                EsActivo
            )
            VALUES
            (
                @vIdPuesto,
                @vDocEmp,
                @vNombreEmp,
                @vFechaContr,
                0,
                1
            )

        COMMIT TRANSACTION

        PRINT 'Empleado cargado [' + CONVERT(VARCHAR(16), @vFechaContr, 120) + ']: ' + @vNombreEmp + ' (' + @vDocEmp + ')'
    END TRY
    BEGIN CATCH
        IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION

        INSERT INTO dbo.DBErrors (UserName, Number, State, Severity, [Line], [Procedure], [Message])
        VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE())

        PRINT 'Error tecnico cargando empleado: ' + ISNULL(@vNombreEmp, '')
    END CATCH

    UPDATE @EmpleadosCarga
    SET Procesado = 1
    WHERE IdCarga = @vIdCargaEmp
END
GO

-- Movimientos (Iterativo)
  
DECLARE @xml XML
DECLARE @vIdCarga         INT
DECLARE @vDocumento       VARCHAR(32)
DECLARE @vTipoMovimiento  VARCHAR(64)
DECLARE @vFecha           DATE
DECLARE @vMonto           MONEY
DECLARE @vPostByUser      VARCHAR(64)
DECLARE @vPostInIP        VARCHAR(64)
DECLARE @vPostTime        DATETIME
DECLARE @vIdEmpleado      INT
DECLARE @vIdTipoMov       INT
DECLARE @vIdPostByUser    INT
DECLARE @vTipoAccion      VARCHAR(16)
DECLARE @vSaldoActual     MONEY
DECLARE @vNuevoSaldo      MONEY

SET @xml = N'<Datos>
	<Movimientos>
		<movimiento ValorDocId="7517662" IdTipoMovimiento="Venta de vacaciones" Fecha="2024-01-18" Monto="2" PostByUser="hardingmicheal" PostInIP="42.142.119.153" PostTime="2024-01-18 18:47:14"/>
		<movimiento ValorDocId="6993943" IdTipoMovimiento="Bono vacacional" Fecha="2024-10-31" Monto="1" PostByUser="mgarrison" PostInIP="156.92.82.57" PostTime="2024-10-31 12:43:18"/>
		<movimiento ValorDocId="8326328" IdTipoMovimiento="Venta de vacaciones" Fecha="2024-11-22" Monto="7" PostByUser="andersondeborah" PostInIP="218.213.110.232" PostTime="2024-11-22 00:23:53"/>
		<movimiento ValorDocId="4510358" IdTipoMovimiento="Reversion de Credito" Fecha="2024-07-03" Monto="3" PostByUser="hardingmicheal" PostInIP="143.42.131.166" PostTime="2024-07-03 17:07:39"/>
		<movimiento ValorDocId="8403646" IdTipoMovimiento="Reversion de Credito" Fecha="2024-12-07" Monto="8" PostByUser="zkelly" PostInIP="155.44.100.105" PostTime="2024-12-07 15:44:30"/>
		<movimiento ValorDocId="8326328" IdTipoMovimiento="Venta de vacaciones" Fecha="2024-11-26" Monto="10" PostByUser="hardingmicheal" PostInIP="141.163.255.56" PostTime="2024-11-26 09:33:41"/>
		<movimiento ValorDocId="6993943" IdTipoMovimiento="Disfrute de vacaciones" Fecha="2024-11-20" Monto="6" PostByUser="hardingmicheal" PostInIP="4.176.52.1" PostTime="2024-11-20 23:31:41"/>
		<movimiento ValorDocId="2918773" IdTipoMovimiento="Disfrute de vacaciones" Fecha="2024-10-30" Monto="10" PostByUser="zkelly" PostInIP="220.164.108.231" PostTime="2024-10-30 03:55:57"/>
		<movimiento ValorDocId="2161775" IdTipoMovimiento="Reversion Debito" Fecha="2024-06-13" Monto="2" PostByUser="hardingmicheal" PostInIP="135.223.57.22" PostTime="2024-06-13 13:28:39"/>
		<movimiento ValorDocId="8403646" IdTipoMovimiento="Bono vacacional" Fecha="2024-01-01" Monto="6" PostByUser="zkelly" PostInIP="150.250.94.62" PostTime="2024-01-01 05:17:10"/>
		<movimiento ValorDocId="2918773" IdTipoMovimiento="Venta de vacaciones" Fecha="2024-07-12" Monto="6" PostByUser="hardingmicheal" PostInIP="218.191.123.15" PostTime="2024-07-12 09:10:16"/>
		<movimiento ValorDocId="5095109" IdTipoMovimiento="Reversion de Credito" Fecha="2024-12-27" Monto="14" PostByUser="hardingmicheal" PostInIP="136.103.23.170" PostTime="2024-12-27 12:59:03"/>
		<movimiento ValorDocId="6993943" IdTipoMovimiento="Venta de vacaciones" Fecha="2024-04-08" Monto="1" PostByUser="jgonzalez" PostInIP="158.48.100.86" PostTime="2024-04-08 01:24:38"/>
		<movimiento ValorDocId="8403646" IdTipoMovimiento="Bono vacacional" Fecha="2024-08-25" Monto="8" PostByUser="jgonzalez" PostInIP="204.0.219.231" PostTime="2024-08-25 16:24:07"/>
		<movimiento ValorDocId="5095109" IdTipoMovimiento="Bono vacacional" Fecha="2024-03-07" Monto="7" PostByUser="andersondeborah" PostInIP="208.0.4.33" PostTime="2024-03-07 08:19:28"/>
		<movimiento ValorDocId="9772211" IdTipoMovimiento="Cumplir mes" Fecha="2024-02-14" Monto="4" PostByUser="martinezlisa" PostInIP="10.10.10.10" PostTime="2024-02-14 08:11:00"/>
		<movimiento ValorDocId="6641189" IdTipoMovimiento="Bono vacacional" Fecha="2024-02-28" Monto="3" PostByUser="floresdaniel" PostInIP="10.10.10.11" PostTime="2024-02-28 09:20:15"/>
		<movimiento ValorDocId="3389054" IdTipoMovimiento="Disfrute de vacaciones" Fecha="2024-03-12" Monto="5" PostByUser="perezmaria" PostInIP="10.10.10.12" PostTime="2024-03-12 14:05:45"/>
		<movimiento ValorDocId="9772211" IdTipoMovimiento="Reversion de Credito" Fecha="2024-04-03" Monto="2" PostByUser="torresluis" PostInIP="10.10.10.13" PostTime="2024-04-03 11:30:05"/>
		<movimiento ValorDocId="6641189" IdTipoMovimiento="Venta de vacaciones" Fecha="2024-04-19" Monto="1" PostByUser="mgarrison" PostInIP="172.16.0.21" PostTime="2024-04-19 16:42:31"/>
		<movimiento ValorDocId="3389054" IdTipoMovimiento="Reversion Debito" Fecha="2024-05-02" Monto="3" PostByUser="jgonzalez" PostInIP="172.16.0.22" PostTime="2024-05-02 07:18:09"/>
		<movimiento ValorDocId="5095109" IdTipoMovimiento="Cumplir mes" Fecha="2024-05-18" Monto="6" PostByUser="andersondeborah" PostInIP="172.16.0.23" PostTime="2024-05-18 18:22:40"/>
		<movimiento ValorDocId="4510358" IdTipoMovimiento="Disfrute de vacaciones" Fecha="2024-06-09" Monto="4" PostByUser="hardingmicheal" PostInIP="172.16.0.24" PostTime="2024-06-09 12:10:55"/>
		<movimiento ValorDocId="6019592" IdTipoMovimiento="Bono vacacional" Fecha="2024-06-25" Monto="2" PostByUser="martinezlisa" PostInIP="172.16.0.25" PostTime="2024-06-25 09:44:03"/>
		<movimiento ValorDocId="7517662" IdTipoMovimiento="Reversion de Credito" Fecha="2024-07-11" Monto="5" PostByUser="floresdaniel" PostInIP="172.16.0.26" PostTime="2024-07-11 13:55:27"/>
		<movimiento ValorDocId="8403646" IdTipoMovimiento="Venta de vacaciones" Fecha="2024-08-08" Monto="4" PostByUser="perezmaria" PostInIP="172.16.0.27" PostTime="2024-08-08 15:00:00"/>
		<movimiento ValorDocId="6993943" IdTipoMovimiento="Cumplir mes" Fecha="2024-09-14" Monto="7" PostByUser="torresluis" PostInIP="172.16.0.28" PostTime="2024-09-14 10:25:18"/>
		<movimiento ValorDocId="2161775" IdTipoMovimiento="Reversion Debito" Fecha="2024-10-05" Monto="1" PostByUser="zkelly" PostInIP="172.16.0.29" PostTime="2024-10-05 08:12:49"/>
		<movimiento ValorDocId="2918773" IdTipoMovimiento="Bono vacacional" Fecha="2024-11-03" Monto="2" PostByUser="martinezlisa" PostInIP="172.16.0.30" PostTime="2024-11-03 17:33:12"/>
		<movimiento ValorDocId="8326328" IdTipoMovimiento="Venta de vacaciones" Fecha="2024-12-18" Monto="8" PostByUser="floresdaniel" PostInIP="172.16.0.31" PostTime="2024-12-18 19:47:59"/>
	</Movimientos>
</Datos>
'

DECLARE @MovimientosCarga TABLE
(
    IdCarga       INT IDENTITY(1, 1),
    Documento     VARCHAR(32),
    TipoMovimiento VARCHAR(64),
    Fecha         DATE,
    Monto         MONEY,
    PostByUser    VARCHAR(64),
    PostInIP      VARCHAR(64),
    PostTime      DATETIME,
    Procesado     BIT DEFAULT 0
)

INSERT INTO @MovimientosCarga (Documento, TipoMovimiento, Fecha, Monto, PostByUser, PostInIP, PostTime)
SELECT X.N.value('@ValorDocId',         'VARCHAR(32)'),
       X.N.value('@IdTipoMovimiento',   'VARCHAR(64)'),
       X.N.value('@Fecha',              'DATE'),
       X.N.value('@Monto',             'MONEY'),
       X.N.value('@PostByUser',         'VARCHAR(64)'),
       X.N.value('@PostInIP',           'VARCHAR(64)'),
       X.N.value('@PostTime',           'DATETIME')
FROM @xml.nodes('/Datos/Movimientos/movimiento') AS X(N)

WHILE EXISTS (SELECT 1 FROM @MovimientosCarga WHERE Procesado = 0)
BEGIN
    SET @vIdEmpleado    = NULL
    SET @vIdTipoMov     = NULL
    SET @vIdPostByUser  = NULL
    SET @vTipoAccion    = NULL
    SET @vSaldoActual   = NULL
    SET @vNuevoSaldo    = NULL

    SELECT TOP 1
           @vIdCarga        = M.IdCarga,
           @vDocumento      = M.Documento,
           @vTipoMovimiento = M.TipoMovimiento,
           @vFecha          = M.Fecha,
           @vMonto          = M.Monto,
           @vPostByUser     = M.PostByUser,
           @vPostInIP       = M.PostInIP,
           @vPostTime       = M.PostTime
    FROM @MovimientosCarga AS M
    WHERE M.Procesado = 0
    ORDER BY M.Fecha ASC, M.PostTime ASC, M.IdCarga ASC

    SELECT @vIdEmpleado  = E.Id,
           @vSaldoActual = E.SaldoVacaciones
    FROM dbo.Empleado AS E
    WHERE E.ValorDocumentoIdentidad = @vDocumento

    SELECT @vIdTipoMov   = T.Id,
           @vTipoAccion  = T.TipoAccion
    FROM dbo.TipoMovimiento AS T
    WHERE T.Nombre = @vTipoMovimiento

    SELECT @vIdPostByUser = U.Id
    FROM dbo.Usuario AS U
    WHERE U.Username = @vPostByUser

    IF (@vIdEmpleado IS NULL OR @vIdTipoMov IS NULL OR @vIdPostByUser IS NULL)
    BEGIN
        PRINT 'Movimiento no cargado - referencia inexistente. Documento=' + ISNULL(@vDocumento, '') + ' Fecha=' + CONVERT(VARCHAR(16), @vFecha, 120)

        UPDATE @MovimientosCarga
        SET Procesado = 1
        WHERE IdCarga = @vIdCarga

        CONTINUE
    END

    IF (@vTipoAccion = 'Credito')
        SET @vNuevoSaldo = @vSaldoActual + @vMonto
    ELSE
        SET @vNuevoSaldo = @vSaldoActual - @vMonto

    BEGIN TRY
        BEGIN TRANSACTION

            INSERT INTO dbo.Movimiento
            (
                IdEmpleado,
                IdTipoMovimiento,
                Fecha,
                Monto,
                NuevoSaldo,
                IdPostByUser,
                PostInIP,
                PostTime
            )
            VALUES
            (
                @vIdEmpleado,
                @vIdTipoMov,
                @vFecha,
                @vMonto,
                @vNuevoSaldo,
                @vIdPostByUser,
                @vPostInIP,
                @vPostTime
            )

            UPDATE dbo.Empleado
            SET SaldoVacaciones = @vNuevoSaldo
            WHERE Id = @vIdEmpleado

        COMMIT TRANSACTION

        PRINT 'Movimiento cargado [' + CONVERT(VARCHAR(16), @vFecha, 120) + ']: Doc=' + @vDocumento + ' Tipo=' + @vTipoMovimiento + ' Monto=' + CONVERT(VARCHAR(12), @vMonto) + ' NuevoSaldo=' + CONVERT(VARCHAR(12), @vNuevoSaldo)
    END TRY
    BEGIN CATCH
        IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION

        INSERT INTO dbo.DBErrors (UserName, Number, State, Severity, [Line], [Procedure], [Message])
        VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE())

        PRINT 'Error tecnico cargando movimiento. Documento=' + ISNULL(@vDocumento, '') + ' Fecha=' + CONVERT(VARCHAR(16), @vFecha, 120)
    END CATCH

    UPDATE @MovimientosCarga
    SET Procesado = 1
    WHERE IdCarga = @vIdCarga
END
GO

SELECT 'Carga terminada' AS Mensaje
SELECT COUNT(*) AS CantidadPuestos      FROM dbo.Puesto
SELECT COUNT(*) AS CantidadUsuarios     FROM dbo.Usuario
SELECT COUNT(*) AS CantidadEmpleados    FROM dbo.Empleado
SELECT COUNT(*) AS CantidadMovimientos  FROM dbo.Movimiento
SELECT COUNT(*) AS CantidadBitacora     FROM dbo.BitacoraEvento
SELECT COUNT(*) AS CantidadErroresBD   FROM dbo.DBErrors
GO

