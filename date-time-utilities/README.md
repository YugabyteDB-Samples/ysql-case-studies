# "date-time-utilities"

**NOTE:** Make sure that you read the section _"Working with just a single case study"_ in the _"README.md"_ on the _"ybmt-clstr-mgmt"_ directory before running this case-study.

The code and data in the _"date-time-utilities"_ directory tree implement what the following sections, within the [Date and time data types and functionality](https://docs.yugabyte.com/preview/api/ysql/datatypes/type_datetime/) YSQL documentation section, cover:

- [The extended_timezone_names view](https://docs.yugabyte.com/preview/api/ysql/datatypes/type_datetime/timezones/extended-timezone-names/)
- [Recommended practice for specifying the UTC offset](Recommended practice for specifying the UTC offset)
- [Rules for resolving a string that's intended to identify a _UTC offset > Helper functions](https://docs.yugabyte.com/preview/api/ysql/datatypes/type_datetime/timezones/ways-to-spec-offset/name-res-rules/helper-functions/)

The material that the following sections within the [Date and time data types and functionality](https://docs.yugabyte.com/preview/api/ysql/datatypes/type_datetime/) YSQL documentation section cover is generically useful:

- [User-defined interval utility functions](https://docs.yugabyte.com/preview/api/ysql/datatypes/type_datetime/date-time-data-types-semantics/type-interval/interval-utilities/)
- [Modeling the internal representation and comparing the model with the actual implementation](https://docs.yugabyte.com/preview/api/ysql/datatypes/type_datetime/date-time-data-types-semantics/type-interval/interval-representation/internal-representation-model/)
- [Custom domain types for specializing the native interval functionality](https://docs.yugabyte.com/preview/api/ysql/datatypes/type_datetime/date-time-data-types-semantics/type-interval/custom-interval-domains/)

This code is therefore installed into the _dt_utils_ schema in the _template1_ database to make it available in every tenant database. You can find the source code on the _"date-time-utilities"_ directory under the _"12-schema-objects-for-template1"_ directory under the _"ybmt-clstr-mgmt"_ directory.

Notice this section within the [Date and time data types and functionality](https://docs.yugabyte.com/preview/api/ysql/datatypes/type_datetime/) YSQL documentation section:

- [Case study: implementing a stopwatch with SQL](https://docs.yugabyte.com/preview/api/ysql/datatypes/type_datetime/stopwatch/)

The approach that this describes is also generically useful. It is therefore installed into the _client_safe_ schema in the _template1_ database to make it available in every tenant database. You can find the source code in the _"05-cr-stopwatch.sql"_ script on the _"12-schema-objects-for-template1"_ directory under the _"ybmt-clstr-mgmt"_ directory.

You might prefer to read about these timing utilities in this blog post on the _yugabyte.com/blog_ site:

- [A SQL Stopwatch Utility for YugabyteDB or PostgreSQL as an Alternative for “\timing on”](https://www.yugabyte.com/blog/a-sql-stopwatch-utility-for-yugabytedb-or-postgresql-as-an-alternative-for-timing-on/)