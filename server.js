const express = require('express');
const sql = require('mssql');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

const dbConfig = {
    server: process.env.DB_SERVER || 'localhost',
    database: process.env.DB_DATABASE || 'ControlVacacionesDB',
    user: process.env.DB_USER || 'developer_tarea2',
    password: process.env.DB_PASSWORD || 'Tarea2_2026!',
    options: { 
      trustServerCertificate: true, 
      encrypt: false 
    }
};

let pool = null;

async function getPool() {
    if (!pool) {
        pool = await sql.connect(dbConfig);
    }

    return pool;
}


function obtenerIP(req) {
    const forwarded = req.headers['x-forwarded-for'];

    if (forwarded) {
        return forwarded.split(',')[0].trim();
    }

    return (req.socket.remoteAddress || '127.0.0.1').replace('::ffff:', '');
}

function leerIdUsuario(req) {
    const id = req.body.idUsuario || req.query.idUsuario;
    return Number(id);
}

function detectarTipoFiltro(filtro) {
    const valor = String(filtro || '').trim();

    if (valor === '') {
        return '';
    }

    if (/^[A-Za-zÁÉÍÓÚáéíóúÑñÜü ]+$/.test(valor)) {
        return 'nombre';
    }

    if (/^[0-9]+$/.test(valor)) {
        return 'cedula';
    }

    return 'invalido';
}

function validarUsuario(req, res) {
    const idUsuario = leerIdUsuario(req);

    if (!idUsuario || Number.isNaN(idUsuario)) {
        res.status(401).json({
            ok: false,
            mensaje: 'Debe iniciar sesión antes de realizar esta operación.'
        });
        return null;
    }

    return idUsuario;
}

async function obtenerDescripcionError(codigo) {
    if (!codigo || codigo === 0) {
        return '';
    }

    const fallback = {
        50001: 'Username no existe',
        50002: 'Password no existe',
        50003: 'Login deshabilitado',
        50004: 'Empleado con ValorDocumentoIdentidad ya existe en inserción',
        50005: 'Empleado con mismo nombre ya existe en inserción',
        50006: 'Empleado con ValorDocumentoIdentidad ya existe en actualizacion',
        50007: 'Empleado con mismo nombre ya existe en actualización',
        50008: 'Error de base de datos',
        50009: 'Nombre de empleado no alfabético',
        50010: 'Valor de documento de identidad no alfabético',
        50011: 'Monto del movimiento rechazado pues si se aplicar el saldo seria negativo.',
    };

    try {
        const pool = await getPool();
        const result = await pool.request()
            .input('inCodigo', sql.Int, codigo)
            .output('outResultCode', sql.Int)
            .execute('dbo.sp_ObtenerError');

        if (result.recordset && result.recordset.length > 0) {
            return result.recordset[0].Descripcion;
        }
    } catch (error) {
        return fallback[codigo] || 'Error desconocido.';
    }

    return fallback[codigo] || 'Error desconocido.';
}

async function responderConCodigo(res, codigo, mensajeExito, datos) {
    if (codigo === 0) {
        res.json({
            ok: true,
            mensaje: mensajeExito,
            ...datos
        });
        return;
    }

    const mensaje = await obtenerDescripcionError(codigo);
    const status = codigo === 50003 ? 423 : (codigo === 50008 ? 500 : 400);

    res.status(status).json({
        ok: false,
        codigo,
        mensaje
    });
}

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

app.get('/api/auth/estado-login', async (req, res) => {
    const username = String(req.query.username || '').trim();

    if (username === '') {
        return res.json({ ok: true, loginHabilitado: true });
    }

    try {
        const pool = await getPool();
        const result = await pool.request()
            .input('inUsername', sql.VarChar(64), username)
            .input('inPostInIP', sql.VarChar(64), obtenerIP(req))
            .output('outResultCode', sql.Int)
            .execute('dbo.sp_PuedeIntentarLogin');

        const codigo = result.output.outResultCode;

        if (codigo === 0) {
            return res.json({ ok: true, loginHabilitado: true });
        }

        const mensaje = await obtenerDescripcionError(codigo);
        return res.status(423).json({
            ok: false,
            loginHabilitado: false,
            codigo,
            mensaje: codigo === 50003
                ? 'Demasiados intentos de login, intente de nuevo dentro de 10 minutos.'
                : mensaje
        });
    } catch (error) {
        res.status(500).json({ ok: false, mensaje: 'Error al consultar estado de login.' });
    }
});


