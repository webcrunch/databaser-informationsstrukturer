from flask import Flask, jsonify, request, g, has_request_context
from flask_restx import Api, Resource, fields, reqparse
import os
import mysql.connector
import time
from datetime import datetime, date  # Importera date här
import json  # Importera json för den anpassade enkodern
from contextlib import contextmanager

# ----------------------------------------------------
# 1. Konfiguration
# ----------------------------------------------------

app = Flask(__name__)

# Databaskonfiguration läses från miljövariabler (som i docker-compose.yml)
# Använder standardvärden för lokal utveckling om variablerna saknas.
app.config["MYSQL_DATABASE_USER"] = os.environ.get("MYSQL_DATABASE_USER", "user")
app.config["MYSQL_DATABASE_PASSWORD"] = os.environ.get(
    "MYSQL_DATABASE_PASSWORD", "password"
)
app.config["MYSQL_DATABASE_DB"] = os.environ.get("MYSQL_DATABASE_DB", "Nexus_DB")
app.config["MYSQL_DATABASE_HOST"] = os.environ.get("MYSQL_DATABASE_HOST", "localhost")


# Flask-RESTX Instans
api = Api(
    app,
    version="1.0",
    title="Course Portal API",
    description="API för student-, lärare-, kurs- och registreringshantering.",
    doc="/apidocs",
)

# Definiera Namespaces (grupper) för API:et
student_ns = api.namespace("students", description="Studenthantering")
teacher_ns = api.namespace("teachers", description="Lärarhantering")
course_ns = api.namespace("courses", description="Kurshantering")
enrollment_ns = api.namespace("enrollments", description="Registreringshantering")


# ----------------------------------------------------
# 2. Databashantering
# ----------------------------------------------------


@contextmanager
def cursor_manager(db):
    """
    Hanterar en databaspekare (cursor) med automatisk stängning.
    Om du vill ha resultaten som ordlistor (dictionary) måste du
    anropa: with cursor_manager(db) as cursor: ...
    """
    cursor = None
    try:
        # HÄR ÄR KORRIGERINGEN: dictionary=True används vid cursor-skapande!
        cursor = db.cursor(dictionary=True)
        yield cursor
    finally:
        if cursor:
            cursor.close()


def get_db():
    """Öppnar en ny databasanslutning om den inte redan finns för den här begäran."""
    # Använd has_request_context för att kontrollera om vi är i en begäran,
    # annars kan vi inte använda 'g'. Detta är viktigt för Flask-setup.
    if not has_request_context():
        return None  # Eller hantera på ett annat sätt för CLI/tester

    if "_database" not in g:
        # FÖRBÄTTRING: Lägg till try/except-block för att hantera anslutningsfel
        try:
            # HÄR ÄR KORRIGERINGEN: Argumentet 'dictionary' är borttaget härifrån.
            g._database = mysql.connector.connect(
                user=app.config["MYSQL_DATABASE_USER"],
                password=app.config["MYSQL_DATABASE_PASSWORD"],
                host=app.config["MYSQL_DATABASE_HOST"],
                database=app.config["MYSQL_DATABASE_DB"],
            )
            print("Database connection established.")
        except mysql.connector.Error as err:
            print(f"Database connection failed: {err}")
            # Vi returnerar None vid fel, och API-metoderna hanterar detta.
            return None
        except Exception as e:
            print(f"An unexpected error occurred during connection: {e}")
            return None
    return g._database


@app.teardown_appcontext
def close_db(exception):
    """Stänger databasanslutningen vid slutet av begäran."""
    db = g.pop("_database", None)
    if db is not None:
        db.close()
        print("Database connection closed.")


# ----------------------------------------------------
# 3. Modeller för indata/utdata (Marshalling)
# ----------------------------------------------------

# (Modellerna är oförändrade men inkluderas för helhet)

