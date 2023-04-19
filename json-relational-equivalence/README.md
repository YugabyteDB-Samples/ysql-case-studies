# "json-relational-equivalence"

**NOTE:** Make sure that you read the section _"Working with just a single case-study"_ in the _"README.md"_ on the _"ybmt-clstr-mgmt"_ directory before running this case-study.

The account of this case-study is not yet included in the YSQL documentation. It was written to complement this presentation in Yugabyte Inc's Friday Tech Talks series (a.k.a. YFTT) delivered by Bryn Llewellyn on 3-Jun-2022. The recording is here:

- **[Spotlight on YSQL JSON](https://www.youtube.com/watch?v=sfFCOlm3v2M)**

The premise of the talk is that an arbitrary SQL compound value can be represented as a JSON document—and that such a JSON representation can be _non-lossily_ transformed back to the SQL compound value that gave rise to the JSON representation.

The code simulates part of a complete app that will

- ingest data as a JSON document for each of a set of books into a _source(k... primary key, book_info jsonb_) table
- shred the books facts into a classic Codd-and-Date relational representation
- transform the set of facts for each book back to a set of JSON documents for transport to a different system.

The source JSON documents (they arrive as Unicode text) represent a book as a JSON _object_ with several keys. Here's an example of the JSON text that describes one book as a JSON object:

```
{
  "isbn"    : "978-0-14-303809-2",
  "title"   : "Joy Luck Club",
  "year"    : 2006, 
  "authors" : [
                {"given name": "Amy", "family name" : "Tan"}
              ],
  "genre"   : "Novel"
}
```

This conforms to a JSON Schema that can be expressed informally in prose, thus:

> The document's top-level object may use only these keys:
>
> - **"isbn"** — **string**
>   _values must be unique across the entire set of documents (in other words, it defines the unique business key); values must have this pattern:_
>   `« ^[0-9]{3}-[0-9]{1}-[0-9]{2}-[0-9]{6}-[0-9]{1}$ »`
>   Notice that this is not the real ISBN format. But it's sufficient for this demo code.
>
> - **"title" — string**
>
> - **"year" — number**
>   _must be a positive integral value_
>
> - **"authors" — array of objects**;
>   _must be at least one object_
>
> - **"genre" — string**
>
> Each object in the _"authors"_ array object may use only these keys:
>
> - **"family name" — string**
>
> - **"given name" — string**
>
> String values other than for _"isbn"_ are unconstrained.
>
> Any key other than the seven listed here is illegal. The _"genre"_ and _"given name"_ keys are _not required_. All the other keys are _required_.
>
> The meaning of _required is that no extracted value must bring a SQL null (so a required key must not have a _JSON null_ value).
>
> And the meaning of _not required_ is "no information is available for this key". The spec author goes further by adding a rule: _this meaning must be expressed by the absence of such a key_.

The _"genre"_ key obviously implies a FK reference to a constraining _genres_ LoV table. And the _authors_ key, with its JSON _array_ of _{"given name"_, _"family name"}_ _objects_, implies a classic separate _authors_ table and an intersection table—in other words, this well-known scheme:

- _books_, _genres_, _authors_, and _books_authors_

The code here loads the incoming documents into a _source(k, book_info)_ table. _k_ is a surrogate primary key; and the data type of _book_info_ is _jsonb_.

It then shreds the data into the four-table relational representation.

Then it converts each row from the _books_ relational table, together with its associated _genre_ and _authors_ details, back to a single _jsonb_ value in the view _r_books_j_view(k, book_info)_.

Then it proves that the round trip, JSON text to classic Codd-and-Date to JSON text, is non-lossy by proving that the set of _target_ rows (produced by _r_books_j_view_) is identical to the set of _source_ rows (in the _j_books_ table).

The code uses whatever PostgreSQL features are optimally appropriate to the task at hand. Moreover, because all sorts of JSON and SQL features are used, the exercise provides an excellent illustration of YB's fidelity to PG's syntax and semantics.

The transformations are done:

- from _jsonb_ to SQL, using the `->>` and`->` operators, and the _jsonb_populate_record()_ built-in function
- from SQL to _jsonb_ using the _to_jsonb()_ built-in function.

These facts could interfere with the _source-target_ identity test.

- When the `->>` operator extracts from an absent key, it brings a _SQL null_ value to the target SQL variable. (Other JSON features do this too.)
- The transformation from a composite type occurrence to a JSON _object_ brings an explicit « _"some key": null_ » to the value of the JSON key that maps the composite type's attribute that is a _SQL null_.

And so special application code is needed to accommodate this. The problem is solved trivially by implementing two complementary functions:

- _no_null_keys()_ checks that a _jsonb_ value has no occurrences of « _"some key": null_ »

- _strip_null_keys()_ removes « _"some key": null_ » occurrences from a _jsonb_ value

The code checks with _no_null_keys()_ that, as expected, no ingested JSON document has an occurrence of « _"some key": null_ ».

And it uses the guilt-in _jsonb_strip_nulls()_ on the output of _to_jsonb()_ — and, as appropriate, any other built-in JSON function that produces a _jsonb_ value.

The check on the incoming documents is included in the _j_books_book_info_is_conformant(jsonb)_ function that is the basis of a constraint that's created on the _source_ table's _book_info_ column.

More code is needed to implement other constraints like, for example, the value of the _"isbn"_ (_string_) key must satisfy a particular regular expression and the value of the _"year"_ (_number_) key must convert to a positive integer.

Critically, one test uses _jsonb_object_keys()_ to scan the top-level object to ensure that all the required keys are present, that every key has the specified JSON data type, and that no keys that the JSON Schema doesn't mention are present. A similar test does the same for the _"authors"_ array. This is why I can be sure that the native `->>` and `->` operators are sufficient for my purpose.

These tests, too, (and other tests) are included in the _j_books_book_info_is_conformant(jsonb)_ function.

After transforming the facts from the relational representation back to one _jsonb_ value for each book with its aggregated facts, each document must adhere to the same JSON Schema as do the incoming documents. This requirement can be expressed thus: This transformation:

```
JSON → relational → JSON
```

must be idempotent. The test is implemented simply with this:

```
do $body$
declare
  differ constant boolean_nn :=
    (
    with
      a as (select * from j_books except select * from r_books_j_view),
      b as (select * from r_books_j_view except select * from j_books)
    select (exists(select 1 from a) or exists(select 1 from b))
    );
begin
  assert not differ, '"j_books" versus "r_books_j_view" test failed';
end;
$body$;
```