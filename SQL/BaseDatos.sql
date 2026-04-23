IF NOT EXISTS (
    SELECT D.name
    FROM sys.databases AS D
    WHERE D.name = 'ControlVacacionesDB'
)
BEGIN
    CREATE DATABASE ControlVacacionesDB
END
GO

USE ControlVacacionesDB
GO

    
-- Limpiar ya existentes

-- SPs (Faltan de hacer)
    
IF OBJECT_ID(N'dbo.sp_InsertarMovimiento', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_InsertarMovimiento
GO
IF OBJECT_ID(N'dbo.sp_ListarMovimientos', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ListarMovimientos
GO
IF OBJECT_ID(N'dbo.sp_RegistrarIntentoBorrado', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RegistrarIntentoBorrado
GO
IF OBJECT_ID(N'dbo.sp_EliminarEmpleado', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_EliminarEmpleado
GO
IF OBJECT_ID(N'dbo.sp_ActualizarEmpleado', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ActualizarEmpleado
GO
IF OBJECT_ID(N'dbo.sp_InsertarEmpleado', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_InsertarEmpleado
GO
IF OBJECT_ID(N'dbo.sp_ObtenerEmpleado', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ObtenerEmpleado
GO
IF OBJECT_ID(N'dbo.sp_ListarEmpleados', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ListarEmpleados
GO
IF OBJECT_ID(N'dbo.sp_ListarTiposMovimiento', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ListarTiposMovimiento
GO
IF OBJECT_ID(N'dbo.sp_ListarPuestos', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ListarPuestos
GO
IF OBJECT_ID(N'dbo.sp_LogoutUsuario', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_LogoutUsuario
GO
IF OBJECT_ID(N'dbo.sp_LoginUsuario', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_LoginUsuario
GO
IF OBJECT_ID(N'dbo.sp_PuedeIntentarLogin', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_PuedeIntentarLogin
GO
IF OBJECT_ID(N'dbo.sp_ObtenerError', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ObtenerError
GO

-- Tablas
    
IF OBJECT_ID(N'dbo.Movimiento', N'U') IS NOT NULL
    DROP TABLE dbo.Movimiento
GO
IF OBJECT_ID(N'dbo.BitacoraEvento', N'U') IS NOT NULL
    DROP TABLE dbo.BitacoraEvento
GO
IF OBJECT_ID(N'dbo.Empleado', N'U') IS NOT NULL
    DROP TABLE dbo.Empleado
GO
IF OBJECT_ID(N'dbo.Puesto', N'U') IS NOT NULL
    DROP TABLE dbo.Puesto
GO
IF OBJECT_ID(N'dbo.TipoMovimiento', N'U') IS NOT NULL
    DROP TABLE dbo.TipoMovimiento
GO
IF OBJECT_ID(N'dbo.TipoEvento', N'U') IS NOT NULL
    DROP TABLE dbo.TipoEvento
GO
IF OBJECT_ID(N'dbo.Usuario', N'U') IS NOT NULL
    DROP TABLE dbo.Usuario
GO
IF OBJECT_ID(N'dbo.Error', N'U') IS NOT NULL
    DROP TABLE dbo.Error
GO
IF OBJECT_ID(N'dbo.DBErrors', N'U') IS NOT NULL
    DROP TABLE dbo.DBErrors
GO


-- TABLAS
    
CREATE TABLE dbo.Puesto
(
    Id INT IDENTITY(1, 1) NOT NULL
    , Nombre VARCHAR(64) NOT NULL
    , SalarioxHora MONEY NOT NULL
    , CONSTRAINT PK_Puesto PRIMARY KEY (Id)
    , CONSTRAINT UQ_Puesto_Nombre UNIQUE (Nombre)
    , CONSTRAINT CK_Puesto_Salario CHECK (SalarioxHora >= 0)
)
GO

CREATE TABLE dbo.TipoMovimiento
(
    Id INT NOT NULL
    , Nombre VARCHAR(64) NOT NULL
    , TipoAccion VARCHAR(16) NOT NULL
    , CONSTRAINT PK_TipoMovimiento PRIMARY KEY (Id)
    , CONSTRAINT UQ_TipoMovimiento_Nombre UNIQUE (Nombre)
    , CONSTRAINT CK_TipoMovimiento_TipoAccion CHECK (TipoAccion IN ('Credito', 'Debito'))
)
GO

CREATE TABLE dbo.Usuario
(
    Id INT NOT NULL
    , Username VARCHAR(64) NOT NULL
    , Password VARCHAR(64) NOT NULL
    , CONSTRAINT PK_Usuario PRIMARY KEY (Id)
    , CONSTRAINT UQ_Usuario_Username UNIQUE (Username)
)
GO

CREATE TABLE dbo.TipoEvento
(
    Id INT NOT NULL
    , Nombre VARCHAR(64) NOT NULL
    , CONSTRAINT PK_TipoEvento PRIMARY KEY (Id)
    , CONSTRAINT UQ_TipoEvento_Nombre UNIQUE (Nombre)
)
GO

CREATE TABLE dbo.Error
(
    Id INT IDENTITY(1, 1) NOT NULL
    , Codigo INT NOT NULL
    , Descripcion VARCHAR(256) NOT NULL
    , CONSTRAINT PK_Error PRIMARY KEY (Id)
    , CONSTRAINT UQ_Error_Codigo UNIQUE (Codigo)
)
GO

CREATE TABLE dbo.Empleado
(
    Id INT IDENTITY(1, 1) NOT NULL
    , IdPuesto INT NOT NULL
    , ValorDocumentoIdentidad VARCHAR(32) NOT NULL
    , Nombre VARCHAR(128) NOT NULL
    , FechaContratacion DATE NOT NULL
    , SaldoVacaciones MONEY NOT NULL CONSTRAINT DF_Empleado_SaldoVacaciones DEFAULT (0)
    , EsActivo BIT NOT NULL CONSTRAINT DF_Empleado_EsActivo DEFAULT (1)
    , CONSTRAINT PK_Empleado PRIMARY KEY (Id)
    , CONSTRAINT FK_Empleado_Puesto FOREIGN KEY (IdPuesto) REFERENCES dbo.Puesto (Id)
    , CONSTRAINT UQ_Empleado_ValorDocumentoIdentidad UNIQUE (ValorDocumentoIdentidad)
    , CONSTRAINT UQ_Empleado_Nombre UNIQUE (Nombre)
)
GO

CREATE TABLE dbo.Movimiento
(
    Id INT IDENTITY(1, 1) NOT NULL
    , IdEmpleado INT NOT NULL
    , IdTipoMovimiento INT NOT NULL
    , Fecha DATE NOT NULL
    , Monto MONEY NOT NULL
    , NuevoSaldo MONEY NOT NULL
    , IdPostByUser INT NOT NULL
    , PostInIP VARCHAR(64) NOT NULL
    , PostTime DATETIME NOT NULL CONSTRAINT DF_Movimiento_PostTime DEFAULT (GETDATE())
    , CONSTRAINT PK_Movimiento PRIMARY KEY (Id)
    , CONSTRAINT FK_Movimiento_Empleado FOREIGN KEY (IdEmpleado) REFERENCES dbo.Empleado (Id)
    , CONSTRAINT FK_Movimiento_TipoMovimiento FOREIGN KEY (IdTipoMovimiento) REFERENCES dbo.TipoMovimiento (Id)
    , CONSTRAINT FK_Movimiento_Usuario FOREIGN KEY (IdPostByUser) REFERENCES dbo.Usuario (Id)
    , CONSTRAINT CK_Movimiento_Monto CHECK (Monto > 0)
)
GO

CREATE TABLE dbo.BitacoraEvento
(
    Id INT IDENTITY(1, 1) NOT NULL
    , IdTipoEvento INT NOT NULL
    , Descripcion VARCHAR(1000) NULL
    , IdPostByUser INT NOT NULL
    ,PostInIP VARCHAR(64) NOT NULL
    , PostTime DATETIME NOT NULL CONSTRAINT DF_BitacoraEvento_PostTime DEFAULT (GETDATE())
    , CONSTRAINT PK_BitacoraEvento PRIMARY KEY (Id)
    , CONSTRAINT FK_BitacoraEvento_TipoEvento FOREIGN KEY (IdTipoEvento) REFERENCES dbo.TipoEvento (Id)
    , CONSTRAINT FK_BitacoraEvento_Usuario FOREIGN KEY (IdPostByUser) REFERENCES dbo.Usuario (Id)
)
GO

CREATE TABLE dbo.DBErrors
(
    Id INT IDENTITY(1, 1) NOT NULL
    , UserName VARCHAR(128) NULL
    , Number INT NULL
    , State INT NULL
    , Severity INT NULL
    , [Line] INT NULL
    , [Procedure] VARCHAR(128) NULL
    , [Message] VARCHAR(4000) NULL
    , [DateTime] DATETIME NOT NULL CONSTRAINT DF_DBErrors_DateTime DEFAULT (GETDATE())
    , CONSTRAINT PK_DBErrors PRIMARY KEY (Id)
)
GO


    
-- SPs
    
CREATE PROCEDURE dbo.sp_ObtenerError
    @inCodigo INT,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        SELECT E.Codigo, E.Descripcion
        FROM dbo.Error AS E
        WHERE E.Codigo = @inCodigo

        SET @outResultCode = 0
    END TRY
    BEGIN CATCH
        INSERT INTO dbo.DBErrors (UserName, Number, State, Severity, [Line], [Procedure], [Message])
        VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE())

        SET @outResultCode = 50008
    END CATCH
END
GO

CREATE PROCEDURE dbo.sp_PuedeIntentarLogin
    @inUsername VARCHAR(64),
    @inPostInIP VARCHAR(64),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        IF EXISTS (
            SELECT B.Id
            FROM dbo.BitacoraEvento AS B
            INNER JOIN dbo.Usuario AS U ON U.Id = B.IdPostByUser
            WHERE B.IdTipoEvento = 3
              AND U.Username = LTRIM(RTRIM(ISNULL(@inUsername, '')))
              AND B.PostInIP = @inPostInIP
              AND B.PostTime >= DATEADD(MINUTE, -10, GETDATE())
        )
        BEGIN
            SET @outResultCode = 50003
            RETURN
        END

        SET @outResultCode = 0
    END TRY
    BEGIN CATCH
        INSERT INTO dbo.DBErrors (UserName, Number, State, Severity, [Line], [Procedure], [Message])
        VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE())

        SET @outResultCode = 50008
    END CATCH
END
GO

CREATE PROCEDURE dbo.sp_LoginUsuario
    @inUsername VARCHAR(64),
    @inPassword VARCHAR(64),
    @inPostInIP VARCHAR(64),
    @outIdUsuario INT OUTPUT,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @vIdUsuario INT
    DECLARE @vPassword VARCHAR(64)
    DECLARE @vIntentosPrevios INT
    DECLARE @vIntentoActual INT
    DECLARE @vCodigoError INT
    DECLARE @vDescripcion VARCHAR(1000)
    DECLARE @vUsername VARCHAR(64)

    BEGIN TRY
        SET @outIdUsuario = NULL
        SET @outResultCode = 0
        SET @vUsername = LTRIM(RTRIM(ISNULL(@inUsername, '')))

        SELECT @vIdUsuario = U.Id, @vPassword = U.Password
        FROM dbo.Usuario AS U
        WHERE U.Username = @vUsername

        IF EXISTS (
            SELECT B.Id
            FROM dbo.BitacoraEvento AS B
            WHERE B.IdTipoEvento = 3
              AND B.IdPostByUser = ISNULL(@vIdUsuario, 1)
              AND B.PostInIP = @inPostInIP
              AND B.PostTime >= DATEADD(MINUTE, -10, GETDATE())
        )
        BEGIN
            BEGIN TRANSACTION
                INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP)
                VALUES (3, 'Login deshabilitado | Username: ' + @vUsername, ISNULL(@vIdUsuario, 1), @inPostInIP)
            COMMIT TRANSACTION

            SET @outResultCode = 50003
            RETURN
        END

        SELECT @vIntentosPrevios = COUNT(B.Id)
        FROM dbo.BitacoraEvento AS B
        WHERE B.IdTipoEvento = 2
          AND B.IdPostByUser = ISNULL(@vIdUsuario, 1)
          AND B.PostInIP = @inPostInIP
          AND B.PostTime >= DATEADD(MINUTE, -20, GETDATE())

        IF (@vIntentosPrevios >= 5)
        BEGIN
            BEGIN TRANSACTION
                INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP)
                VALUES (3, 'Login deshabilitado | Username: ' + @vUsername, ISNULL(@vIdUsuario, 1), @inPostInIP)
            COMMIT TRANSACTION

            SET @outResultCode = 50003
            RETURN
        END

        IF (@vIdUsuario IS NULL)
        BEGIN
            SET @vCodigoError = 50001
            SET @vIntentoActual = @vIntentosPrevios + 1
            SET @vDescripcion = 'Intento: ' + CAST(@vIntentoActual AS VARCHAR(16))
                + ' | Codigo: ' + CAST(@vCodigoError AS VARCHAR(16))
                + ' | Username: ' + @vUsername

            BEGIN TRANSACTION
                INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP)
                VALUES (2, @vDescripcion, 1, @inPostInIP)
            COMMIT TRANSACTION

            SET @outResultCode = @vCodigoError
            RETURN
        END

        IF (@vPassword <> ISNULL(@inPassword, ''))
        BEGIN
            SET @vCodigoError = 50002
            SET @vIntentoActual = @vIntentosPrevios + 1
            SET @vDescripcion = 'Intento: ' + CAST(@vIntentoActual AS VARCHAR(16))
                + ' | Codigo: ' + CAST(@vCodigoError AS VARCHAR(16))
                + ' | Username: ' + @vUsername

            BEGIN TRANSACTION
                INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP)
                VALUES (2, @vDescripcion, @vIdUsuario, @inPostInIP)
            COMMIT TRANSACTION

            SET @outResultCode = @vCodigoError
            RETURN
        END

        BEGIN TRANSACTION
            INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP)
            VALUES (1, 'Exitoso', @vIdUsuario, @inPostInIP)
        COMMIT TRANSACTION

        SET @outIdUsuario = @vIdUsuario
        SET @outResultCode = 0
    END TRY
    BEGIN CATCH
        IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION

        INSERT INTO dbo.DBErrors (UserName, Number, State, Severity, [Line], [Procedure], [Message])
        VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE())

        SET @outResultCode = 50008
    END CATCH
END
GO

CREATE PROCEDURE dbo.sp_LogoutUsuario
    @inIdUsuario INT,
    @inPostInIP VARCHAR(64),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        IF NOT EXISTS (SELECT U.Id FROM dbo.Usuario AS U WHERE U.Id = @inIdUsuario)
        BEGIN
            SET @outResultCode = 50001
            RETURN
        END

        BEGIN TRANSACTION
            INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP)
            VALUES (4, 'Logout', @inIdUsuario, @inPostInIP)
        COMMIT TRANSACTION

        SET @outResultCode = 0
    END TRY
    BEGIN CATCH
        IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION

        INSERT INTO dbo.DBErrors (UserName, Number, State, Severity, [Line], [Procedure], [Message])
        VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE())

        SET @outResultCode = 50008
    END CATCH
END
GO



CREATE PROCEDURE dbo.sp_ListarPuestos
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(64),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        IF NOT EXISTS (SELECT U.Id FROM dbo.Usuario AS U WHERE U.Id = @inIdPostByUser)
        BEGIN
            SET @outResultCode = 50001
            RETURN
        END

        INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP)
        VALUES (11, 'Consulta catalogo: Puesto', @inIdPostByUser, @inPostInIP)

        SELECT P.Id, P.Nombre, P.SalarioxHora
        FROM dbo.Puesto AS P
        ORDER BY P.Nombre ASC

        SET @outResultCode = 0
    END TRY
    BEGIN CATCH
        INSERT INTO dbo.DBErrors (UserName, Number, State, Severity, [Line], [Procedure], [Message])
        VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE())

        SET @outResultCode = 50008
    END CATCH
END
GO


CREATE PROCEDURE dbo.sp_ListarTiposMovimiento
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(64),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        IF NOT EXISTS (SELECT U.Id FROM dbo.Usuario AS U WHERE U.Id = @inIdPostByUser)
        BEGIN
            SET @outResultCode = 50001
            RETURN
        END

        INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP)
        VALUES (11, 'Consulta catalogo: TipoMovimiento', @inIdPostByUser, @inPostInIP)

        SELECT T.Id, T.Nombre, T.TipoAccion
        FROM dbo.TipoMovimiento AS T
        ORDER BY T.Nombre ASC

        SET @outResultCode = 0
    END TRY
    BEGIN CATCH
        INSERT INTO dbo.DBErrors (UserName, Number, State, Severity, [Line], [Procedure], [Message])
        VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE())

        SET @outResultCode = 50008
    END CATCH
