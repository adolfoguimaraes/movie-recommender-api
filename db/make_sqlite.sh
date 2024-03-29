#!/bin/bash

if [ ! -f "movielens-small.db" ]; then
  # Download the file
  curl -SOL http://files.grouplens.org/datasets/movielens/ml-latest-small.zip
  # Unzip it
  unzip ml-latest-small.zip # creates ml-latest-small dir
  rm -f ml-latest-small.zip

cat <<EOF > import.sql
.mode csv
.import ml-latest-small/movies.csv movies
.import ml-latest-small/tags.csv tags
.import ml-latest-small/links.csv links
.import ml-latest-small/ratings.csv ratings
.import movie_poster.csv poster_links
EOF
  echo ".read import.sql" | sqlite3 movielens-small.db
  rm import.sql

  rm -rf ml-latest-small

cat <<EOF > fix.sql
create table movies_fix as select movieId, title, substr(trim(title),-5,4) as year, genres from movies;
update movies_fix set year = null where year not like '1%' and year not like '2%';
update movies_fix set title = substr(trim(title),0,length(trim(title))-6) where year is not null;

create table links_fix as select cast(movieId as integer) as movieId, imdbId, tmdbId from links;
drop table links;
create table links as select * from links_fix;
drop table links_fix;

drop table movies;
create table movies as select cast(tb1.movieId as integer) as movieId, tb1.title, cast(tb1.year as integer) as year, tb1.genres, '' as url_poster, tb2.imdbid from movies_fix tb1, links tb2 where tb1.movieId = tb2.movieId;
drop table movies_fix;
create table ratings_fix as select cast(userId as integer) as userId, cast(movieId as integer) as movieId, cast(rating as real) as rating, cast(timestamp as integer) as timestamp from ratings;
drop table ratings;
create table ratings as select * from ratings_fix;
drop table ratings_fix;

create table tags_fix as select cast(userId as integer) as userId, cast(movieId as integer) as movieId, tag, cast(timestamp as timestamp) as timestamp from tags;
drop table tags;
create table tags as select * from tags_fix;
drop table tags_fix;
create table users as select distinct(userId), 'User ' || userId as userName from ratings
EOF
  echo ".read fix.sql" | sqlite3 movielens-small.db
  rm fix.sql
fi
