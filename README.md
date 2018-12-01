
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

```shell
sudo su -l postgres
initdb -D '/var/lib/postgres/data'
sudo systemctl start postgresql.service
createuser --interactive 
#create <dbuser>
createdb <database>
```

## Database setup

```shell
psql -d <database>
```
```sql
create table users(id int, created_at date, updated_at date, username text, realname text, password text, avatar text, perms text[]);
```

## start

```shell
git clone <url>
cd authd
shards install
shards build
./bin/authd -u <dbuser> -d <database>
```

