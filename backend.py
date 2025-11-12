from flask import Flask, jsonify, request, g
from flask_restx import Api, Resource, fields, reqparse
import os
import mysql.connector
import time
from datetime import datetime

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
student_ns = api.namespace("students", description="Studenthantering (CRUD)")
teacher_ns = api.namespace("teachers", description="Lärarhantering (CRUD)")
course_ns = api.namespace("courses", description="Kurshantering (CRUD och Batch Query)")
enrollment_ns = api.namespace(
    "enrollments", description="Registreringshantering (CRUD och Stored Procedure)"
)


# ----------------------------------------------------
# 2. Databasanslutning
# ----------------------------------------------------


def get_db():
    """Hämtar en databasanslutning från g-objektet eller skapar en ny."""
    db = getattr(g, "_database", None)
    if db is None:
        try:
            db = g._database = mysql.connector.connect(
                user=app.config["MYSQL_DATABASE_USER"],
                password=app.config["MYSQL_DATABASE_PASSWORD"],
                host=app.config["MYSQL_DATABASE_HOST"],
                database=app.config["MYSQL_DATABASE_DB"],
            )
            print("Databasanslutning etablerad framgångsrikt.")
        except mysql.connector.Error as err:
            print(f"Fel vid anslutning till databasen: {err}")
            db = None  # Se till att db är None om anslutningen misslyckas
    return db


@app.teardown_appcontext
def close_connection(exception):
    """Stänger databasanslutningen när appkontexten avslutas."""
    db = getattr(g, "_database", None)
    if db is not None:
        db.close()


# ----------------------------------------------------
# 3. Helpers för att vänta på databasen (viktigt i Docker)
# ----------------------------------------------------


def wait_for_db(max_retries=10, delay=5):
    """Försöker ansluta till databasen med återförsök."""
    retries = 0
    while retries < max_retries:
        try:
            db = mysql.connector.connect(
                user=app.config["MYSQL_DATABASE_USER"],
                password=app.config["MYSQL_DATABASE_PASSWORD"],
                host=app.config["MYSQL_DATABASE_HOST"],
                database=app.config["MYSQL_DATABASE_DB"],
            )
            db.close()
            print("Databasen är igång och anslutningsbar.")
            return True
        except mysql.connector.Error as err:
            print(
                f"Väntar på databasen... Försök {retries + 1}/{max_retries}. Fel: {err}"
            )
            time.sleep(delay)
            retries += 1
    print("Kunde inte ansluta till databasen efter flera försök.")
    return False


# Körs vid uppstart för att säkerställa att DB är redo
with app.app_context():
    wait_for_db()

# ----------------------------------------------------
# 4. Modeller för API-dokumentation
# ----------------------------------------------------

# Student Modeller
student_model = api.model(
    "Student",
    {
        "firstName": fields.String(required=True, description="Studentens förnamn"),
        "lastName": fields.String(required=True, description="Studentens efternamn"),
        "personNr": fields.String(
            required=True, description="Personnummer (ÅÅMMDD-XXXX)"
        ),
        "email": fields.String(required=True, description="E-postadress"),
        "registeredDate": fields.String(
            required=True, description="Registreringsdatum (YYYY-MM-DD)"
        ),
    },
)

student_update_model = api.model(
    "StudentUpdate",
    {
        "firstName": fields.String(description="Studentens förnamn"),
        "lastName": fields.String(description="Studentens efternamn"),
        "email": fields.String(description="E-postadress"),
    },
)

# Teacher Modeller
teacher_model = api.model(
    "Teacher",
    {
        "firstName": fields.String(required=True, description="Lärarens förnamn"),
        "lastName": fields.String(required=True, description="Lärarens efternamn"),
        "email": fields.String(required=True, description="E-postadress"),
        "department": fields.String(required=True, description="Avdelning"),
    },
)

