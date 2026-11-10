#!/bin/sh
# Körs av MySQL-imagen vid första uppstarten av mysql_db (tom volym), efter 01_init.sql.
# Skapar travelagency-databasen och dess användare. Lösenordet kommer från miljön
# (TRAVEL_AGENT_PASSWORD i .env), så att det inte står i en SQL-fil i repot.
set -e

mysql -uroot -p"$MYSQL_ROOT_PASSWORD" <<SQL
CREATE DATABASE IF NOT EXISTS \`travelagency\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'travel_agent'@'%' IDENTIFIED BY '${TRAVEL_AGENT_PASSWORD}';
GRANT EXECUTE ON \`travelagency\`.* TO 'travel_agent'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON \`travelagency\`.* TO 'travel_agent'@'%';
FLUSH PRIVILEGES;
SQL