app.post('/api/auth/login', async (req, res) => {
  const { username, password } = req.body;

    if (!username || !password) {
        return res.status(400).json({
            ok: false,
            mensaje: 'Debe digitar usuario y contraseña.'
        });
    }

    try {
        const pool = await getPool();
        const result = await pool.request()
          .input('inUsername', sql.VarChar(64), username)
          .input('inPassword', sql.VarChar(64), password)
          .input('inPostInIP', sql.VarChar(64), obtenerIP(req))
          .output('outIdUsuario', sql.Int)
          .output('outResultCode', sql.Int)
          .execute('dbo.sp_LoginUsuario');

        const codigo = result.output.outResultCode;

        if (codigo === 0) {
            return res.json({
                ok: true,
                mensaje: 'Login exitoso.',
                usuario: {
                    id: result.output.outIdUsuario,
                    username
                }
            });
        }

        const mensaje = await obtenerDescripcionError(codigo);
        const status = codigo === 50003 ? 423 : 401;

        res.status(status).json({
            ok: false,
            codigo,
            mensaje: codigo === 50003
                ? 'Demasiados intentos de login, intente de nuevo dentro de 10 minutos.'
                : mensaje
        });
    } catch (error) {
        res.status(500).json({ ok: false, mensaje: 'Error al conectar con SQL Server.' });
    }
});

app.post('/api/auth/logout', async (req, res) => {
    const idUsuario = validarUsuario(req, res);

    if (!idUsuario) {
        return;
    }

    try {
        const pool = await getPool();
        const result = await pool.request()
            .input('inIdUsuario', sql.Int, idUsuario)
            .input('inPostInIP', sql.VarChar(64), obtenerIP(req))
            .output('outResultCode', sql.Int)
            .execute('dbo.sp_LogoutUsuario');

        await responderConCodigo(res, result.output.outResultCode, 'Logout registrado.', {});
    } catch (error) {
        res.status(500).json({ ok: false, mensaje: 'Error al registrar logout.' });
    }
});

app.get('/api/puestos', async (req, res) => {
    const idUsuario = validarUsuario(req, res);

    if (!idUsuario) {
        return;
    }

    try {
        const pool = await getPool();
        const result = await pool.request()
          .input('inIdPostByUser', sql.Int, idUsuario)
          .input('inPostInIP', sql.VarChar(64), obtenerIP(req))
          .output('outResultCode', sql.Int)
          .execute('dbo.sp_ListarPuestos');

        await responderConCodigo(res, result.output.outResultCode, 'Puestos cargados.', {
            puestos: result.recordset || []
        });
    } catch (error) {
        res.status(500).json({ ok: false, mensaje: 'Error al listar puestos.' });
    }
});

app.get('/api/tipos-movimiento', async (req, res) => {
    const idUsuario = validarUsuario(req, res);

    if (!idUsuario) {
        return;
    }

    try {
        const pool = await getPool();
        const result = await pool.request()
            .input('inIdPostByUser', sql.Int, idUsuario)
            .input('inPostInIP', sql.VarChar(64), obtenerIP(req))
            .output('outResultCode', sql.Int)
            .execute('dbo.sp_ListarTiposMovimiento');

        await responderConCodigo(res, result.output.outResultCode, 'Tipos de movimiento cargados.', {
            tiposMovimiento: result.recordset || []
        });
    } catch (error) {
        res.status(500).json({ ok: false, mensaje: 'Error al listar tipos de movimiento.' });
    }
});

