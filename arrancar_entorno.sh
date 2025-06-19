#!/bin/bash

###################################
# Hora de inicio
###################################
start_time=$(date +%s)

###################################
# Arrancar entorno Ansible
###################################
echo "🔧 Buscando contenedores en la red 'ansible'..."

docker ps -a --filter network=ansible --format '{{.Names}} {{.ID}}' | while read -r name id; do
  echo "⏳  Arrancando contenededor $name con id: $id"

  if docker start "$name" >/dev/null; then
    echo "🛑  Contenedor $name arrancado."
  else
    echo "❌  Error al arrancar contenedor $name."
  fi
done

###################################
# Hora de fin
###################################
end_time=$(date +%s)
echo "⏱️  Tiempo total: $((end_time - start_time)) segundos."