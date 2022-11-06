-- 2. Podziel warstwę trees na trzy warstwy. Na każdej z nich umieść inny typ lasu. Zapisz wyniki do
-- osobnych tabel.

SELECT * FROM deciduous_trees

SELECT * FROM mixed_trees

SELECT * FROM evergreen

-- 6. W tabeli wynikowej z poprzedniego zadania zostaw tylko te budynki, które są położone nie dalej
-- niż 100 km od rzek (rivers). Ile jest takich budynków?

SELECT COUNT(*) FROM bristol_bay_buildings

SELECT * FROM rivers

SELECT COUNT(DISTINCT(b.gid))
FROM bristol_bay_buildings as b, rivers as r
WHERE ST_DWithin(b.wkb_geometry, r.geom, 1000000) -- \100km = 1000000m



-- 8. Wydobądź węzły dla warstwy railroads. Ile jest takich węzłów? Zapisz wynik w postaci osobnej
-- tabeli w bazie danych.


SELECT COUNT(*) from railroads_vertices