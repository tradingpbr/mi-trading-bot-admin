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
              ? `<button onclick="cancelarSuscripcion('${cliente.email}')">Cancelar</button>`
              : '';

            fila.innerHTML = `
              <td>${cliente.email}</td>
              <td class="${cliente.activo ? 'estado-activo' : 'estado-inactivo'}">${cliente.activo ? 'Activo' : 'Inactivo'}</td>
              <td>${cliente.fechaAlta ? new Date(cliente.fechaAlta).toLocaleString() : '-'}</td>
              <td>${cliente.fechaBaja ? new Date(cliente.fechaBaja).toLocaleString() : '-'}</td>
              <td>${cliente.ultimaOrden || '-'}</td>
              <td>${botonCancelar}</td>
            `;

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
  if (!confirm(`¿Cancelar suscripción de ${email}?`)) return;

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
