psql -c "drop schema public cascade;  "
psql -c "create schema public; "
psql -c "grant all on schema public to public; "