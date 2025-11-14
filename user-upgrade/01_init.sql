-- ----------------------------------------------------
-- 01_grant_subroot.sql
-- Skriptet körs vid första uppstarten av mysql_db (Scratchpad).
-- Målet är att ge användaren 'user' (från environment) fulla rättigheter
-- på alla databaser och tabeller (*.*), vilket ger den sub-root-status.
-- ----------------------------------------------------

-- Ge ALLA rättigheter på ALLA databaser (*.*) till 'user'
-- som kan ansluta från valfri värd (%).
GRANT ALL PRIVILEGES ON *.* TO 'user' @'%' WITH GRANT OPTION;

-- Uppdatera MySQL:s interna minneslagring av rättigheter.
FLUSH PRIVILEGES;

-- ----------------------------------------------------
-- Användaren 'user' har nu fullständig kontroll över databasinstansen.
-- ----------------------------------------------------