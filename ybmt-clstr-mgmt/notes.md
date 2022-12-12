### THE MULTITENANCY PROVISIONING SYSTEM

  The system that this script, and its callee scripts, jointly define is intended
  for provisioning databases for use by individual contributors. Such databases
  support prototyping and the development of the set of ".sql" scripts that will
  be periodically merged (GitHub style) with contributions from other developers
  in the "database application development" team.

  The term "tenant database" denotes the kind of database that is provisioned (i.e.
  created, configured, and dropped) by this multitenancy provisioning system.

The provisioning system is defined by:

- the two roles "yugabyte" (a superuser) and "clstr$admin" (a non-superuser  with "createdb" and "createrole")
- the "postgres" database and the customized "template1" database.

Tautologically, the databases "yugabyte" and "template1", together with the PG-shipped "template0" database that YB inherits and the YB-shipped "system_platform" database, are NOT "tenant databases".

The so-called "pristine-multitenancy-cluster" contains ONLY the multitenancy provisioning system.

#### Drop and re-create the one-and-only laptop PG cluster

See [initdb](www.postgresql.org/docs/current/app-initdb.html). At the O/S prompt:

```
pg_ctl -D /usr/local/var/postgres stop
```
Not interesting to have more than one viable cluster on a laptop. So move _"/usr/local/var/postgres"_ off to the side.

```
initdb -U "PG-SYSTEM" --encoding UTF8 --no-locale -D /usr/local/var/postgres
```

Reports _"Success. You can now start the database server using..."_. Don't bother with _"logile"_. Just use the plain variant:

```
pg_ctl -D /usr/local/var/postgres start
psql -h localhost -p 5432 -d postgres -U "PG-SYSTEM"
```
### One time SQL Bootstrap

```
create role postgres with
  superuser
  login password 'postgres';
```

## Using "single-user-mode"

To rescue after a slip-up that locks you out (like this:

```
alter user postgres with nosuperuser;
```

Stop the server. Then (on PG) start a [single-user session](https://www.postgresql.org/docs/current/app-postgres.html#APP-POSTGRES-SINGLE-USER). Specify the name of the database to be accessed as the last argument on the command line. If it is omitted it defaults to the O/S user name.

```
postgres --single -D /usr/local/var/postgres postgres
```

Gets you to the the _"backend>"_ prompt. There's no challenge, and no need for privileges like _"connect"_ to a database. This:

```
select current_role;
```

shows the role that was specified by _-U_ in _"initdb"_ invocation.

Notice that bare _select_, and even complicated ones like these, are OK:

```
with c(v) as (values (17), (42)) select array_agg(v) from c;
```

At least some DDLs are OK too. You can now rescue things. In this example, you say:

```
alter user postgres with superuser;
```

The UI is primitive w.r.t. _psql_. But you can achieve what you need to.

## (Re-)establish a standard "pristine" starting start.

Must be run as "postgres". The effect of this script is idempotent, so it can can be run time and again, starting in any arbitrary regime of created artifacts. It always, silently, produces the same result. See this at the end:

```
call admin.assert_pristine_cluster_final_state_ok();
```

We coin these terms:

### Usabable superuser"

A user with with _rolsuper_ and _rolcanlogin_ both set to _true_.

### Usabable database

A database with _datallowconn_ set to _true_.

Notice that a freshy-created YB cluster comes with _two_ superusers: _"postgres"_ and _"yugabyte"_. This is bad practice. Run this script immediately after creating a YB cluster. It will drop the offending _yugabyte_. The _"drop role"_ DDL has _"if exists"_ to make it idempotent.

## Definition of the "unique pristine starting state"

This script:

```
qq
```

must be run while no other session is running it (else possible race condition errors that you might have to sort out manually). It's easy to prevent non-superusers from starting sessions during this drastic maintenance. They will all anayway be dropped by the time the script as finished. But superusers are governed by _"with nologin"_. So you have to rely on the fact that the password of the one-and-only superuser _"postgres"_ is closely guarded and that people who know it cooperate.

- Just a single usable superuser called _"postgres"_.

- Just a single non-template database that allows connections called _"postgres"_.
    It has "read committed" default txn isolation level.

* The _"postgres"_ database has no _"public"_ schema and just two user-created schemas: one called _"extensions"_ for whatever extensions are needed; and one called _"admin"_ with various utilitities.
