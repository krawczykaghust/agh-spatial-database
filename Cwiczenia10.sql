CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;

-- 2. Załaduj te dane do tabeli o nazwie uk_250k

SELECT * FROM rasters.uk_250k;

-- a. Dodanie serial primary key

ALTER TABLE rasters.uk_250k
ADD COLUMN rid SERIAL PRIMARY KEY;

-- b. Utworzenie indeksu przestrzennego

CREATE INDEX idx_uk_250k ON rasters.uk_250k
USING gist (ST_ConvexHull(rast));

-- c. Dodanie raster constraints

SELECT AddRasterConstraints('rasters'::name,
'uk_250k'::name,'rast'::name);


-- 3. Połącz te dane (wszystkie kafle) w mozaikę, a następnie wyeksportuj jako GeoTIFF. 

CREATE TABLE rasters.uk_250k_mosaic AS
SELECT ST_Union(r.rast)
FROM rasters.uk_250k AS r

CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
       ST_AsGDALRaster(ST_Union(rast), 'GTiff',  ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
        ) AS loid
FROM rasters.uk_250k_mosaic;

-- Zapisywanie pliku na dysku 

SELECT lo_export(loid, 'C:/Kacper/Studia Semestr 5/Bazy Danych Przestrzennych/Cwiczenia/Cwiczenia 7/uk_250k_mosaic.tif')
FROM tmp_out;

-- Usuwanie obiektu

SELECT lo_unlink(loid)
FROM tmp_out;

DROP TABLE tmp_out;

-- 5. Załaduj do bazy danych tabelę reprezentującą granice parków narodowych. (Wczytanie danych GeoPackage do QGIS - Wyeksportowanie sqldump dla National Parks - Wczytanie do Postgres)

SELECT * FROM vectors.uk_national_parks;

-- 6. Utwórz nową tabelę o nazwie uk_lake_district, do której zaimportujesz mapy rastrowe z punktu 1., które zostaną przycięte do granic parku narodowego Lake District. 

CREATE TABLE rasters.uk_lake_district AS
SELECT r.rid, ST_Clip(r.rast, u.wkb_geometry, true) AS rast, u.id
FROM rasters.uk_250k AS r, vectors.uk_national_parks AS u
WHERE ST_Intersects(r.rast, u.wkb_geometry) AND u.id = 1;

SELECT UpdateRasterSRID('rasters','uk_lake_district','rast',27700);

DROP TABLE rasters.uk_lake_district

-- 7. Wyeksportuj wyniki do pliku GeoTIFF.

CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
       ST_AsGDALRaster(ST_Union(rast), 'GTiff',  ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
        ) AS loid
FROM rasters.uk_lake_district;

-- Zapisywanie pliku na dysku 

SELECT lo_export(loid, 'C:/Kacper/Studia Semestr 5/Bazy Danych Przestrzennych/Cwiczenia/Cwiczenia 7/lake_district.tif')
FROM tmp_out;

-- Usuwanie obiektu

SELECT lo_unlink(loid)
FROM tmp_out;

DROP TABLE tmp_out;


-- 8. Pobierz dane z satelity Sentinel-2 wykorzystując portal: https://scihub.copernicus.eu. Wybierz dowolne zobrazowanie, które pokryje teren parku Lake District oraz gdzie parametr cloud coverage będzie poniżej 20%. 
-- 9. Załaduj dane z Sentinela-2 do bazy danych. (raster2pgsql)

SELECT * FROM rasters.sentinel2

DROP TABLE rasters.sentinel2

-- 10. Policz indeks NDWI oraz przytnij wyniki do granic Lake District

DROP TABLE rasters.sentinel2_ndvi

SELECT * FROM rasters.sentinel2_ndvi

CREATE TABLE rasters.sentinel2_ndvi AS
WITH r AS (
	SELECT r.rid, r.rast AS rast
	FROM rasters.sentinel2 AS r
)
SELECT
	r.rid, ST_MapAlgebra(
		r.rast, 8,
		r.rast, 4,
		'([rast2.val] - [rast1.val]) / ([rast2.val] + [rast1.val])::float','32BF'
	) AS rast
FROM r;

-- a. Dodanie serial primary key

ALTER TABLE rasters.sentinel2_ndvi
ADD COLUMN rid SERIAL PRIMARY KEY;

-- b. Utworzenie indeksu przestrzennego

CREATE INDEX idx_sentinel2_ndvi ON rasters.sentinel2_ndvi
USING gist (ST_ConvexHull(rast));

-- c. Dodanie raster constraints

SELECT AddRasterConstraints('rasters'::name,
'sentinel2_ndvi'::name,'rast'::name);

-- 11. Wyeksportuj obliczony i przycięty wskaźnik NDWI do GeoTIFF.

CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
       ST_AsGDALRaster(ST_Union(rast), 'GTiff',  ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
        ) AS loid
FROM rasters.sentinel2_ndvi;

-- Zapisywanie pliku na dysku 

SELECT lo_export(loid, 'C:/Kacper/Studia Semestr 5/Bazy Danych Przestrzennych/Cwiczenia/Cwiczenia 7/lake_district_ndvi.tif')
FROM tmp_out;

-- Usuwanie obiektu

SELECT lo_unlink(loid)
FROM tmp_out;

DROP TABLE tmp_out;