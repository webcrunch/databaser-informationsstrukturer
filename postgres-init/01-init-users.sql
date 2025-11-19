-- Skapa en vanlig användare med begränsade rättigheter (valfritt)
CREATE USER app_user WITH PASSWORD 'app_password';

-- Ge användaren rättigheter till databasen
GRANT ALL PRIVILEGES ON DATABASE main_database TO app_user;

-- Om du vill ha en specifik admin-användare utöver "postgres":
CREATE USER owneruser WITH SUPERUSER PASSWORD 'securepassword';