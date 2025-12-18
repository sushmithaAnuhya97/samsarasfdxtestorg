/**
 * Copyright (c), Groundswell Cloud Solutions - https://www.gscloudsolutions.com/
 * All rights reserved.
 */

public interface gslib_IRestClientSerializer {

    String contentType();

    Object serialize(HttpRequest request, Object payload);

    Object deserialize(HttpRequest request, HttpResponse response);

    Object deserializeError(HttpRequest request, HttpResponse response);
}