/**
 * Copyright (c), Groundswell Cloud Solutions - https://www.gscloudsolutions.com/
 * All rights reserved.
 */

/**
 * JSON serializer. Used for serialize and serialize JSON payloads.
 */
public class gslib_RestJsonSerializer implements gslib_IRestClientSerializer {

    /**
     * Defines the serializer content type.
     * @return The content type.
     */
    public String contentType() {
        return 'application/json';
    }

    /**
     * Serializes the given payload as JSON string.
     *
     * @param request The HTTP Request.
     * @param payload The payload to be serializer.
     *
     * @return The given payload serialized as JSON string.
     */
    public Object serialize(HttpRequest request, Object payload) {
        if(payload == null) {
            return null;
        }
        if(payload instanceof String) {
            return payload;
        }
        return JSON.serialize(payload);
    }

    /**
     * Deserializes the received JSON payload.
     * @param request The HTTP Request sent to the service.
     * @param response The HTTP Response received from the service.
     *
     * @return A Map<String, Object> instance with the JSON data.
     */
    public Object deserialize(HttpRequest request, HttpResponse response) {
        String payload = response.getBody();
        if(String.isNotBlank(payload)) {
            return JSON.deserializeUntyped(payload);
        }
        return new Map<String, Object>();
    }

    /**
     * Deserializes the received JSON error payload.
     * @param request The HTTP Request sent to the service.
     * @param response The HTTP Response received from the service.
     *
     * @return A Map<String, Object> instance with the JSON data.
     */
    public Object deserializeError(HttpRequest request, HttpResponse response) {
        return this.deserialize(request, response);
    }
}