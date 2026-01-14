const express = require('express');
const session = require('express-session');
const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');
const axios = require('axios');
dotenv.config();

const app = express();
const PORT = 3000;

const ADMIN_USER = process.env.ADMIN_USER;
const ADMIN_PASS = process.env.ADMIN_PASS;

app.use(express.urlencoded({ extended: true }));
app.use(express.json());

app.use(session({
  secret: 'clave-segura',
  resave: false,
  saveUninitialized: false
}));

function requiereLogin(req, res, next) {
  if (req.session && req.session.authenticated) return next();
  return res.redirect('/login.html');
}

app.use(express.static(path.join(__dirname, 'public')));

app.post('/login', (req, res) => {
  const { username, password } = req.body;
  if (username === ADMIN_USER && password === ADMIN_PASS) {
    req.session.authenticated = true;
    res.redirect('/dashboard.html');
  } else {
    res.send('❌ Credenciales incorrectas');
  }
});

app.get('/logout', (req, res) => {
  req.session.destroy(() => res.redirect('/login.html'));
});

app.get('/dashboard.html', requiereLogin, (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'dashboard.html'));
});

app.get('/api/clientes', requiereLogin, (req, res) => {
  const data = JSON.parse(fs.readFileSync('./clientes.json', 'utf8'));
  res.json(data);
});

app.post('/api/cancelar', requiereLogin, async (req, res) => {
  const { email } = req.body;
  const data = JSON.parse(fs.readFileSync('./clientes.json', 'utf8'));
  const cliente = data.clientes.find(c => c.email === email);

  if (!cliente || !cliente.subscriptionId) {
    return res.status(400).json({ success: false, message: 'No se encontró la suscripción' });
  }

  try {
    await axios.post(
      `${process.env.DLOCAL_URL}/v1/subscriptions/${cliente.subscriptionId}/cancel`,
      {},
      {
        headers: {
          'Content-Type': 'application/json',
          'X-Login': process.env.DLOCAL_X_LOGIN,
          'X-Trans-Key': process.env.DLOCAL_X_TRANS_KEY
        }
      }
    );

    cliente.activo = false;
    cliente.fechaBaja = new Date().toISOString();
    fs.writeFileSync('./clientes.json', JSON.stringify(data, null, 2));
    res.json({ success: true });

  } catch (err) {
    console.error('❌ Error al cancelar:', err.response?.data || err.message);
    res.status(500).json({ success: false, message: 'Error al cancelar suscripción' });
  }
});

app.listen(PORT, () => {
  console.log(`✅ Servidor corriendo en http://localhost:${PORT}`);
});