app.get('/api/empleados', async (req, res) => {
    const idUsuario = validarUsuario(req, res);

    if (!idUsuario) {
        return;
    }

    const filtro = String(req.query.filtro || '').trim();
    const tipoFiltro = detectarTipoFiltro(filtro);

    if (tipoFiltro === 'invalido') {
        return res.status(400).json({
            ok: false,
            mensaje: 'El filtro debe contener solo letras y espacios, o solo números.'
        });
    }

    try {
        const pool = await getPool();
        const result = await pool.request()
            .input('inFiltro', sql.VarChar(128), filtro)
            .input('inTipoFiltro', sql.VarChar(16), tipoFiltro)
            .input('inIdPostByUser', sql.Int, idUsuario)
            .input('inPostInIP', sql.VarChar(64), obtenerIP(req))
            .output('outResultCode', sql.Int)
            .execute('dbo.sp_ListarEmpleados');

        await responderConCodigo(res, result.output.outResultCode, 'Empleados cargados.', {
            empleados: result.recordset || []
        });
    } catch (error) {
        res.status(500).json({ ok: false, mensaje: 'Error al listar empleados.' });
    }
});

app.get('/api/empleados/:id', async (req, res) => {
    const idUsuario = validarUsuario(req, res);

    if (!idUsuario) {
        return;
    }

    try {
        const pool = await getPool();
        const result = await pool.request()
            .input('inIdEmpleado', sql.Int, Number(req.params.id))
            .input('inIdPostByUser', sql.Int, idUsuario)
            .input('inPostInIP', sql.VarChar(64), obtenerIP(req))
            .output('outResultCode', sql.Int)
            .execute('dbo.sp_ObtenerEmpleado');

        if (result.output.outResultCode !== 0) {
            return responderConCodigo(res, result.output.outResultCode, '', {});
        }

        if (!result.recordset || result.recordset.length === 0) {
            return res.status(404).json({ ok: false, mensaje: 'Empleado no encontrado.' });
        }

        res.json({ ok: true, empleado: result.recordset[0] });
    } catch (error) {
        res.status(500).json({ ok: false, mensaje: 'Error al consultar empleado.' });
    }
});

app.post('/api/empleados', async (req, res) => {
    const idUsuario = validarUsuario(req, res);

    if (!idUsuario) {
        return;
    }

    const { valorDocumentoIdentidad, nombre, idPuesto, fechaContratacion } = req.body;

    if (!valorDocumentoIdentidad || !nombre || !idPuesto || !fechaContratacion) {
        return res.status(400).json({
            ok: false,
            mensaje: 'Debe completar documento, nombre, puesto y fecha de contratación.'
        });
    }

    try {
        const pool = await getPool();
        const result = await pool.request()
            .input('inValorDocumentoIdentidad', sql.VarChar(32), valorDocumentoIdentidad)
            .input('inNombre', sql.VarChar(128), nombre)
            .input('inIdPuesto', sql.Int, Number(idPuesto))
            .input('inFechaContratacion', sql.Date, fechaContratacion)
            .input('inIdPostByUser', sql.Int, idUsuario)
            .input('inPostInIP', sql.VarChar(64), obtenerIP(req))
            .output('outResultCode', sql.Int)
            .execute('dbo.sp_InsertarEmpleado');

        await responderConCodigo(res, result.output.outResultCode, 'Empleado insertado correctamente.', {});
    } catch (error) {
        res.status(500).json({ ok: false, mensaje: 'Error al insertar empleado.' });
    }
});

app.put('/api/empleados/:id', async (req, res) => {
    const idUsuario = validarUsuario(req, res);

    if (!idUsuario) {
        return;
    }

    const { valorDocumentoIdentidad, nombre, idPuesto } = req.body;

    if (!valorDocumentoIdentidad || !nombre || !idPuesto) {
        return res.status(400).json({
            ok: false,
            mensaje: 'Debe completar documento, nombre y puesto.'
        });
    }

    try {
        const pool = await getPool();
        const result = await pool.request()
            .input('inIdEmpleado', sql.Int, Number(req.params.id))
            .input('inValorDocumentoIdentidad', sql.VarChar(32), valorDocumentoIdentidad)
            .input('inNombre', sql.VarChar(128), nombre)
            .input('inIdPuesto', sql.Int, Number(idPuesto))
            .input('inIdPostByUser', sql.Int, idUsuario)
            .input('inPostInIP', sql.VarChar(64), obtenerIP(req))
            .output('outResultCode', sql.Int)
            .execute('dbo.sp_ActualizarEmpleado');

        await responderConCodigo(res, result.output.outResultCode, 'Empleado actualizado correctamente.', {});
    } catch (error) {
        res.status(500).json({ ok: false, mensaje: 'Error al actualizar empleado.' });
    }
});

