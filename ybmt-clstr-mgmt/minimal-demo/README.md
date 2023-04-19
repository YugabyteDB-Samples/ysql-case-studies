# "mini.sql" — a minimal end-to-end demonstration of the YBMT scheme

Start _mini.sql_

- _either_ at the _ysqlsh_ prompt for a YugabyteDB cluster;
- _or_ at the _psql_ prompt for a PostgreSQL cluster.

You can do this using a freshly-created cluster or a cluster with _any_ content state. The only requirement is the existence of:

- a superuser called _yugabyte_ that was created (or altered) _with login_.
- a database called _yugabyte_ that was created (or altered) _with allow_connections true_.

You can ensure this starting state if the cluster is freshly-created by running this script:

```
ysql-case-studies/ybmt-clstr-mgmt/00-post-creation-bootstrap.sql
```

This connects using \\_c postgres postgres_. So it's assumed that (for a PostgreSQL cluster), you follow the recommended practice of naming the _bootstrap superuser_ as _postgres_. (A freshly-created YugabyteDB cluster non-negotiably has a superuser and a database with the name _postgres_.)

The _mini.sql_ script does this:

- Re-initializes the cluster as a YBMT cluster—with just the single database _yugabyte_.
- Creates a tenant database called _d9_.
- Installs a multi-role, multi-schema mini-application that has roles with the nicknames _data_ and _code_. This is a mini version of the case study _ysql-case-studies/hard-shell_.
- Displays inventories of all the artifacts that the script creates.
- Tests the application by connecting as the special, pre-created role with the nickname _client_.
- Demonstrates that, when connected as _client_, you can use _only_ the intended user-defined subprograms that implement the applications API for client-side code. For example, even _select 10/2_ fails! (The error message is _"permission denied for function int4div"_.)

The script spools two files using "\\_o re-conf-clstr.txt_" and "\\_o cr-db-and-install.txt_". These are renamed thus in the repo:

```
re-conf-clstr-0.txt
cr-db-and-install-0.txt
```

You can _diff_ your spool files with these. They'll be identical.

The _ybmt-clstr-mgmt/minimal-demo/_ directory also contains the file _example-psqlrc.txt_. It defines _psql_ variables to be used as shortcuts for common YBMT operations and reporting queries. You might like to include its content in your own _psqlrc_ file.