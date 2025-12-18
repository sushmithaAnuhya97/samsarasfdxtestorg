/**
 * Copyright (c), Groundswell Cloud Solutions - https://www.gscloudsolutions.com/
 * All rights reserved.
 */

public with sharing class gslib_RestRawSerializer implements gslib_IRestClientSerializer {

    private String contentTypeValue;

    public gslib_RestRawSerializer() {
        this('text/plain');
    }

    public gslib_RestRawSerializer(String contentType) {
        this.contentTypeValue = contentType;
    }

    public String contentType() {
        return this.contentTypeValue;
    }

    public Object serialize(HttpRequest request, Object payload) {
        return payload;
    }

    public Object deserialize(HttpRequest request, HttpResponse response) {
        return response.getBody();
    }

    public Object deserializeError(HttpRequest request, HttpResponse response) {
        return response.getBody();
    }
}