teacher_update_model = api.model(
    "TeacherUpdate",
    {
        "firstName": fields.String(description="Lärarens förnamn"),
        "lastName": fields.String(description="Lärarens efternamn"),
        "email": fields.String(description="E-postadress"),
        "department": fields.String(description="Avdelning"),
    },
)

# Course Modeller
course_model = api.model(
    "Course",
    {
        "code": fields.String(required=True, description="Kurskod"),
        "name": fields.String(required=True, description="Kursnamn"),
        "credits": fields.Float(required=True, description="Kursens poäng (t.ex. 7.5)"),
        "responsibleTeacherId": fields.Integer(
            required=True, description="Ansvarig lärares ID"
        ),
    },
)

course_update_model = api.model(
    "CourseUpdate",
    {
        "name": fields.String(description="Kursnamn"),
        "credits": fields.Float(description="Kursens poäng (t.ex. 7.5)"),
        "responsibleTeacherId": fields.Integer(description="Ansvarig lärares ID"),
    },
)

# Enrollment Modeller
enrollment_model = api.model(
    "Enrollment",
    {
        "studentId": fields.Integer(required=True, description="Studentens ID"),
        "courseCode": fields.String(required=True, description="Kurskod"),
        "grade": fields.String(required=False, description="Betyg (t.ex. 'A', 'U')"),
        "completionDate": fields.String(
            required=False, description="Slutförandedatum (YYYY-MM-DD)"
        ),
    },
)

enrollment_update_model = api.model(
    "EnrollmentUpdate",
    {
        "grade": fields.String(description="Betyg (t.ex. 'A', 'U')"),
        "completionDate": fields.String(description="Slutförandedatum (YYYY-MM-DD)"),
    },
)

# Ny modell för anrop av Stored Procedure
register_model = api.model(
    "Register",
    {
        "studentId": fields.Integer(required=True, description="Studentens ID"),
        "courseCode": fields.String(required=True, description="Kurskod"),
    },
)


# ----------------------------------------------------
# 5. API-Resurser: Student
# ----------------------------------------------------


@student_ns.route("/")
class StudentList(Resource):
    @student_ns.doc("list_students")
    def get(self):
        """Hämta alla studenter."""
        db = get_db()
        if not db:
            return {"error": "Kunde inte ansluta till databasen"}, 503

        try:
            cursor = db.cursor(dictionary=True)
            cursor.execute("SELECT * FROM Student")
            students = cursor.fetchall()
            cursor.close()
            return students, 200
        except mysql.connector.Error as err:
            return {"error": f"Fel vid hämtning från databasen: {err}"}, 500

    @student_ns.doc("create_student")
    @student_ns.expect(student_model)
    def post(self):
        """Skapa en ny student."""
        data = request.json
        # Hämta obligatoriska fält
        firstName = data.get("firstName")
        lastName = data.get("lastName")
        personNr = data.get("personNr")
        email = data.get("email")
        registeredDate = data.get("registeredDate")

        if not all([firstName, lastName, personNr, email, registeredDate]):
            return {"message": "Alla obligatoriska fält måste anges."}, 400

        db = get_db()
        if not db:
            return {"error": "Kunde inte ansluta till databasen"}, 503

        try:
            cursor = db.cursor()
            query = """
                INSERT INTO Student (firstName, lastName, personNr, email, registeredDate)
                VALUES (%s, %s, %s, %s, %s)
            """
            cursor.execute(
                query, (firstName, lastName, personNr, email, registeredDate)
            )
            db.commit()
            last_id = cursor.lastrowid
            cursor.close()
            return {"message": "Student skapad.", "id": last_id}, 201
        except mysql.connector.IntegrityError as err:
            db.rollback()
            return {
                "error": f"Student misslyckades: PersonNr eller Email existerar redan. Detaljer: {err}"
            }, 409
        except mysql.connector.Error as err:
            db.rollback()
            return {"error": f"Fel vid insättning i databasen: {err}"}, 500


