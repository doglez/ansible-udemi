#!/bin/bash

###################################
# Hora de inicio
###################################
start_time=$(date +%s)

###################################
# Detener entorno Ansible
###################################
echo "🔧 Buscando contenedores en la red 'ansible'..."

docker ps --filter network=ansible --format '{{.Names}} {{.ID}}' | while read -r name id; do
  echo "⏳  Deteniendo contenededor $name con id: $id"

  if docker stop "$name" >/dev/null; then
    echo "🛑  Contenedor $name detenido."
  else
    echo "❌  Error al detener $name."
  fi
done

###################################
# Hora de fin
###################################
end_time=$(date +%s)
echo "⏱️  Tiempo total: $((end_time - start_time)) segundos."