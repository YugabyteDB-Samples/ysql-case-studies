# The "ysql-case-studies" repo

This repo contains several YSQL case-studies. The purpose of each is to complement an existing, or future, section within the [Yugabyte Structured Query Language](https://docs.yugabyte.com/preview/api/ysql/) within the YugabyteDB documentation. (The term "Yugabyte Structured Query Language" will, hereinafter, be abbreviated to "YSQL".)

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

Each case study has its own _"README.md"_ in its top directory. Some of the case-studies are already described in the YSQL documentation. For these, the _"README.md"_ needs to do little more than provide the URL to the relevant section. Others are not yet described in the YSQL documentation. Until this is done, a sufficient account is provided in the _"README.md"_ for these case-studies.

The _"ybmt-clstr-mgmt"_ directory implements a multitenancy scheme that relies on a software-enforced naming convention for global objects that avoids collisions of global names. ("YBMT" is an informal shorthand for short for "Yugabyte Multitenancy".) This is an interesting study in its own right because it relies upon, and demonstrates, key PostgreSQL notions for roles and privileges. In particular, it uses a dedicated _clstr$mgr_ role for provisioning tenant databases and, by using _security definer_ procedures in each provisioned database, for provisioning local roles within that tenant database. The scheme implements a disciplined separation of duties notion so that a session needs to authorize as the superuser only for the one-time configuration of the _ybmt-clstr-mgmt_ subsystem immediately following the creation of a cluster.

**NOTE:** It would be relatively straightforward to install each study directly into a cluster where the _ybmt-clstr-mgmt_ subsystem is not installed and where installing it would conflict with already existing databases and roles that had been created by using "bare" SQL. To do this, you'd have to replace the calls to the YBMT role provisioning procedures with "bare" SQL statements and take responsibility yourself to avoid collision of role names. You'd also have to install any extensions that a particular case-study depends upon. Try to avoid the need for this by dedicating a cluster to these case studies.