@student_ns.route("/<int:student_id>")
@student_ns.param("student_id", "Studentens unika ID")
class Student(Resource):
    @student_ns.doc("get_student")
    @student_ns.response(404, "Student hittades inte.")
    def get(self, student_id):
        """Hämta en specifik student."""
        db = get_db()
        if not db:
            return {"error": "Kunde inte ansluta till databasen"}, 503

        try:
            cursor = db.cursor(dictionary=True)
            cursor.execute("SELECT * FROM Student WHERE id = %s", (student_id,))
            student = cursor.fetchone()
            cursor.close()

            if student is None:
                return {"message": "Student hittades inte."}, 404

            return student, 200
        except mysql.connector.Error as err:
            return {"error": f"Fel vid hämtning från databasen: {err}"}, 500

    @student_ns.doc("update_student")
    @student_ns.expect(student_update_model)
    @student_ns.response(404, "Student hittades inte.")
    def put(self, student_id):
        """Uppdatera en student."""
        data = request.json
        updates = []
        params = []

        if "firstName" in data:
            updates.append("firstName = %s")
            params.append(data["firstName"])
        if "lastName" in data:
            updates.append("lastName = %s")
            params.append(data["lastName"])
        if "email" in data:
            updates.append("email = %s")
            params.append(data["email"])

        if not updates:
            return {"message": "Inga uppdateringsfält angivna."}, 400

        db = get_db()
        if not db:
            return {"error": "Kunde inte ansluta till databasen"}, 503

        try:
            cursor = db.cursor()
            query = f"UPDATE Student SET {', '.join(updates)} WHERE id = %s"
            params.append(student_id)
            cursor.execute(query, params)
            rows_affected = cursor.rowcount

            if rows_affected == 0:
                db.rollback()
                cursor.close()
                return {"message": "Student hittades inte."}, 404

            db.commit()
            cursor.close()
            return {"message": "Student uppdaterad."}, 200

        except mysql.connector.IntegrityError as err:
            db.rollback()
            cursor.close()
            return {
                "error": f"Uppdatering misslyckades: Email existerar redan. Detaljer: {err}"
            }, 409
        except mysql.connector.Error as err:
            db.rollback()
            cursor.close()
            return {"error": f"Fel vid uppdatering i databasen: {err}"}, 500

    @student_ns.doc("delete_student")
    @student_ns.response(204, "Student raderad framgångsrikt.")
    @student_ns.response(
        409, "Studenten är registrerad på kurser och kan inte raderas."
    )
    def delete(self, student_id):
        """Radera en specifik student."""
        db = get_db()
        if not db:
            return {"error": "Kunde inte ansluta till databasen"}, 503

        try:
            cursor = db.cursor()
            cursor.execute("DELETE FROM Student WHERE id = %s", (student_id,))
            rows_deleted = cursor.rowcount
            db.commit()
            cursor.close()

            if rows_deleted == 0:
                return {"message": "Student hittades inte."}, 404

            return "", 204
        except mysql.connector.IntegrityError as err:
            db.rollback()
            return {
                "error": f"Studenten kan inte raderas: Den är troligen registrerad på en kurs (Foreign Key-brott). Detaljer: {err}"
            }, 409
        except mysql.connector.Error as err:
            db.rollback()
            return {"error": f"Fel vid radering i databasen: {err}"}, 500


# ----------------------------------------------------
# 6. API-Resurser: Teacher
# ----------------------------------------------------