student_model = api.model(
    "Student",
    {
        "id": fields.Integer(readonly=True, description="Student ID"),
        "firstName": fields.String(required=True, description="Förnamn"),
        "lastName": fields.String(required=True, description="Efternamn"),
        "personNr": fields.String(
            required=True, description="Personnummer (ÅÅMMDD-XXXX)"
        ),
        "email": fields.String(required=True, description="E-postadress"),
        "registeredDate": fields.Date(description="Registreringsdatum"),
    },
)

student_input_parser = reqparse.RequestParser()
student_input_parser.add_argument("firstName", type=str, required=True, location="json")
student_input_parser.add_argument("lastName", type=str, required=True, location="json")
student_input_parser.add_argument("personNr", type=str, required=True, location="json")
student_input_parser.add_argument("email", type=str, required=True, location="json")


teacher_model = api.model(
    "Teacher",
    {
        "id": fields.Integer(readonly=True, description="Lärar-ID"),
        "firstName": fields.String(required=True, description="Förnamn"),
        "lastName": fields.String(required=True, description="Efternamn"),
        "email": fields.String(required=True, description="E-postadress"),
        "department": fields.String(required=True, description="Avdelning"),
    },
)

teacher_input_parser = reqparse.RequestParser()
teacher_input_parser.add_argument("firstName", type=str, required=True, location="json")
teacher_input_parser.add_argument("lastName", type=str, required=True, location="json")
teacher_input_parser.add_argument("email", type=str, required=True, location="json")
teacher_input_parser.add_argument(
    "department", type=str, required=True, location="json"
)


course_model = api.model(
    "Course",
    {
        "code": fields.String(readonly=True, description="Kurskod"),
        "name": fields.String(required=True, description="Kursnamn"),
        "credits": fields.Float(required=True, description="Högskolepoäng"),
        "responsibleTeacherId": fields.Integer(
            required=True, description="Ansvarig lärares ID"
        ),
    },
)

course_input_parser = reqparse.RequestParser()
course_input_parser.add_argument("code", type=str, required=True, location="json")
course_input_parser.add_argument("name", type=str, required=True, location="json")
course_input_parser.add_argument("credits", type=float, required=True, location="json")
course_input_parser.add_argument(
    "responsibleTeacherId", type=int, required=True, location="json"
)


enrollment_model = api.model(
    "StudentEnrollment",
    {
        "studentId": fields.Integer(readonly=True, description="Student-ID"),
        "courseCode": fields.String(readonly=True, description="Kurskod"),
        "grade": fields.String(description="Betyg (t.ex. 'A', 'U', 'G')"),
        "completionDate": fields.Date(description="Slutförandedatum"),
    },
)

enrollment_input_parser = reqparse.RequestParser()
enrollment_input_parser.add_argument("grade", type=str, required=False, location="json")
enrollment_input_parser.add_argument(
    "completionDate", type=str, required=False, location="json"
)


# ----------------------------------------------------
# 4. API Resurser (Endpoints)
# ----------------------------------------------------


# --- Student Resurser ---


