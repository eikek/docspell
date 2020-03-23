package org.apache.tika.parser.txt;

import java.io.InputStream;
import java.io.IOException;

public final class IOUtils {

    public static long readFully(InputStream in, byte[] buffer) throws IOException {
        return in.read(buffer, 0, buffer.length);
    }
}