END
GO
    

CREATE PROCEDURE dbo.sp_ListarEmpleados
    @inFiltro VARCHAR(128),
    @inTipoFiltro VARCHAR(16),
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(64),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @vFiltro VARCHAR(128)
    DECLARE @vTipoFiltro VARCHAR(16)
    DECLARE @vDescripcion VARCHAR(1000)

    BEGIN TRY
        IF NOT EXISTS (SELECT U.Id FROM dbo.Usuario AS U WHERE U.Id = @inIdPostByUser)
        BEGIN
            SET @outResultCode = 50001
            RETURN
        END

        SET @vFiltro = LTRIM(RTRIM(ISNULL(@inFiltro, '')))
        SET @vTipoFiltro = LTRIM(RTRIM(ISNULL(@inTipoFiltro, '')))

        IF (@vTipoFiltro NOT IN ('', 'nombre', 'cedula'))
        BEGIN
            SET @outResultCode = 50008
            RETURN
        END

        IF (@vTipoFiltro = 'nombre')
        BEGIN
            SET @vDescripcion = 'Filtro nombre: ' + @vFiltro
            INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP)
            VALUES (11, @vDescripcion, @inIdPostByUser, @inPostInIP)
        END

        IF (@vTipoFiltro = 'cedula')
        BEGIN
            SET @vDescripcion = 'Filtro cedula: ' + @vFiltro
            INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP)
            VALUES (12, @vDescripcion, @inIdPostByUser, @inPostInIP)
        END

        IF (@vTipoFiltro = '')
        BEGIN
            INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP)
            VALUES (11, 'Consulta general de empleados', @inIdPostByUser, @inPostInIP)
        END

        SELECT E.Id,
               E.ValorDocumentoIdentidad,
               E.Nombre,
               E.FechaContratacion,
               E.SaldoVacaciones,
               P.Nombre AS NombrePuesto
        FROM dbo.Empleado AS E
        INNER JOIN dbo.Puesto AS P ON P.Id = E.IdPuesto
        WHERE E.EsActivo = 1
          AND (
              @vTipoFiltro = ''
              OR (@vTipoFiltro = 'nombre' AND E.Nombre LIKE '%' + @vFiltro + '%')
              OR (@vTipoFiltro = 'cedula' AND E.ValorDocumentoIdentidad LIKE '%' + @vFiltro + '%')
          )
        ORDER BY E.Nombre ASC

        SET @outResultCode = 0
    END TRY
    BEGIN CATCH
        INSERT INTO dbo.DBErrors (UserName, Number, State, Severity, [Line], [Procedure], [Message])
        VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE())

        SET @outResultCode = 50008
    END CATCH
