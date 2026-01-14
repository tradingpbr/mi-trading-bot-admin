#!/bin/bash

echo "🚀 Creando proyecto 'mi-trading-bot-admin'..."

mkdir mi-trading-bot-admin
cd mi-trading-bot-admin

# Crear archivos principales
echo "📦 Generando archivos..."

# .env.example
cat <<EOF > .env.example
DLOCAL_X_LOGIN=tu_x_login
DLOCAL_X_TRANS_KEY=tu_x_trans_key
DLOCAL_URL=https://sandbox.dlocal.com
DLOCAL_RETURN_URL=https://tusitio.com/return

ADMIN_USER=admin
ADMIN_PASS=claveSuperSecreta
EOF

# clientes.json
cat <<EOF > clientes.json
{
  "clientes": []
}
EOF

# package.json
cat <<EOF > package.json
{
  "name": "mi-trading-bot-admin",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "axios": "^1.6.0",
    "dotenv": "^16.0.3",
    "express": "^4.18.2",
    "express-session": "^1.17.3"
  }
}
EOF

# Crear carpeta public
mkdir public

# login.html
cat <<EOF > public/login.html
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <title>Login Admin</title>
  <link rel="stylesheet" href="style.css" />
</head>
<body>
  <h1>Login Administrador</h1>
  <form method="POST" action="/login">
    <input type="text" name="username" placeholder="Usuario" required />
    <input type="password" name="password" placeholder="Contraseña" required />
    <button type="submit">Entrar</button>
  </form>
</body>
</html>
EOF

# dashboard.html
cat <<EOF > public/dashboard.html
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <title>Dashboard Administrativo</title>
  <link rel="stylesheet" href="style.css" />
</head>
<body>
  <h1>Clientes - Mi Trading Bot</h1>
  <input type="text" id="buscarEmail" placeholder="Buscar por email..." />
  <table>
    <thead>
      <tr>
        <th>Email</th>
        <th>Estado</th>
        <th>Alta</th>
        <th>Baja</th>
        <th>Orden</th>
        <th>Acción</th>
      </tr>
    </thead>
    <tbody id="tablaClientes"></tbody>
  </table>
  <script src="script.js"></script>
</body>
</html>
EOF

# style.css
cat <<EOF > public/style.css
body {
  font-family: Arial, sans-serif;
  padding: 20px;
  background-color: #f4f6f8;
}

h1 {
  color: #1f3b73;
}

input {
  padding: 10px;
  margin-bottom: 20px;
  width: 300px;
}

table {
  width: 100%;
  border-collapse: collapse;
  background: white;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

th, td {
  border: 1px solid #ccc;
  padding: 12px;
  text-align: left;
}

th {
  background-color: #1f3b73;
  color: white;
}

tr:nth-child(even) {
  background-color: #f9f9f9;
}

.estado-activo {
  color: green;
  font-weight: bold;
}

.estado-inactivo {
  color: red;
  font-weight: bold;
}

button {
  padding: 5px 10px;
  background-color: #cc0000;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}
EOF

# script.js
cat <<EOF > public/script.js
document.addEventListener('DOMContentLoaded', () => {
  const tabla = document.getElementById('tablaClientes');
  const buscarInput = document.getElementById('buscarEmail');

  function cargarClientes(filtro = '') {
    fetch('/api/clientes')
      .then(res => res.json())
      .then(data => {
        tabla.innerHTML = '';
        data.clientes
          .filter(c => c.email.toLowerCase().includes(filtro.toLowerCase()))
          .forEach(cliente => {
            const fila = document.createElement('tr');

            const botonCancelar = cliente.activo && cliente.subscriptionId
              ? \`<button onclick="cancelarSuscripcion('\${cliente.email}')">Cancelar</button>\`
              : '';

            fila.innerHTML = \`
              <td>\${cliente.email}</td>
              <td class="\${cliente.activo ? 'estado-activo' : 'estado-inactivo'}">\${cliente.activo ? 'Activo' : 'Inactivo'}</td>
              <td>\${cliente.fechaAlta ? new Date(cliente.fechaAlta).toLocaleString() : '-'}</td>
              <td>\${cliente.fechaBaja ? new Date(cliente.fechaBaja).toLocaleString() : '-'}</td>
              <td>\${cliente.ultimaOrden || '-'}</td>
              <td>\${botonCancelar}</td>
            \`;

            tabla.appendChild(fila);
          });
      });
  }

  buscarInput.addEventListener('input', () => {
    cargarClientes(buscarInput.value);
  });

  cargarClientes();
});

function cancelarSuscripcion(email) {
  if (!confirm(\`¿Cancelar suscripción de \${email}?\`)) return;

  fetch('/api/cancelar', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email })
  })
    .then(res => res.json())
    .then(data => {
      if (data.success) {
        alert('Suscripción cancelada');
        location.reload();
      } else {
        alert('Error: ' + (data.message || ''));
      }
    })
    .catch(() => alert('Error de red'));
}
EOF

# server.js
cat <<EOF > server.js
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
      \`\${process.env.DLOCAL_URL}/v1/subscriptions/\${cliente.subscriptionId}/cancel\`,
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
  console.log(\`✅ Servidor corriendo en http://localhost:\${PORT}\`);
});
EOF

echo "📦 Proyecto creado con éxito."
echo "👉 Ejecuta: cd mi-trading-bot-admin && npm install && cp .env.example .env"

