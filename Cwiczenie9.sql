-- I. Ładowanie danych rastrowych

-- Przykład 1 – ładowanie rastru przy użyciu pliku .sql

SELECT * FROM rasters.dem;

-- Przykład 3 – załadowanie danych landsat 8 o wielkości kafelka 128x128 przy użyciu pliku .sql

SELECT * from rasters.landsat8

-- Sprawdź strukturę oraz zawartość widoku public.raster_columns.

SELECT * FROM public.raster_columns

-- II. Tworzenie rastrów z istniejących rastrów i interakcja z wektorami

-- Przykład 1 - ST_Intersects - wydorębnienie kafelki nakładające się na geometrię (dane parafii z okolic Porto w Portugalii)

CREATE TABLE krawczyk.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

-- Czynności sugerowane do wykonania podczas tworzenia tabeli z danymi rastrowymi

-- a. Dodanie serial primary key

ALTER TABLE krawczyk.intersects
ADD COLUMN rid SERIAL PRIMARY KEY;

-- b. Utworzenie indeksu przestrzennego

CREATE INDEX idx_intersects_rast_gist ON krawczyk.intersects
USING gist (ST_ConvexHull(rast));

-- c. Dodanie raster constraints

SELECT AddRasterConstraints('rasters'::name, 'intersects'::name, 'rast'::name);

-- Przykład 2 - ST_Clip - obcinanie rastra na podstawie wektora

CREATE TABLE krawczyk.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';


-- Przykład 3 - ST_Union - połączenie wielu kafelków w jeden raster

CREATE TABLE krawczyk.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);

-- ST_Union pozwala na operacje na naładających się rastrach opartych na danej funkcji agregującej f.e. FIRST LAST SUM COUNT MEAN lub RANGE 
-- (jeśli mamy wiele rastrów z danymi o opadach atmosferycznych i potrzebujemy średniej wartości, możemy użyć st_union lub map_algebra)

-- III. Tworzenie rastrów z wektorów (rastrowanie)

-- Przykład 1 - ST_AsRaster - rastrowanie tabeli z parafiami o takiej samej charakterystyce przestrzennej tj. wielkosci piksela, zakresy etc.

CREATE TABLE krawczyk.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

-- Przykładowe zapytanie używa piksela typu '8BUI' tworząc 8-bitową nieoznaczoną liczbę całkowitą (8-
-- bit unsigned integer). Unsigned integer może reprezentować tylko nieujemne liczby całkowite; signed
-- integer mogą również reprezentować liczby całkowite ujemne. Aby uzyskać więcej informacji o
-- typach rastrowych PostGIS

-- Wynikowy raster z poprzedniego zadania to jedna parafia na rekord, na wiersz tabeli. Użyj QGIS lub
-- ArcGIS do wizualizacji wyników.

-- Przykład 2 - ST_Union

-- Drugi przykład łączy rekordy z poprzedniego przykładu przy użyciu funkcji ST_UNION w pojedynczy
-- raster.

DROP TABLE krawczyk.porto_parishes; --> drop table porto_parishes first
CREATE TABLE krawczyk.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

-- Przykład 3 - ST_Tile

-- Po uzyskaniu pojedynczego rastra można generować kafelki za pomocą funkcji ST_Tile

DROP TABLE krawczyk.porto_parishes; --> drop table porto_parishes first
CREATE TABLE krawczyk.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1 )
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-
32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

-- IV. Konwertowanie rastrów na wektory (wektoryzowanie)

-- Poniższe przykłady użycia funkcji ST_Intersection i ST_DumpAsPolygons pokazują konwersję rasterów na wektory

-- Przykład 1 - ST_Intersection

-- Funkcja St_Intersection jest podobna do ST_Clip. ST_Clip zwraca raster, a ST_Intersection zwraca
-- zestaw par wartości geometria-piksel, ponieważ ta funkcja przekształca raster w wektor przed
-- rzeczywistym „klipem”. Zazwyczaj ST_Intersection jest wolniejsze od ST_Clip więc zasadnym jest
-- przeprowadzenie operacji ST_Clip na rastrze przed wykonaniem funkcji ST_Intersection.

CREATE TABLE krawczyk.intersection as
SELECT a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

