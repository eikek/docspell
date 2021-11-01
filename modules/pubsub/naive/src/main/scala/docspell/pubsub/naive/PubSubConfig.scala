/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.pubsub.naive

import docspell.common.{Ident, LenientUri}

case class PubSubConfig(nodeId: Ident, url: LenientUri, subscriberQueueSize: Int)
