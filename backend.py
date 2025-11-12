from flask import Flask, jsonify, request, g
from flask_restx import Api, Resource, fields
import os
import mysql.connector
import time

# ----------------------------------------------------
# 1. Konfiguration
# ----------------------------------------------------

app = Flask(__name__)

# Ändra konfigurationen för att läsa från miljövariabler
# OBS! Använder Docker Compose miljövariabler: MYSQL_DATABASE_HOST: mysql_db
app.config["MYSQL_DATABASE_USER"] = os.environ.get("MYSQL_DATABASE_USER", "user")
app.config["MYSQL_DATABASE_PASSWORD"] = os.environ.get(
    "MYSQL_DATABASE_PASSWORD", "password"
)
app.config["MYSQL_DATABASE_DB"] = os.environ.get("MYSQL_DATABASE_DB", "main_database")
app.config["MYSQL_DATABASE_HOST"] = os.environ.get("MYSQL_DATABASE_HOST", "mysql_db")

# Flask-RESTX Instans och konfiguration (Ersätter Flasgger)
api = Api(
    app,
    version="1.0",
    title="Course Portal API",
    description="API för studentregistrering och kurshantering.",
    doc="/apidocs",  # Nuvarande Swagger UI URL
)

# Definiera Namespaces (grupper) för API:et
student_ns = api.namespace("students", description="Studenthantering")
system_ns = api.namespace("system", description="Systemfunktioner")

# Datamodell för Swagger-dokumentationen
student_model = student_ns.model(
    "Student",
    {
        "id": fields.Integer(required=True, description="Studentens unika ID"),
        "firstName": fields.String(required=True, description="Förnamn"),
        "lastName": fields.String(required=True, description="Efternamn"),
        "email": fields.String(required=True, description="E-postadress"),
    },
)

# ----------------------------------------------------
# 2. Databasanslutning och Health Check
# ----------------------------------------------------


def get_db():
    """Hämtar databasanslutningen. Om den inte finns, skapas en ny."""
    if "db" not in g:
        try:
            # Använder de uppdaterade app.config inställningarna
            g.db = mysql.connector.connect(
                user=app.config["MYSQL_DATABASE_USER"],
                password=app.config["MYSQL_DATABASE_PASSWORD"],
                host=app.config["MYSQL_DATABASE_HOST"],
                database=app.config["MYSQL_DATABASE_DB"],
                connection_timeout=5,
            )
        except mysql.connector.Error as err:
            # I en produktionsmiljö vill man logga felet
            print(f"Databasanslutningsfel: {err}")
            # Vi returnerar None vid fel
            g.db = None

    return g.db


@app.teardown_appcontext
def close_db(e=None):
    """Stänger databasanslutningen när app-kontexten avslutas."""
    db = g.pop("db", None)
    if db is not None and db.is_connected():
        db.close()


# ----------------------------------------------------
# 3. Klassbaserade Endpoints (Flask-RESTX)
# ----------------------------------------------------


@system_ns.route("/health")
class HealthCheck(Resource):
    """
    Hälsokontroll. API-route: /system/health
    """

    @system_ns.doc("Hälsokontroll")
    @system_ns.response(200, "API och Databas OK")
    @system_ns.response(503, "Databasanslutning misslyckades")
    def get(self):
        """
        Kontrollerar om API:et är igång och kan ansluta till databasen.
        """
        db = get_db()

        if db and db.is_connected():
            return {"status": "OK", "database": "Connected"}, 200
        else:
            return {"status": "Service Unavailable", "database": "Disconnected"}, 503


@student_ns.route("/")  # API-route: /students/
class StudentList(Resource):
    """
    Hantering av studentlistan.
    """

    @student_ns.doc("get_all_students")
    @student_ns.marshal_with(
        student_model, as_list=True
    )  # Använder datamodellen för utdata
    @student_ns.response(200, "Lista med studenter hämtad framgångsrikt.")
    @student_ns.response(503, "Kunde inte ansluta till databasen")
    @student_ns.response(500, "Fel vid SQL-fråga")
    def get(self):
        """
        Hämta alla studenter
        Den här endpointen returnerar en komplett lista över alla studenter i databasen.
        """
        db = get_db()

        if not db:
            return {"error": "Kunde inte ansluta till databasen"}, 503

        cursor = db.cursor(dictionary=True)
        query = "SELECT id, firstName, lastName, email FROM Student"
        try:
            cursor.execute(query)
            students = cursor.fetchall()
            cursor.close()
            # RESTX marshallar automatiskt listan
            return students
        except mysql.connector.Error as err:
            cursor.close()
            return {"error": f"Fel vid SQL-fråga: {err}"}, 500


# ----------------------------------------------------
# 4. Kör applikationen
# ----------------------------------------------------

if __name__ == "__main__":
    print("Applikationen startar på http://127.0.0.1:5000/")
    print("Swagger UI tillgänglig på http://127.0.0.1:5000/apidocs")
    app.run(debug=True, host="0.0.0.0")
