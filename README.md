
# authd

## Dependencies

- crystal
- shards
- postgresql

Usually install on Arch like
```shell
sudo pacman -S crystal shards git vim postgresql
```
## Database init

 Memo https://olivier.dossmann.net/wiki/services/postgres/#cr%C3%A9er-une-nouvelle-base-de-donn%C3%A9es-avec-un-nouvel-utilisateur

```shell
sudo su -l postgres
initdb -D '/var/lib/postgres/data'
sudo systemctl start postgresql.service
createuser <dbuser>
createdb -O <dbuser> -E UTF-8 <database>
psql -d <database>
```
```sql
create table users(id int, created_at date, updated_at date, username text, realname text, password text, avatar text, perms text[]);
```
```shell
\q
```

## start

```shell
git clone <url>
cd authd
shards install
shards build
./bin/authd -u <dbuser> -d <database>
```

