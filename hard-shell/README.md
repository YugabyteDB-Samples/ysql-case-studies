# "hard-shell"

**NOTE:** Make sure that you read the section _"Working with just a single case study"_ in the _"README.md"_ on the _"ybmt-clstr-mgmt"_ directory before running this case-study.

The account of this case-study is not yet included in the YSQL documentation. It was written to complement this presentation in Yugabyte Inc's Friday Tech Talks series (a.k.a. YFTT) delivered by Bryn Llewellyn on 15-July-2022. The recording is here:

- **[Are Stored Procedures a Good Thing?](https://www.youtube.com/watch?v=SkDKrMEa-kA)**

The premise of the talk is that you should hide the internals of your application’s database module behind an impenetrable PL/pgSQL API. Here's why:

> The success of any serious software system depends critically on adhering to the principles of modular decomposition—principles that are as old as computer science itself. A module encapsulates specified, coherent functionality—exposed by an API. And all implementation details must be scrupulously hidden behind this API. Nobody would dream of challenging these notions.
>
> When an application uses a relational database, then this is surely a module at the highest level of top-down decomposition. Therefore, the structure of the database’s tables, the rules that constrain their rows, and the SQL statements that read and change these rows, are the implementation details. And PostgreSQL provides PL/pgSQL subprograms to express the API—specifically, the set of atomic business transactions and queries that the database must support.
>
> It’s straightforward to design a regime of object ownership and “security definer” subprograms so that the database “client” role, used by external programs to create sessions, can invoke only the exact set of subprograms that implement the API—but cannot explicitly invoke helper subprograms, query or change tables, or create objects.
>
> The parameterization of the subprograms presents a challenge. For example, a business transaction might be provided to insert a new “master” row and a set of new “detail” rows for it—and a user-error might cause it to fail because a to-be-inserted row violates a unique, or other, constraint, which must be reported using the business terminology. Similarly, a query function whose purpose is to return exactly one row might need to report, instead, that it found no rows or many rows.
>
> Here’s where JSON’s arbitrary flexibility comes to the rescue—both for input parameterization and for return values. This implies that the API will be defined exclusively by procedures. PostgreSQL’s built-in _jsonb_ functions let you transform an arbitrary compound SQL value to a _jsonb_ value with identical semantics—and vice versa.
>
> Of course, there’s also the possibility that an API function might cause an unexpected error. This tautologically reveals a bug in the implementation of the database module. Every API procedure must therefore end with an exception section that handles _others_ by inserting all available diagnostic information into an _incidents_ table and that returns the ticket ID.

## Interesting features and techniques that the code shows

- _0.sql_ creates and tests the entire kit, runs the functionality tests, and writes the output to a spool file. This allows straightforward regression testing.
- YB & PG produce identical spooled output—barring small cosmetic differences.
- The API is defined by procedures with a standard _"in text, inout text"_ signature. Both the input and output are the plain text representation of a _jsonb_ value.
- JSON lets you express a variety of possible outcomes (different according to “success”, “expected error” or “unexpected error” in a single parsable value. 
- Business functions often imply multi-statement txns. 
- _"Security definer"_ and _"security invoker"_ subprograms are both used in the implementation according to what bests suits the purpose. 
- Everything to do with exception handling is kept in the database (behind the hard shell). The client deals only with JSON. 
- The design allows UI-independent testing. You need only dedicated Pl/pgSQL and e.g. _ysqlsh_ scripts to invoke them—or a Python harness if you prefer.
- An _enum_ is used where in Oracle database you'd simply use package spec constants.