END
GO



CREATE PROCEDURE dbo.sp_ObtenerEmpleado
    @inIdEmpleado INT,
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(64),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @vDescripcion VARCHAR(1000)
    DECLARE @vValorDocumentoIdentidad VARCHAR(32)
    DECLARE @vNombre VARCHAR(128)
    DECLARE @vNombrePuesto VARCHAR(64)
    DECLARE @vSaldoVacaciones MONEY

    BEGIN TRY
        IF NOT EXISTS (SELECT U.Id FROM dbo.Usuario AS U WHERE U.Id = @inIdPostByUser)
        BEGIN
            SET @outResultCode = 50001
            RETURN
        END

        SELECT @vValorDocumentoIdentidad = E.ValorDocumentoIdentidad,
               @vNombre = E.Nombre,
               @vNombrePuesto = P.Nombre,
               @vSaldoVacaciones = E.SaldoVacaciones
        FROM dbo.Empleado AS E
        INNER JOIN dbo.Puesto AS P ON P.Id = E.IdPuesto
        WHERE E.Id = @inIdEmpleado
          AND E.EsActivo = 1

        IF (@vValorDocumentoIdentidad IS NULL)
        BEGIN
            SET @outResultCode = 50008
            RETURN
        END

        SET @vDescripcion = 'Documento: ' + @vValorDocumentoIdentidad
            + ' | Nombre: ' + @vNombre
            + ' | Puesto: ' + @vNombrePuesto
            + ' | Saldo: ' + CONVERT(VARCHAR(32), @vSaldoVacaciones)

        INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP)
        VALUES (12, @vDescripcion, @inIdPostByUser, @inPostInIP)

        SELECT E.Id,
               E.IdPuesto,
               E.ValorDocumentoIdentidad,
               E.Nombre,
               E.FechaContratacion,
               E.SaldoVacaciones,
               E.EsActivo,
               P.Nombre AS NombrePuesto
        FROM dbo.Empleado AS E
        INNER JOIN dbo.Puesto AS P ON P.Id = E.IdPuesto
        WHERE E.Id = @inIdEmpleado
          AND E.EsActivo = 1

        SET @outResultCode = 0
    END TRY
    BEGIN CATCH
        INSERT INTO dbo.DBErrors (UserName, Number, State, Severity, [Line], [Procedure], [Message])
        VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE())

        SET @outResultCode = 50008
    END CATCH