@teacher_ns.route("/")
class TeacherList(Resource):
    @teacher_ns.doc("list_teachers")
    def get(self):
        """Hämta alla lärare."""
        db = get_db()
        if not db:
            return {"error": "Kunde inte ansluta till databasen"}, 503

        try:
            cursor = db.cursor(dictionary=True)
            cursor.execute("SELECT * FROM Teacher")
            teachers = cursor.fetchall()
            cursor.close()
            return teachers, 200
        except mysql.connector.Error as err:
            return {"error": f"Fel vid hämtning från databasen: {err}"}, 500

    @teacher_ns.doc("create_teacher")
    @teacher_ns.expect(teacher_model)
    def post(self):
        """Skapa en ny lärare."""
        data = request.json
        firstName = data.get("firstName")
        lastName = data.get("lastName")
        email = data.get("email")
        department = data.get("department")

        if not all([firstName, lastName, email, department]):
            return {"message": "Alla obligatoriska fält måste anges."}, 400

        db = get_db()
        if not db:
            return {"error": "Kunde inte ansluta till databasen"}, 503

        try:
            cursor = db.cursor()
            query = """
                INSERT INTO Teacher (firstName, lastName, email, department)
                VALUES (%s, %s, %s, %s)
            """
            cursor.execute(query, (firstName, lastName, email, department))
            db.commit()
            last_id = cursor.lastrowid
            cursor.close()
            return {"message": "Lärare skapad.", "id": last_id}, 201
        except mysql.connector.IntegrityError as err:
            db.rollback()
            return {
                "error": f"Lärare misslyckades: Email existerar redan. Detaljer: {err}"
            }, 409
        except mysql.connector.Error as err:
            db.rollback()
            return {"error": f"Fel vid insättning i databasen: {err}"}, 500


@teacher_ns.route("/<int:teacher_id>")
@teacher_ns.param("teacher_id", "Lärarens unika ID")
class Teacher(Resource):
    @teacher_ns.doc("get_teacher")
    @teacher_ns.response(404, "Lärare hittades inte.")
    def get(self, teacher_id):
        """Hämta en specifik lärare."""
        db = get_db()
        if not db:
            return {"error": "Kunde inte ansluta till databasen"}, 503

        try:
            cursor = db.cursor(dictionary=True)
            cursor.execute("SELECT * FROM Teacher WHERE id = %s", (teacher_id,))
            teacher = cursor.fetchone()
            cursor.close()

            if teacher is None:
                return {"message": "Lärare hittades inte."}, 404

            return teacher, 200
        except mysql.connector.Error as err:
            return {"error": f"Fel vid hämtning från databasen: {err}"}, 500

    @teacher_ns.doc("update_teacher")
    @teacher_ns.expect(teacher_update_model)
    @teacher_ns.response(404, "Lärare hittades inte.")
    def put(self, teacher_id):
        """Uppdatera en lärare."""
        data = request.json
        updates = []
        params = []

        if "firstName" in data:
            updates.append("firstName = %s")
            params.append(data["firstName"])
        if "lastName" in data:
            updates.append("lastName = %s")
            params.append(data["lastName"])
        if "email" in data:
            updates.append("email = %s")
            params.append(data["email"])
        if "department" in data:
            updates.append("department = %s")
            params.append(data["department"])

        if not updates:
            return {"message": "Inga uppdateringsfält angivna."}, 400

        db = get_db()
        if not db:
            return {"error": "Kunde inte ansluta till databasen"}, 503

        try:
            cursor = db.cursor()
            query = f"UPDATE Teacher SET {', '.join(updates)} WHERE id = %s"
            params.append(teacher_id)
            cursor.execute(query, params)
            rows_affected = cursor.rowcount

            if rows_affected == 0:
                db.rollback()
                cursor.close()
                return {"message": "Lärare hittades inte."}, 404

            db.commit()
            cursor.close()
            return {"message": "Lärare uppdaterad."}, 200

        except mysql.connector.IntegrityError as err:
            db.rollback()
            cursor.close()
            return {
                "error": f"Uppdatering misslyckades: Email existerar redan. Detaljer: {err}"
            }, 409
        except mysql.connector.Error as err:
            db.rollback()
            cursor.close()
            return {"error": f"Fel vid uppdatering i databasen: {err}"}, 500

    @teacher_ns.doc("delete_teacher")
    @teacher_ns.response(204, "Lärare raderad framgångsrikt.")
    @teacher_ns.response(409, "Läraren är ansvarig för kurser och kan inte raderas.")
    def delete(self, teacher_id):
        """Radera en specifik lärare."""
        db = get_db()
        if not db:
            return {"error": "Kunde inte ansluta till databasen"}, 503

        try:
            cursor = db.cursor()
            cursor.execute("DELETE FROM Teacher WHERE id = %s", (teacher_id,))
            rows_deleted = cursor.rowcount
            db.commit()
            cursor.close()

            if rows_deleted == 0:
                return {"message": "Lärare hittades inte."}, 404

            return "", 204
        except mysql.connector.IntegrityError as err:
            db.rollback()
            return {
                "error": f"Läraren kan inte raderas: Den är ansvarig för en eller flera kurser (Foreign Key-brott). Detaljer: {err}"
            }, 409
        except mysql.connector.Error as err:
            db.rollback()
            return {"error": f"Fel vid radering i databasen: {err}"}, 500


