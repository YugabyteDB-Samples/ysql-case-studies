# The "ysql-case-studies" repo

**NOTE:** Make sure that you read the _Passwords_ section at the bottom of this page before running the _"0-end-to-end-test.sql"_ script.

This repo contains several YSQL case-studies. The purpose of each is to complement an existing, or future, section within the [Yugabyte Structured Query Language](https://docs.yugabyte.com/preview/api/ysql/) within the YugabyteDB documentation. (The term "Yugabyte Structured Query Language" will, hereinafter, be abbreviated to "YSQL".)

You can install all the case-studies into a cluster that has been configured using the scripts on the _"ybmt-clstr-mgmt"_. directory. The _"0-end-to-end-test.sql"_ script on this directory provides a one-touch way to do this configuration and then to install, and test, all of the case-studies.

The studies are organised within the following directory structure:

```
ybmt-clstr-mgmt

analyzing-covid-data-with-aggregate-functions
date-time-utilities
hard-shell
json-relational-equivalence
recursive-cte
  basics
    procedural-implementation-of-recursive-cte-algorithm
    fibonacci
  employee-hierarchy
  bacon-numbers
triggers
  trigger-firing-order
  
  ** COMING SOON **	
  [mandatory-one-to-many-relationship]
    [triggers-to-check-the-rule-needs-serializable]
    [ask-tom-approach]
```

Each case-study has its own _"README.md"_ in its top directory. Some of the case-studies are already described in the YSQL documentation. For these, the _"README.md"_ needs to do little more than provide the URL to the relevant section. Others are not yet described in the YSQL documentation. Until this is done, a sufficient account is provided in the _"README.md"_ for these case-studies.

The _"ybmt-clstr-mgmt"_ directory implements a multitenancy scheme that relies on a software-enforced naming convention for global objects that avoids collisions of global names. ("YBMT" is an informal shorthand for short for "Yugabyte Multitenancy".) This is an interesting study in its own right because it relies upon, and demonstrates, key [PostgreSQL](https://www.yugabyte.com/postgresql/) notions for roles and privileges. In particular, it uses a dedicated _clstr$mgr_ role for provisioning tenant databases and, by using _security definer_ procedures in each provisioned database, for provisioning local roles within that tenant database. The scheme implements a disciplined separation of duties notion so that a session needs to authorize as the superuser only for the one-time configuration of the _ybmt-clstr-mgmt_ subsystem immediately following the creation of a cluster.

You can demonstrate the [full compatibility between YSQL and PostgreSQL](https://www.yugabyte.com/postgresql/postgresql-compatibility/) by installing and running all of the scripts that this _repo_ provides in a Vanilla PostgreSQL cluster. They have been tested both with Version 11 (upon which the current YugabyteDB version is based) and with the _current_ PostgreSQL version. The tests detect whether they're running in YugabyteDB or in PostgreSQL and use the _\if_ meta-command to spool the test output to a file that starts with _yb-_ or with _pg-_. This enables you immediately to use your favorite _diff_ toll to compare the test output and to confirm that it's the same with YugabyteDB and PostgreSQL.

**NOTE:** It would be relatively straightforward to install each study directly into a cluster where the _ybmt-clstr-mgmt_ subsystem is not installed and where installing it would conflict with already existing databases and roles that had been created by using "bare" SQL. To do this, you'd have to replace the calls to the YBMT role provisioning procedures with "bare" SQL statements and take responsibility yourself to avoid collision of role names. You'd also have to install any extensions that a particular case-study depends upon. Try to avoid the need for this by dedicating a cluster to these case-studies.

## Passwords

The files under the _"ysql-case-studies"_ directory are all plain text.

- Most of them are SQL scripts.
- Some are the spooled output that running these scripts produces.
- And the remaining small few are read by the _\copy_ meta-command to load example data into tables.

Not one of these files contains any sensitive material.

The _"0-end-to-end-test.sql"_ master script calls further _sql_ scripts. And these, in turn, either directly or recursively, from the scripts that these call, call the remaining _.sql_ scripts. These scripts, between them, create several roles—and several of these are defined using this locution in a PL/pgSQL block statement:

```
execute format('create role %I with ... login password %L', r_name::text, 'some clear text');
```

Do a global search for the string _password_ within _all_ of the _.sql_ scripts under the _"ysql-case-studies"_ directory. You'll find about half-a-dozen places where the password is defined using clear text, thus:

- The password for the _yugabyte_ superuser and the _clstr$mgr_ role (configured for provisioning databases and roles) is set to _x_.
- The password for the _dN$mgr_ role (configured for provisioning roles within a single tenant database _dN_) is set to _m_.
- The password for the _dN$client_ role (configured to support connecting from client-side code to use the application that a single tenant database _dN_ houses) is set to _c_.

Notice that the password for the application-specific roles within a tenant database, with names like _dN$data_ or _dN$code_, are set to _null_.  These become the current role upon using the _set _role_ statement from a session whose _session_role_ is _dN$mgr_.

It's expected that you'll typically run the _"0-end-to-end-test.sql"_ master script only when you're connected to a cluster that's installed on a developer laptop and that isn't visible from outside of that machine—and passwords like _x_, _m_, and _c_ work fine in this use case. They certainly give no information about actual passwords that might be defined in a deployment where the cluster is accessible from machines other than the one that hosts the cluster. In other words, the convention that's used here is deemed to be safe.

Notice that it's very easy to modify those few _create role_ and _alter role_ statements where the password is provided as a single-letter clear text and modify them to use a secure approach along these lines:

```
create procedure mgr.create_role_and_set_initial_password(
  r_name in name, password inout text)
  security definer
  set client_min_messages = warning
  set search_path = pg_catalog, pg_temp
  language plpgsql
as $body$
begin
  password := mgr.password();
  execute format('create role %I with /* ... */ login password %L', r_name::text, password);
  execute format('alter role %I set search_path = pg_catalog, pg_temp', r_name::text);
  -- ...
end;
$body$;
```

The function _mgr.password()_ can use your favorite reliable method to generate a strong password. And you can use a follow-up reliable method to show the generated password _text_ value to whomever needs to see it. 