END
GO

CREATE PROCEDURE dbo.sp_InsertarEmpleado
    @inValorDocumentoIdentidad VARCHAR(32),
    @inNombre VARCHAR(128),
    @inIdPuesto INT,
    @inFechaContratacion DATE,
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(64),
    @inPostTime DATETIME = NULL,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @vValorDocumentoIdentidad VARCHAR(32)
    DECLARE @vNombre VARCHAR(128)
    DECLARE @vNombrePuesto VARCHAR(64)
    DECLARE @vDescripcionError VARCHAR(256)
    DECLARE @vDescripcionBitacora VARCHAR(1000)
    DECLARE @vPostTime DATETIME

    BEGIN TRY
        SET @outResultCode = 0
        SET @vValorDocumentoIdentidad = LTRIM(RTRIM(ISNULL(@inValorDocumentoIdentidad, '')))
        SET @vNombre = LTRIM(RTRIM(ISNULL(@inNombre, '')))
        SET @vPostTime = ISNULL(@inPostTime, GETDATE())

        SELECT @vNombrePuesto = P.Nombre
        FROM dbo.Puesto AS P
        WHERE P.Id = @inIdPuesto

        IF (@vNombre = '' OR @vNombre LIKE '%[^A-Za-zÁÉÍÓÚáéíóúÑñÜü ]%')
            SET @outResultCode = 50009
        ELSE IF (@vValorDocumentoIdentidad = '' OR @vValorDocumentoIdentidad LIKE '%[^0-9]%')
            SET @outResultCode = 50010
        ELSE IF (@vNombrePuesto IS NULL)
            SET @outResultCode = 50008
        ELSE IF (@inFechaContratacion IS NULL)
            SET @outResultCode = 50008
        ELSE IF NOT EXISTS (SELECT U.Id FROM dbo.Usuario AS U WHERE U.Id = @inIdPostByUser)
            SET @outResultCode = 50001
        ELSE IF EXISTS (SELECT E.Id FROM dbo.Empleado AS E WHERE E.ValorDocumentoIdentidad = @vValorDocumentoIdentidad)
            SET @outResultCode = 50004
        ELSE IF EXISTS (SELECT E.Id FROM dbo.Empleado AS E WHERE E.Nombre = @vNombre)
            SET @outResultCode = 50005

        IF (@outResultCode <> 0)
        BEGIN
            SELECT @vDescripcionError = E.Descripcion FROM dbo.Error AS E WHERE E.Codigo = @outResultCode

            SET @vDescripcionBitacora = ISNULL(@vDescripcionError, '')
                + ' | Documento: ' + @vValorDocumentoIdentidad
                + ' | Nombre: ' + @vNombre
                + ' | Puesto: ' + ISNULL(@vNombrePuesto, 'Puesto no encontrado')

            IF EXISTS (SELECT U.Id FROM dbo.Usuario AS U WHERE U.Id = @inIdPostByUser)
            BEGIN
                INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
                VALUES (5, @vDescripcionBitacora, @inIdPostByUser, @inPostInIP, @vPostTime)
            END

            RETURN
        END

        SET @vDescripcionBitacora = 'Documento: ' + @vValorDocumentoIdentidad
            + ' | Nombre: ' + @vNombre
            + ' | Puesto: ' + @vNombrePuesto

        BEGIN TRANSACTION
            INSERT INTO dbo.Empleado (IdPuesto, ValorDocumentoIdentidad, Nombre, FechaContratacion)
            VALUES (@inIdPuesto, @vValorDocumentoIdentidad, @vNombre, @inFechaContratacion)

            INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
            VALUES (6, @vDescripcionBitacora, @inIdPostByUser, @inPostInIP, @vPostTime)
        COMMIT TRANSACTION

        SET @outResultCode = 0
    END TRY
    BEGIN CATCH
        IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION

        INSERT INTO dbo.DBErrors (UserName, Number, State, Severity, [Line], [Procedure], [Message])
        VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE())

        SET @outResultCode = 50008
    END CATCH
