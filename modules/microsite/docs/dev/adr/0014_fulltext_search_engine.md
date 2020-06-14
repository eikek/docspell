---
layout: docs
title: Fulltext Search Engine
---

# Choose a Fulltext Search Engine

It should be possible to search the contents of all documents.

## Context and Problem Statement

To allow searching the documents contents efficiently, a separate
index is necessary. The "defacto standard" for fulltext search on the
JVM is something backed by [Lucene](https://lucene.apache.org).
Another option is to use a RDBMS that supports fulltext search.

This adds another component to the mix, which increases the complexity
of the setup and the software. Since docspell works great without this
feature, it shouldn't have a huge impact on the application, i.e. if
the fulltext search component is down or broken, docspell should still
work (just the fulltext search is then not working).

## Considered Options

* [Apache SOLR](https://lucene.apache.org/solr)
* [ElasticSearch](https://www.elastic.co/elasticsearch/)
* [PostgreSQL](https://www.postgresql.org/docs/12/textsearch.html)
* All of them or a subset

## Decision Outcome

If docspell is running on PostgreSQL, it would be the best option to
also use it for fulltext search. But I don't want to lock the database
to PostgreSQL *only* because of the fulltext search feature. This
would be a too large impact on the whole application.

ElasticSearch and Apache SOLR are quite similiar in features. SOLR is
part of Lucene and therefore lives in the Apache ecosystem. I would
choose this over ElasticSearch, which is backed by a company (the oss
version is released under the Apache License, afaiu). Regarding
features, both are great.

The last option (supporting all) is interesting, since it would enable
to use PostgreSQL for fulltext search, when already using PostgreSQL
as the database for docspell.

So in a first step, identify what docspell needs from a fulltext
search component and create this interface and an implementation for
Apache SOLR. This enables all users to use the fulltext search
feature. As a later step, an implementation based on PostgreSQL could
be provided, too.