-- Obie funkcje zwracają zestaw wartości geomval
	-- geomval is a compound data type consisting of a geometry object referenced by the .geom field and val, a double precision value that represents the pixel value at a particular geometric location in a raster band. It is used by the ST_DumpAsPolygon and Raster intersection family of functions as an output type to explode a raster band into geometry polygons.

-- Przykład 2 - ST_DumpAsPolygons - konwertuje rastry w wektory (poligony)


CREATE TABLE krawczyk.dumppolygons AS
SELECT a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

-- V. Analiza rastrów

-- Przykład 1 - ST_Band - wydorębnianie pasm z rastra

CREATE TABLE krawczyk.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;

-- Przykład 2 - ST_Clip - wycięcie rastra z innego rastra, w tym wypadku wycina jedną parafię z tabeli vectors.porto_parishes

CREATE TABLE krawczyk.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

-- Przykład 3 - ST_Slope - generuje nachylenie

CREATE TABLE krawczyk.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM krawczyk.paranhos_dem AS a;

-- Przykład 4 - ST_Reclass - reklasyfikacja rastra

CREATE TABLE krawczyk.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3','32BF',0)
FROM krawczyk.paranhos_slope AS a;

-- Przykład 5 - ST_SummaryStats - statystyki rastra

SELECT st_summarystats(a.rast) AS stats
FROM krawczyk.paranhos_dem AS a;

-- Przykład 6 -  ST_SummaryStats oraz Union

SELECT st_summarystats(ST_Union(a.rast))
FROM krawczyk.paranhos_dem AS a;


-- ST_SummaryStats zwraca złożony typ danych (tuple)

-- Przykład 7 - ST_SummaryStats z lepszą kontrolą złożonego typu danych 

WITH t AS (
	SELECT st_summarystats(ST_Union(a.rast)) AS stats
	FROM krawczyk.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;

-- Przykład 8 - ST_SummaryStats w połączeniu z GROUP BY - wyświetlamy statysyke dla kazdego poligonu "parish" (parafii)

WITH t AS (
	SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast, b.geom,true))) AS stats
	FROM rasters.dem AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
	group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;


-- Przykład 9 - ST_Value

-- Funkcja ST_Value pozwala wyodrębnić wartość piksela z punktu lub zestawu punktów.
-- Poniższy przykład wyodrębnia punkty znajdujące się w tabeli vectors.places.

-- Ponieważ geometria punktów jest wielopunktowa, a funkcja ST_Value wymaga geometrii
-- jednopunktowej, należy przekonwertować geometrię wielopunktową na geometrię
-- jednopunktową za pomocą funkcji (ST_Dump(b.geom)).geom

SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;

-- Przykład 10 - ST_TPI

-- TPI porównuje wysokość każdej komórki w DEM ze średnią wysokością określonego sąsiedztwa
-- wokół tej komórki. Wartości dodatnie reprezentują lokalizacje, które są wyższe niż średnia ich
-- otoczenia, zgodnie z definicją sąsiedztwa (grzbietów). Wartości ujemne reprezentują lokalizacje,
-- które są niższe niż ich otoczenie (doliny). Wartości TPI bliskie zeru to albo płaskie obszary (gdzie
-- nachylenie jest bliskie zeru), albo obszary o stałym nachyleniu.

-- Funkcja ST_Value pozwala na utworzenie mapy TPI z DEM wysokości. Obecna wersja PostGIS może
-- obliczyć TPI jednego piksela za pomocą sąsiedztwa wokół tylko jednej komórki. Poniższy przykład
-- pokazuje jak obliczyć TPI przy użyciu tabeli rasters.dem jako danych wejściowych. Tabela nazywa się
-- TPI30 ponieważ ma rozdzielczość 30 metrów i TPI używa tylko jednej komórki sąsiedztwa do
-- obliczeń. Tabela wyjściowa z wynikiem zapytania zostanie stworzona w schemacie schema_name,
-- jest więc możliwa jej wizualizacja w QGIS.

CREATE TABLE krawczyk.tpi30 as
SELECT ST_TPI(a.rast,1) as rast
FROM rasters.dem a

-- a. Dodanie serial primary key

ALTER TABLE krawczyk.tpi30
ADD COLUMN rid SERIAL PRIMARY KEY;

-- b. Utworzenie indeksu przestrzennego

CREATE INDEX idx_tpi30_rast_gist ON krawczyk.tpi30
USING gist (ST_ConvexHull(rast));

