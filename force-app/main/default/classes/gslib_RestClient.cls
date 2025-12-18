/**
 * Copyright (c), Groundswell Cloud Solutions - https://www.gscloudsolutions.com/
 * All rights reserved.
 */

/**
 * REST Services communication class.
 */
public virtual class gslib_RestClient {

    /**
     * The service endpoint.
     */
    @TestVisible
    protected String endpoint;
    @TestVisible
    protected gslib_IRestClientSerializer serializer;
    @TestVisible
    protected List<gslib_IRestClientConfigModule> configModules;

    /*
     * Constructors
     */

    /**
     * Creates a new Rest Client instance.
     *
     * @param endpoint The service endpoint. This endpoint will be concatenated to the path received on the service call.
     */
    public gslib_RestClient(String endpoint) {
        this(endpoint, new List<gslib_IRestClientConfigModule>(), null);
    }

    /**
     * Creates a new Rest Client instance.
     *
     * @param endpoint The service endpoint. This endpoint will be concatenated to the path received on the service call.
     * @param serializer The global serializer responsible for serialize and deserialize the request and response payloads.
     * This global serializer can be overridden by a serializer specified on the rest call method.
     */
    public gslib_RestClient(String endpoint, gslib_IRestClientSerializer serializer) {
        this(endpoint, new List<gslib_IRestClientConfigModule>(), serializer);
    }

    /**
     * Creates a new Rest Client instance.
     *
     * @param endpoint The service endpoint. This endpoint will be concatenated to the path received on the service call.
     * @param configModule The configuration module instance that will be used for prepare the HTTP Request before the service call.
     */
    public gslib_RestClient(String endpoint, gslib_IRestClientConfigModule configModule) {
        this(endpoint, new List<gslib_IRestClientConfigModule>{
            configModule
        }, null);
    }

    /**
     * Creates a new Rest Client instance.
     *
     * @param endpoint The service endpoint. This endpoint will be concatenated to the path received on the service call.
     * @param configModules A list of configuration modules instances that will be used for prepare the HTTP Request before the service call.
     */
    public gslib_RestClient(String endpoint, List<gslib_IRestClientConfigModule> configModules) {
        this(endpoint, configModules, null);
    }

    /**
     * Creates a new Rest Client instance.
     *
     * @param endpoint The service endpoint. This endpoint will be concatenated to the path received on the service call.
     * @param configModule The configuration module instance that will be used for prepare the HTTP Request before the service call.
     * @param serializer The global serializer responsible for serialize and deserialize the request and response payloads.
     * This global serializer can be overridden by a serializer specified on the rest call method.
     */
    public gslib_RestClient(String endpoint, gslib_IRestClientSerializer serializer, gslib_IRestClientConfigModule configModule) {
        this(endpoint, new List<gslib_IRestClientConfigModule>{
            configModule
        }, serializer);
    }

    /**
     * Creates a new Rest Client instance.
     *
     * @param endpoint The service endpoint. This endpoint will be concatenated to the path received on the service call.
     * @param configModules A list of configuration modules instances that will be used for prepare the HTTP Request before the service call.
     * @param serializer The global serializer responsible for serialize and deserialize the request and response payloads.
     * This global serializer can be overridden by a serializer specified on the rest call method.
     */
    public gslib_RestClient(String endpoint, List<gslib_IRestClientConfigModule> configModules, gslib_IRestClientSerializer serializer) {
        this.endpoint = endpoint;
        this.serializer = serializer == null ? new gslib_RestJsonSerializer() : serializer;
        this.configModules = configModules == null ? new List<gslib_IRestClientConfigModule>() : configModules;
    }

    /*
     * Protected methods
     */

    /**
     * Creates a new request.
     *
     * @return A new RestClientRequest instance.
     */
    @TestVisible
    protected RestClientRequest createRequest() {
        return new RestClientRequest(
            this.endpoint,
            new List<gslib_IRestClientConfigModule>(this.configModules),
            this.serializer
        );
    }

    /**
     * Creates the HTTP request serializing the payload applying the configurations modules.
     *
     * @param method - HTTP request method.
     * @param endpoint - The service endpoint.
     * @param payload - The payload to be sent in the request.
     * @param serializer - The payload serializer.
     * @param headerFields - Custom header fields.
     * @param configModules - The HTTP request configuration modules.
     * @return The REST service HttpResponse.
     */
    private static HttpRequest createRequest(
        String method,
        String endpoint,
        Object payload,
        gslib_IRestClientSerializer serializer,
        Map<String, String> headerFields,
        List<gslib_IRestClientConfigModule> configModules)
    {
        // Creates and prepared the request.
        HttpRequest request = new HttpRequest();
        request.setHeader('Content-Type', serializer.contentType());
        request.setEndpoint(endpoint);
        request.setMethod(method);

        // Sets the payload.
        if (payload != null) {
            Object serializedPayload = serializer.serialize(request, payload);
            if (serializedPayload instanceof String) {
                request.setBody((String) serializedPayload);
            } else if (serializedPayload instanceof Blob) {
                request.setBodyAsBlob((Blob) serializedPayload);
            } else {
                throw new gslib_RestClientException('Invalid body type. Only Blob and String bodies are supported.');
            }
        }
        // Apply the module configurations.
        if(configModules != null) {
            for (gslib_IRestClientConfigModule configModule : configModules) {
                configModule.applyConfiguration(request);
            }
        }
        // Adds the header fields.
        if(headerFields != null) {
            for (String fieldName : headerFields.keySet()) {
                request.setHeader(fieldName, headerFields.get(fieldName));
            }
        }
        return request;
    }

    /**
     * Calls the REST Services.
     * @param request - The HttpRequest.
     * @param serializer - The payload serializer.
     * @return The REST service HttpResponse.
     */
    private static HttpResponse call(HttpRequest request, gslib_IRestClientSerializer serializer) {
        HttpResponse response = new Http().send(request);
        Integer statusCode = response.getStatusCode();
        if (statusCode < 200 || statusCode > 299) {
            String message = 'The server returned an error. Status code: ' +
                statusCode + ' - ' + response.getStatus();
            Object payload = serializer.deserializeError(request, response);
            throw new gslib_RestClientException(message, response, payload);
        }
        return response;
    }

    /*
     * Nested classes
     */
    public class QueueableRestClientExecutor implements Queueable, Database.AllowsCallouts {

        private HttpRequestData requestData;
        @TestVisible
        private gslib_IRestClientCallback callback;
        private gslib_IRestClientSerializer serializer;

        public QueueableRestClientExecutor(HttpRequestData requestData, gslib_IRestClientSerializer serializer, gslib_IRestClientCallback callback) {
            this.requestData = requestData;
            this.serializer = serializer;
            this.callback = callback;
        }

        public void execute(QueueableContext context) {
            HttpResponse response = null;
            HttpRequest request = new HttpRequest();
            try {
                request = createRequest(
                    requestData.method, requestData.endpoint, requestData.payload,
                    requestData.serializer, requestData.headerFields, requestData.configModules
                );
                response = gslib_RestClient.call(request, this.serializer);
                Object payload = this.serializer.deserialize(request, response);
                this.callback.onSuccess(request, payload);
            } catch (Exception e) {
                this.callback.onError(request, response, e);
            }
        }
    }

    private class HttpRequestData {

        public String method { get; set; }
        public String endpoint { get; set; }
        public Object payload { get; set; }
        public gslib_IRestClientSerializer serializer { get; set; }
        public Map<String, String> headerFields  { get; set; }
        public List<gslib_IRestClientConfigModule> configModules { get; set; }

        public HttpRequestData(
            String method,
            String endpoint,
            Object payload,
            gslib_IRestClientSerializer serializer,
            Map<String, String> headerFields,
            List<gslib_IRestClientConfigModule> configModules
        ) {
            this.method = method;
            this.endpoint = endpoint;
            this.payload = payload;
            this.serializer = serializer;
            this.headerFields = headerFields;
            this.configModules = configModules;
        }
    }

    public class RestClientRequest {
        @TestVisible
        private String endpoint;
        @TestVisible
        private gslib_IRestClientSerializer serializer;
        @TestVisible
        private List<gslib_IRestClientConfigModule> configModules;
        @TestVisible
        private Map<String, String> headerFields = new Map<String, String>();

        /*
         * Constructors
         */
        private RestClientRequest(String endpoint, List<gslib_IRestClientConfigModule> configModules, gslib_IRestClientSerializer serializer) {
            this.endpoint = endpoint;
            this.serializer = serializer;
            this.configModules = configModules;
        }

        /*
         * Configuration methods
         */

        /**
         * Sets the serializer / deserializer to be used for the current instance request and response.
         *
         * @param serializer The serializer / deserializer instance.
         *
         * @return The RestClientRequest instance.
         */
        public RestClientRequest setSerializer(gslib_IRestClientSerializer serializer) {
            this.serializer = serializer;
            return this;
        }

        /**
         * Clear the default configuration modules list.
         *
         * @return The RestClientRequest instance.
         */
        public RestClientRequest clearConfigModules() {
            this.configModules.clear();
            return this;
        }

        /**
         * Add a new configuration module to the current request instance.
         *
         * @param configModule The configuration module instance.
         *
         * @return The RestClientRequest instance.
         */
        public RestClientRequest addConfigModule(gslib_IRestClientConfigModule configModule) {
            this.configModules.add(configModule);
            return this;
        }

        /**
         * Add a new list of configuration modules to the current request instance.
         *
         * @param configModules The list of configuration modules instances.
         *
         * @return The RestClientRequest instance.
         */
        public RestClientRequest addConfigModules(List<gslib_IRestClientConfigModule> configModules) {
            this.configModules.addAll(configModules);
            return this;
        }

        /**
         * Sets a request header value.
         *
         * @param headerName The request header name.
         * @param value The request header value.
         *
         * @return The RestClientRequest instance.
         */
        public RestClientRequest addHeader(String headerName, String value) {
            this.headerFields.put(headerName, value);
            return this;
        }

        /**
         * Sets a list of request header values.
         *
         * @param headerFields A map with all header names and their values.
         *
         * @return The RestClientRequest instance.
         */
        public RestClientRequest addHeaders(Map<String, String> headerFields) {
            this.headerFields.putAll(headerFields);
            return this;
        }

        /*
         * GET methods
         */

        /**
         * Calls the REST Service using the GET method.
         *
         * @param path - The service path using the APEX String.format placeholders to hold the path arguments.
         * @return The deserialized payload.
         */
        public Object get(String path) {
            return this.get(path, new Map<String, String>(), null);
        }

        /**
         * Calls the REST Service using the GET method.
         *
         * @param path - The service path using the APEX String.format placeholders to hold the path arguments.
         * @param pathArguments - The argument that will be put in the path placeholder.
         * @return The deserialized payload.
         */
        public Object get(String path, Map<String, String> pathArguments) {
            return this.get(path, pathArguments, null);
        }

        /**
         * Calls the REST Service using the GET method.
         *
         * @param path - The service path using the APEX String.format placeholders to hold the path arguments.
         * @param payload - The payload to send in the request.
         * @return The deserialized payload.
         */
        public Object get(String path, Object payload) {
            return this.get(path, new Map<String, String>(), payload);
        }

        /**
         * Calls the REST Service using the GET method.
         *
         * @param path - The service path using the APEX String.format placeholders to hold the path arguments.
         * @param pathArguments - The argument that will be put in the path placeholder.
         * @param payload - The payload to send in the request.
         * @return The deserialized payload.
         */
        public Object get(String path, Map<String, String> pathArguments, Object payload) {
            return this.call('GET', path, pathArguments, payload);
        }

        /*
         * POST methods
         */

        /**
         * Calls the REST Service using the POST method.
         *
         * @param path - The service path using the APEX String.format placeholders to hold the path arguments.
         * @return The deserialized payload.
         */
        public Object post(String path) {
            return this.post(path, new Map<String, String>(), null);
        }

        /**
         * Calls the REST Service using the POST method.
         *
         * @param path - The service path using the APEX String.format placeholders to hold the path arguments.
         * @param pathArguments - The argument that will be put in the path placeholder.
         * @return The deserialized payload.
         */
        public Object post(String path, Map<String, String> pathArguments) {
            return this.post(path, pathArguments, null);
        }

        /**
         * Calls the REST Service using the POST method.
         *
         * @param path - The service path using the APEX String.format placeholders to hold the path arguments.
         * @param payload - The payload to send in the request.
         * @return The deserialized payload.
         */
        public Object post(String path, Object payload) {
            return this.post(path, new Map<String, String>(), payload);
        }

        /**
         * Calls the REST Service using the POST method.
         *
         * @param path - The service path using the APEX String.format placeholders to hold the path arguments.
         * @param pathArguments - The argument that will be put in the path placeholder.
         * @param payload - The payload to send in the request.
         * @return The deserialized payload.
         */
        public Object post(String path, Map<String, String> pathArguments, Object payload) {
            return this.call('POST', path, pathArguments, payload);
        }

        /*
         * PUT methods
         */

        /**
         * Calls the REST Service using the PUT method.
         *
         * @param path - The service path using the APEX String.format placeholders to hold the path arguments.
         * @return The deserialized payload.
         */
        public Object put(String path) {
            return this.put(path, new Map<String, String>(), null);
        }

        /**
         * Calls the REST Service using the PUT method.
         *
         * @param path - The service path using the APEX String.format placeholders to hold the path arguments.
         * @param pathArguments - The argument that will be put in the path placeholder.
         * @return The deserialized payload.
         */
        public Object put(String path, Map<String, String> pathArguments) {
            return this.put(path, pathArguments, null);
        }

        /**
         * Calls the REST Service using the PUT method.
         *
         * @param path - The service path using the APEX String.format placeholders to hold the path arguments.
         * @param payload - The payload to send in the request.
         * @return The deserialized payload.
         */
        public Object put(String path, Object payload) {
            return this.put(path, new Map<String, String>(), payload);
        }

        /**
         * Calls the REST Service using the PUT method.
         *
         * @param path - The service path using the APEX String.format placeholders to hold the path arguments.
         * @param pathArguments - The argument that will be put in the path placeholder.
         * @param payload - The payload to send in the request.
         * @return The deserialized payload.
         */
        public Object put(String path, Map<String, String> pathArguments, Object payload) {
            return this.call('PUT', path, pathArguments, payload);
        }

        /*
         * Generic call methods
         */

        /**
         * Calls the REST Service.
         *
         * @param method - HTTP request method.
         * @param path - The service path using the APEX String.format placeholders to hold the path arguments.
         * @return The deserialized payload.
         */
        public Object call(String method, String path) {
            return this.call(method, path, new Map<String, String>(), null);
        }

        /**
         * Calls the REST Service.
         *
         * @param method - HTTP request method.
         * @param path - The service path using the APEX String.format placeholders to hold the path arguments.
         * @param pathArguments - The argument that will be put in the path placeholder.
         * @return The deserialized payload.
         */
        public Object call(String method, String path, Map<String, String> pathArguments) {
            return this.call(method, path, pathArguments, null);
        }

        /**
         * Calls the REST Service.
         *
         * @param method - HTTP request method.
         * @param path - The service path using the APEX String.format placeholders to hold the path arguments.
         * @param payload - The payload to send in the request.
         * @return The deserialized payload.
         */
        public Object call(String method, String path, Object payload) {
            return this.call(method, path, new Map<String, String>(), payload);
        }

        /**
         * Calls the REST Service.
         *
         * @param method - HTTP request method.
         * @param path - The service path using the APEX String.format placeholders to hold the path arguments.
         * @param pathArguments - The argument that will be put in the path placeholder.
         * @param payload - The payload to send in the request.
         * @return The deserialized payload.
         */
        public Object call(String method, String path, Map<String, String> pathArguments, Object payload) {
            path = buildPath(path, pathArguments);
            HttpRequest request = createRequest(
                method, path, payload,
                this.serializer, this.headerFields, this.configModules
            );
            HttpResponse response = gslib_RestClient.call(request, this.serializer);
            return serializer.deserialize(request, response);
        }

        /*
         * Async call methods
         */

        /**
         * Calls asynchronously the REST Service.
         *
         * @param method - HTTP request method.
         * @param path - The service path using the APEX String.format placeholders to hold the path arguments.
         * @param callback - The callback instance.
         * @return The batch Id.
         */
        public Id callAsync(String method, String path, gslib_IRestClientCallback callback) {
            return this.callAsync(method, path, null, null, callback);
        }

        /**
         * Calls asynchronously the REST Service.
         *
         * @param method - HTTP request method.
         * @param path - The service path using the APEX String.format placeholders to hold the path arguments.
         * @param payload - The payload to send in the request.
         * @param callback - The callback instance.
         * @return The batch Id.
         */
        public Id callAsync(String method, String path, Object payload, gslib_IRestClientCallback callback) {
            return this.callAsync(method, path, null, payload, callback);
        }

        /**
         * Calls asynchronously the REST Service.
         *
         * @param method - HTTP request method.
         * @param path - The service path using the APEX String.format placeholders to hold the path arguments.
         * @param pathArguments - The argument that will be put in the path placeholder.
         * @param callback - The callback instance.
         * @return The batch Id.
         */
        public Id callAsync(String method, String path, Map<String, String> pathArguments, gslib_IRestClientCallback callback) {
            return this.callAsync(method, path, pathArguments, null, callback);
        }

        /**
         * Calls asynchronously the REST Service.
         *
         * @param method - HTTP request method.
         * @param path - The service path using the APEX String.format placeholders to hold the path arguments.
         * @param pathArguments - The argument that will be put in the path placeholder.
         * @param payload - The payload to send in the request.
         * @param callback - The callback instance.
         * @return The batch Id.
         */
        public Id callAsync(String method, String path, Map<String, String> pathArguments, Object payload, gslib_IRestClientCallback callback) {
            path = this.buildPath(path, pathArguments);
            HttpRequestData requestData = new HttpRequestData(
                method, path, payload,
                this.serializer, this.headerFields, this.configModules
            );
            return System.enqueueJob(new QueueableRestClientExecutor(requestData, serializer, callback));
        }

        /*
         * Private methods
         */
        private String buildPath(String path, Map<String, String> pathArguments) {
            path = this.endpoint + path;
            if (pathArguments == null || pathArguments.isEmpty()) {
                return path;
            }
            List<String> arguments = new List<String>();
            for (String key : pathArguments.keySet()) {
                arguments.add(
                    EncodingUtil.urlEncode(key, 'UTF-8') + '=' +
                        EncodingUtil.urlEncode(pathArguments.get(key), 'UTF-8')
                );
            }
            String prefix = path.contains('?') ? '&' : '?';
            return path + prefix + String.join(arguments, '&');
        }
    }
}