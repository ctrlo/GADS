if [ "$( psql -U $2 -h $1 -XtAc "SELECT 1 FROM pg_database WHERE datname='$3'" )" = '1' ]; then
    echo "SUCCESS";
else
    psql -U $2 -h $1 -c "CREATE DATABASE $3";
    psql $3 -U $2 -h $1 -c "CREATE EXTENSION citext WITH SCHEMA public";
    echo "SUCCESS";
fi