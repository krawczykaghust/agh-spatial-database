-- 1. Ładowanie postgis 

CREATE EXTENSION postgis;

-- 2. Tworzenie tabeli Drogi

CREATE TABLE roads(id INT, name VARCHAR(30), geom GEOMETRY);

-- Dodawanie elementow

INSERT INTO roads VALUES
-- a. RoadX
(0, 'RoadX', ST_GeomFromText('LINESTRING(0 4.5, 12 4.5)', 0)),
-- b. RoadY
(1, 'RoadY', ST_GeomFromText('LINESTRING(7.5 0, 7.5 10.5)', 0));

SELECT * FROM roads;

-- 3. Tworzenie tabeli Pktinfo
CREATE TABLE points(id INT, name CHAR(1), geom GEOMETRY);

-- Dodawanie elementow
INSERT INTO points VALUES
-- a. G
(1, 'G', ST_GeomFromText('POINT(1 3.5)', 0)),
-- b. H
(2, 'H', ST_GeomFromText('POINT(5.5 1.5)', 0)),
-- c. I 
(3, 'I', ST_GeomFromText('POINT(9.5 6)', 0)),
-- d. J
(4, 'J', ST_GeomFromText('POINT(6.5 6)', 0)),
-- e. K
(5, 'K', ST_GeomFromText('POINT(6 9.5)', 0));

SELECT * FROM POINTS

-- 4. Tworzenie tabeli Budynki
CREATE TABLE buildings(id INT, name CHAR(9), geom GEOMETRY);

-- Dodawanie elementow
INSERT INTO buildings VALUES
-- a. Building A
(1, 'BuildingA', ST_GeomFromText('POLYGON((8 1.5, 10.5 1.5, 10.5 4, 8 4, 8 1.5))', 0)),
-- b. Building B
(2, 'BuildingB', ST_GeomFromText('POLYGON((4 5, 6 5, 6 7, 4 7, 4 5))', 0)),
-- c. Building C
(3, 'BuildingC', ST_GeomFromText('POLYGON((3 6, 5 6, 5 8, 3 8, 3 6))', 0)),
-- d. Building D
(4, 'BuildingD', ST_GeomFromText('POLYGON((9 8, 10 8, 10 9, 9 9, 9 8))', 0)),
-- e. Building F
(5, 'BuildingF', ST_GeomFromText('POLYGON((1 1, 2 1, 2 2, 1 2, 1 1))', 0));
-- ZADANIA

SELECT * FROM buildings;

-- 1. Wyznacz całkowitą długość dróg w analizowanym mieście.
SELECT
	SUM(ST_LENGTH(geom)) AS Len
FROM roads;

-- 2. Wypisz geometrię (WKT), pole powierzchni oraz obwód poligonu reprezentującego BuildingA.
SELECT
	geom AS WKT_Geometry,
	ST_AREA(geom) AS Area,
	ST_Perimeter(geom) AS Perimeter
FROM buildings
WHERE name = 'BuildingA';

-- 3. Wypisz nazwy i pola powierzchni wszystkich poligonów w warstwie budynki. Wyniki posortuj alfabetycznie.
SELECT
	name,
	ST_AREA(geom) AS Area
FROM buildings
ORDER BY name;

-- 4. Wypisz nazwy i obwody 2 budynków o największej powierzchni.
SELECT
	name,
	ST_PERIMETER(geom) AS Perimeter
FROM buildings
ORDER BY ST_AREA(geom) DESC
LIMIT 2;

-- 5. Wyznacz najkrótszą odległość między budynkiem BuildingC a punktem G
SELECT
	ST_DISTANCE(p.geom, b.geom)
FROM
	points as p,
	buildings as b
WHERE
	p.name = 'G' AND
	b.name = 'BuildingC'


-- 6. Wypisz pole powierzchni tej części budynku BuildingC, która znajduje się w odległości większej niż 0.5 od budynku BuildingB.
SELECT
	ST_Area(ST_Difference(buildings_c.geom, ST_BUFFER(buildings_b.geom, 0.5))) AS Area
FROM
	buildings as buildings_b, buildings as buildings_c
WHERE buildings_b.name = 'BuildingB' AND
	buildings_c.name = 'BuildingC';

-- 7. Wybierz te budynki, których centroid (ST_Centroid) znajduje się powyżej drogi RoadX.
SELECT
	b.name,
	b.geom
FROM buildings AS b, roads AS r
WHERE ST_Y(ST_CENTROID(b.geom)) > ST_Y(ST_CENTROID(r.geom)) AND
r.name = 'RoadX';


-- 8. Oblicz pole powierzchni tych części budynku BuildingC i poligonu o współrzędnych (4 7, 6 7, 6 8, 4 8, 4 7), które nie są wspólne dla tych dwóch obiektów
SELECT
	ST_Area(ST_SymDifference(buildings_c.geom, ST_PolygonFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))', 0))) AS Area
FROM buildings as buildings_c
WHERE buildings_c.name = 'BuildingC'