@student_ns.route("/")
class StudentList(Resource):
    @student_ns.doc("list_students")
    @student_ns.marshal_list_with(student_model)
    def get(self):
        """Returnerar en lista över alla studenter."""
        db = get_db()
        if not db:
            student_ns.abort(503, "Kunde inte ansluta till databasen")

        try:
            # Korrigerad cursor-skapande
            with cursor_manager(db) as cursor:
                cursor.execute("SELECT * FROM Student")
                students = cursor.fetchall()
                return students
        except mysql.connector.Error as err:
            print(f"Database error: {err}")
            student_ns.abort(
                500, f"Fel vid hämtning från databasen: {err}"
            )  # Abort hanteras av Flask-RESTX

    @student_ns.doc("create_student")
    @student_ns.expect(student_input_parser)
    @student_ns.marshal_with(student_model, code=201)
    def post(self):
        """Skapa en ny student."""
        args = student_input_parser.parse_args()
        db = get_db()
        if not db:
            student_ns.abort(503, "Kunde inte ansluta till databasen")

        try:
            with cursor_manager(db) as cursor:
                # Använd CURDATE() i SQL för att få dagens datum
                query = """
                    INSERT INTO Student (firstName, lastName, personNr, email, registeredDate)
                    VALUES (%s, %s, %s, %s, CURDATE())
                """
                cursor.execute(
                    query,
                    (
                        args["firstName"],
                        args["lastName"],
                        args["personNr"],
                        args["email"],
                    ),
                )
                db.commit()
                new_id = cursor.lastrowid

                # Hämta den nyskapade studenten för att returnera den
                cursor.execute("SELECT * FROM Student WHERE id = %s", (new_id,))
                new_student = cursor.fetchone()
                return new_student, 201
        except mysql.connector.IntegrityError as err:
            db.rollback()
            student_ns.abort(
                409,
                f"Student kunde inte skapas: Personnummer eller E-post är redan registrerad. ({err})",
            )
        except mysql.connector.Error as err:
            db.rollback()
            student_ns.abort(500, f"Fel vid insättning i databasen: {err}")


@student_ns.route("/<int:student_id>")
@student_ns.param("student_id", "Studentens unika ID")
class Student(Resource):
    @student_ns.doc("get_student")
    @student_ns.marshal_with(student_model)
    def get(self, student_id):
        """Returnerar en specifik student."""
        db = get_db()
        if not db:
            student_ns.abort(503, "Kunde inte ansluta till databasen")

        try:
            # Korrigerad cursor-skapande
            with cursor_manager(db) as cursor:
                cursor.execute("SELECT * FROM Student WHERE id = %s", (student_id,))
                student = cursor.fetchone()
                if not student:
                    student_ns.abort(404, f"Student med ID {student_id} hittades inte.")
                return student
        except mysql.connector.Error as err:
            student_ns.abort(500, f"Fel vid hämtning från databasen: {err}")

    @student_ns.doc("update_student")
    @student_ns.expect(student_input_parser)
    @student_ns.marshal_with(student_model)
    def put(self, student_id):
        """Uppdatera en specifik student."""
        args = student_input_parser.parse_args()
        db = get_db()
        if not db:
            student_ns.abort(503, "Kunde inte ansluta till databasen")

        # Bygg upp uppdateringsfrågan dynamiskt
        set_clauses = []
        params = []
        for key, value in args.items():
            if value is not None:
                set_clauses.append(f"{key} = %s")
                params.append(value)

        if not set_clauses:
            student_ns.abort(400, "Ingen data att uppdatera angiven.")

        params.append(student_id)  # Lägg till ID för WHERE-satsen

        try:
            with cursor_manager(db) as cursor:
                query = f"UPDATE Student SET {', '.join(set_clauses)} WHERE id = %s"
                cursor.execute(query, params)
                rows_affected = cursor.rowcount
                db.commit()

                if rows_affected == 0:
                    student_ns.abort(404, f"Student med ID {student_id} hittades inte.")

                # Hämta den uppdaterade posten för att returnera den
                cursor.execute("SELECT * FROM Student WHERE id = %s", (student_id,))
                updated_student = cursor.fetchone()
                return updated_student
        except mysql.connector.IntegrityError as err:
            db.rollback()
            student_ns.abort(
                409,
                f"Uppdateringen misslyckades: Personnummer eller E-post är redan registrerad. ({err})",
            )
        except mysql.connector.Error as err:
            db.rollback()
            student_ns.abort(500, f"Fel vid uppdatering i databasen: {err}")

    @student_ns.doc("delete_student")
    @student_ns.response(204, "Student raderad framgångsrikt.")
    def delete(self, student_id):
        """Radera en specifik student."""
        db = get_db()
        if not db:
            student_ns.abort(503, "Kunde inte ansluta till databasen")

        try:
            with cursor_manager(db) as cursor:
                # Kolla först om studenten är inskriven på någon kurs (Foreign Key-begränsning)
                cursor.execute(
                    "SELECT 1 FROM StudentEnrollment WHERE studentId = %s LIMIT 1",
                    (student_id,),
                )
                if cursor.fetchone():
                    student_ns.abort(
                        409,
                        f"Student {student_id} är inskriven på en eller flera kurser och kan inte raderas.",
                    )

                cursor.execute("DELETE FROM Student WHERE id = %s", (student_id,))
                rows_deleted = cursor.rowcount
                db.commit()

                if rows_deleted == 0:
                    student_ns.abort(404, f"Student med ID {student_id} hittades inte.")

                return "", 204
        except mysql.connector.Error as err:
            db.rollback()
            student_ns.abort(500, f"Fel vid radering i databasen: {err}")