# ----------------------------------------------------
# 7. API-Resurser: Course (Inklusive Batch Query)
# ----------------------------------------------------


@course_ns.route("/")
class CourseList(Resource):
    @course_ns.doc("list_courses")
    def get(self):
        """Hämta alla kurser."""
        db = get_db()
        if not db:
            return {"error": "Kunde inte ansluta till databasen"}, 503

        try:
            cursor = db.cursor(dictionary=True)
            cursor.execute("SELECT * FROM Course")
            courses = cursor.fetchall()
            cursor.close()
            return courses, 200
        except mysql.connector.Error as err:
            return {"error": f"Fel vid hämtning från databasen: {err}"}, 500

    @course_ns.doc("create_course")
    @course_ns.expect(course_model)
    def post(self):
        """Skapa en ny kurs."""
        data = request.json
        code = data.get("code")
        name = data.get("name")
        credits = data.get("credits")
        responsibleTeacherId = data.get("responsibleTeacherId")

        if not all([code, name, credits, responsibleTeacherId]):
            return {"message": "Alla obligatoriska fält måste anges."}, 400

        db = get_db()
        if not db:
            return {"error": "Kunde inte ansluta till databasen"}, 503

        try:
            cursor = db.cursor()
            query = """
                INSERT INTO Course (code, name, credits, responsibleTeacherId)
                VALUES (%s, %s, %s, %s)
            """
            cursor.execute(query, (code, name, credits, responsibleTeacherId))
            db.commit()
            cursor.close()
            return {"message": "Kurs skapad.", "code": code}, 201
        except mysql.connector.IntegrityError as err:
            db.rollback()
            return {
                "error": f"Kurs misslyckades: Kurskod existerar redan eller ogiltig ansvarig lärare. Detaljer: {err}"
            }, 409
        except mysql.connector.Error as err:
            db.rollback()
            return {"error": f"Fel vid insättning i databasen: {err}"}, 500


