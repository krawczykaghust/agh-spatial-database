CREATE EXTENSION postgis;

-- 4. Wyznacz liczbę budynków (tabela: popp, atrybut: f_codedesc, reprezentowane, jako punkty)
-- położonych w odległości mniejszej niż 1000 m od głównych rzek. Budynki spełniające to
-- kryterium zapisz do osobnej tabeli tableB.

	
CREATE TABLE tableB AS
	SELECT 
		COUNT(DISTINCT p.gid) as number_of_buildings 
	FROM
		popp as p,
		majrivers as r
	WHERE p.f_codedesc = 'Building' and
	ST_DISTANCE(p.geom, r.geom) < 1000
	
SELECT * FROM tableB;
-- DROP TABLE tableB;

-- 5. Utwórz tabelę o nazwie airportsNew. Z tabeli airports do zaimportuj nazwy lotnisk, ich
-- geometrię, a także atrybut elev, reprezentujący wysokość n.p.m.

-- a) Znajdź lotnisko, które położone jest najbardziej na zachód i najbardziej na wschód.
-- b) Do tabeli airportsNew dodaj nowy obiekt - lotnisko, które położone jest w punkcie
-- środkowym drogi pomiędzy lotniskami znalezionymi w punkcie a. Lotnisko nazwij airportB.

-- Wysokość n.p.m. przyjmij dowolną.
-- Uwaga: geodezyjny układ współrzędnych prostokątnych płaskich (x – oś pionowa, y – oś
-- pozioma)

-- Tworzenie tabeli

CREATE TABLE airportsNew AS
	SELECT name, geom, elev
	FROM airports
	
SELECT * FROM airportsNew
		
-- a) Znajdź lotnisko, które położone jest najbardziej na zachód i najbardziej na wschód.
 	
SELECT * FROM airportsNew as ap
WHERE ST_X(ap.geom) = (SELECT MAX(ST_X(a.geom)) FROM airportsNew as a)
OR ST_X(ap.geom) = (SELECT MIN(ST_X(a.geom)) FROM airportsNew as a)

-- b) Do tabeli airportsNew dodaj nowy obiekt - lotnisko, które położone jest w punkcie
-- środkowym drogi pomiędzy lotniskami znalezionymi w punkcie a. Lotnisko nazwij airportB.

INSERT INTO airportsNew VALUES(
	'airportB', (SELECT ST_Centroid(ST_ShortestLine((SELECT a.geom FROM airportsNew as a WHERE a.name = 'ATKA'), (SELECT a.geom FROM airportsNew as a WHERE a.name = 'ANNETTE ISLAND')))), 32);

SELECT * FROM airportsNew;


-- 6. Wyznacz pole powierzchni obszaru, który oddalony jest mniej niż 1000 jednostek od najkrótszej
-- linii łączącej jezioro o nazwie ‘Iliamna Lake’ i lotnisko o nazwie „AMBLER”


SELECT
	ST_Area(ST_Buffer(ST_SHORTESTLINE(a.geom, l.geom), 1000)) as AREA
FROM airportsNew as a, lakes as l
WHERE
	l.names = 'Iliamna Lake' and
	a.name = 'AMBLER'


-- 7. Napisz zapytanie, które zwróci sumaryczne pole powierzchni poligonów reprezentujących
-- poszczególne typy drzew znajdujących się na obszarze tundry i bagien (swamps).


SELECT
	t.vegdesc,
	SUM(t.area_km2)
FROM trees as t, tundra as tu, swamp as s
WHERE
	ST_Contains(t.geom, tu.geom) OR
	ST_Contains(t.geom, s.geom)
GROUP BY t.vegdesc


	

