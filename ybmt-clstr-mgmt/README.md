# The YBMT scheme for implementing a disciplined approach to multitenancy in a PostgreSQL or YugabyteDB cluster

This account uses only the vocabulary of PostgreSQL (hereinafter PG)—and might give the impression that it applies only to that environment. However, because YugabyteDB's YSQL (hereinafter YB) re-uses PG's SQL-processing code "as is", everything discussed here is applicable both to PG and to YB.

> **NOTE:** _"YBMT"_ (in prose) and _"ybmt"_ (in code and filenames) are _informal_ abbreviations. They are used within the [ysql-case-studies](https://github.com/YugabyteDB-Samples/ysql-case-studies) repo under Yugabyte Inc's [YugabyteDB-Samples](https://github.com/YugabyteDB-Samples) GitHub "organization". The _"yb"_ component follows the establish convention to use this prefix for things that come from Yugabyte Inc. And the _"mt"_ component, of course, stands for _"multitenancy"_.

The files under the _"ysql-case-studies/ybmt-clstr-mgmt"_ directory jointly implement the YBMT scheme. And this _README_ describes the goals that the scheme meets and how this is done.

Critically, the scheme relies only on native functionality that PG Version 11 supports—which functionality is available with the same syntax and semantics in YB. All the code has been tested in vanilla PG Version 11 and in YB Version 2.17 and behaves the same in both environments.

The account is structured as follows:

- **Overview**
  - What is YBMT for?
  - High-level description of YBMT
- **The underlying generic PG features that determine the challenge—and how YBMT overcomes these**
  - Roles, objects, and their scopes
  - Artifacts, roles, and objects
  - The native PG features allow too much freedom
- **The YBMT conventions**
  - Introducing the "local role" convention
  - Defining "bootstrap database" and "tenant database"
  - Role provisioning
    - _cr_role()_
    - _drop_role()_
    - _drop_all_regular_local_roles()_
    - _set_role_search_path()_
    - _set_role_password()_
    - _set_role()_
    - _revoke_all_from_public()_
    - _grant_priv()_
    - _prepend_to_current_search_path()_
  - Avoiding collision of local role names
- **The YBMT implementation**
  - Before starting to use the code
  - (Re)initialize a cluster as a YBMT cluster
  - Drop and re-create _N_ tenant databases
  - Drop _N_ tenant databases
  - Convenience partner scripts
  - Using a _.sql_ script to write and execute another _.sql_ script
  - The role-provisioning procedures
  - The join views for the _pg_catalog_ tables and the table functions wrappers for these
  - Implementing the principle of least privileges for _"client"_ roles
    - _Background_
    - _What does the "06-xfer-schema-grants-from-public-to-clstr-developer.sql" script do?_
  - The currently available case-studies
    - Working with just a single case-study
    - End-to-end test of the YBMT scheme and all of the case-studies

## Overview

This section describes what the YBMT scheme is for and what its high-level characteristics are.

### What is YBMT for?

The YBMT scheme was designed and implemented to allow any number of YSQL case-studies, which in general each uses a set of objects whose ownership is spread among several roles and that are located in several schemas, all to be installed into the same cluster without interfering with each other and without needing special design to achieve this. The term "case-study" implies that the YBMT's purpose is pedagogy; and this is indeed the case. And one of the goals of the pedagogy is to show that each case-study runs without error, and with the same effect, in both YB and PG.

However, the notions can certainly inform the design of real-world multitenancy schemes. Having said this, YBMT's notions are entirely semantic. In other words, the scheme has no physical component and in no way reflects any of YugabyteDB's special distributed storage layer features.

Typically, each case-study is installed in a dedicated database. But a study whose objects all have a single owner is typically installed, together with other such studies, into a single dedicated database for such studies. Of course, if you prefer, you could install every case-study into its own dedicated database. And you'd achieve this by making only tiny changes to the installation scripts, as this repo has them, that implement such a single-owner study.

### High-level description of YBMT

The high-level notion is that the entire cluster is set up as a YBMT cluster and follows its rules. It's assumed that you start with a minimally populated cluster that contains no user-defined artifacts of interest, but has just these:

- The inevitable _bootstrap superuser_, called _postgres_, with password set to _null_. This will never be used to authorize a session.
- The "ordinary" superuser _yugabyte_. The session that establishes the YBMT environment authorizes as this role.
- Exactly one non-template database, called _yugabyte_, that serves as the "home base" for a session that authorizes as the _yugabyte_ role. (You cannot start a session unless you specify not just the role that authorizes it but also a database to which it will connect.)

Neither a freshly-created PG cluster, nor a freshly created YB cluster, is set up exactly like this. But it's trivial to arrange that this is the case. As it happens, PG allows you to specify the name of the bootstrap superuser; but YB forces the choice of _postgres_. Because the name of the bootstrap superuser is reflected in a few places in the code, you should choose this name when you create your PG cluster.

A freshly (re)configured, but otherwise empty, YBMT cluster will have two extra roles

- **The _clstr$mgr_ role (allows login)**
  
  This honors the practice advice that's given in the PG doc section [Role Attributes](https://www.postgresql.org/docs/11/role-attributes.html):
  
  > It is good practice to create a role that has the CREATEDB and CREATEROLE privileges, but is not a superuser, and then use this role for all routine management of databases and roles. This approach avoids the dangers of operating as a superuser for tasks that do not really require it.
  
  The _clstr$mgr_ role is therefore created _"... with nosuperuser createdb createrole login..."_.
  
- **The _clstr$developer_ role ("pure" role—doesn't allow login)**
  
  This role is a user-created equivalent to the system roles like _pg_read_all_settings_, _pg_read_all_stats_, and so on in that it is listed by this query:
  
  ```
  select rolname
  from pg_authid
  where not rolcanlogin and rolpassword is null
  order by rolname;
  ```

  Again just like for _pg_read_all_settings_, _pg_read_all_stats_, and so on, this query produces the result _false_.
  
  ```
  select exists(
    select 1
    from pg_database
    where has_database_privilege('clstr$developer', datname, 'connect')
    or    has_database_privilege('clstr$developer', datname, 'create')
    or    has_database_privilege('clstr$developer', datname, 'temp')
  )::text;
  ```

  You should regard it as a global role.

  Its purpose is to be the target of grants of privileges on objects which, in a freshly-created cluster, are granted to _public_ but which have been deliberately revoked from _public_ and are granted instead to _clstr$developer_. The _clstr$developer_ role is then granted only to those roles that need such privileges—i.e. to non-_"client"_ roles. See the section _«Implementing the principle of least privileges for "client" roles»_.

People who know the passwords for _yugabyte_ and for _clstr$mgr_ have the power to subvert the YBMT scheme. For example, you could grant _connect_ on some database to  _clstr$developer_ (or, for that matter, to, say, _pg_read_all_settings_). But the very few people who know these passwords must be trusted not to break the rules. A session needs to authorize as _yugabyte_ only to (re)configure a YBMT cluster. This task is implemented entirely mechanically by the _.sql_ scripts under the _"ysql-case-studies/ybmt-clstr-mgmt"_ directory. And a session needs to authorize as _clstr$mgr_ only to create, or to drop, so-called tenant databases. (This term is defined below.) Thereafter, a person who knows the password for the manager of a particular tenant database can create only sessions that use that database and create, or drop, local roles for that tenant database. The manager role is created as part of tenant database creation. Neither this manager role, nor any roles that it creates, can subvert the YBMT scheme or operate outside of their own tenant database.

Critically, the YBMT scheme must allow name choices within the scope of one tenant database to be made without reference to name choices that have been made, or that will be made later, within other tenant databases. Lest, given what you already know about the globality of roles, you think that no such scheme could work, here is the clue: role names are specified as _nicknames_. And the scheme is defined by a software-enforced convention that maps the nicknames to actual role names. The scheme is described in the section _"Avoiding collision of local role names"_, below.

Briefly:

- Database names follow this strict convention: _d0, d1, ... d9, d10, ... d99, d100, ..._ — in other words, a lower-case _d_ followed by a (non-negative) integer that has no leading zeroes. Because these names convey nothing about purpose, you use the _"comment on"_ SQL statement to do this.
- Role names follow this strict convention: _database-
- name$role-nickname_. (It's this that supports the notion of a _local role_. See the section _"Introducing the "local role" convention"_ below.) A role nickname must use only lower-case latin letters, digits, and underscores; and it must start with a letter. An example of such a nickname is _test42_. And, as we shall see, you think of it, and deal with it, by this nickname. This means that the databases _d7_ and _d19_ can each have their own local roles, respectively _d7$test42_ and _d19$test42_. 

## The underlying generic PG features that determine the challenge—and how YBMT overcomes these

This section revises the key concepts that you must understand in order to appreciate the challenge that the YBMT scheme addresses. And it describes, in concept, how the scheme addresses these challenges. You need to have a solid understanding of the concepts, the mechanisms, the syntax, and the terms of art that belong to this general area of PG's functionality. You may already understand this area very well. And if you do, then you'll be able to skim this section quickly.

### Roles, objects, and their scopes

- The space in which _roles_ and _databases_ exist is the entire cluster. And the names of these artifacts must be unique within the entire cluster. For this reason, roles and databases are referred to as *global* artifacts. _Tablespaces_ are also global artifacts—and these three (roles, databases, and tablespaces) are the _only_ kinds of global artifact. Notice that, as far as the specific YBMT scheme is concerned, tablespaces are never mentioned. However, the conventions that YBMT defines and supports with code could be extended, in a natural way, to include tablespaces.
- The space in which _schemas_ exist is a particular database. The name of a schema must be unique within a database. While databases _d1_ and _d2_ can each contain a schema called _s_, you cannot refer to both in the same SQL statement. There is therefore no qualified notation like _d1.s_. In short, you cannot create a session without specifying a database to which to connect. The session is then bound to that database for the rest of its lifetime—and it can see only _objects that exist inside that database_ together with other databases (as opaque objects), roles, and tablespaces.
- The ability for a cluster to contain two or more databases does not bring any semantics. Rather, it's purely a practical scheme to support multitenancy—where the granule of provisioning is the database.
- The space in which so-called _schema-objects_ (like tables, user-defined functions and procedures, user-defined types, and so on) exist is a particular schema within a particular database. The name of a schema-object must be unique within a particular schema for a particular set of kinds of object. You _can_ refer to schema-objects in difference schemas (in the same database) within a single SQL statement—so, here, schema-qualified names are legal and meaningful. Suppose that you create a session by connecting to database _d1_, authorizing as role _r1_ (for example, using the _"\c d1 r1"_ meta-command in _ysqlsh_ or _psql_). You can then do this:

  ```
  create schema s1;
  create schema s2;
  
  create table s1.t(k serial primary key, c1 text not null);
  insert into s1.t ...
  
  create table s2.t(k serial primary key, c2 text not null);
  insert into s2.t ...
  
  select a1.c1, a2.c2
  from s1.t as a1 inner join s2.t as a2 using(k);
  ```
  
  Notice that neither the role name nor the database name appears in the SQL statements—and nor can they. Different objects in the same database (both schemas and schema-objects) can have different owners. An object is (initially at least) owned by the role that creates it. Object ownership is a key component of the privilege model. If schema _s1_ is owned by role _r1_, a session whose _current_role_ is _r2_ cannot use any schema-object in schema _s1_ unless _r2_ is first granted the _usage_ privilege on schema _s1_. This necessary condition isn't sufficient. For example, _r2_ cannot select rows from table _s1.t_ unless it additionally has been granted the _select_ privilege on this table. And this alone does not allow _r2_ to change the content of _s1.t_. 

  Further, you can define both a function and a table with the same name in the same schema. But you cannot define both a view and a table, or both a function and a procedure, with the same name in the same schema. The sub-space within a schema within which names must be unique is called a _catalog_—and a catalog has a name. For example, tables and views are in the _pg_class_ catalog; functions and procedures are in the _pg_proc_ catalog; and types are in the _pg_type_ catalog.

- Schemas and schema-objects are referred to as _local_ objects—local, that is, to a particular database and visible only to sessions that are connected to that database.

- Artifacts like a trigger or a constraint are _secondary-objects_. A secondary-object cannot exist autonomously like a schema or an object can. Rather, a secondary-object must "hang off" a schema-object. For example, a trigger must hang off a table. Secondary-objects are transitively local objects. The name of  a secondary-object must be unique within the schema-object off which it hangs. In other words, two tables, _s1.t_ and _s2.t_ can each have a constraint called _c_.

### Artifacts, roles, and objects

A role is the principal that owns things. Tautologically, a role has no owner and it is not an object. (This is why the term "artifact" was used as the umbrella for roles and objects.) Any artifact that is not a role is, tautologically, some kind of object—either global or local. And every object has an owner. (Strictly speaking, a secondary-object does not have a direct owner. Rather, it inherits its ownership from the owner of the schema-object off which it hangs. This subtle distinction has no consequence for the YBMT scheme.)

### The native PG features allow too much freedom

PG's mechanisms allow you to configure a role so that it can connect to zero, to just one, or to several, databases. A role that has _"...with superuser..."_ can connect to _any_ database, including ones that are still to be created without itself needing explicit privileges to allow this. But a role that does not have _"...with superuser..."_ cannot connect to a database unless it has the explicitly granted _connect_ privilege that allows this. Notice that, the _connect_ privilege on a database (just like _any_ object privilege) can be granted to _public_. However, the conventions of the YBMT scheme disallow this. Two other privileges govern what a role can do within a database.

- The _create_ privilege governs object creation. When role _r1_ has _create_ on database _d1_, it can create schemas within database _d1_. And then _r1_ can create schema-objects within any schema that it owns. (Any object is owned, initially, by the role that creates it. But the ownership of an existing object can be changed.)
- The _temporary_ privilege governs the creation of objects within a database's temporary schema. This schema is referred to using the alias _pg_temp_. But it might have a different actual name, like _pg_temp_3_.
- Just as a role that has _"...with superuser..."_ can connect to _any_ database without needing the explicit _connect_ privilege, so can such a role create schemas, regular schema-objects, and temporary objects without needing the explicit _create_ and _temporary_ privileges.

Notice, though, that a database has attributes that are set at _create_ or _alter_ time by _"...with allow_connections... connection limit..."_. The argument of the _allow_connections_ keyword is _true_ or _false_; and the argument of the _connection limit_ keyword pair is _-1_, _0_, or a positive integer. Zero means what it says. And _1_ is short hand for "unlimited". These notions have the obvious meaning for a role that does not have _"...with superuser..."_. But _connection limit_ has no effect for a role that has _"...with superuser..."_.

>  **NOTE:** When _allow_connections_ is _false_ for a database, this prevents even a role that has _"...with superuser..."_ from connecting to that database. Typically, a template database, once it has been (optionally) populated with objects that any database that's created by using that template will inherit, is altered so that _allow_connections_ is set to _false_. 

The freedom that allows a regular role (i.e. one that has no special attributes) to connect to two or several databases, and to own objects in these, is a nuisance—and brings all sorts of problems. The YBMT scheme strictly limits this freedom.

This regime is further complicated by some historical PG rules that, for compatibility reasons, will never be changed. Various kinds of object, when they are first created, already allow the _public_ role certain operations upon these. (Every role non-negotiably has the _public_ role.) The critical point for the present discussion is that a newly-created database has the _connect_ and _temporary_ privileges _effectively_ granted to _public_. Notice the qualifier _effectively_. This is a subtle point. A newly-created database has _pg_database.datacl_ set to _null_. If, subsequently, _connect on _d1_ is granted to _r1_, then _pg_database.datacl_ is set to a _not null_ value that explicitly represents not just the newly granted privilege but also the privileges that _public_ has. Try this:

```
\c yugabyte yugabyte
create database d1;
select (datacl is null)::text
from pg_database
where datname = 'd1';
```
The result is _true_. And the semantics _"datacl is null"_ is the same as if _connect_ and _temporary_ had been granted explicitly. Now do this:

```
create function rname(oid_in in oid)
  returns text
  language sql
as $body$
  select case
           when oid_in = 0::oid then 'public'
           else (select r.rolname::text from pg_roles r where r.oid = oid_in)
         end;
$body$;

prepare qry as
with
  c(r) as (
    select aclexplode(datacl)
    from pg_database
    where datname = 'd1')
select rname((r).grantee) as grantee, (r).privilege_type
from c;

create role r1;
grant connect on database d1 to r1;
execute qry;
```

This is the result:

```
 grantee  | privilege_type 
----------+----------------
 public   | TEMPORARY
 public   | CONNECT
 yugabyte | CREATE
 yugabyte | TEMPORARY
 yugabyte | CONNECT
 r1       | CONNECT
```

The implicit grants of _connect_ and _temporary_ to pubic have now been made explicit. In addition to the explicitly granted privilege for _r1_, the implicit privileges for the owner, _yugabyte_, and for _public_, are now also explicit.

## The YBMT conventions

The YBMT scheme works by defining critical notions by convention and by enforcing these conventions programmatically. For example, during the initial pass when a cluster is configured as a YBMT cluster, all privileges for _public_ are revoked from each of the three starting databases, _yugabyte_, _template0_, and _template1_. Then, whenever a database is created, all privileges for _public_ are revoked from it. For good measure, this is checked thus, following any database provisioning operation:

```
declare
  bad_dbs constant name[] :=(
      select array_agg(datname)
      from pg_database
      where has_database_privilege('public', datname, 'connect')
      or    has_database_privilege('public', datname, 'create')
      or    has_database_privilege('public', datname, 'temp')
    );
begin
  assert (bad_dbs is null or cardinality(bad_dbs) = 0),
    'databases found with privs granted to public:'||e'\n'||bad_dbs::text;
end;
```

### Introducing the "local role" convention

It is possible for a particular role to own objects in two or several databases. The most  familiar example of this is the so-called bootstrap superuser. It owns, _inter alia_, the _pg_catalog_ schema, and all of the schema-objects within it, in every database. The YBMT scheme creates a special role called _clstr$mgr_ set up thus:

```
... with nosuperuser createrole createdb ...
```

and this, too, owns objects in every database in a few dedicated schemas—for example, the _mgr_ schema. Just as is the case with the objects that the bootstrap superuser owns, those that _clstr$mgr_ owns are brought by the _template1_ database. This is customized by the _.sql_ scripts that define the YBMT scheme. (The bootstrap database is, of course, a special case. The objects that it contains that _clstr$mgr_ owns are created explicitly as part of configuring a YBMT cluster.)

Having a role own the same set of objects in every database, by virtue of the content of _template1_, is useful in that it defines the standard starting content of a new database that's created with reference to that template database. However, this seems to be the _only_ use case for allowing a role to own objects in more than one database. Therefore, the only two possibilities that seem to make sense are:

- _either_ a role owns the same set of objects in _every_ database, or no objects at all.
- _or_ a role owns objects only in _exactly one_ database (or owns no objects at all).

The YBMT scheme defines the terms _local role_ and _global role_ thus:

- A _local role_ can connect to _exactly one_ database and can own objects only in that database.
- A _global role_ can connect to _every_ database (or, if it's a pure role that doesn't allow login, to no database at all). A global role must own the same set of objects in _every_ database (or no objects at all). More carefully stated, it owns the same set of objects in every _tenant database_ (see below). The YBMT rules allow a _global role_ to own a different set of objects in the _bootstrap database_ (see below) than it does in all other databases.

Nothing in the native PG functionality enforces such a convention. But the YBMT scheme achieves this by delegating role creation to dedicated _"security definer"_ role provisioning procedures, owned by _clstr$mgr_, in the _mgr_ schema brought by the customized _template1_ database.

The configuration of a YBMT cluster sets the password of the bootstrap superuser to _null_ so that it cannot be used to start a session—except by using a client that runs on (one of) the server node(s) and that uses _"local, peer"_ authentication. And it creates a second superuser called _yugabyte_ that will be used (albeit very rarely) to start a session that can do what it has to _only_ as a superuser.

### Defining "bootstrap database" and "tenant database"

After the YBMT configuration has been done, template databases are set so that they don't allow connections. Because no session can be started without connecting to a database, at least one non-template database is, therefore, essential to allow the cluster to be used. We'll call this database the _bootstrap database_. The YBMT configuration creates this database with the name _yugabyte_ with the bootstrap superuser, _postgres_, as its owner.

A freshly-configured YBMT cluster has _only_ these three databases: _template0_, _template1_, and _yugabyte_,

Thereafter, new databases are created _only_ using a dedicated script. This script uses some PL/pgSQL procedures that were created as part of the initial YBMT creation. We'll call such a database a _tenant database_.

>  **NOTE:** Because of profound architectural reasons, neither _"drop database"_ nor _"create database"_ can be executed from an anonymous PL/pgSQL block (a.k.a. a _"do"_ statement) or from a user-defined procedure. (This second restriction holds whatever the procedure's _language_ is.) This is why a _psql/ysqlsh_ script (or, say, a Python program) must be used. See the section _"Using a .sql script to write and execute another .sql script"_.

A YBMT cluster has, therefore exactly and only:

-  the _template0_ and _template1_ databases
- the _yugabyte_ bootstrap database
- zero, one, or several tenant databases with names like _d0, d1, ... d9, d10, ... d99, d100, ..._ that are enforced by the tenant database creation script.

A local role, by construction, is able to connect only to exactly one tenant database. For example, the role _d7$test_ can connect only to the database _d7_.

### Role provisioning

As long as people who are trusted to create a session as the _yugabyte_ superuser or as the _clstr$mgr_ special role for provisioning databases and roles know, and promise to follow, the YBMT rules, every role will be guaranteed to be either a global role or a local role. The global roles are created during the one-time configuration of a YMBT cluster. And _postgres_, _yugabyte_, and _clstr$mgr_ are the only global roles that the YBMT scheme allows. (Moreover, the convention insists that the _session role_ built-in function will never report _postgres_.)

>  **NOTE:** There exist other global roles, supplied by the system, whose sole purpose is to simplify the granting of privileges and that cannot be used to start a session. The account of the YBMT scheme doesn't need to describe, or to constrain, these.

Following the configuration of a YBMT cluster, roles are created only during scripted database creation or later by using the role-provisioning procedure _cr_role()_. This guarantees that the only roles that allow connection apart from the global roles _yugabyte_ and _clstr$mgr_ will be local roles. 

### Avoiding collision of local role names

Name collision is avoided by a _convention_ that is strictly enforced by user-defined procedures.

- Database names follow this strict convention: _d0, d1, ... d9, d10, ... d99, d100,_ and so on—in other words, a lower-case _d_ followed by a (positive) integer that has no leading zeroes. Because these names convey nothing about purpose, you use the _"comment on"_ SQL statement to do this.
- Role names follow this strict convention: _database-name$role-nickname_. A role nickname must use only lower-case latin letters, digits, and underscores; and it must start with a letter.

These conventions are enforced by the one-time bootstrap that sets up the YBMT environment and thereafter, within any particular database, by PL/pgSQL procedures for role provisioning and management. For example:

- When _cr_role('mary')_ is invoked when _current_database()_ reports _d7_, the result is to create the role called _d7$mary_.
- When _set_role('mary')_ is invoked when _current_database()_ reports _d7_, the result is to set the role to _d7$mary_.
- When _grant_priv('usage', 'schema', 's', 'mary')_ is invoked when _current_database()_ reports _d7_, the result is to grant _usage_ on the schema _s_ to the role _d7$mary_.

The role-provisioning procedures are brought by _template1_ and are owned by _clstr$mgr_ (i.e. _not_ by a superuser) honoring the practice advice from the PG documentation quoted above. This advice, in turn, honors the general principle of least privilege.

The regime is aided by a further enforced convention. When database _d7_ is provisioned, a dedicated ordinary role _d7$mgr_ is created as its manager and _execute_ on the various role-management procedures is granted to this role. This role is ordinary in the sense that it has no powerful attributes set. In particular, it is created _"... with nosuperuser nocreatedb nocreaterole ..."_. It is special _only_ by virtue of being empowered to execute the role-management procedures. When _d7$mgr_ invokes _cr_role('mary')_, the procedure also grants _d7$mary_ to _d7$mgr_ so that, later, a session whose _session_user_ is _d7$mgr_ can invoke _set_role('mary')_. Because the _set role_ SQL statement doesn't itself require a password, all that's needed to work within the particular database _d7_ is to start by authorizing as _d7$mgr_.

The net effect is that the _.sql_ scripts that implement a case-study need to spell the database name and the name of its manager role _only_ in the context of one (or a small few) _"\c"_ meta-commands. It's therefore a trivial effort to repurpose such a set of scripts to use _any_ database.

## The YBMT implementation

The YBMT scheme is implemented by three major cluster-level operations, each orchestrated by its own _.sql_ master script:

- To initialize a cluster as a YBMT cluster.
- To (re)create tenant databases.
- To drop tenant databases.

Then, at the tenant database level, each is provided with a set of role provisioning procedures, brought by the _template1_ database, to create, configure, and drop local roles for that database.

The _template1_ database also brings some views and generic utilities that proved to be useful while developing the YBMT scheme and while installing and running the case-studies. Most notable among these are views that encapsulate frequently-used joins among the catalog tables (for example, to show the name of the owner and the name of the schema for a schema-object). Some of these join views are further encapsulated by table functions that make the output easier to read than the output of a simple SQL query against the join view.

All of these operations, both at cluster-level and at tenant-database-level, are described in the following subsections. It is recommended that you try these operations as soon as you have understood enough from what follows to know what to type. Then you can study the code further to learn how it all works.

### Before starting to use the code

Everything that follows assumes that you will use only _psql_ and _ysqlsh_ and that you connect to a PG cluster and to a YB cluster somewhere convenient. The YBMT scheme was developed using _psql_ and _ysqlsh_ running directly on macOS Big Sur on a typical "developer" MacBook. However, no assumptions are made about where the PG cluster and the YB cluster each is located beyond the obvious: that the _psql_ and _ysqlsh_ clients can see them and connect to them. It's assumed that you know how to install the PG and YB software and how to create clusters.

>  **NOTE:** The YBMT scheme was developed using a PG cluster and a single-node YB cluster installed in a Parallels virtual machine  running on the same MacBook. This works very well for supporting the intended pedagogy. Notice, though, that the client-scripts implicitly assume that the YB cluster has just a single node. The assumption is embedded in the logic that is used to kill sessions when the aim is to drop a tenant database or to drop a role. (The _"drop database"_ and _"drop role"_ SQL statements are blocked when, respectively, another concurrent session is connected to the to-be-dropped database or is authorized as the to-be-dropped role.) The "kill sessions" scheme makes naïve use of the _pg_terminate_backend()_ built-in function, driven by querying the _pg_stat_activity_ catalog table. This is an inherently single-node approach. So far, YSQL provides no corresponding native features to kill all sessions cluster-wide that meet some criterion. However, it does support the low level primitive that allows you to implement such a scheme: the _yb_servers()_ function. An Internet search for this function finds the Stack Overflow question _["Which YugabyteDB node am I connected to?"](https://stackoverflow.com/questions/70345854/which-yugabytedb-node-am-i-connected-to)_ It is answered by Yugabyte Developer Advocate Franck Pachot. You could write, for example, a Python script, that uses _yb_servers()_ to list the cluster's nodes and then connect to each in turn to execute the scheme that is exemplified here by the procedure _kill_all_sessions_for_specified_database()_ in the file _"01-cr-kill-all-sessions-for-specified-database.sql"_ and by the procedure _kill_all_sessions_for_role()_ in the file  _"09-cr-tenant-role-mgmt-procs.sql"_.

There are, inevitably, some references to directories and paths (in the client-side environment) in what follows and in the _.sql_ scripts themselves. These assume that you clone the _"ysql-case-studies"_ repo to a machine with a Linux-like operating system and that you run _psql_ and _ysqlsh_ there. If you prefer to use a Windows laptop, then it will be simplest to work entirely within a Ubuntu virtual machine. While the PG client code is available for Windows, the YB client code is not. If you insist on using Windows natively, then you can simply use _psql_ to connect to YB as well as to PG. 

It doesn't matter where, in your machine's directory hierarchy, you create your local _git_ clone of the [ysql-case-studies](https://github.com/YugabyteDB-Samples/ysql-case-studies) repo. But notice that some of the case-studies use the _"\copy"_ meta-command to install data—and this works best when the target file is specified using an absolute path.

> **NOTE:** The _"\copy"_ meta-command has no syntax ("like _"\copyr"_ is to _"\copy"_ as _"\ir"_ is to _"\i"_) to express that a relative path is to be treated as relative to the directory where the script in which it is invoked is found. Rather, it's always taken as relative to the current working directory from which _psql_ or _ysqlsh_ is invoked. Nor does _"\copy"_ understand an environment variable.
>
> In order to be able to use scripts that invoke _"\copy"_ when _psql_ or _ysqlsh_ is invoked from two or more different directories (as the scripts brought by the [ysql-case-studies](https://github.com/YugabyteDB-Samples/ysql-case-studies) repo do) you therefore have to use an absolute path. Because this might be quite long, you can use a symbolic link (which "\copy" does understand).
>
> The _"\copy"_ targets are denoted, in the _.sql_ scripts that are brought by cloning the [ysql-case-studies](https://github.com/YugabyteDB-Samples/ysql-case-studies) repo all start like this:
>
> ```
>/etc/ysql-case-studies/
> ```
> 
> If you don't clone the repo directly under _/etc/_, you can specify the absolute path by defining a symbolic link.
>
> Of course, you don't have to use a path that starts at _"/etc/"_. But if you don't, then you'll have to do a global search-and replace for the _"\copy"_ invocations. (There are only a small few of these.)
>
> If you use Windows natively to run _psql_ (and sacrifice the use of _ysqlsh_), then you'll have to make some changes to how you specify paths and accommodate the differences between how Windows and Linux handle symbolic links.

### (Re)initialize a cluster as a YBMT cluster

This is implemented by the script _"01-re-initialize-ybmt-clstr.sql"_. It authorizes as the superuser _yugabyte_.

As long as the _template0_ and _template1_ databases, the bootstrap superuser with the name _postgres_, the superuser _yugabyte_ (with a known password), and the database _yugabyte_ (set to allow connection), are present, it doesn't matter what other artifacts, if any, might be present. (But you must accept that any such will be sacrificed.)

The script _"00-post-creation-bootstrap.sql"_ ensures that these conditions are met, both for a freshly-created PG cluster and for a freshly-created YB cluster. (Of course, a newly-created PG cluster has no _yugabyte_ role or _yugabyte_ database.) If you incorporate this into a Linux shell script that drops and re-creates the cluster, and that configures password authentication, then you'll be able to run  _01-re-initialize-ybmt-clstr_ immediately after re-creating a cluster from scratch. It isn't necessary to configure your cluster to use password authentication. But you'll get the most realistic experience if you do this. This is why the _"00-post-creation-bootstrap.sql"_ script sets a known password for the _yugabyte_ superuser.

The _"01-re-initialize-ybmt-clstr.sql"_ script drops everything that it needs to in order to define a standard starting state and then does the required configuration. The configuration creates the _clstr$mgr_ and _clstr_developer_ roles and creates views, procedures, and other schema-objects in dedicated schemas in the _yugabyte_ database and in the _template1_ database.

- The _mgr_ schema in the _yugabyte_ database is configured with procedures that support the provisioning of tenant databases.
- The _template1_ database is provisioned with: procedures, in the _mgr_ schema, that support a standard way to provision local roles in any tenant database; some domains, in the _dt_utils_ schema and associated procedures that rationalize interval arithmetic; and the _pgcrypto_ and _tablefunc_ extensions in the _extensions_ schema. The _mgr_ schema also has some views that encapsulate typically useful join queries between the _"pg_catalog"_ tables and some table functions to render the output of queries against these views (using whitespace, and similar, to improve readability). In addition, the configuration creates a small few functions and procedures in the _client_safe_ schema. These are considered to be safe for use by sessions that authorize as the _dN$client_ role (see below) to allow client-side application developers to test, and time, the application's API procedures that are exposed for this role using _psql_ or _ysqlsh_.

  Of course, you can modify this starting regime to add other extensions according to your needs. Notice that the YBMT concept rests on this initial configuration of the cluster so that the provisioning of tenant databases and local roles for these is standardized and doesn't need a session that authorizes as a superuser. If you insist on installing different extensions in different tenant databases, then you'll have to break the paradigm and authorize as a superuser _after_ provisioning the tenant database in question.

It's best to understand the real detail by reading the _.sql_ scripts themselves. They are organized under these three directories:

- _"11-initialize-clstr"_
- _"12-schema-objects-for-template1"_
- _"13-schema-objects-for-yugabyte-db-only"_

The scripts themselves have descriptive names. For example, this:

- _"11-initialize-clstr/05-customize-template1.sql"_

sets the attributes of the _template1_ database and invokes the various scripts on the sibling _12-schema-objects-for-template1_ directory. (You'll see, too, that _"01-re-initialize-ybmt-clstr.sql"_ invokes all of the scripts on the _"13-schema-objects-for-yugabyte-db-only"_ directory and also some of the scripts on the _"12-schema-objects-for-template1"_ directory.

The result of running _"01-re-initialize-ybmt-clstr.sql"_ is  an empty YBMT cluster (i.e. one with no tenant databases).

### Drop and re-create _N_ tenant databases

This is implemented by the script _"02-drop-and-re-create-tenant-databases.sql"_. It authorizes as the _clstr$mgr_ role whose purpose is directly to provision tenant databases and indirectly to provision local roles via the _security definer_ procedures that it owns for this purpose that are brought by _template1_.

The script can be used with any arbitrarily populated YBMT cluster. The action is determined by the two _psql_ variables _:lower_db_no_ and _:upper_db_no_. These must be set to strings that can be typecast to SQL _integers_. The pair of values denotes the intended set of tenant databases. For example, setting _:lower_db_no_ to _3_ and _:upper_db_no_ to _7_, denotes the databases with names _d3, d4, d5, d6_, and _d7_. Any of these that might already exist are dropped. Then the full set that you specified is created. Of course, _:upper_db_no_ must be greater than or equal to _:lower_db_no_. Setting the two values equal to each other specifies just a single database.

The script assumes that, following the initial configuration with _01-re-initialize-ybmt-clstr_, thereafter only sanctioned YBMT scripts (this one or _"04-drop-tenant-databases.sql"_), or the role-provisioning procedures (_cr_role()_, _drop_role()_, and so on) have been used for database and role provisioning.

A freshly-provisioned tenant database comes with two dedicated local roles. Their names follow the naming convention of local roles. The following uses _dN_ to stand for any tenant database, _d0_, _d7_, _d42_, or whatever.

- _dN$mgr_

  This role has no special attributes. In particular, it's created _"with inherit nosuperuser nocreatedb nocreaterole login"_. But it, uniquely among the local roles for a particular tenant database, has the _execute_ privilege on the role-provisioning procedures that _clstr$mgr_ owns and that are brought by _tenant1_. The _clstr$developer_ role is granted to the _dN$mgr_ role.
  
- _dN$client$_

  This role has no special attributes. In particular, it's created _"with noinherit nosuperuser nocreatedb nocreaterole login"_.  Its purpose is to support client-side applications whose database backend is implemented by _dN_ and to allow such sessions to use exactly and only the intended application functionality. Critically, the _clstr$developer_ role is _not_ granted to the _dN$client_ role. The idea is that privileges that, in a freshly-created cluster, are granted to _public_ are revoked from that and are then re-granted to _clstr$developer_. This is done by the _"01-re-initialize-ybmt-clstr.sql"_ script. (See the section _«Implementing the principle of least privileges for "client" roles»_). This means that sessions that authorize as _dN$client_ are not able to use these objects. For example, they cannot query the _"pg_catalog"_ tables and views.

Notice that local roles created using _cr_role()_ are expected to own the schema-objects that implement an application's database backend but are _not_ intended to be used for authorizing client-side sessions. One effect of _cr_role()_ is to grant _clstr$developer_ to the newly-created role.

### Drop _N_ tenant databases

This is implemented by the script _"04-drop-tenant-databases.sql"_. It authorizes as the _clstr$mgr_ role.

The action of this script, too, is determined by the two _psql_ variables _:lower_db_no_ and _:upper_db_no_. These have the same meaning that they have for the _"02-drop-and-re-create-tenant-databases.sql"_ script. But the effect, of course, is just to drop any tenant databases that might exists that have names in the specified set. To drop all tenant databases and restore a populated YBMT cluster to the state that it has immediately following running _"01-re-initialize-ybmt-clstr.sql"_, simply set _:lower_db_no_ to _0_ and set _:upper_db_no_ to an arbitrarily large number like _9999_. It doesn't take measurably longer if you specify a huge range like this than if you take care just to cover the actual range that the names of the tenant databases that you happen to have spans. And it's quicker to do this than it is to run the _"01-re-initialize-ybmt-clstr.sql"_ script. Simply dropping all extant tenant databases is preferable, too, because it requires authorizing only as _clstr$mgr_ rather than as the superuser _yugabyte_. (Of course, the result is the same, whichever approach you use.)

### Convenience partner scripts

The scripts _"03-drop-and-re-create-tenant-databases-driver.sql"_ and _"05-drop-tenant-databases-driver.sql"_ are provided as a convenience. Each simply sets the _:lower_db_no_ and _:upper_db_no_ _psql_ variables and then invokes, respectively, _"02-drop-and-re-create-tenant-databases.sql"_ or _"04-drop-tenant-databases.sql"_ to do the real work. You might like to define _psql_ variables with short names in the _psqlrc_ startup file so that you can invoke any of these three main actions with a couple of keystrokes no matter what happens to be the current directory. For example:

```
\set RC '\\i /etc/ysql-case-studies/ybmt-clstr-mgmt/01-re-initialize-ybmt-clstr.sql'
\set RT '\\i /etc/ysql-case-studies/ybmt-clstr-mgmt/03-drop-and-re-create-tenant-databases-driver.sql'
\set DT '\\i /etc/ysql-case-studies/ybmt-clstr-mgmt/05-drop-tenant-databases-driver.sql'
```

### Using a _.sql_ script to write and execute another _.sql_ script

Because of profound architectural reasons, neither _"drop database"_ nor _"create database"_ can be executed from an anonymous PL/pgSQL block (a.k.a. a _"do"_ statement) or from a user-defined procedure. Nor, for that matter, is it possible to create a session from an anonymous block or a user-defined. You can operate inside a database only when you have already connected to it (and you can choose the database only when a session is created).

These limitations present a challenge for the three major cluster-level operations

- to initialize a cluster as a YBMT cluster
- to (re)create tenant databases
- to drop tenant databases

because each needs to drop or create and configure several databases.

The overwhelmingly most common way to implement the creation and configuration of many database artifacts, which task requires many DDL statements and the like, is to write _.sql_ scrips and to execute them with _psql_ or _ysqlsh_. This approach is preferred over using, say, a Python program because you simply type up the intended SQL statements "as is" in text files without any adorning syntax beyond the semicolon SQL statement terminator. The text of a Python program that has the same effect will be much more verbose, and voluminous, because  the SQL statements must be presented as text strings which in turn must be submitted using dedicated syntax. One _.sql_ script can invoke another. And this gives you, effectively, a subroutine paradigm. The story of formal and actual arguments is rather non-standard. (You have to set _psql_ variables in the calling script and read them in the callee script.) But it works well enough.

Moreover, the _psql_ scripting language supports terse meta-commands for, for example, creating a session and for controlling  the verbosity of error reporting. The scripting language even supports the _if-then-else_ construct, using meta-commands, where you test a so-called _psql_ variable that you can set using a _select_ statement. However, the _psql_ scripting language dos not support a construct for looping. You typically don't notice this as a limitation because you can execute the SQL statements that you intend to from an anonymous _PL/pgSQL_ block or, if appropriate, from a _PL/pgSQL_ procedure that your scripts created earlier.

This is where the limitation that you cannot execute _"drop database"_ or _"create database"_ from _PL/pgSQL_ hits you. However, a well-known, and straightforward, approach comes to the rescue. You simply use _PL/pgSQL_ to write a _.sql_ script (a table function does this most conveniently) and spool its output to a file using the _"\o"_ meta-command. Then you immediately execute the just-written script using the _"\i"_ meta-command. This approach is used by each of the scripts that implement the three operations listed at the start of this section. The _random()_ built-in function is used to create a name from the generated script on the _/tmp/_ directory. And the meta-command _"\! rm [filename]"_ is used to delete the generated script once it's been executed.

### The role-provisioning procedures

This section lists the procedures that the _dN$mgr_ role will use to create, configure, or drop local roles for the tenant database _dN_. They are all installed in the _mgr_ schema. (Some of the procedures are executable, too, by any role that _dN$mgr_ creates.) Recall that the _dN$mgr_ role is created by the _"02-drop-and-re-create-tenant-databases.sql"_ script; and this has to authorize as _clstr$mgr_. Recall, too, that the _dN$mgr_ role has only ordinary attributes and therefore cannot create, alter or drop roles (or databases) explicitly. Its ability to do role-provisioning is brought entirely by the _"security definer"_ procedures, owned by _clstr$mgr_, on which it has been granted the _execute_ privileges (without _"grant option"_). And these procedures use the _current_database()_ built-in function to enforce the rule that the _dN$mgr_ role can provision only local roles for the database _dN_. The _dN$mgr_ role is not empowered to do database provisioning. This design is key to the integrity of the YBMT conventions.

Each of the procedures _cr_role()_, _drop_role()_, _set_role_password()_, _set_role_search_path()_, _grant_priv()_, and _set_role()_ has a _"nickname"_ formal argument. This is always interpreted in the same way. For example, when _cr_role()_ is invoked with, say, _nickname=>'mary'_, it creates the local role _dN$mary_, for the database _dN_.

#### cr_role()

Executable only by _dN$mgr_. Here is the signature:

```
procedure mgr.cr_role(
  nickname         in text,
  with_schema      in boolean = true,
  with_temp_on_db  in boolean = false,
  comment          in text    = 'For ad hoc tests')
```

The procedure creates a local role with these attributes:

```
inherit nosuperuser nocreaterole nocreatedb noreplication nobypassrls
in role clstr$developer
connection limit 0 nologin password null
```

As mentioned, _"connect on database current_database() with grant option"_ is granted to the new role. So also is _"create on database current_database() with grant option"_.

The choice of _"with connection limit 0 nologin password null"_ is deliberate. The _mgr.cr_role()_ procedure also grants the new role to _dN$mgr_. (The fact that the _clstr$mgr_ role is created _"with createrole"_ empowers it to grant any non-superuser role to any other role.) This means, in turn, that a session that authorizes as _dN$mgr_ can use the _"set role"_ statement to change its current role to, for example, _dN$mary_ (without needing a password) so that the _session_user_ built-in function will now continue to report _dN$mgr_ while the _current_role_ built-in function will now report _dN$mary_—and will now act with only the privileges that have been explicitly granted to _dN$mary_ (together with what the _clstr$developer_ role brings) but _without_ the privileges that are granted to _dN$mgr_. The philosophy is that developers will, in general, need to work with the artifacts owned by any of the roles that jointly own the application's database backend—and so one single authorization challenge is enough. (The same thinking holds for patching an in-use application backend.)

Here are the meanings of the defaulted parameters:

- _with_schema_: When this is _true_, a schema called _nickname_ is created, owned by the new role and with _usage_ revoked from _public_. Regard this as nothing more than a convenience shortcut for the common case that a local role will own only one schema. Once _"set role"_ has been used to switch identity to, say, _dN$Mary_, then _"create schema"_ can be used to create any number of schemas that inevitably will then be owed by _dN$Mary_.
- _with_temp_on_db_: When this is _true_, _"temporary on database current_database()"_ is granted to the new role.
- _comment_: the actual argument for this is used by the _"comment on role"_ SQL statement to document the purpose of the new role.

#### drop_role()

Executable only by _dN$mgr_. Here is the signature:

```
procedure mgr.drop_role(nickname in text)
```

The procedure executes _"drop owned by... cascade"_ and then _"drop role"_ for the specified role. Because the to-be-deleted role is, by construction, a local role for the database _dN_, just a single invocation of _"drop owner by..."_, when $dN_ is the current database, is sufficient to guarantee that the subsequent invocation of _"drop role"_ will succeed.

#### drop_all_regular_local_roles()

Executable only by _dN$mgr_. Here is the signature:

```
procedure mgr.drop_all_regular_local_roles()
```

A "regular" local role is any local role for the current database except for _dN$mgr_ and _dN$client_. The procedure discovers all the regular local roles and, for each, invokes _mgr.drop_role()_. It therefore restores the tenant database to the state it has immediately following its creation.

#### set_role_search_path()

Executable by _clstr$developer_. Here is the signature:

```
procedure mgr.set_role_search_path(nickname in text, path in text)
```

The procedure executes _"alter role... set search_path..."_ for the specified role to the specified search path.

#### set_role_password()

Executable by _clstr$developer_. Here is the signature:

```
procedure mgr.set_role_password(nickname in text, password in text)
```

The procedure executes _"alter role... with connection limit -1 login password..."_ for the specified role to the specified password. This is expected to be used only very rarely. The motivation use case is when the _dN_ database is used as a sandbox for pedagogy or for experimentation.

#### set_role()

Executable by _clstr$developer_. Here is the signature:

```
procedure mgr.set_role(nickname in text)
```

The procedure executes "_set role..."_ to the specified role.

#### revoke_all_from_public()

Executable by _clstr$developer_. Here is the signature:

```
procedure mgr.revoke_all_from_public(object_kind in text, object in text)
```

The procedure executes _"revoke all on <object_kind>... from public"_ for the specified object kind with the specified name. The actual argument for _object_ can be a schema-qualified identifier.

#### grant_priv()

Executable by _clstr$developer_. Here is the signature:

```
procedure mgr.grant_priv(
  priv              in text,
  object_kind       in text,
  object            in text,
  grantee_nickname  in text)
```

The procedure executes _"grant... on <object_kind>... to..."_ for the specified privilege on the specified object kind with the specified name to the specified role.

#### prepend_to_current_search_path()

Executable by _clstr$developer_. Here is the signature:

```
procedure mgr.prepend_to_current_search_path(p in text)
```

The procedure executes _"set search_path..."_ to _"p||current_setting('search_path')"_.

### The join views for the _pg_catalog_ tables and the table functions wrappers for these

All of these items are installed in the _mgr_ schema. You can read their definitions in the _"07-cr-catalog-views-and-table-functions.sql"_ script. A dedicated view, defined using an explicit list, shows the most useful ones. Try this:

```
select name from mgr.catalog_views_and_tfs order by kind, rank;
```

This is the result:

```
         name          
-----------------------
 dbs_with_comments()
 roles_with_comments()
 roles_and_schemas()
 schema_objects()
 constraints()
 triggers()
 tenant_roles
 roles_and_schemas
 schema_objects
 constraints
 triggers
```

The query adds trailing parentheses to the name to denote that the result is a function. Usually, the table functions will be sufficient for your needs. Most have a single formal argument that lets you choose between a couple of fixed options for how to restrict the output. (See the section _"Useful psqlrc shortcuts"_ below.) If you want to write your own specific restriction criteria, then use the views instead. However, using the view means that you'll lose the nice formatting.

#### Join views for the _pg_catalog_ tables

The system-supplied _pg_catalog_ schema houses a table (or view) for each kind of artifact—for example, _pg_roles_, _pg_database_, _pg_class_, _pg_type_, _pg_proc_, and so on. The generic term for such a table or view is _catalog_. Each of these catalogs has a column for the _oid_. And the column design for each catalog follows a standard pattern. For example, for the catalogs that hold facts about schema-objects, there's  always a column for the object name, the schema that houses it, and its owner. (Of course there are columns that are specific to the object kind too.) However (and following the principles of relational design) the schema and owner are identified by the _oid_ of these artifacts in their dedicated catalogs. This means that a typical _ad hoc_ query needs some joins in order to be ordinarily useful.

Consider the _"hard-shell"_ case-study. The schema-objects that implement this are distributed across several schemas and are owned by several roles. All of these schema-objects will have owners whose names follow the pattern for local roles—that is, they start with _dN$_ (where the integer _N_ denotes the tenant database that houses the case-study). Suppose that you want to get an _ad hoc_ overview of, say, the user-defined functions and procedures. This view (in the database in question) gets the answer:

```
create temporary view procedures(name, kind, schema, owner) as
select
  p.proname,
  case p.prokind::text
    when 'f' then 'function'
    when 'p' then 'procedure'
  end,
  n.nspname,
  r.rolname
from
  pg_proc p
  inner join pg_namespace n on p.pronamespace = n.oid
  inner join pg_roles r on p.proowner = r.oid
where p.prokind::text in ('f', 'p')
and r.rolname::text like 'd%$%';
```

It's easy enough to type this query once you get used to the design of the catalogs and remember their names and the naming conventions for the column names. But even so, typing it takes more time than is consistent with the notion of _"ad hoc query"_. It would help enormously if PG (and therefore YB) shipped with a view like this (with object-kind specific columns, too) for every available kind of schema-object. As it happens, many such shipped views _are_ available. But their names, the schema that houses them, and their column designs don't follow a consistent pattern. And some that you want are not present. Try this. Notice that the restriction on the schema name must include _information_schema_.

```
create temporary view catalogs(schema, name) as
select n.nspname, c.relname
from pg_class c inner join pg_namespace n on c.relnamespace = n.oid
where c.relkind::text in ('r', 'v')
and n.nspname::text in ('pg_catalog', 'information_schema')
and c.relname ~ any(array['tab', 'view', 'seq', 'type', 'dom', 'func', 'proc', 'trig', 'cons']);
```
Here is the result, after manual pruning:

```
       schema       |            name             
--------------------+-----------------------------
 pg_catalog         | pg_sequences
 pg_catalog         | pg_tables
 pg_catalog         | pg_views
 information_schema | check_constraints
 information_schema | domains
 information_schema | referential_constraints
 information_schema | sequences
 information_schema | table_constraints
 information_schema | tables
 information_schema | triggers
 information_schema | user_defined_types
 information_schema | views
```
This looks promising. But there's nothing at all for user-defined functions or procedures. Notice that none of these has an _oid_ column. And the _domains_ and the _user_defined_types_ views (in the _information_schema_ schema) have no _owner_ column. This means that, if you wanted to list triggers of interest by, say, _trigger_name_, _table_name, _table_schema_, and _table_owner_, then you'd have to type the explicit four-way join between _pg_trigger_, _pg_class_, _pg_namespace_, and _pg_roles_. It's even more complicated for constraints if you want to list constraints of _all_ kinds by name and the name, kind, schema, and owner, of the object off which each hangs. (Notice that the _mgr.constraints_ view does this.)

Notice especially that there's no shipped view that lists schema-objects of _all_ kinds. However, writing the SQL to define one is straightforward—albeit pretty lengthy. This is provided as the _mgr.schema_objects_ view.

#### Table function wrappers for the join views for the _pg_catalog_ tables

Some of the columns in the views for the _pg_catalog_ tables are arrays—for example, the schemas that a role owns or the roles that are granted to a particular role. Try this:

```
select schemas from mgr.roles_and_schemas where name = 'clstr$mgr';
```

This is the result:

```
                schemas                
---------------------------------------
 {client_safe,dt_utils,extensions,mgr}
```

When you select all the roles from the _roles_and_schemas_ view, when, for example, the current database houses the _"hard-shell"_ case-study, the result is quite hard to read. The _roles_and_schemas()_ table function formats the results like this:

```
 super?  owner       schemas           granted roles
 ------  ----------  ----------------  ---------------
 super   yugabyte                      
 ------  ----------  ----------------  ---------------
         clstr$mgr   client_safe       clstr$developer
                     dt_utils          
                     extensions        
                     mgr               
 ------  ----------  ----------------  ---------------
         d3$api      api               clstr$developer
 ------  ----------  ----------------  ---------------
         d3$client                     
 ------  ----------  ----------------  ---------------
         d3$code     code              clstr$developer
                     code_helpers      
 ------  ----------  ----------------  ---------------
         d3$data     data              clstr$developer
 ------  ----------  ----------------  ---------------
         d3$json     json_helpers      clstr$developer
                     json_shim         
                     json_utils        
 ------  ----------  ----------------  ---------------
         d3$mgr                        clstr$developer
                                       d3$api
                                       d3$code
                                       d3$data
                                       d3$json
                                       d3$qa
                                       d3$support
 ------  ----------  ----------------  ---------------
         d3$qa       qa_code           clstr$developer
                     qa_json_utils     
                     qa_ui_simulation  
 ------  ----------  ----------------  ---------------
         d3$support  support           clstr$developer
```

Each of the table function wrappers for the join views for the _pg_catalog_ tables does something along these lines to improve the readability with respect to the results that an ordinary SQL query to list the same information would produce.

#### Useful _psqlrc_ shortcuts

You might find it useful to define these shortcuts in your _psqlrc_ file:

```
-- Get an overview of the available table functions.
-- that expose information from the "pg_catalog" tables.
\set lk  '\\t on \\\\ select \'\'; select name from mgr.catalog_views_and_tfs order by kind, name; \\t off'

-- Information about databases and roles.
\set ld  '\\t on \\\\ select \'\'; select z from mgr.dbs_with_comments(); \\t off'
\set ldx '\\t on \\\\ select \'\'; select z from mgr.dbs_with_comments(true); \\t off'
\set lr  '\\t on \\\\ select \'\'; select z from mgr.roles_with_comments(); \\t off'
\set lrx '\\t on \\\\ select \'\'; select z from mgr.roles_with_comments(true); \\t off'

-- Information about the user-created schemas in the current database.
\set ls  '\\t on \\\\ select \'\'; select z from mgr.roles_and_schemas(); \\t off'

-- Information about the schema-objects in the current database.
\set co  '\\t on \\\\ select \'\'; select z from mgr.schema_objects(false); \\t off'
\set lo  '\\t on \\\\ select \'\'; select z from mgr.schema_objects(true);  \\t off'

-- Information about the secondary-objects in the current database.
\set cc  '\\t on \\\\ select \'\'; select z from mgr.constraints(false); \\t off'
\set lc  '\\t on \\\\ select \'\'; select z from mgr.constraints(); \\t off'
\set lt  '\\t on \\\\ select \'\'; select z from mgr.triggers(); \\t off'
```

These allow you to get useful overviews of global artifacts and local artifacts in the current database with just a couple of keystrokes. (If you can remember Linux commands and _psql_ meta-commands for catalog queries, then you'll be able to remember these, too.)

* For databases, you can use: _either_ _":ld"_ to list all databases with their owners, including the bootstrap database and the template databases; _or_ _":ldx"_ to list just the tenant databases with their owners. In each case, the comments are listed too. Compare the output of these shortcuts with that of the _"\lx+"_ meta-command. These shortcuts present a useful restriction in a more readable format than the native meta-command.
* For roles, you can use: _either_ _":lr"_ to list all non-system global roles together with all tenant roles for the current database; _or_ _":lrx"_ to list just those tenant roles that have been created after the database was created by using the _cr_role()_ procedure. (In other words, _":lrx"_ excludes global roles and the _"mgr"_ and _"client"_ tenant roles that are brought by the _"02-drop-and-re-create-tenant-databases.sql"_ script and that have the same purpose in every tenant database.)
* For schemas, _"ls"_ lists the user-created schemas in the current database grouped by owner. The entry for each owner also lists the roles that have been granted to it. (You might think that the granted roles should be listed by the _roles_with_comments()_ table function rather than by the _roles_and_schemas()_ table function. The choice is arbitrary.)
* For schema-objects, _":co"_ lists the _common_ schema-objects—that is the schema-objects in the _client_safe_, _dt_utils_. and _mgr_ schemas that are brought by the _template1_ database. These, by construction, are the same in every existing (and yet-to-be-created) tenant database. And _":lo"_ lists the _local_ schema-objects—that is the schema-objects in schemas other than _client_safe_, _dt_utils_. and _mgr_ that are owned by local roles in the current database.
* For secondary-objects, _":cc"_ lists the constraints that hang off _common_ schema-objects; and _":lc"_ lists the constraints that hang off _local_ schema-objects. As it happens, there are no _common_ tables and therefore there are no nominally common triggers. The _triggers()_ table function makes no distinction between _common_ and _local_ triggers and would list both kinds if instances of each of these kinds existed. The effect, though, is to list only _local_ triggers. This is why its shortcut is called _":lt"_.

### Implementing the principle of least privileges for _"client"_ roles

This section explains a straightforward scheme, implemented by the _"06-xfer-schema-grants-from-public-to-clstr-developer.sql"_ script (called from the _"01-re-initialize-ybmt-clstr.sql"_ script). The scheme revokes the privilege that allows usage on each of about 3.3K objects from _public_ and regrants each of these privileges to _clstr$developer_. The effect is that every local role except for the _"client"_ role enjoys the same regime as it would without this scheme; but that the _"client"_ role experiences a very restricted least privileges regime where it sees only the privileges that have been granted to it explicitly so that it can use the designed application functionality that the tenant database to which it is local implements.

If you don't like this scheme, you can simply comment out the invocation of the _"06-xfer-schema-grants-from-public-to-clstr-developer.sql"_ script—or, if you prefer, comment out sections within that script. The spooled output that the _"0-end-to-end-test.sql"_ master script produces is unaffected by any such change that you might make. But making such changes exposes you to an increased security vulnerability—which vulnerability, as it happens, is the default regime brought by the native PG (and therefore YB) functionality.

One of the most troublesome risks is brought by the information that the tables and views in _pg_catalog_ and _information_schema_ expose. The information gives hackers an understanding that they might be able to exploit for nefarious purposes. For example, without the approach that the _"06-xfer-schema-grants-from-public-to-clstr-developer.sql"_ script code below implements, a session that authorizes as the _"client"_ role can read the source code of all of the user-defined functions and procedures in that tenant database. Reading the source code might allow the hacker to spot, for example, a SQL injection vulnerability in carelessly written code.

#### Background

The principle of least privileges says that you should grant exactly and only those privileges that are necessary to allow an application to function as intended. It brings a regime that contrasts dramatically with the regime that is often seen in real world deployments where an application functions as intended because it has been granted a large set of privileges that includes the necessary ones and that also includes very many that are not needed. Security experts agree that it is very hard to prove that every superfluous privilege is harmless when that set is large.

This section shows that, in the default regime, when a PG or YB client session authorizes to use the designed application functionality that a particular database implements, it also enjoys about three-and-a-half thousand privileges that are not needed. It's hard to defend using this default regime when, as this section explains, it's straightforward to revoke these superfluous privileges.

The _template1_ database, in a freshly-created cluster, has schemas called _"pg_catalog"_ and _"information_schema_". Together, they house about 3.3K "schema-objects of interest" — i.e. objects upon each of which the appropriate privilege to allow its use has been granted to _public_, and where their consequent availability can reasonably be considered to violate the principle of least privileges.

Try this exercise in any newly-created tenant database, like _d0_, in a YBMT cluster.

Create this view to define the list of objects that, by default, each have the appropriate usage privilege (like _select_ on a table or _execute_ on a function)  granted to _public_:

```
\c d0 d0$mgr
create temporary view schema_objects_of_interest(owner, name, kind) as
with
  c(nsp_oid, owner_oid, name, kind) as (
      select relnamespace, relowner, relname, case relkind::text
                                                when 'r' then 'table'
                                                when 'c' then 'type-companion'
                                                when 'v' then 'view'
                                              end
      from pg_class
      where relkind::text != 'i' -- exclude indexes
    union all
      select typnamespace, typowner, typname, case typtype::text
                                                when 'c' then 'composite-type'
                                                when 'd' then 'domain'
                                                when 'r' then 'range'
                                              end
      from pg_type
      where typtype::text != all(array['b', 'p']) -- exclude base- and pseudo-types
    union all
      select pronamespace, proowner, proname, case prokind::text
                                                when 'f' then 'function'
                                                when 'a' then 'aggregate-fn'
                                                when 'w' then 'window-fn'
                                              end
      from pg_proc)
select
  r.rolname,
  c.name,
  c.kind
from
  c
  inner join pg_namespace n on c.nsp_oid = n.oid
  inner join pg_roles r on c.owner_oid = r.oid
where n.nspname::text = any(array['pg_catalog', 'information_schema']);
```

**NOTE:** The _pg_operator_ catalog table is not included in the view's definition because there's no specific privilege that you grant on an operator to allow its use by a role. Rather, an operator's use by a role is allowed, or not, according to whether or not _execute_ on its implementation function is granted to the role. Similarly, indexes are excluded from the _pg_class_ query because there's no specific privilege that you grant on an index to allow its use by a role. Rather, you can access an index only implicitly by doing DML on a table that has an index—and it is the ability of a role to do such DML that is governed by privileges on the table. Base-types and pseudo-types are excluded from the _pg_type_ query because leaving these with _usage_ granted to _public_ (i.e. the regime that obtains in a freshly-created cluster) is not considered to bring any worrisome abilities. (Any object kinds that are not mentioned in the _case_ expressions that produce the human-readable names happen not to exist in _pg_catalog_ or _information_schema_. If they did, they would show up as _null_ in the output.)

Here's where the value, 3.3K, comes from:

```
select count(*) as n, owner
from schema_objects_of_interest
group by owner;
```

This is the result:

```
  n   |  owner   
------+----------
 3348 | postgres
```

Notice that all of the objects are owned by the bootstrap superuser. Now do this:

```
select count(*) as n, kind
from schema_objects_of_interest
group by kind
order by 1 desc;
```

This is the result:

```
  n   |     kind     
------+--------------
 2808 | function
  188 | composite-type
  138 | aggregate-fn
  119 | view
   69 | table
   15 | window-fn
    6 | range
    5 | domain
```

As it happens, creating a table or a view inevitably creates a composite type with the same name. This explains the arithmetic outcome _"(69 + 119) = 118"_ in the list above. Further, creating a composite type inevitably creates a companion row in _pg_class_ with _relkind::text = 'c'_. Notice, though, that the categorization of catalog table rows above has no entry for _"type-companion"_. This shows that, as it happens, there are no explicitly created composite types in _pg_catalog_ or _information_schema_.

Finally, notice that the schema-objects that the _"07-customize-template1.sql"_ script creates are useful to the tenant roles other than the _"client"_ role but might bring a potential security risk if they were accessible to sessions that authorize as the _"client"_ role. So _"06-xfer-schema-grants-from-public-to-clstr-developer.sql"_ script handles these too.

#### What does the "06-xfer-schema-grants-from-public-to-clstr-developer.sql" script do?

All of the schemas except for _pg_catalog_ are trivially handled at the whole schema granularity, thus:

```
revoke usage on schema information_schema  from public;
revoke usage on schema mgr                 from public;
revoke usage on schema dt_utils            from public;
revoke usage on schema extensions          from public;

grant  usage on schema information_schema  to   clstr$developer;
grant  usage on schema mgr                 to   clstr$developer;
grant  usage on schema dt_utils            to   clstr$developer;
grant  usage on schema extensions          to   clstr$developer;
```

The objects in the _pg_catalog_ schema are handled at the individual object granularity because it's possible that just a small few might be useful, and safe, to leave granted to _public_ so that _"client"_ sessions can use them. Look at the script for the full story. The richest example is provided by the treatment of the objects the the _pg_proc_ table lists:

```
do $body$
declare
  kind text;
  proc text;
  candidates constant "char"[] := array['f'::"char", 'a'::"char", 'w'::"char", 'p'::"char"];
  allowlist constant text[] not null := array[
    'current_database',
    'pg_typeof',
    'int4pl',       -- implements the + operator between int values
    'int4mi',       -- implements the - operator between int values
    'int4eq',       -- implements the = operator between int values
    ...
    'textcat',      -- implements the || operator
    'texteq',       -- implements the = operator between text values
    'lpad', 'rpad'
    ];
begin
  -- Ensure known starting state.
  for kind, proc in (
    select
      case p.prokind
        when 'f' then 'function'
        when 'a' then 'function'
        when 'w' then 'function'
        when 'p' then 'procedure'
      end,
      p.oid::regprocedure::text
    from pg_proc p inner join pg_namespace n on p.pronamespace = n.oid
    where n.nspname = 'pg_catalog'
    and p.prokind = any(candidates))
  loop
    execute format('grant execute on %s pg_catalog.%s to public',  kind, proc);
  end loop;

  for kind, proc in (
    select
      case p.prokind
        when 'f' then 'function'
        when 'a' then 'function'
        when 'w' then 'function'
        when 'p' then 'procedure'
      end,
      p.oid::regprocedure::text
    from pg_proc p inner join pg_namespace n on p.pronamespace = n.oid
    where n.nspname = 'pg_catalog'
    and ((p.proname)::text != all (allowlist))
    and p.prokind = any(candidates))
  loop
    execute format('revoke execute on %s pg_catalog.%s from public',           kind, proc);
    execute format('grant  execute on %s pg_catalog.%s to   clstr$developer',  kind, proc);
  end loop;
end;
$body$;
```

It's up to you how you populate the _allowlist_ array. Of course, it's best if you can leave it with a cardinality of zero. Notice that, in this case, every-day operations like typecasting a _text_ value to _numeric_ or concatenating two _text_ values fail with a _"42501 permission denied"_ error. However, when you application's API is a properly designed set of procedures or functions, just as the _"hard-shell"_ case-study demonstrates, client-side code will never need such operations.

## The currently available case-studies

The currently available case-studies are organized in directories under the repo's top directory, _"ysql-case-studies"_. You can consider each to be a mini application backend. Each has its own directory, thus:

```
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
  mandatory-one-to-many-relationship
    ask-tom-approach
    triggers-to-check-the-rule-needs-serializable
```

The leaves in this directory hierarchy hold the actual case-studies—and there are currently _eleven_ of these.

Each of the nine case-studies has its own _"README.md"_. And the code that implements each is organized in its own directory hierarchy.

### Working with just a single case-study

The top directory for each of the case-studies has a script called _"0.sql"_ and a file called _"x.sql"_.

The _"0.sql"_ script creates the artifacts that implement the case-study. (It hard-codes the name of the database that it will use.) Sometimes, all of these artifacts are have the same owner and live in the same schema. But, in general, the schema-objects are owned, jointly, by several roles where several of these own more than one schema to house its schema-objects. In every case, the _0.sql_ script calls the _cr_role()_ procedure as required and creates the required schemas. It then conducts some tests. Sometimes, these use the PL/pgSQL's _assert_ feature—and so "test succeeded" results in silent completion. Otherwise, the scripts execute _select_ statements and the results are seen in the terminal window.

For each case-study, the _"0.sql"_ script is idempotent: you can run it in a freshly created tenant database. And you can run it time and again thereafter. Apart from the inessential run-to-run differences described below, the result is always the same.

The _"x.sql"_ is a trivial wrapper that invokes the _"0.sql"_ script thus:

```
select (version() like '%YB%')::text as is_yb
\gset

\if :is_yb
  \o output/yb.txt
\else
  \o output/pg.txt
\endif

\ir 0.sql
\o
```

Every case-study, therefore, has its own _"output"_ directory. When you look on these directories, you'll see, in general, files with these names:

- _"yb-0.sql"_, _"yb.sql"_
- _"pg-0.sql"_, _"pg.sql"_

The files with the _"-0"_ suffix are renamed reference copies. And the files with the generated names are simply from recent test runs. Use your favorite _diff_ tool to compare them: _both_ recent test result (and especially, of course, the result when you run the tests yourself) _versus_ reference copy; and _"yb"_ _versus_ _"pg"_.

Often, the recent test result will differ only in inessential detail from the reference copy (pairwise for _"yb"_ or pairwise for _"pg"_) when the spool file mentions the value of a generated surrogate primary key. Here's an example:

```
message_text:         new row for relation "details" violates check constraint "details_v_chk"
pg_exception_detail:  Failing row contains (8baa95fb-a712-4f6e-a3aa-e27e9a1564c9,
                         22b042ca-ff17-4624-8fd7-bca3b90f01a1, small portable workbench).
```

These differences inevitably show up. But you can easily see them for what they are.

Sometimes, the spooled output differs slightly when the tests are run using YB from when they are run using PG. The differences, here too, are inessential. For example, they might reflect differences in the execution plan for a query. In such cases, both the _"yb-0.sql"_ and the _"pg-0.sql"_ reference files are provided. In other cases, when there are no such differences, just a single reference file, called _"0.txt"_, is provided.

### End-to-end test of the YBMT scheme and all of the case-studies

Look at the _"0-end-to-end-test.sql"_ master script located directly on the _"ysql-case-studies"_ directory. It (re)initializes the YBMT cluster and creates six tenant databases.

Tenant _d0_ is intended for any _ad hoc_ tests that you might like to invent and try—for example to test the effects of the role-provisioning procedures. And tenants _d1_ through _d5_ house the nine case-studies. Each of tenants _d2_ through _d5_ each houses a single multi-role, multi-schema case-study; and tenant _d1_ houses seven single-role, single-schema case-study.

Then it runs each of the nine case-studies. Each of these steps is individually timed. And so, too, is the overall elapsed time.

#### How the timing is done

Look at the section [Case-study: implementing a stopwatch with SQL](https://docs.yugabyte.com/preview/api/ysql/datatypes/type_datetime/stopwatch/) in the YSQL documentation. The code that this section describes is installed in the _client_safe_ schema in the _template1_ database. This means that even _"client"_ sessions can use it. You might find it convenient to define these two shortcuts in your _psqlrc_ file:

```
\set start_stopwatch 'select extract(epoch from clock_timestamp())::text as s0 \\gset stopwatch_'
\set stopwatch_reading 'select client_safe.stopwatch_reading(:stopwatch_s0);'
```

 Doing this will let you effortlessly do _ad hoc_ timing tests and, critically, spool the timing outcomes to a file, like this:

```
\o spool.txt
:start_stopwatch
< do stuff that produces "select" results >
:stopwatch_reading
\o
```

>  Compare this with how the _"\timing on"_ meta-command works. It non-negotiably reports the elapsed time for every single server call. And the output cannot be easily captured to a spool file, interleaved with _select_ results produced by the timed server calls.

Notice that _:stopwatch_reading_ renders the elapsed time in sensible units with sensible precision according to the size of the duration like, for example, _563 ms_, _5.33 ss_, or _03:42 mi:ss_.

#### Running the script

- The script first invokes _"01-re-initialize-ybmt-clstr.sql"_, without timing it, so that the starting condition is well-defined.
- Then it sets _:lower_db_no_ to _0_ and _:upper_db_no_ to _5_ to specify the creation of the six tenant databases and invokes, and times, _02-drop-and-re-create-tenant-databases.sql_.
- Then, leaving _:lower_db_no_ and _:upper_db_no_ unchanged, it simply invokes, and times, _02-drop-and-re-create-tenant-databases.sql_ for a second time. This second invocation will take longer than the first because the first time there are no extant tenant databases to drop and the second time there are six (albeit empty) extant tenant databases.
- Then it invokes, and times, the _"0.sql"_ script for each of the nine case-studies.

Spooling is turned on at the start, and turned off at the finish, of the end-to-end test—using the same logic as shown above to write to _"yb.sql"_ or _"pg.sql"_ on the _"output"_ directory directly under the _"ysql-case-studies"_ directory.

When you read the _"0-end-to-end-test.sql"_ script, you'll see that its use of the _"\o"_ meta-command is just a little tricky. This is because not only do child scripts of the _"01-re-initialize-ybmt-clstr.sql"_ and _"02-drop-and-re-create-tenant-databases.sql"_ scripts themselves use the _"\o"_ meta-command to write scripts that they then execute—but so also does a child script of the _"analyzing-covid-data-with-aggregate-functions/0.sql"_ script do this. The "real" spooling can be started only _after_ this rather special use of the _"\o"_ meta-command is complete (it doesn't support a push-and-pop notion) and only then can the timings from the earlier steps be queried and captured in the spool file.

Notice the _"xfer-schema-grants-from-public-to-clstr-developer-choices"_ directory on the _"ysql-case-studies"_ directory. It holds two sets of three spool files, thus:

- _"yb-everything-public.txt"_
- _"yb-entire-schemas-and-catalog-views-revoked-from-public.txt"_
- _"yb-everything-except-a-few-innocent-catalog-functions-revoked-from-public.txt"_

and

- _"pg-everything-public.txt"_
- _"pg-entire-schemas-and-catalog-views-revoked-from-public.txt"_
- _"pg-everything-except-a-few-innocent-catalog-functions-revoked-from-public.txt"_

These are the YB and PG reference spool files for the indicated variants:

- _"everything-public"_ records the output when the invocation of _"06-xfer-schema-grants-from-public-to-clstr-developer.sql"_ is commented out.
- _"entire-schemas-and-catalog-views-revoked-from-public"_ records the output when the invocation of _"06-xfer-schema-grants-from-public-to-clstr-developer.sql"_ is used but when the final anonymous block that transfers privileges for executing functions is commented out.
- _"everything-except-a-few-innocent-catalog-functions-revoked-from-public"_ records the output when the invocation of _"06-xfer-schema-grants-from-public-to-clstr-developer.sql"_ is used and when nothing in that script is commented out. (The mechanism that holds back just a few functions is the population of the _"allowlist"_ array).

#### Discussion of the results

The main purpose of the _"0.sql"_ script for each case-study, and the _"0-end-to-end-test.sql"_ script, is to test the _correctness_ of the functionality and to test that the outcomes are the same in YB and in PG. You can see, by running the tests in your own environment, that this purpose is well-satisfied. The timings are of secondary interest. You'll inevitably notice these high-level outcomes:

- There's a noticeably large run-to-run variation in the elapsed time for any particular test. This means that the timings must be regarded as just a rough indication. Proper timing experiments would need to do many repetitions and calculate appropriate measures of central tendency and confidence.
- YB (even using a single node cluster) is noticeably slower than PG. This is well-known—and only to be expected.
- The work that _"0-end-to-end-test.sql"_ does is dominated by _installation_ tasks. This means that most of the elapsed time is accounted for by DDLs—and these are especially slower in YB than in PG. The elapsed time that the actual tests of run-time behavior (i.e. _insert_, _update_, _delete_, and _select_ statements) is a tiny fraction of the total time. But its the performance characteristics of exactly these that are critical for real-world deployed applications. In other words, _"0-end-to-end-test.sql"_ gives no information about ordinary run-time performance.
- Within the _installation_ tasks, the dominating contribution to the total elapsed time is configuring the YBMT cluster and creating a set of tenant databases. But this is a very rare task. Once the tenant databases exist, then the installation and maintenance of artifacts within one of these is relatively quick. Moreover, these tasks can be done concurrently in each of many tenant databases as long as the DDLs done in any one of these are done in self-imposed single-user mode.
- It seems that the least privileges regimes impose a speed penalty. This is presumably because of how SQL compilation works—and so the effect would not be felt by ordinary run-time activity in a warmed up production system. SQL compilation has to check that the role that does the compilation has the privileges that allow the required kinds of operation. Presumably, the internal implementation is quicker when such a privilege is available because it's been granted to _public_ than because it's been granted to a role that, in turn, is granted to the role that does the compilation. Notice that:
  - This effect is hardly noticeable in PG; but it is noticeable in YB. And in YB, it has its biggest effect at YBMT configuration time and at tenant database creation time. (This is very much to be expected.)
  - In YB, where the effects are noticeable, they are noticeable in the tests for each of the case-studies only when the maximally secure option is chosen that revokes the _execute_ privilege from (almost all of) the _pg_catalog_ functions. This, too, is to be expected because very many of these functions are routinely used by application code both at DDL time and at run-time. (In contrast, the _pg_catalog_ tables and views are very rarely accessed by application code—neither at DDL time nor at run-time.)