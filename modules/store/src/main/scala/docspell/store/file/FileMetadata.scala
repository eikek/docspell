/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.file

import docspell.common._

import scodec.bits.ByteVector

final case class FileMetadata(
    id: FileKey,
    created: Timestamp,
    mimetype: MimeType,
    length: ByteSize,
    checksum: ByteVector
)