END
GO

CREATE PROCEDURE dbo.sp_ActualizarEmpleado
    @inIdEmpleado INT,
    @inValorDocumentoIdentidad VARCHAR(32),
    @inNombre VARCHAR(128),
    @inIdPuesto INT,
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(64),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @vValorDocumentoIdentidadNuevo VARCHAR(32)
    DECLARE @vNombreNuevo VARCHAR(128)
    DECLARE @vNombrePuestoNuevo VARCHAR(64)
    DECLARE @vValorDocumentoIdentidadAnterior VARCHAR(32)
    DECLARE @vNombreAnterior VARCHAR(128)
    DECLARE @vNombrePuestoAnterior VARCHAR(64)
    DECLARE @vSaldoVacaciones MONEY
    DECLARE @vDescripcionError VARCHAR(256)
    DECLARE @vDescripcionBitacora VARCHAR(1000)

    BEGIN TRY
        SET @outResultCode = 0
        SET @vValorDocumentoIdentidadNuevo = LTRIM(RTRIM(ISNULL(@inValorDocumentoIdentidad, '')))
        SET @vNombreNuevo = LTRIM(RTRIM(ISNULL(@inNombre, '')))

        SELECT @vValorDocumentoIdentidadAnterior = E.ValorDocumentoIdentidad,
               @vNombreAnterior = E.Nombre,
               @vNombrePuestoAnterior = P.Nombre,
               @vSaldoVacaciones = E.SaldoVacaciones
        FROM dbo.Empleado AS E
        INNER JOIN dbo.Puesto AS P ON P.Id = E.IdPuesto
        WHERE E.Id = @inIdEmpleado
          AND E.EsActivo = 1

        SELECT @vNombrePuestoNuevo = P.Nombre
        FROM dbo.Puesto AS P
        WHERE P.Id = @inIdPuesto

        IF (@vValorDocumentoIdentidadAnterior IS NULL)
            SET @outResultCode = 50008
        ELSE IF (@vNombreNuevo = '' OR @vNombreNuevo LIKE '%[^A-Za-zÁÉÍÓÚáéíóúÑñÜü ]%')
            SET @outResultCode = 50009
        ELSE IF (@vValorDocumentoIdentidadNuevo = '' OR @vValorDocumentoIdentidadNuevo LIKE '%[^0-9]%')
            SET @outResultCode = 50010
        ELSE IF (@vNombrePuestoNuevo IS NULL)
            SET @outResultCode = 50008
        ELSE IF NOT EXISTS (SELECT U.Id FROM dbo.Usuario AS U WHERE U.Id = @inIdPostByUser)
            SET @outResultCode = 50001
        ELSE IF EXISTS (
            SELECT E.Id
            FROM dbo.Empleado AS E
            WHERE E.ValorDocumentoIdentidad = @vValorDocumentoIdentidadNuevo
              AND E.Id <> @inIdEmpleado
        )
            SET @outResultCode = 50006
        ELSE IF EXISTS (
            SELECT E.Id
            FROM dbo.Empleado AS E
            WHERE E.Nombre = @vNombreNuevo
              AND E.Id <> @inIdEmpleado
        )
            SET @outResultCode = 50007

        IF (@outResultCode <> 0)
        BEGIN
            SELECT @vDescripcionError = E.Descripcion FROM dbo.Error AS E WHERE E.Codigo = @outResultCode

            SET @vDescripcionBitacora = ISNULL(@vDescripcionError, '')
                + ' | Documento antes: ' + ISNULL(@vValorDocumentoIdentidadAnterior, '')
                + ' | Nombre antes: ' + ISNULL(@vNombreAnterior, '')
                + ' | Puesto antes: ' + ISNULL(@vNombrePuestoAnterior, '')
                + ' | Documento despues: ' + @vValorDocumentoIdentidadNuevo
                + ' | Nombre despues: ' + @vNombreNuevo
                + ' | Puesto despues: ' + ISNULL(@vNombrePuestoNuevo, 'Puesto no encontrado')
                + ' | Saldo: ' + CONVERT(VARCHAR(32), ISNULL(@vSaldoVacaciones, 0))

            IF EXISTS (SELECT U.Id FROM dbo.Usuario AS U WHERE U.Id = @inIdPostByUser)
            BEGIN
                INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP)
                VALUES (7, @vDescripcionBitacora, @inIdPostByUser, @inPostInIP)
            END

            RETURN
        END

        SET @vDescripcionBitacora = 'Documento antes: ' + @vValorDocumentoIdentidadAnterior
            + ' | Nombre antes: ' + @vNombreAnterior
            + ' | Puesto antes: ' + @vNombrePuestoAnterior
            + ' | Documento despues: ' + @vValorDocumentoIdentidadNuevo
            + ' | Nombre despues: ' + @vNombreNuevo
            + ' | Puesto despues: ' + @vNombrePuestoNuevo
            + ' | Saldo: ' + CONVERT(VARCHAR(32), @vSaldoVacaciones)

        BEGIN TRANSACTION
            UPDATE dbo.Empleado
            SET ValorDocumentoIdentidad = @vValorDocumentoIdentidadNuevo,
                Nombre = @vNombreNuevo,
                IdPuesto = @inIdPuesto
            WHERE Id = @inIdEmpleado
              AND EsActivo = 1

            INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP)
            VALUES (8, @vDescripcionBitacora, @inIdPostByUser, @inPostInIP)
        COMMIT TRANSACTION

        SET @outResultCode = 0
    END TRY
    BEGIN CATCH
        IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION

        INSERT INTO dbo.DBErrors (UserName, Number, State, Severity, [Line], [Procedure], [Message])
        VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE())

        SET @outResultCode = 50008
    END CATCH