-- c. Dodanie raster constraints

SELECT AddRasterConstraints('krawczyk'::name,
'tpi30'::name,'rast'::name);

-- Problem do samodzielnego rozwiązania
-- Przetwarzanie poprzedniego zapytania może potrwać dłużej niż minutę, a niektóre zapytania mogą
-- potrwać zbyt długo. W celu skrócenia czasu przetwarzania czasami można ograniczyć obszar
-- zainteresowania i obliczyć mniejszy region. Dostosuj zapytanie z przykładu 10, aby przetwarzać tylko
-- gminę Porto. Musisz użyć ST_Intersects, sprawdź Przykład 1 - ST_Intersects w celach
-- informacyjnych. Porównaj różne czasy przetwarzania. Na koniec sprawdź wynik w QGIS

CREATE TABLE krawczyk.tpi30 as
SELECT ST_TPI(a.rast,1) as rast
FROM rasters.dem a, vectors.porto_parishes as b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

-- VI. Algebra Map

-- Istnieją dwa sposoby korzystania z algebry map w PostGIS. Jednym z nich jest użycie wyrażenia,
-- a drugim użycie funkcji zwrotnej. Poniższe przykłady pokazują jak stosując obie techniki
-- utworzyć wartości NDVI na podstawie obrazu Landsat8.

-- Wzór na NDVI:
-- NDVI=(NIR-Red)/(NIR+Red)

-- Przykład 1 - Wyrażenie Algebry Map

