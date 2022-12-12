# The "ysql-case-studies" repo

This repo contains several YSQL case-studies. The purpose of each is to complement a section within the [Yugabyte Structured Query Language](https://docs.yugabyte.com/preview/api/ysql/) within the YugabyteDB documentation. (The term "Yugabyte Structured Query Language" will, herinafter, be abbreviated to "YSQL".)

The studies are organised within the following directory strucure:

```
ybmt-clstr-mgmt

date-time-utilities
recursive-cte
  basics
    procedural-implementation-of-recursive-cte-algorithm
    fibonacci
  employee-hierarchy
  bacon-numbers
json-relational-equivalence
hard-shell
triggers
  trigger-firing-order
  mandatory-one-to-many-relationship
    ask-tom-approach
    triggers-to-check-the-rule-needs-serializable
```

The _"ybmt-clstr-mgmt"_ directory implements a multitenancy scheme that relies on a software-enforced naming convention for global objects that avoids collisions of global names.