@course_ns.route("/<string:course_code>")
@course_ns.param("course_code", "Kursens unika kod")
class Course(Resource):
    @course_ns.doc("get_course")
    @course_ns.response(404, "Kurs hittades inte.")
    def get(self, course_code):
        """Hämta en specifik kurs."""
        db = get_db()
        if not db:
            return {"error": "Kunde inte ansluta till databasen"}, 503

        try:
            cursor = db.cursor(dictionary=True)
            cursor.execute("SELECT * FROM Course WHERE code = %s", (course_code,))
            course = cursor.fetchone()
            cursor.close()

            if course is None:
                return {"message": "Kurs hittades inte."}, 404

            return course, 200
        except mysql.connector.Error as err:
            return {"error": f"Fel vid hämtning från databasen: {err}"}, 500

    @course_ns.doc("update_course")
    @course_ns.expect(course_update_model)
    @course_ns.response(404, "Kurs hittades inte.")
    def put(self, course_code):
        """Uppdatera en kurs."""
        data = request.json
        updates = []
        params = []

        if "name" in data:
            updates.append("name = %s")
            params.append(data["name"])
        if "credits" in data:
            updates.append("credits = %s")
            params.append(data["credits"])
        if "responsibleTeacherId" in data:
            updates.append("responsibleTeacherId = %s")
            params.append(data["responsibleTeacherId"])

        if not updates:
            return {"message": "Inga uppdateringsfält angivna."}, 400

        db = get_db()
        if not db:
            return {"error": "Kunde inte ansluta till databasen"}, 503

        try:
            cursor = db.cursor()
            query = f"UPDATE Course SET {', '.join(updates)} WHERE code = %s"
            params.append(course_code)
            cursor.execute(query, params)
            rows_affected = cursor.rowcount

            if rows_affected == 0:
                db.rollback()
                cursor.close()
                return {"message": "Kurs hittades inte."}, 404

            db.commit()
            cursor.close()
            return {"message": "Kurs uppdaterad."}, 200

        except mysql.connector.IntegrityError as err:
            db.rollback()
            cursor.close()
            return {
                "error": f"Uppdatering misslyckades: Ogiltig ansvarig lärare. Detaljer: {err}"
            }, 409
        except mysql.connector.Error as err:
            db.rollback()
            cursor.close()
            return {"error": f"Fel vid uppdatering i databasen: {err}"}, 500

    @course_ns.doc("delete_course")
    @course_ns.response(204, "Kurs raderad framgångsrikt.")
    @course_ns.response(409, "Kursen har studenter registrerade och kan inte raderas.")
    def delete(self, course_code):
        """Radera en specifik kurs."""
        db = get_db()
        if not db:
            return {"error": "Kunde inte ansluta till databasen"}, 503

        try:
            cursor = db.cursor()
            cursor.execute("DELETE FROM Course WHERE code = %s", (course_code,))
            rows_deleted = cursor.rowcount
            db.commit()
            cursor.close()

            if rows_deleted == 0:
                return {"message": "Kurs hittades inte."}, 404

            return "", 204
        except mysql.connector.IntegrityError as err:
            db.rollback()
            return {
                "error": f"Kursen kan inte raderas: Den har studenter registrerade (Foreign Key-brott). Detaljer: {err}"
            }, 409
        except mysql.connector.Error as err:
            db.rollback()
            return {"error": f"Fel vid radering i databasen: {err}"}, 500


# NY RESURS: Exekverar komplex SELECT-fråga (Batch Query)
@course_ns.route("/enrollment_counts")
class CourseEnrollmentCounts(Resource):
    @course_ns.doc("get_enrollment_counts")
    @course_ns.response(200, "Framgångsrik")
    def get(self):
        """Hämta en lista över alla kurser och antalet inskrivna studenter i varje kurs (Fråga 10 från queries.sql)."""
        db = get_db()
        if not db:
            return {"error": "Kunde inte ansluta till databasen"}, 503

        query = """
            SELECT
                C.code,
                C.name,
                COUNT(SE.studentId) AS EnrolledStudents
            FROM
                Course AS C
                LEFT JOIN StudentEnrollment AS SE ON C.code = SE.courseCode
            GROUP BY
                C.code,
                C.name
            ORDER BY
                EnrolledStudents DESC;
        """

        try:
            # Använd dictionary-cursor för att få resultat med kolumnnamn
            cursor = db.cursor(dictionary=True)
            cursor.execute(query)
            courses = cursor.fetchall()
            cursor.close()

            return courses, 200

        except mysql.connector.Error as err:
            return {"error": f"Fel vid hämtning av kursstatistik: {err}"}, 500


# ----------------------------------------------------
# 8. API-Resurser: StudentEnrollment (Inklusive Stored Procedure)
# ----------------------------------------------------


