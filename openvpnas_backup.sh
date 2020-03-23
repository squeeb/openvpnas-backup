#!/bin/bash

backup_date=$(date +%Y%m%d%H%M)
openvpnas_base=/usr/local/openvpn_as
source_dir=${openvpnas_base}/etc/db
backup_dir=/data/backup/openvpnas/${backup_date}
openvpnas_dbs=(
  config.db
  certs.db
  userprop.db
  log.db
  config_local.db
  cluster.db
  clusterdb.db
  notification.db
)

[ ! -d $backup_dir ] && mkdir -p $backup_dir

function log() {
  logger -t openvpn_backup $1
  echo $(date +%F' '%H:%M:%S) $1
}

function backup_openvpnas_db() {
  log "${FUNCNAME[0]}: Backing up ${db}"
  [ -e $source_dir/$1 ] && sqlite3 $source_dir/$1 .dump > $backup_dir/$1.bak
  [ $? -eq 0 ] && log "${FUNCNAME[0]}: Done" || log "${FUNCNAME[0]}: Failed"
}

function backup_openvpnas_configs() {
  log "${FUNCNAME[0]}: Backing up running configuration: "
  $openvpnas_base/scripts/sacli ConfigQuery > $backup_dir/config.json
  [ $? -eq 0 ] && log "${FUNCNAME[0]}: Done" || log "${FUNCNAME[0]}: Failed"
  log "${FUNCNAME[0]}: Backing up static configuration: "
  cp {$openvpnas_base/etc,$backup_dir}/as.conf
  [ $? -eq 0 ] && log "${FUNCNAME[0]}: Done" || log "${FUNCNAME[0]}: Failed"
}

function symlink_last_backup() {
  log "${FUNCNAME[0]}: Creating 'current' symlink: "
  [ -L ${backup_dir}/current ] && unlink $(dirname ${backup_dir})/current
  ln -s ${backup_dir} $(dirname ${backup_dir})/current
  [ $? -eq 0 ] && log "${FUNCNAME[0]}: Done" || log "${FUNCNAME[0]}: Failed"
}

for db in ${openvpnas_dbs[@]}
do
  backup_openvpnas_db $db
done
backup_openvpnas_configs
symlink_last_backup
