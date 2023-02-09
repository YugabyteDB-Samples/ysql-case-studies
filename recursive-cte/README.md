# "recursive-cte"

**NOTE:** Make sure that you read the section _"Working with just a single case-study"_ in the _"README.md"_ on the _"ybmt-clstr-mgmt"_ directory before running this case-study.

There are two small demonstrations and two case-studies under this directory. They complement the material that the following sections, within the YSQL documentation section [The recursive CTE](https://docs.yugabyte.com/preview/api/ysql/the-sql-language/with-clause/recursive-cte/), cover:

- [The recursive CTE](https://docs.yugabyte.com/preview/api/ysql/the-sql-language/with-clause/recursive-cte/) &gt; [Pseudocode definition of the semantics](https://docs.yugabyte.com/preview/api/ysql/the-sql-language/with-clause/recursive-cte/#pseudocode-definition-of-the-semantics)

- [Case-study: using a recursive CTE to traverse an employee hierarchy](https://docs.yugabyte.com/preview/api/ysql/the-sql-language/with-clause/emps-hierarchy/)
- [Case-study: using a recursive CTE to compute Bacon Numbers for actors listed in the IMDb](https://docs.yugabyte.com/preview/api/ysql/the-sql-language/with-clause/bacon-numbers/)

You can find the code under the following directories:

```
recursive-cte
  basics
    procedural-implementation-of-recursive-cte-algorithm
    fibonacci
  employee-hierarchy
  bacon-numbers
```

Notice that the "fibonacci" demonstration is not described in the documentation. It underlines the point made by [this note](https://www.postgresql.org/docs/11/queries-with.html#id-1.5.6.12.5.4) in the PG documentation:

> Strictly speaking, [the recursive CTE implements] iteration not recursion, but RECURSIVE is the terminology chosen by the SQL standards committee

You might like to read these two blog posts on _www.yugabyte.com_:

- [Using the PostgreSQL Recursive CTE – Part One: Traversing an employee hierarchy](https://www.yugabyte.com/blog/using-postgresql-recursive-cte-part-1-employee-hierarchy/#traversing-an-employee-hierarchy)
- [Using the PostgreSQL Recursive CTE – Part Two: Computing Bacon Numbers for actors listed in the IMDb](https://www.yugabyte.com/blog/using-postgresql-recursive-cte-part-2-bacon-numbers/)