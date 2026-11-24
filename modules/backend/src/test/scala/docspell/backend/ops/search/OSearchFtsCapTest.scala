/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops.search

import docspell.store.qb.Batch

import munit.FunSuite

class OSearchFtsCapTest extends FunSuite {

  test("page size 5 does not materialize unbounded FTS hits") {
    val limit = OSearch.ftsMaterializationLimit(Batch.limit(5))
    assertEquals(limit, 5 * OSearch.FtsMaterializationFactor)
    assert(limit < 1000)
    assert(limit <= OSearch.MaxFtsMaterialization)
  }

  test("cap grows with offset + limit but never exceeds hard max") {
    val mid = OSearch.ftsMaterializationLimit(Batch(100, 50))
    assertEquals(mid, 150 * OSearch.FtsMaterializationFactor)

    val deep = OSearch.ftsMaterializationLimit(Batch(10_000, 200))
    assertEquals(deep, OSearch.MaxFtsMaterialization)
  }

  test("hard max is far below pathological Solr hit counts") {
    // Production evidence for content:"invoice": ~496k Solr hits.
    assert(OSearch.MaxFtsMaterialization < 10_000)
    assert(OSearch.MaxFtsMaterialization < 496_243)
  }
}