END
GO

CREATE PROCEDURE dbo.sp_RegistrarIntentoBorrado
    @inIdEmpleado INT,
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(64),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @vDescripcion VARCHAR(1000)
    DECLARE @vValorDocumentoIdentidad VARCHAR(32)
    DECLARE @vNombre VARCHAR(128)
    DECLARE @vNombrePuesto VARCHAR(64)
    DECLARE @vSaldoVacaciones MONEY

    BEGIN TRY
        IF NOT EXISTS (SELECT U.Id FROM dbo.Usuario AS U WHERE U.Id = @inIdPostByUser)
        BEGIN
            SET @outResultCode = 50001
            RETURN
        END

        SELECT @vValorDocumentoIdentidad = E.ValorDocumentoIdentidad,
               @vNombre = E.Nombre,
               @vNombrePuesto = P.Nombre,
               @vSaldoVacaciones = E.SaldoVacaciones
        FROM dbo.Empleado AS E
        INNER JOIN dbo.Puesto AS P ON P.Id = E.IdPuesto
        WHERE E.Id = @inIdEmpleado
          AND E.EsActivo = 1

        IF (@vValorDocumentoIdentidad IS NULL)
        BEGIN
            SET @outResultCode = 50008
            RETURN
        END

        SET @vDescripcion = 'Documento: ' + @vValorDocumentoIdentidad
            + ' | Nombre: ' + @vNombre
            + ' | Puesto: ' + @vNombrePuesto
            + ' | Saldo: ' + CONVERT(VARCHAR(32), @vSaldoVacaciones)

        BEGIN TRANSACTION
            INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP)
            VALUES (9, @vDescripcion, @inIdPostByUser, @inPostInIP)
        COMMIT TRANSACTION

        SET @outResultCode = 0
    END TRY
    BEGIN CATCH
        IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION

        INSERT INTO dbo.DBErrors (UserName, Number, State, Severity, [Line], [Procedure], [Message])
        VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE())

        SET @outResultCode = 50008
    END CATCH
