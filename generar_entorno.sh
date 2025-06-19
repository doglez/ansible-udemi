#!/bin/bash

###################################
# Hora de inicio
###################################
start_time=$(date +%s)

###################################
# Borrar  las maquinas si existen
###################################

remove_container() {
  if docker ps -a --format '{{.Names}}' | grep -q "^$1$"; then
    docker rm -f "$1" >/dev/null
    echo "✔️  Contenedor $1 eliminado."
  else
    echo "ℹ️  Contenedor $1 no existe. Nothing to do."
  fi
}

remove_container debian1
remove_container debian2
remove_container rocky1
remove_container rocky2
remove_container ubuntu1
remove_container mysql1
remove_container tomcat1
remove_container tomcat2

###################################
# Borrar la red si existe
###################################

remove_network() {
  if docker network ls --format '{{.Name}}' | grep -q "^$1$"; then
    docker network rm "$1" >/dev/null
    echo "✔️  Red $1 eliminada."
  else
    echo "ℹ️  Red $1 no existe. Nothing to do."
  fi
}

remove_network ansible

###################################
# Crear la red y las maquinas
###################################

create_network() {
  local output

  if output=$(docker network create "$1" --subnet="$2" 2>&1); then
    echo "✔️  Red $1 creada, ID: $output"
  else
    echo "❌  Error al crear la red $1:"
    echo "$output"
  fi
}

create_network ansible 172.18.0.0/16

create_container() {
  local output
  
  echo "⏳  Creando contenedor $3 con la imagen $4..."

  if output=$(docker run --detach --privileged --volume="$1" --ip "$2" --cgroupns=host --name="$3" --network="$4" "$5" 2>&1); then
    echo "✔️  Contenedor $3 creado, ID: $output"
  else
    echo "❌  Error al crear el contenedor $3:"
    echo "$output"
  fi 
}

create_container /sys/fs/cgroup:/sys/fs/cgroup:rw 172.18.0.2 debian1 ansible apasoft/debian11-ansible 
create_container /sys/fs/cgroup:/sys/fs/cgroup:rw 172.18.0.3 debian2 ansible apasoft/debian11-ansible 
create_container /sys/fs/cgroup:/sys/fs/cgroup:rw 172.18.0.5 rocky1 ansible apasoft/rocky9-ansible 
create_container /sys/fs/cgroup:/sys/fs/cgroup:rw 172.18.0.6 rocky2 ansible apasoft/rocky9-ansible 
create_container /sys/fs/cgroup:/sys/fs/cgroup:rw 172.18.0.8 ubuntu1 ansible apasoft/ubuntu22-ansible 
create_container /sys/fs/cgroup:/sys/fs/cgroup:rw 172.18.0.10 mysql1 ansible apasoft/debian11-ansible 
create_container /sys/fs/cgroup:/sys/fs/cgroup:rw 172.18.0.12 tomcat1 ansible apasoft/debian11-ansible 
create_container /sys/fs/cgroup:/sys/fs/cgroup:rw 172.18.0.13 tomcat2 ansible apasoft/debian11-ansible 

###################################
# Hora de fin
###################################
end_time=$(date +%s)
echo "⏱️  Tiempo total: $((end_time - start_time)) segundos."