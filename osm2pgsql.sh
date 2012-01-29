#!/bin/bash -x

# 
# This script expects to be run as the postgres user.
# 

createdb osm
createlang plpgsql osm
psql -f /usr/share/postgresql/8.4/contrib/postgis-1.5/postgis.sql osm
psql -f /usr/share/postgresql/8.4/contrib/postgis-1.5/spatial_ref_sys.sql osm

curl -o tmp/default.style http://svn.openstreetmap.org/applications/utils/export/osm2pgsql/default.style

function osm2geodata
{
    slug=$1

    osm2pgsql -sluc -C 1024 -d osm -S tmp/default.style -p ${slug}_osm ex/$slug.osm.bz2 > /dev/null 2>&1
    
    pgsql2shp -rk -f tmp/$slug.osm-point.shp osm ${slug}_osm_point
    pgsql2shp -rk -f tmp/$slug.osm-polygon.shp osm ${slug}_osm_polygon
    pgsql2shp -rk -f tmp/$slug.osm-line.shp osm ${slug}_osm_line
    zip -j tmp/$slug.shapefiles.zip tmp/$slug.osm-*.shp tmp/$slug.osm-*.prj tmp/$slug.osm-*.dbf tmp/$slug.osm-*.shx

    rm tmp/$slug.osm-*.*
    
    echo "DROP TABLE ${slug}_osm_line" | psql osm
    echo "DROP TABLE ${slug}_osm_nodes" | psql osm
    echo "DROP TABLE ${slug}_osm_point" | psql osm
    echo "DROP TABLE ${slug}_osm_polygon" | psql osm
    echo "DROP TABLE ${slug}_osm_rels" | psql osm
    echo "DROP TABLE ${slug}_osm_roads" | psql osm
    echo "DROP TABLE ${slug}_osm_ways" | psql osm
}

osm2geodata cairo &
osm2geodata johannesburg &
wait
osm2geodata lagos &
wait