app.post('/api/empleados/:id/intento-borrado', async (req, res) => {
    const idUsuario = validarUsuario(req, res);

    if (!idUsuario) {
        return;
    }

    try {
        const pool = await getPool();
        const result = await pool.request()
            .input('inIdEmpleado', sql.Int, Number(req.params.id))
            .input('inIdPostByUser', sql.Int, idUsuario)
            .input('inPostInIP', sql.VarChar(64), obtenerIP(req))
            .output('outResultCode', sql.Int)
            .execute('dbo.sp_RegistrarIntentoBorrado');

        await responderConCodigo(res, result.output.outResultCode, 'Intento de borrado registrado.', {});
    } catch (error) {
        res.status(500).json({ ok: false, mensaje: 'Error al registrar intento de borrado.' });
    }
});

app.delete('/api/empleados/:id', async (req, res) => {
    const idUsuario = validarUsuario(req, res);

    if (!idUsuario) {
        return;
    }

    try {
        const pool = await getPool();
        const result = await pool.request()
            .input('inIdEmpleado', sql.Int, Number(req.params.id))
            .input('inIdPostByUser', sql.Int, idUsuario)
            .input('inPostInIP', sql.VarChar(64), obtenerIP(req))
            .output('outResultCode', sql.Int)
            .execute('dbo.sp_EliminarEmpleado');

        await responderConCodigo(res, result.output.outResultCode, 'Empleado eliminado correctamente.', {});
    } catch (error) {
        res.status(500).json({ ok: false, mensaje: 'Error al eliminar empleado.' });
    }
});

app.get('/api/empleados/:id/movimientos', async (req, res) => {
    const idUsuario = validarUsuario(req, res);

    if (!idUsuario) {
        return;
    }

    try {
        const pool = await getPool();
        const result = await pool.request()
            .input('inIdEmpleado', sql.Int, Number(req.params.id))
            .input('inIdPostByUser', sql.Int, idUsuario)
            .input('inPostInIP', sql.VarChar(64), obtenerIP(req))
            .output('outResultCode', sql.Int)
            .execute('dbo.sp_ListarMovimientos');

        await responderConCodigo(res, result.output.outResultCode, 'Movimientos cargados.', {
            movimientos: result.recordset || []
        });
    } catch (error) {
        res.status(500).json({ ok: false, mensaje: 'Error al listar movimientos.' });
    }
});

app.post('/api/empleados/:id/movimientos', async (req, res) => {
    const idUsuario = validarUsuario(req, res);

    if (!idUsuario) {
        return;
    }

    const { idTipoMovimiento, fecha, monto } = req.body;

    if (!idTipoMovimiento || !fecha || monto === undefined || monto === null) {
        return res.status(400).json({
            ok: false,
            mensaje: 'Debe completar tipo de movimiento, fecha y monto.'
        });
    }

    if (Number(monto) <= 0) {
        return res.status(400).json({
            ok: false,
            codigo: 50011,
            mensaje: 'Monto del movimiento rechazado pues si se aplicar el saldo seria negativo.'
        });
    }

    try {
        const pool = await getPool();
        const result = await pool.request()
            .input('inIdEmpleado', sql.Int, Number(req.params.id))
            .input('inIdTipoMovimiento', sql.Int, Number(idTipoMovimiento))
            .input('inFecha', sql.Date, fecha)
            .input('inMonto', sql.Money, Number(monto))
            .input('inIdPostByUser', sql.Int, idUsuario)
            .input('inPostInIP', sql.VarChar(64), obtenerIP(req))
            .output('outResultCode', sql.Int)
            .execute('dbo.sp_InsertarMovimiento');

        await responderConCodigo(res, result.output.outResultCode, 'Movimiento insertado correctamente.', {});
    } catch (error) {
        res.status(500).json({ ok: false, mensaje: 'Error al insertar movimiento.' });
    }
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Servidor Node encendido en http://localhost:${PORT}`);
});