# --- Lärar Resurser ---


@teacher_ns.route("/")
class TeacherList(Resource):
    @teacher_ns.doc("list_teachers")
    @teacher_ns.marshal_list_with(teacher_model)
    def get(self):
        """Returnerar en lista över alla lärare."""
        db = get_db()
        if not db:
            teacher_ns.abort(503, "Kunde inte ansluta till databasen")
        try:
            # Korrigerad cursor-skapande
            with cursor_manager(db) as cursor:
                cursor.execute("SELECT * FROM Teacher")
                teachers = cursor.fetchall()
                return teachers
        except mysql.connector.Error as err:
            teacher_ns.abort(500, f"Fel vid hämtning från databasen: {err}")

    @teacher_ns.doc("create_teacher")
    @teacher_ns.expect(teacher_input_parser)
    @teacher_ns.marshal_with(teacher_model, code=201)
    def post(self):
        """Skapa en ny lärare."""
        args = teacher_input_parser.parse_args()
        db = get_db()
        if not db:
            teacher_ns.abort(503, "Kunde inte ansluta till databasen")
        try:
            with cursor_manager(db) as cursor:
                query = """
                    INSERT INTO Teacher (firstName, lastName, email, department)
                    VALUES (%s, %s, %s, %s)
                """
                cursor.execute(
                    query,
                    (
                        args["firstName"],
                        args["lastName"],
                        args["email"],
                        args["department"],
                    ),
                )
                db.commit()
                new_id = cursor.lastrowid

                # Hämta den nyskapade läraren
                cursor.execute("SELECT * FROM Teacher WHERE id = %s", (new_id,))
                new_teacher = cursor.fetchone()
                return new_teacher, 201
        except mysql.connector.IntegrityError as err:
            db.rollback()
            teacher_ns.abort(
                409, f"Lärare kunde inte skapas: E-post är redan registrerad. ({err})"
            )
        except mysql.connector.Error as err:
            db.rollback()
            teacher_ns.abort(500, f"Fel vid insättning i databasen: {err}")


@teacher_ns.route("/<int:teacher_id>")
@teacher_ns.param("teacher_id", "Lärarens unika ID")
class Teacher(Resource):
    @teacher_ns.doc("get_teacher")
    @teacher_ns.marshal_with(teacher_model)
    def get(self, teacher_id):
        """Returnerar en specifik lärare."""
        db = get_db()
        if not db:
            teacher_ns.abort(503, "Kunde inte ansluta till databasen")
        try:
            # Korrigerad cursor-skapande
            with cursor_manager(db) as cursor:
                cursor.execute("SELECT * FROM Teacher WHERE id = %s", (teacher_id,))
                teacher = cursor.fetchone()
                if not teacher:
                    teacher_ns.abort(404, f"Lärare med ID {teacher_id} hittades inte.")
                return teacher
        except mysql.connector.Error as err:
            teacher_ns.abort(500, f"Fel vid hämtning från databasen: {err}")


# --- Kurs Resurser ---


