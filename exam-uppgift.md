# Kursportal (Universitet)

## Domän 

Ett system för studenter som registrerar sig på kurser.

## Tabeller
Studenter, Kurser, Lärare, StudentPrestationer (kopplingstabell).


### Studenter
student_id (Primary Key, PK)
fornamn
efternamn
personnummer(Ska vara UNIQUE för där ska inte finnas dubbletter)
epost (Bör vara UNIQUE för att undvika dubbletter) 
registrerad_datum (Bra för DATE-funktioner)

