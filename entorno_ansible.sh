#!/bin/bash

###################################
# Definir Network
###################################
NETWORK_NAME="ansible"
SUBNET="172.18.0.0/16"

start_time=$(date +%s)

###################################
# Funciones
###################################

remove_container() {
  if docker ps -a --format '{{.Names}}' | grep -q "^$1$"; then
    docker rm -f "$1" >/dev/null
    echo "✔️  Contenedor $1 eliminado."
  else
    echo "ℹ️  Contenedor $1 no existe. Nothing to do."
  fi
}

remove_network() {
  if docker network inspect "$1" >/dev/null 2>&1; then
    docker network rm "$1" >/dev/null
    echo "✔️  Red $1 eliminada."
  else
    echo "ℹ️  Red $1 no existe. Nothing to do."
  fi
}

create_network() {
  local output
  if output=$(docker network create "$1" --subnet="$2" 2>&1); then
    echo "✔️  Red $1 creada, ID: $output"
  else
    echo "❌  Error al crear la red $1:"
    echo "$output"
    exit 1
  fi
}

create_container() {
  local output
  echo "⏳  Creando contenedor $3 con la imagen $5..."
  if output=$(docker run --detach --privileged --volume="$1" --ip="$2" --cgroupns=host --name="$3" --network="$4" "$5" 2>&1); then
    echo "✔️  Contenedor $3 creado, ID: $output"
  else
    echo "❌  Error al crear el contenedor $3:"
    echo "$output"
  fi
}

start_all() {
  if ! docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
    echo "❌ La red '$NETWORK_NAME' no existe."
    return
  fi

  containers=$(docker ps -a --filter network=$NETWORK_NAME --format '{{.Names}} {{.ID}}')

  echo "🔧 Buscando contenedores en la red '$NETWORK_NAME'..."

  if [[ -z "$containers" ]]; then
    echo "⚠️  No se encontraron contenedores conectados a la red '$NETWORK_NAME'."
    return
  fi

  echo "$containers" | while read -r name id; do
    echo "⏳  Arrancando contenedor $name (ID: $id)..."
    if docker start "$name" >/dev/null; then
      echo "🚀  Contenedor $name arrancado."
    else
      echo "❌  Error al arrancar contenedor $name."
    fi
  done
}

stop_all() {
  echo "🔧 Buscando contenedores en la red '$NETWORK_NAME'..."
  docker ps -a --filter network=$NETWORK_NAME --format '{{.Names}} {{.ID}}' | while read -r name id; do
    echo "⏳  Deteniendo contenedor $name (ID: $id)..."
    if docker stop "$name" >/dev/null; then
      echo "🛑  Contenedor $name detenido."
    else
      echo "❌  Error al detener contenedor $name."
    fi
  done
}

rebuild() {
  remove_container debian1
  remove_container debian2
  remove_container rocky1
  remove_container rocky2
  remove_container ubuntu1
  remove_container mysql1
  remove_container tomcat1
  remove_container tomcat2

  remove_network "$NETWORK_NAME"
  create_network "$NETWORK_NAME" "$SUBNET"

  create_container /sys/fs/cgroup:/sys/fs/cgroup:rw 172.18.0.2  debian1 "$NETWORK_NAME" apasoft/debian11-ansible
  create_container /sys/fs/cgroup:/sys/fs/cgroup:rw 172.18.0.3  debian2 "$NETWORK_NAME" apasoft/debian11-ansible
  create_container /sys/fs/cgroup:/sys/fs/cgroup:rw 172.18.0.5  rocky1  "$NETWORK_NAME" apasoft/rocky9-ansible
  create_container /sys/fs/cgroup:/sys/fs/cgroup:rw 172.18.0.6  rocky2  "$NETWORK_NAME" apasoft/rocky9-ansible
  create_container /sys/fs/cgroup:/sys/fs/cgroup:rw 172.18.0.8  ubuntu1 "$NETWORK_NAME" apasoft/ubuntu22-ansible
  create_container /sys/fs/cgroup:/sys/fs/cgroup:rw 172.18.0.10 mysql1  "$NETWORK_NAME" apasoft/debian11-ansible
  create_container /sys/fs/cgroup:/sys/fs/cgroup:rw 172.18.0.12 tomcat1 "$NETWORK_NAME" apasoft/debian11-ansible
  create_container /sys/fs/cgroup:/sys/fs/cgroup:rw 172.18.0.13 tomcat2 "$NETWORK_NAME" apasoft/debian11-ansible
}

case "$1" in
  --start)
    start_all
    ;;
  --stop)
    stop_all
    ;;
  --rebuild)
    rebuild
    ;;
  *)
    echo "❓ Uso: $0 [--start | --stop | --rebuild]"
    exit 1
    ;;
esac

###################################
# Hora de fin
###################################
end_time=$(date +%s)
echo ""
echo "⏱️  Tiempo total: $((end_time - start_time)) segundos."