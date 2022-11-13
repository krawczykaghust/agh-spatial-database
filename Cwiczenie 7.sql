CREATE EXTENSION postgis;

-- 1. Utwórz tabelę obiekty. W tabeli umieść nazwy i geometrie obiektów przedstawionych poniżej. Układ odniesienia
-- ustal jako niezdefiniowany. Definicja geometrii powinna odbyć się za pomocą typów złożonych, właściwych dla EWKT.


CREATE TABLE obiekty (
	id INT PRIMARY KEY,
	nazwa VARCHAR(80),
	geom GEOMETRY
);

TRUNCATE TABLE obiekty

-- Obiekt 1.

-- 	INSERT INTO obiekty VALUES(
-- 	1, 'obiekt1', ST_Collect(ARRAY[ST_GeomFromEWKT('LINESTRING(0 1, 1 1)'), ST_GeomFromEWKT('CIRCULARSTRING(1 1, 2 0, 3 1)'), ST_GeomFromEWKT('CIRCULARSTRING(3 1, 4 2, 5 1)'), ST_GeomFromEWKT('LINESTRING(5 1, 6 1)')])
-- );

INSERT INTO obiekty VALUES(
	1, 'obiekt1', ST_GeomFromEWKT('COMPOUNDCURVE((0 1, 1 1), CIRCULARSTRING(1 1, 2 0, 3 1), CIRCULARSTRING(3 1, 4 2, 5 1), (5 1, 6 1))')
);	

-- Obiekt 2.

-- The CIRCULARSTRING is the basic curve type, similar to a LINESTRING in the linear world. A single segment required three points, the start and end points (first and third) and any other point on the arc. The exception to this is for a closed circle, where the start and end points are the same. In this case the second point MUST be the center of the arc, ie the opposite side of the circle. To chain arcs together, the last point of the previous arc becomes the first point of the next arc, just like in LINESTRING. This means that a valid circular string must have an odd number of points greated than 1.

-- INSERT INTO obiekty VALUES(
--	2, 'obiekt2', ST_Collect(ARRAY[ST_GeomFromEWKT('LINESTRING(10 6, 14 6)'), ST_GeomFromEWKT('CIRCULARSTRING(14 6, 16 4, 14 2)'), ST_GeomFromEWKT('CIRCULARSTRING(14 2, 12 0, 10 2)'), ST_GeomFromEWKT('LINESTRING(10 2, 10 6)'), ST_GeomFromEWKT('CIRCULARSTRING(11 2, 13 2, 11 2)'), ST_GeomFromEWKT('CIRCULARSTRING(13 2, 11 2, 13 2)')])
-- );

INSERT INTO obiekty VALUES(
	2, 'obiekt2', ST_GeomFromEWKT('CURVEPOLYGON(COMPOUNDCURVE((10 6, 14 6), CIRCULARSTRING(14 6, 16 4, 14 2), CIRCULARSTRING(14 2, 12 0, 10 2), (10 2, 10 6)), CIRCULARSTRING(11 2, 13 2, 11 2), CIRCULARSTRING(13 2, 11 2, 13 2) )')
);	

-- Obiekt 3.

INSERT INTO obiekty VALUES(
	3, 'obiekt3', ST_GeomFromEWKT('COMPOUNDCURVE((7 15, 10 17, 12 13, 7 15))')
);	


-- INSERT INTO obiekty VALUES(
--	3, 'obiekt3', ST_Collect(ARRAY[ST_GeomFromEWKT('LINESTRING(7 15, 12 13, 10 17, 7 15)')])
-- );


-- Obiekt 4.

INSERT INTO obiekty VALUES(
	4, 'obiekt4', ST_GeomFromEWKT('COMPOUNDCURVE((20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5))')
);	


-- Obiekt 5.

INSERT INTO obiekty VALUES(
	5, 'obiekt5', ST_GeomFromEWKT('MULTIPOINT Z(30 30 59, 38 32 234)')
);


-- INSERT INTO obiekty VALUES(
--	5, 'obiekt5', ST_Collect(ARRAY[ST_GeomFromEWKT('POINT Z (30 30 59)'), ST_GeomFromEWKT('POINT Z (38 32 234)')])
-- );

-- Obiekt 6.


INSERT INTO obiekty VALUES(
	6, 'obiekt6', ST_Collect(ST_GeomFromEWKT('POINT(4 2)'), ST_GeomFromEWKT('LINESTRING(1 1, 3 2)'))
);

-- 1. Wyznacz pole powierzchni bufora o wielkości 5 jednostek, który został utworzony wokół najkrótszej linii łączącej
-- obiekt 3 i 4.

SELECT
	ST_Area(ST_Buffer(ST_ShortestLine(obiekt3.geom, obiekt4.geom), 5))
FROM obiekty AS obiekt3, obiekty AS obiekt4
WHERE
	obiekt3.id = 3 AND
	obiekt4.id = 4;

-- 2. Zamień obiekt4 na poligon. Jaki warunek musi być spełniony, aby można było wykonać to zadanie? Zapewnij te
-- warunki.

-- Condition: input geometries must be closed LineStrings (rings).

SELECT
	ST_MakePolygon(ST_AddPoint(ST_CurveToLine(geom), ST_StartPoint(geom)))
FROM obiekty
WHERE
	obiekty.id = 4
	
-- 3. W tabeli obiekty, jako obiekt7 zapisz obiekt złożony z obiektu 3 i obiektu 4.

INSERT INTO obiekty VALUES(
	7, 'obiekt7', (SELECT ST_Union(obiekt3.geom, obiekt4.geom) FROM obiekty AS obiekt3, obiekty AS obiekt4 WHERE obiekt3.id = 3 AND obiekt4.id = 4)
);

SELECT * from obiekty

-- 4. Wyznacz pole powierzchni wszystkich buforów o wielkości 5 jednostek, które zostały utworzone wokół obiektów nie
-- zawierających łuków.

SELECT
	ST_Area(ST_Buffer(geom, 5))
FROM obiekty
WHERE 
	ST_HasArc(geom) = false	