@course_ns.route("/")
class CourseList(Resource):
    @course_ns.doc("list_courses")
    @course_ns.marshal_list_with(course_model)
    def get(self):
        """Returnerar en lista över alla kurser."""
        db = get_db()
        if not db:
            course_ns.abort(503, "Kunde inte ansluta till databasen")
        try:
            # Korrigerad cursor-skapande
            with cursor_manager(db) as cursor:
                cursor.execute("SELECT * FROM Course")
                courses = cursor.fetchall()
                return courses
        except mysql.connector.Error as err:
            course_ns.abort(500, f"Fel vid hämtning från databasen: {err}")

    @course_ns.doc("create_course")
    @course_ns.expect(course_input_parser)
    @course_ns.marshal_with(course_model, code=201)
    def post(self):
        """Skapa en ny kurs."""
        args = course_input_parser.parse_args()
        db = get_db()
        if not db:
            course_ns.abort(503, "Kunde inte ansluta till databasen")

        # Försök att konvertera 'credits' till Decimal, även om fältet är float
        # i modellen, är det bäst att skicka det som ett numeriskt värde.
        try:
            credits_val = float(args["credits"])
        except ValueError:
            course_ns.abort(400, "Credits måste vara ett giltigt numeriskt värde.")

        try:
            with cursor_manager(db) as cursor:
                query = """
                    INSERT INTO Course (code, name, credits, responsibleTeacherId)
                    VALUES (%s, %s, %s, %s)
                """
                cursor.execute(
                    query,
                    (
                        args["code"],
                        args["name"],
                        credits_val,
                        args["responsibleTeacherId"],
                    ),
                )
                db.commit()
                # Hämta den nyskapade kursen
                cursor.execute("SELECT * FROM Course WHERE code = %s", (args["code"],))
                new_course = cursor.fetchone()
                return new_course, 201
        except mysql.connector.IntegrityError as err:
            db.rollback()
            # Hantera fel som t.ex. att kurskoden redan finns (PK) eller att lärarens ID inte finns (FK)
            course_ns.abort(
                409,
                f"Kurs kunde inte skapas: Kurskod finns eller Ogiltigt Lärar-ID. ({err})",
            )
        except mysql.connector.Error as err:
            db.rollback()
            course_ns.abort(500, f"Fel vid insättning i databasen: {err}")


@course_ns.route("/<string:course_code>")
@course_ns.param("course_code", "Kursens unika kod (t.ex. DB101)")
class Course(Resource):
    @course_ns.doc("get_course")
    @course_ns.marshal_with(course_model)
    def get(self, course_code):
        """Returnerar en specifik kurs."""
        db = get_db()
        if not db:
            course_ns.abort(503, "Kunde inte ansluta till databasen")
        try:
            # Korrigerad cursor-skapande
            with cursor_manager(db) as cursor:
                cursor.execute("SELECT * FROM Course WHERE code = %s", (course_code,))
                course = cursor.fetchone()
                if not course:
                    course_ns.abort(404, f"Kurs med kod {course_code} hittades inte.")
                return course
        except mysql.connector.Error as err:
            course_ns.abort(500, f"Fel vid hämtning från databasen: {err}")


# --- Registrering Resurser (StudentEnrollment) ---


