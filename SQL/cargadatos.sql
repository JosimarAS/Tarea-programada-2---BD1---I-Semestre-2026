USE ControlVacacionesDB
GO

-- Script para meter los datos de prueba a la bd

DECLARE @xml XML
SET @xml = N'<Datos>
  <Puestos><Puesto Nombre="Cajero" SalarioxHora="11.00"/><Puesto Nombre="Camarero" SalarioxHora="10.00"/></Puestos>
  <TiposEvento><TipoEvento Id="1" Nombre="Login Exitoso"/><TipoEvento Id="2" Nombre="Login No Exitoso"/><TipoEvento Id="3" Nombre="Login deshabilitado"/><TipoEvento Id="4" Nombre="Logout"/></TiposEvento>
  <TiposMovimientos><TipoMovimiento Id="1" Nombre="Cumplir mes" TipoAccion="Credito"/><TipoMovimiento Id="4" Nombre="Disfrute de vacaciones" TipoAccion="Debito"/></TiposMovimientos>
  <Usuarios><usuario Id="1" Nombre="UsuarioScripts" Pass="UsuarioScripts"/><usuario Id="2" Nombre="mgarrison" Pass=")*2LnSr^lk"/></Usuarios>
  <Empleados><empleado Puesto="Cajero" ValorDocumentoIdentidad="5095109" Nombre="Christina Ward" FechaContratacion="2015-09-13"/></Empleados>
  <Error><error Codigo="50001" Descripcion="Username no existe"/><error Codigo="50008" Descripcion="Error de base de datos"/></Error>
</Datos>'

INSERT INTO dbo.Puesto (Nombre, SalarioxHora)
SELECT X.N.value('@Nombre','VARCHAR(64)'), X.N.value('@SalarioxHora','MONEY')
FROM @xml.nodes('/Datos/Puestos/Puesto') AS X(N)

INSERT INTO dbo.TipoEvento (Id, Nombre)
SELECT X.N.value('@Id','INT'), X.N.value('@Nombre','VARCHAR(64)')
FROM @xml.nodes('/Datos/TiposEvento/TipoEvento') AS X(N)

INSERT INTO dbo.TipoMovimiento (Id, Nombre, TipoAccion)
SELECT X.N.value('@Id','INT'), X.N.value('@Nombre','VARCHAR(64)'), X.N.value('@TipoAccion','VARCHAR(16)')
FROM @xml.nodes('/Datos/TiposMovimientos/TipoMovimiento') AS X(N)

INSERT INTO dbo.Usuario (Id, Username, Password)
SELECT X.N.value('@Id','INT'), X.N.value('@Nombre','VARCHAR(64)'), X.N.value('@Pass','VARCHAR(64)')
FROM @xml.nodes('/Datos/Usuarios/usuario') AS X(N)

INSERT INTO dbo.Error (Codigo, Descripcion)
SELECT X.N.value('@Codigo','INT'), X.N.value('@Descripcion','VARCHAR(256)')
FROM @xml.nodes('/Datos/Error/error') AS X(N)

INSERT INTO dbo.Empleado (IdPuesto, ValorDocumentoIdentidad, Nombre, FechaContratacion)
SELECT P.Id, X.N.value('@ValorDocumentoIdentidad','VARCHAR(32)'), X.N.value('@Nombre','VARCHAR(128)'), X.N.value('@FechaContratacion','DATE')
FROM @xml.nodes('/Datos/Empleados/empleado') AS X(N)
INNER JOIN dbo.Puesto AS P ON P.Nombre = X.N.value('@Puesto','VARCHAR(64)')
GO