@enrollment_ns.route("/")
class EnrollmentList(Resource):
    @enrollment_ns.doc("list_enrollments")
    def get(self):
        """Hämta alla registreringar."""
        db = get_db()
        if not db:
            return {"error": "Kunde inte ansluta till databasen"}, 503

        try:
            # Använd dictionary-cursor för att få resultat med kolumnnamn
            cursor = db.cursor(dictionary=True)
            cursor.execute("SELECT * FROM StudentEnrollment")
            enrollments = cursor.fetchall()
            cursor.close()
            return enrollments, 200
        except mysql.connector.Error as err:
            return {"error": f"Fel vid hämtning från databasen: {err}"}, 500

    @enrollment_ns.doc("create_enrollment")
    @enrollment_ns.expect(enrollment_model)
    @enrollment_ns.response(201, "Registrering skapad framgångsrikt.")
    @enrollment_ns.response(400, "Ogiltiga indata eller saknade ID/kurskod.")
    def post(self):
        """Skapa en ny registrering."""
        data = request.json
        student_id = data.get("studentId")
        course_code = data.get("courseCode")
        grade = data.get("grade")
        completion_date = data.get("completionDate")

        if not student_id or not course_code:
            return {"message": "Både studentId och courseCode måste anges."}, 400

        db = get_db()
        if not db:
            return {"error": "Kunde inte ansluta till databasen"}, 503

        try:
            cursor = db.cursor()
            query = """
                INSERT INTO StudentEnrollment (studentId, courseCode, grade, completionDate)
                VALUES (%s, %s, %s, %s)
            """
            cursor.execute(query, (student_id, course_code, grade, completion_date))
            db.commit()
            cursor.close()
            return {"message": "Registrering skapad."}, 201
        except mysql.connector.IntegrityError as err:
            db.rollback()
            return {
                "error": f"Registrering misslyckades: Duplicerat ID/Kurskod eller ogiltig student/kurs. Detaljer: {err}"
            }, 409
        except mysql.connector.Error as err:
            db.rollback()
            return {"error": f"Fel vid insättning i databasen: {err}"}, 500


@enrollment_ns.route("/<int:student_id>/<string:course_code>")
@enrollment_ns.param("student_id", "Studentens unika ID")
@enrollment_ns.param("course_code", "Kursens kod")
class Enrollment(Resource):
    @enrollment_ns.doc("get_enrollment")
    @enrollment_ns.response(404, "Registrering hittades inte.")
    def get(self, student_id, course_code):
        """Hämta en specifik registrering."""
        db = get_db()
        if not db:
            return {"error": "Kunde inte ansluta till databasen"}, 503

        try:
            cursor = db.cursor(dictionary=True)
            cursor.execute(
                "SELECT * FROM StudentEnrollment WHERE studentId = %s AND courseCode = %s",
                (student_id, course_code),
            )
            enrollment = cursor.fetchone()
            cursor.close()

            if enrollment is None:
                return {"message": "Registrering hittades inte."}, 404

            return enrollment, 200
        except mysql.connector.Error as err:
            return {"error": f"Fel vid hämtning från databasen: {err}"}, 500

    @enrollment_ns.doc("update_enrollment")
    @enrollment_ns.expect(enrollment_update_model)
    @enrollment_ns.response(200, "Registrering uppdaterad framgångsrikt.")
    @enrollment_ns.response(404, "Registrering hittades inte.")
    def put(self, student_id, course_code):
        """Uppdatera betyg och/eller slutförandedatum för en registrering."""
        data = request.json
        updates = []
        params = []

        if "grade" in data:
            updates.append("grade = %s")
            params.append(data["grade"])
        if "completionDate" in data:
            # Validera datumformat, t.ex. YYYY-MM-DD
            try:
                datetime.strptime(data["completionDate"], "%Y-%m-%d")
                updates.append("completionDate = %s")
                params.append(data["completionDate"])
            except ValueError:
                return {"error": "completionDate måste vara i formatet YYYY-MM-DD"}, 400

        if not updates:
            return {"message": "Inga uppdateringsfält angivna."}, 400

        db = get_db()
        if not db:
            return {"error": "Kunde inte ansluta till databasen"}, 503

        try:
            cursor = db.cursor()
            query = f"UPDATE StudentEnrollment SET {', '.join(updates)} WHERE studentId = %s AND courseCode = %s"
            params.extend([student_id, course_code])
            cursor.execute(query, params)
            rows_affected = cursor.rowcount

            if rows_affected == 0:
                db.rollback()
                cursor.close()
                return {"message": "Registrering hittades inte."}, 404

            db.commit()
            cursor.close()
            return {"message": "Registrering uppdaterad."}, 200

        except mysql.connector.Error as err:
            db.rollback()
            cursor.close()
            return {"error": f"Fel vid uppdatering i databasen: {err}"}, 500

    @enrollment_ns.doc("delete_enrollment")
    @enrollment_ns.response(204, "Registrering raderad framgångsrikt.")
    def delete(self, student_id, course_code):
        """Radera en specifik registrering."""
        db = get_db()
        if not db:
            return {"error": "Kunde inte ansluta till databasen"}, 503

        try:
            cursor = db.cursor()
            cursor.execute(
                "DELETE FROM StudentEnrollment WHERE studentId = %s AND courseCode = %s",
                (student_id, course_code),
            )
            rows_deleted = cursor.rowcount
            db.commit()
            cursor.close()

            if rows_deleted == 0:
                return {"message": "Registrering hittades inte."}, 404

            return "", 204
        except mysql.connector.Error as err:
            db.rollback()
            return {"error": f"Fel vid radering i databasen: {err}"}, 500