@enrollment_ns.route("/")
class EnrollmentList(Resource):
    @enrollment_ns.doc("list_enrollments")
    @enrollment_ns.marshal_list_with(enrollment_model)
    def get(self):
        """Returnerar en lista över alla registreringar."""
        db = get_db()
        if not db:
            enrollment_ns.abort(503, "Kunde inte ansluta till databasen")
        try:
            # Korrigerad cursor-skapande
            with cursor_manager(db) as cursor:
                cursor.execute("SELECT * FROM StudentEnrollment")
                enrollments = cursor.fetchall()
                return enrollments
        except mysql.connector.Error as err:
            enrollment_ns.abort(500, f"Fel vid hämtning från databasen: {err}")

    # POST-metod för att skapa en ny registrering (inte specificerad i ursprunglig kod, men användbar)
    @enrollment_ns.doc("create_enrollment")
    @enrollment_ns.expect(
        enrollment_ns.model(
            "NewEnrollment",
            {
                "studentId": fields.Integer(required=True),
                "courseCode": fields.String(required=True),
                "grade": fields.String(required=False),
                "completionDate": fields.Date(required=False),
            },
        )
    )
    @enrollment_ns.response(201, "Registrering skapad framgångsrikt.")
    @enrollment_ns.response(409, "Registrering finns redan eller ogiltigt ID/kod.")
    def post(self):
        """Registrera en student på en kurs."""
        data = request.json
        student_id = data.get("studentId")
        course_code = data.get("courseCode")
        grade = data.get("grade")
        completion_date = data.get("completionDate")

        db = get_db()
        if not db:
            enrollment_ns.abort(503, "Kunde inte ansluta till databasen")

        try:
            with cursor_manager(db) as cursor:
                query = """
                    INSERT INTO StudentEnrollment (studentId, courseCode, grade, completionDate)
                    VALUES (%s, %s, %s, %s)
                """
                # Konvertera completion_date till datetime-objekt om det finns
                date_obj = (
                    datetime.strptime(completion_date, "%Y-%m-%d").date()
                    if completion_date
                    else None
                )

                cursor.execute(query, (student_id, course_code, grade, date_obj))
                db.commit()

                # Hämta den nya registreringen för respons
                cursor.execute(
                    "SELECT * FROM StudentEnrollment WHERE studentId = %s AND courseCode = %s",
                    (student_id, course_code),
                )
                new_enrollment = cursor.fetchone()
                return new_enrollment, 201

        except mysql.connector.IntegrityError as err:
            db.rollback()
            enrollment_ns.abort(
                409,
                f"Registrering misslyckades: Studenten är redan registrerad eller Ogiltigt Student-/Kurs-ID. ({err})",
            )
        except ValueError:
            db.rollback()
            enrollment_ns.abort(
                400, "Ogiltigt format för 'completionDate'. Använd YYYY-MM-DD."
            )
        except mysql.connector.Error as err:
            db.rollback()
            enrollment_ns.abort(500, f"Fel vid insättning i databasen: {err}")


