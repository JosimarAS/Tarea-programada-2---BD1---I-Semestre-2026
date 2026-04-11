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
