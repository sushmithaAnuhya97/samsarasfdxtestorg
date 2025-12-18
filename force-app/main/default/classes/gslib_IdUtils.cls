/**
 * Copyright (c), Groundswell Cloud Solutions - https://www.gscloudsolutions.com/
 * All rights reserved.
 */
public class gslib_IdUtils {

    /**
     * Creates an unique UUID.
     * Format: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
     *
     * @return An unique UUID.
     */
    public static String createUUID() {
        Blob b = Crypto.generateAesKey(128);
        String h = EncodingUtil.convertToHex(b);
        return h.substring(0, 8)  + '-' // 8
            + h.substring(8, 12)  + '-' // 4
            + h.substring(12, 16) + '-' // 4
            + h.substring(16, 20) + '-' // 4
            + h.substring(20);          // 12
    }
}