@enrollment_ns.route("/<int:student_id>/<string:course_code>")
@enrollment_ns.param("student_id", "Studentens ID")
@enrollment_ns.param("course_code", "Kursens kod")
class Enrollment(Resource):
    @enrollment_ns.doc("get_enrollment")
    @enrollment_ns.marshal_with(enrollment_model)
    def get(self, student_id, course_code):
        """Returnerar en specifik registrering."""
        db = get_db()
        if not db:
            enrollment_ns.abort(503, "Kunde inte ansluta till databasen")

        try:
            # Korrigerad cursor-skapande
            with cursor_manager(db) as cursor:
                cursor.execute(
                    "SELECT * FROM StudentEnrollment WHERE studentId = %s AND courseCode = %s",
                    (student_id, course_code),
                )
                enrollment = cursor.fetchone()

                if not enrollment:
                    enrollment_ns.abort(
                        404,
                        f"Registrering för student {student_id} på kurs {course_code} hittades inte.",
                    )

                return enrollment
        except mysql.connector.Error as err:
            enrollment_ns.abort(500, f"Fel vid hämtning från databasen: {err}")

    @enrollment_ns.doc("update_enrollment")
    @enrollment_ns.expect(enrollment_input_parser)
    @enrollment_ns.marshal_with(enrollment_model)
    def put(self, student_id, course_code):
        """Uppdatera betyg och/eller slutförandedatum för en registrering."""
        args = enrollment_input_parser.parse_args()
        grade = args.get("grade")
        completion_date_str = args.get("completionDate")

        db = get_db()
        if not db:
            enrollment_ns.abort(503, "Kunde inte ansluta till databasen")

        set_clauses = []
        params = []

        if grade is not None:
            set_clauses.append("grade = %s")
            params.append(grade)

        if completion_date_str is not None:
            try:
                # Konvertera sträng till date-objekt
                completion_date_obj = datetime.strptime(
                    completion_date_str, "%Y-%m-%d"
                ).date()
                set_clauses.append("completionDate = %s")
                params.append(completion_date_obj)
            except ValueError:
                enrollment_ns.abort(
                    400, "Ogiltigt format för 'completionDate'. Använd YYYY-MM-DD."
                )

        if not set_clauses:
            enrollment_ns.abort(
                400, "Ingen data (grade eller completionDate) angiven för uppdatering."
            )

        # Lägg till WHERE-satserna i slutet av params
        params.extend([student_id, course_code])

        try:
            with cursor_manager(db) as cursor:
                query = f"UPDATE StudentEnrollment SET {', '.join(set_clauses)} WHERE studentId = %s AND courseCode = %s"
                cursor.execute(query, params)
                rows_affected = cursor.rowcount
                db.commit()

                if rows_affected == 0:
                    enrollment_ns.abort(
                        404,
                        f"Registrering för student {student_id} på kurs {course_code} hittades inte.",
                    )

                # Hämta den uppdaterade registreringen för respons
                cursor.execute(
                    "SELECT * FROM StudentEnrollment WHERE studentId = %s AND courseCode = %s",
                    (student_id, course_code),
                )
                updated_enrollment = cursor.fetchone()
                return updated_enrollment
        except mysql.connector.Error as err:
            db.rollback()
            enrollment_ns.abort(500, f"Fel vid uppdatering i databasen: {err}")

    @enrollment_ns.doc("delete_enrollment")
    @enrollment_ns.response(204, "Registrering raderad framgångsrikt.")
    def delete(self, student_id, course_code):
        """Radera en specifik registrering."""
        db = get_db()
        if not db:
            enrollment_ns.abort(503, "Kunde inte ansluta till databasen")

        try:
            with cursor_manager(db) as cursor:
                cursor.execute(
                    "DELETE FROM StudentEnrollment WHERE studentId = %s AND courseCode = %s",
                    (student_id, course_code),
                )
                rows_deleted = cursor.rowcount
                db.commit()

                if rows_deleted == 0:
                    enrollment_ns.abort(
                        404,
                        f"Registrering för student {student_id} på kurs {course_code} hittades inte.",
                    )

                return "", 204
        except mysql.connector.Error as err:
            db.rollback()
            enrollment_ns.abort(500, f"Fel vid radering i databasen: {err}")


# ----------------------------------------------------
# 5. Global JSON Encoder
# ----------------------------------------------------


# Anpassad JSON-enkoder för att hantera date/datetime-objekt
class CustomJSONEncoder(json.JSONEncoder):
    """Konverterar date och datetime objekt till ISO 8601 strängar."""

    def default(self, obj):
        if isinstance(obj, (date, datetime)):
            # MySQL-anslutningen returnerar standard Python date/datetime objekt.
            # Vi konverterar dessa till en ISO-formatsträng som JSON kan hantera.
            return obj.isoformat()
        # Låt basklassen (json.JSONEncoder) hantera andra typer
        return json.JSONEncoder.default(self, obj)


# Sätt den anpassade enkodern för hela appen
app.json_encoder = CustomJSONEncoder


# ----------------------------------------------------
# 6. Kör applikationen
# ----------------------------------------------------

if __name__ == "__main__":
    # Körs endast om filen startas direkt (t.ex. python backend.py)
    # I en produktionsmiljö (som med Gunicorn eller Docker) kommer detta block inte att köras.
    app.run(debug=True, host="0.0.0.0", port=5000)