END
GO

CREATE PROCEDURE dbo.sp_EliminarEmpleado
    @inIdEmpleado INT,
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(64),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @vDescripcion VARCHAR(1000)
    DECLARE @vValorDocumentoIdentidad VARCHAR(32)
    DECLARE @vNombre VARCHAR(128)
    DECLARE @vNombrePuesto VARCHAR(64)
    DECLARE @vSaldoVacaciones MONEY

    BEGIN TRY
        IF NOT EXISTS (SELECT U.Id FROM dbo.Usuario AS U WHERE U.Id = @inIdPostByUser)
        BEGIN
            SET @outResultCode = 50001
            RETURN
        END

        SELECT @vValorDocumentoIdentidad = E.ValorDocumentoIdentidad,
               @vNombre = E.Nombre,
               @vNombrePuesto = P.Nombre,
               @vSaldoVacaciones = E.SaldoVacaciones
        FROM dbo.Empleado AS E
        INNER JOIN dbo.Puesto AS P ON P.Id = E.IdPuesto
        WHERE E.Id = @inIdEmpleado
          AND E.EsActivo = 1

        IF (@vValorDocumentoIdentidad IS NULL)
        BEGIN
            SET @outResultCode = 50008
            RETURN
        END

        SET @vDescripcion = 'Documento: ' + @vValorDocumentoIdentidad
            + ' | Nombre: ' + @vNombre
            + ' | Puesto: ' + @vNombrePuesto
            + ' | Saldo: ' + CONVERT(VARCHAR(32), @vSaldoVacaciones)

        BEGIN TRANSACTION
            UPDATE dbo.Empleado
            SET EsActivo = 0
            WHERE Id = @inIdEmpleado
              AND EsActivo = 1

            INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP)
            VALUES (10, @vDescripcion, @inIdPostByUser, @inPostInIP)
        COMMIT TRANSACTION

        SET @outResultCode = 0
    END TRY
    BEGIN CATCH
        IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION

        INSERT INTO dbo.DBErrors (UserName, Number, State, Severity, [Line], [Procedure], [Message])
        VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE())

        SET @outResultCode = 50008
    END CATCH
END
GO

-- SPs de movimientos
            
CREATE PROCEDURE dbo.sp_ListarMovimientos
    @inIdEmpleado INT,
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(64),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @vDescripcion VARCHAR(1000)
    DECLARE @vValorDocumentoIdentidad VARCHAR(32)
    DECLARE @vNombre VARCHAR(128)
    DECLARE @vSaldoVacaciones MONEY

    BEGIN TRY
        IF NOT EXISTS (SELECT U.Id FROM dbo.Usuario AS U WHERE U.Id = @inIdPostByUser)
        BEGIN
            SET @outResultCode = 50001
            RETURN
        END

        SELECT @vValorDocumentoIdentidad = E.ValorDocumentoIdentidad,
               @vNombre = E.Nombre,
               @vSaldoVacaciones = E.SaldoVacaciones
        FROM dbo.Empleado AS E
        WHERE E.Id = @inIdEmpleado
          AND E.EsActivo = 1

        IF (@vValorDocumentoIdentidad IS NULL)
        BEGIN
            SET @outResultCode = 50008
            RETURN
        END

        SET @vDescripcion = 'Documento: ' + @vValorDocumentoIdentidad
            + ' | Nombre: ' + @vNombre
            + ' | Saldo actual: ' + CONVERT(VARCHAR(32), @vSaldoVacaciones)

        INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP)
        VALUES (12, @vDescripcion, @inIdPostByUser, @inPostInIP)

        SELECT E.ValorDocumentoIdentidad,
               E.Nombre AS NombreEmpleado,
               E.SaldoVacaciones,
               M.Fecha,
               T.Nombre AS NombreTipoMovimiento,
               M.Monto,
               M.NuevoSaldo,
               U.Username AS NombreUsuario,
               M.PostInIP,
               M.PostTime
        FROM dbo.Movimiento AS M
        INNER JOIN dbo.Empleado AS E ON E.Id = M.IdEmpleado
        INNER JOIN dbo.TipoMovimiento AS T ON T.Id = M.IdTipoMovimiento
        INNER JOIN dbo.Usuario AS U ON U.Id = M.IdPostByUser
        WHERE M.IdEmpleado = @inIdEmpleado
        ORDER BY M.Fecha DESC, M.PostTime DESC, M.Id DESC

        SET @outResultCode = 0
    END TRY
    BEGIN CATCH
        INSERT INTO dbo.DBErrors (UserName, Number, State, Severity, [Line], [Procedure], [Message])
        VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE())

        SET @outResultCode = 50008
    END CATCH
