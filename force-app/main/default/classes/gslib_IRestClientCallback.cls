/**
 * Copyright (c), Groundswell Cloud Solutions - https://www.gscloudsolutions.com/
 * All rights reserved.
 */

public interface gslib_IRestClientCallback {

    void onSuccess(HttpRequest request, Object payload);
    void onError(HttpRequest request, HttpResponse response, Exception callException);
}