CREATE TABLE krawczyk.porto_ndvi AS
WITH r AS (
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
	r.rid,ST_MapAlgebra(
		r.rast, 1,
		r.rast, 4,
		'([rast2.val] - [rast1.val]) / ([rast2.val] + [rast1.val])::float','32BF'
	) AS rast
FROM r;

-- a. Dodanie serial primary key

ALTER TABLE krawczyk.porto_ndvi
ADD COLUMN rid SERIAL PRIMARY KEY;

-- b. Utworzenie indeksu przestrzennego

CREATE INDEX idx_porto_ndvi_rast_gist ON krawczyk.porto_ndvi
USING gist (ST_ConvexHull(rast));

-- c. Dodanie raster constraints

SELECT AddRasterConstraints('krawczyk'::name,
'porto_ndvi'::name,'rast'::name);

-- Możliwe jest użycie algebry map na wielu rastrach i/lub wielu pasmach,
-- służy do tego rastbandargset

-- Przyklad 2 - Funkcja zwrotna

-- Tworzymy funkcje, która będzie wywoływana

create or replace function krawczyk.ndvi(
	value double precision [] [] [],
	pos integer [][],
	VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
	--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug purposes
	RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value [1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

-- W kwerendzie algebry map należy można wywołać zdefiniowaną wcześniej funkcję

CREATE TABLE krawczyk.porto_ndvi2 AS
WITH r AS (
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
	r.rid,ST_MapAlgebra(
		r.rast, ARRAY[1,4],
		'krawczyk.ndvi(double precision[], integer[],text[])'::regprocedure, --> This is the function!
		'32BF'::text
	) AS rast
FROM r;

-- a. Dodanie serial primary key

ALTER TABLE krawczyk.porto_ndvi2
ADD COLUMN rid SERIAL PRIMARY KEY;

-- b. Utworzenie indeksu przestrzennego

CREATE INDEX idx_porto_ndvi2_rast_gist ON krawczyk.porto_ndvi
USING gist (ST_ConvexHull(rast));

-- c. Dodanie raster constraints

SELECT AddRasterConstraints('krawczyk'::name,
'porto_ndvi2'::name,'rast'::name);

-- Przykład 3 - Funckje TPI

-- Aktualnie zaimplementowana w PostGIS funkcja TPI wykorzystuje algebrę mapy z wywołaniem
-- funkcji.
-- Schemat public zawiera dwie funkcje TPI:
-- • public._st_tpi4ma - funkcja używana w algebrze map
-- • public.st_tpi - funkcja, która wywołuje poprzednią funkcję. Istnieją dwie funkcje st_tpi, które
-- różnią się liczbą dozwolonych wejść lecz obie te funkcje wykonują tę samą akcję.
-- Przeanalizuj kod wspomnianych funkcji oraz sposób ich wykonania.
-- Więcej informacji odnośnie algebry map w PostGIS znajduje się na stronach:
-- MapAlgebra z wyrażeniem: https://postgis.net/docs/RT_ST_MapAlgebra_expr.html
-- MapAlgebra z wywołaniem funkcji:
-- https://postgis.net/docs/RT_ST_MapAlgebra.html
-- Obecna implementacja TPI w PostGIS obsługiwana przy użyciu funkcji ST_TPI pozwala tylko na
-- obliczenie TPI z jedną komórką sąsiedztwa. Nowa implementacja TPI pozwalająca użytkownikowi
-- określić komórki sąsiedztwa (wewnętrzny pierścień i pierścień zewnętrzny), za pomocą algebry
-- mapy dostępna jest tutaj: https://github.com/lcalisto/postgis_customTPI

-- VII. Eksport Danych

-- Przykład 0 - Użycie QGIS

-- Po załadowaniu tabeli/widoku z danymi rastrowymi do QGIS, możliwe jest
-- zapisanie/wyeksportowanie warstwy rastrowej do dowolnego formatu obsługiwanego przez GDAL za
-- pomocą interfejsu QGIS.

-- Przykład 1 - ST_AsTiff

-- Funkcja ST_AsTiff tworzy dane wyjściowe jako binarną reprezentację pliku tiff, może to być
-- przydatne na stronach internetowych, skryptach itp., w których programista może kontrolować, co
-- zrobić z plikiem binarnym, na przykład zapisać go na dysku lub po prostu wyświetlić.

SELECT ST_AsTiff(ST_Union(rast))
FROM krawczyk.porto_ndvi;

-- Przykład 2 - ST_AsGDALRaster

-- Podobnie do funkcji ST_AsTiff, ST_AsGDALRaster nie zapisuje danych wyjściowych bezpośrednio
-- na dysku, natomiast dane wyjściowe są reprezentacją binarną dowolnego formatu GDAL.

SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
FROM krawczyk.porto_ndvi;

-- Uwaga:

-- Funkcje ST_AsGDALRaster pozwalają nam zapisać raster w dowolnym formacie obsługiwanym przez
-- gdal. Aby wyświetlić listę formatów obsługiwanych przez bibliotekę uruchom:
SELECT ST_GDALDrivers();

-- Przykład 3 - Zapisywanie danych na dysku za pomocą dużego obiektu (large object, lo)

CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
       ST_AsGDALRaster(ST_Union(rast), 'GTiff',  ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
        ) AS loid
FROM krawczyk.porto_ndvi;

-- Zapisywanie pliku na dysku 

SELECT lo_export(loid, 'C:\Kacper\porto_ndvitiff')
FROM tmp_out;

-- Usuwanie obiektu

SELECT lo_unlink(loid)
FROM tmp_out;

-- Przykład 4 - Użycie GDAL

-- Gdal obsługuje rastry z PostGISa. Polecenie gdal_translate eksportuje raster do dowolnego formatu
-- obsługiwanego przez GDAL.

gdal_translate -co COMPRESS=DEFLATE -co PREDICTOR=2 -co ZLEVEL=9
PG:"host=localhost port=5432 dbname=postgis_raster user=postgres
password=postgis schema=schema_name table=porto_ndvi mode=2"
porto_ndvi.tiff

-- VIII. Publikowanie danych za pomocą MapServer

-- Ponieważ GDAL obsługuje rastry PostGIS, możliwe jest opublikowanie rastra jako WMS.
-- Należy pamiętać, że w takim przypadku zaleca się generowanie podglądów w celu uzyskania
-- lepszej wydajności.

-- Poniższy przykład to plik mapowania z rastrem przy użyciu standardowych opcji i klauzuli


-- IX. Publikowanie danych przy użyciu GeoServera

-- Przykład 1 - Mapfile

-- X. Publikowanie danych przez użycia GeoServera

CREATE TABLE public.mosaic (
    name character varying(254) COLLATE pg_catalog."default" NOT NULL,
    tiletable character varying(254) COLLATE pg_catalog."default" NOT NULL,
    minx double precision,
    miny double precision,
    maxx double precision,
    maxy double precision,
    resx double precision,
    resy double precision,
    CONSTRAINT mosaic_pkey PRIMARY KEY (name, tiletable)
);

INSERT INTO mosaic (name,tiletable) VALUES ('mosaicpgraster','rasters.dem');






