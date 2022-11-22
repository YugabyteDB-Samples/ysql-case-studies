# Implementing a disciplined approach to multitenancy in a PostgreSQL cluster

>  The following uses only the vocabulary of PostgreSQL (hereinafter PG)—and might give the impression that it applies only to that environment. However, because YugabyteDB's YSQL (hereinafter YB) re-uses PG's SQL-processing code "as is", everything discussed here (and in particular all the code) is applicable both to PG and to YSQL (hereinafter YB). All the code examples have been tested in vanilla PG Version 11 and in YB Version 2.15.
>
> The approach described here, critically, assumes only the native functionality that PG Version 11 supports. In particular, any scheme that might, for example, formally define the notion of a _local role_ whose name is required to be unique only within a database, by making changes in the PG implementation of _pg_authid_ (the table the underlies the _pg_roles_ view). and related catalogs, is strictly out of scope.

## Introduction—names and their scopes

A _role_ must have a name that is unique within the scope of the entire cluster. The same is true for a _database_ and a _tablespace_. In this document, I'll call roles, databases, and tablespaces "global" phenomena. There are no other kinds of global phenomena.

> NOTE: When you create a session, you must specify a database to which to connect and a role that will be its so-called session user. (The term _user_ is shorthand for a role that has _pg_roles.rolcanlogin_ set to true.) These two facts never change during a session's lifetime. They can be observed with the built-in functions _current_database()_ and _session_user_. (For historical reasons, the latter cannot be spelled with trailing parentheses.) A session's effective role can be changed during its lifetime with the _set role_ statement. It also can change when a _"security definer"_ subprogram is pushed onto the call stack. Use the _current_role_ built-in function (again without trailing parentheses) to observe this.

I'll reserve the term "object" for something that is owned by a role. Each kind of object is listed in a _catalog_. The term _catalog_ is used to denote a table in the _pg_catalog_ schema that you can always query—whatever is the value of _current_database()_. The owner of an object is denoted by the value in a suitably named column (with the data type _oid_) that references a row in the _pg_roles_ catalog with the matching _pg_roles.oid_ value.

Tautologically, because it does not have an owner, a role is not an object. Here are a few more terms:

- **role** — A _role_ is in a category of its own. A role exists within a cluster. And the uniqueness scope for its name is the cluster within which it exists.

- **global object** — A _tablespace_ and _database_ belong in this category; there are no other object kinds in this category. A tablespace and a database each exists within a cluster. And the uniqueness scope for the name of a tablespace and for the name of a database is the cluster within which each exists.
- **local object** — Any kind of object that is not a global object. 
- **schema** — This is a local object kind in a category of its own. A schema exists within a database, And the uniqueness scope for its name is the database within which it exists. In other words, two databases, _d1_ and _d2_, can each contain a schema called _s_.
- **schema object** — The familiar artifacts like a _table_, a _view_, an _index_, a _composite_type_, a _domain_, a _function_, a _procedure_, and so on, are schema objects. Schema objects are local objects. A schema object exists within a schema (within a database). And the uniqueness scope for its name is the schema in which it exists. In other words, two schemas, _s1_ and _s2_, can each contain a table called _t_.
- **secondary object** — Artifacts like a _trigger_ or a _constraint_ are secondary objects. A secondary object cannot exist autonomously like a schema object can. Rather, a secondary object must "hang off" a schema object. For example, a trigger must hang off a table. Secondary objects are transitively local objects. The name of  a secondary object must be unique within the schema object off which it hangs. In other words, two tables, _s1.t_ and _s2.t_ can each have a constraint called _c_. Strictly speaking, a secondary object does not have a direct owner. Rather, it inherits its ownership from the owner of the schema object off which it hangs.

## No cross-database visibility for schemas, schema objects, and secondary objects

It might be tempting to talk about a table using a three-part name, _database-name.schema-name.object-name_. And this might help in conversation or prose. For example, there might exist both a table  _d1.s.t_ and a table  _d2.s.t_ within the same cluster. However, it is simply not possible to reference two or more objects in different databases in any code utterance.

You can see it this way:

* **The database is the practical container for the set of artifacts that jointly implement (one of) a multitier application's RDBMS back end(s).**

Some multitier applcations use more than one RDBMS backend—sometimes geographically separated and sometimes of different kinds (for example, both a PostgreSQL RDBMS and an Oracle RDBMS).

* **The PG cluster is simply a mechanism that brings a "manage-as-one" benefit for a set of PG databases that might just as well exist each as the only database within a dedicated cluster.**

In other words, the ability for a PG cluster to contain two or more databases is not a notion that brings any semantics. Rather, it's purely a practical scheme to support multitenancy—where the granule of provisioning is the database.

## Practical problems that PG's native multitenancy scheme brings

qq



