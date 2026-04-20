const express = require('express');
const sql = require('mssql');
const app = express();
const PORT = process.env.PORT || 3000;
app.use(express.json());
app.use(express.static('public'));
const dbConfig = { server: 'localhost', database: 'ControlVacacionesDB', user: 'developer_tarea2', password: 'Tarea2_2026!', options: { trustServerCertificate: true, encrypt: false } };
async function getPool(){ return sql.connect(dbConfig); }
app.post('/api/auth/login', async (req, res) => {
  const pool = await getPool();
  const result = await pool.request()
    .input('inUsername', sql.VarChar(64), req.body.username)
    .input('inPassword', sql.VarChar(64), req.body.password)
    .input('inPostInIP', sql.VarChar(64), req.ip)
    .output('outIdUsuario', sql.Int)
    .output('outResultCode', sql.Int)
    .execute('dbo.sp_LoginUsuario');
  res.json(result.output);
});
app.post('/api/auth/logout', async (req, res) => {
  const pool = await getPool();
  const result = await pool.request()
    .input('inIdUsuario', sql.Int, req.body.idUsuario)
    .input('inPostInIP', sql.VarChar(64), req.ip)
    .output('outResultCode', sql.Int)
    .execute('dbo.sp_LogoutUsuario');
  res.json(result.output);
});
app.listen(PORT, () => console.log(`Servidor en http://localhost:${PORT}`));


app.get('/api/empleados', async (req, res) => {
  const pool = await getPool();
  const filtro = req.query.filtro || '';
  const tipoFiltro = /^\d+$/.test(filtro) ? 'cedula' : (filtro.trim() === '' ? '' : 'nombre');
  const result = await pool.request()
    .input('inFiltro', sql.VarChar(128), filtro)
    .input('inTipoFiltro', sql.VarChar(16), tipoFiltro)
    .input('inIdUsuario', sql.Int, Number(req.query.idUsuario || 1))
    .input('inPostInIP', sql.VarChar(64), req.ip)
    .output('outResultCode', sql.Int)
    .execute('dbo.sp_ListarEmpleados');
  res.json({ empleados: result.recordset, codigo: result.output.outResultCode });
});

