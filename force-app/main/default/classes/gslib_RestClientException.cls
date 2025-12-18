/**
 * Copyright (c), Groundswell Cloud Solutions - https://www.gscloudsolutions.com/
 * All rights reserved.
 */

/**
 * REST client exception.
 */
public class gslib_RestClientException extends Exception {

    /**
     * The REST response.
     */
    public HttpResponse response { get; private set; }
    /**
     * The deserialized payload.
     */
    public Object payload { get; private set; }

    /**
     * Exception constructor.
     *
     * @param message The error message.
     * @param response The REST response.
     * @param payload The deserialized payload.
     */
    public gslib_RestClientException(String message, HttpResponse response, Object payload) {
        super.setMessage(message);
        this.response = response;
        this.payload = payload;
    }
}