# NY RESURS: Anropar den lagrade proceduren RegisterStudentToCourse
@enrollment_ns.route("/register")
class EnrollmentRegister(Resource):
    @enrollment_ns.doc("register_student_to_course")
    @enrollment_ns.expect(register_model)
    @enrollment_ns.response(201, "Student registrerad på kursen.")
    @enrollment_ns.response(
        409, "Registreringen existerar redan eller student/kurs är ogiltig."
    )
    @enrollment_ns.response(400, "Ogiltiga indata eller saknade ID/kurskod.")
    def post(self):
        """Registrerar en student på en kurs med hjälp av en Stored Procedure (RegisterStudentToCourse)."""
        data = request.json
        student_id = data.get("studentId")
        course_code = data.get("courseCode")

        if not student_id or not course_code:
            return {"message": "Både studentId och courseCode måste anges."}, 400

        db = get_db()
        if not db:
            return {"error": "Kunde inte ansluta till databasen"}, 503

        try:
            cursor = db.cursor()
            # Anropa den lagrade proceduren. Parametrarna skickas som en tuple.
            # OBS: Proceduren måste vara skapad i databasen (t.ex. genom att köra queries.sql)
            cursor.callproc("RegisterStudentToCourse", (student_id, course_code))

            db.commit()
            cursor.close()
            return {
                "message": f"Student {student_id} registrerad på kurs {course_code}."
            }, 201

        except mysql.connector.IntegrityError as err:
            # Fångar fel vid dublettnyckel eller FK-brott (ogiltig student/kurs)
            db.rollback()
            return {
                "error": f"Registrering misslyckades: Studenten är redan registrerad på kursen eller så existerar inte student/kurs. Detaljer: {err}"
            }, 409
        except mysql.connector.Error as err:
            db.rollback()
            return {"error": f"Fel vid anrop av stored procedure: {err}"}, 500


# ----------------------------------------------------
# 9. Main
# ----------------------------------------------------


# Lägger till en dummy route för att visa att appen körs
@app.route("/")
def index():
    return "API Running - Se /apidocs för dokumentation (Swagger UI)."


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