END
GO

CREATE PROCEDURE dbo.sp_InsertarMovimiento
    @inIdEmpleado INT,
    @inIdTipoMovimiento INT,
    @inFecha DATE,
    @inMonto MONEY,
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(64),
    @inPostTime DATETIME = NULL,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @vValorDocumentoIdentidad VARCHAR(32)
    DECLARE @vNombreEmpleado VARCHAR(128)
    DECLARE @vSaldoActual MONEY
    DECLARE @vNuevoSaldo MONEY
    DECLARE @vNombreTipoMovimiento VARCHAR(64)
    DECLARE @vTipoAccion VARCHAR(16)
    DECLARE @vDescripcionError VARCHAR(256)
    DECLARE @vDescripcionBitacora VARCHAR(1000)
    DECLARE @vPostTime DATETIME

    BEGIN TRY
        SET @outResultCode = 0
        SET @vPostTime = ISNULL(@inPostTime, GETDATE())

        SELECT @vValorDocumentoIdentidad = E.ValorDocumentoIdentidad,
               @vNombreEmpleado = E.Nombre,
               @vSaldoActual = E.SaldoVacaciones
        FROM dbo.Empleado AS E
        WHERE E.Id = @inIdEmpleado
          AND E.EsActivo = 1

        SELECT @vNombreTipoMovimiento = T.Nombre,
               @vTipoAccion = T.TipoAccion
        FROM dbo.TipoMovimiento AS T
        WHERE T.Id = @inIdTipoMovimiento

        IF NOT EXISTS (SELECT U.Id FROM dbo.Usuario AS U WHERE U.Id = @inIdPostByUser)
            SET @outResultCode = 50001
        ELSE IF (@vValorDocumentoIdentidad IS NULL)
            SET @outResultCode = 50008
        ELSE IF (@vNombreTipoMovimiento IS NULL)
            SET @outResultCode = 50008
        ELSE IF (@inFecha IS NULL)
            SET @outResultCode = 50008
        ELSE IF (@inMonto IS NULL OR @inMonto <= 0)
            SET @outResultCode = 50011
        ELSE
        BEGIN
            IF (@vTipoAccion = 'Credito')
                SET @vNuevoSaldo = @vSaldoActual + @inMonto
            ELSE
                SET @vNuevoSaldo = @vSaldoActual - @inMonto

            IF (@vNuevoSaldo < 0)
                SET @outResultCode = 50011
        END

        IF (@outResultCode <> 0)
        BEGIN
            SELECT @vDescripcionError = E.Descripcion FROM dbo.Error AS E WHERE E.Codigo = @outResultCode

            SET @vDescripcionBitacora = ISNULL(@vDescripcionError, '')
                + ' | Documento: ' + ISNULL(@vValorDocumentoIdentidad, '')
                + ' | Nombre: ' + ISNULL(@vNombreEmpleado, '')
                + ' | Saldo actual: ' + CONVERT(VARCHAR(32), ISNULL(@vSaldoActual, 0))
                + ' | Tipo movimiento: ' + ISNULL(@vNombreTipoMovimiento, '')
                + ' | Monto: ' + CONVERT(VARCHAR(32), ISNULL(@inMonto, 0))

            IF EXISTS (SELECT U.Id FROM dbo.Usuario AS U WHERE U.Id = @inIdPostByUser)
            BEGIN
                INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
                VALUES (13, @vDescripcionBitacora, @inIdPostByUser, @inPostInIP, @vPostTime)
            END

            RETURN
        END

        SET @vDescripcionBitacora = 'Documento: ' + @vValorDocumentoIdentidad
            + ' | Nombre: ' + @vNombreEmpleado
            + ' | Nuevo saldo: ' + CONVERT(VARCHAR(32), @vNuevoSaldo)
            + ' | Tipo movimiento: ' + @vNombreTipoMovimiento
            + ' | Monto: ' + CONVERT(VARCHAR(32), @inMonto)

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
                @inIdEmpleado,
                @inIdTipoMovimiento,
                @inFecha,
                @inMonto,
                @vNuevoSaldo,
                @inIdPostByUser,
                @inPostInIP,
                @vPostTime
            )

            UPDATE dbo.Empleado
            SET SaldoVacaciones = @vNuevoSaldo
            WHERE Id = @inIdEmpleado
              AND EsActivo = 1

            INSERT INTO dbo.BitacoraEvento (IdTipoEvento, Descripcion, IdPostByUser, PostInIP, PostTime)
            VALUES (14, @vDescripcionBitacora, @inIdPostByUser, @inPostInIP, @vPostTime)
        COMMIT TRANSACTION

        SET @outResultCode = 0
    END TRY
    BEGIN CATCH
        IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION

        INSERT INTO dbo.DBErrors (UserName, Number, State, Severity, [Line], [Procedure], [Message])
        VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE())

        SET @outResultCode = 50008
    END CATCH
END
GO

