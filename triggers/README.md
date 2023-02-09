# "triggers"

**NOTE:** Make sure that you read the section _"Working with just a single case-study"_ in the _"README.md"_ on the _"ybmt-clstr-mgmt"_ directory before running this case-study.

## Background

The account of these case-studies is not yet included in the YSQL documentation. It was written to complement this presentation in Yugabyte Inc's Friday Tech Talks series (a.k.a. YFTT) delivered by Bryn Llewellyn on 16-Sep-2022. The recording is here:

- **[“Triggers Considered Harmful” Considered Harmful](https://www.youtube.com/watch?v=CKbgBPCOLuE)**

The premise of the talk is that there are most definitely use cases where using triggers is definitely the best way to meet the goal. However, the use cases tend to take some explanation—and it isn't possible to manage to cover such explanations in a thirty minute talk.

## Current status

So far, only one study is included: _"trigger-firing-order"_. This uses the classic _masters_ and _details_ table pair and creates a trigger at each of the four possible timing points on each of the two tables. The function for each table reports its table and timing point. This allows you to see, operationally, how they firings interleave. You have to know this when you create triggers on tables that are connected by FK constraints.

