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
