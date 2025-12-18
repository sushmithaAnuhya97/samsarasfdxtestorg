/**
 * Copyright (c), Groundswell Cloud Solutions - https://www.gscloudsolutions.com/
 * All rights reserved.
 */

@IsTest(IsParallel = true)
public class gslib_RestClientTest {

    /*
     * Constructor tests.
     */

    @IsTest
    static void constructor_ShouldSetEndpoint() {
        // Act.
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint');

        // Assert.
        System.assertEquals('https://test.endpoint', client.endpoint);
        System.assertEquals(true, client.configModules.isEmpty());
        System.assert(client.serializer instanceof gslib_RestJsonSerializer, 'Should be a gslib_RestJsonSerializer instance.');
    }

    @IsTest
    static void constructor_ShouldSetEndpointAndSerializer() {
        // Arrange.
        TestSerializer1 serializer = new TestSerializer1();

        // Act.
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint', serializer);

        // Assert.
        System.assertEquals('https://test.endpoint', client.endpoint);
        System.assertEquals(true, client.configModules.isEmpty());
        System.assert(client.serializer == serializer, 'Should be a TestSerializer instance.');
    }

    @IsTest
    static void constructor_ShouldSetEndpointAndConfigModule() {
        // Arrange.
        TestClientConfigModule1 configModule = new TestClientConfigModule1();

        // Act.
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint', configModule);

        // Assert.
        System.assertEquals('https://test.endpoint', client.endpoint);
        System.assertEquals(1, client.configModules.size());
        System.assert(client.configModules.contains(configModule), 'Should contain a TestClientConfigModule instance.');
        System.assert(client.serializer instanceof gslib_RestJsonSerializer, 'Should be a gslib_RestJsonSerializer instance.');
    }

    @IsTest
    static void constructor_ShouldSetEndpointAndConfigModuleList() {
        // Arrange.
        TestClientConfigModule1 configModule = new TestClientConfigModule1();
        List<gslib_IRestClientConfigModule> configModules = new List<gslib_IRestClientConfigModule> {
            configModule
        };

        // Act.
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint', configModules);

        // Assert.
        System.assertEquals('https://test.endpoint', client.endpoint);
        System.assertEquals(1, client.configModules.size());
        System.assert(client.configModules.contains(configModule), 'Should contain a TestClientConfigModule instance.');
        System.assert(client.serializer instanceof gslib_RestJsonSerializer, 'Should be a gslib_RestJsonSerializer instance.');
    }

    @IsTest
    static void constructor_ShouldSetEndpointConfigModuleAndSerializer() {
        // Arrange.
        TestClientConfigModule1 configModule = new TestClientConfigModule1();
        TestSerializer1 serializer = new TestSerializer1();

        // Act.
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint', serializer, configModule);

        // Assert.
        System.assertEquals('https://test.endpoint', client.endpoint);
        System.assertEquals(1, client.configModules.size());
        System.assert(client.configModules.contains(configModule), 'Should contain a TestClientConfigModule instance.');
        System.assert(client.serializer == serializer, 'Should be a TestSerializer instance.');
    }

    @IsTest
    static void constructor_ShouldSetEndpointConfigModuleListAndSerializer() {
        // Arrange.
        TestClientConfigModule1 configModule = new TestClientConfigModule1();
        TestSerializer1 serializer = new TestSerializer1();
        List<gslib_IRestClientConfigModule> configModules = new List<gslib_IRestClientConfigModule> {
            configModule
        };

        // Act.
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint', configModules, serializer);

        // Assert.
        System.assertEquals('https://test.endpoint', client.endpoint);
        System.assertEquals(1, client.configModules.size());
        System.assert(client.configModules.contains(configModule), 'Should contain a TestClientConfigModule instance.');
        System.assert(client.serializer == serializer, 'Should be a TestSerializer instance.');
    }

    /*
     * Request creation tests.
     */

    @IsTest
    static void createRequest_ShouldUseConstructorArguments() {
        // Arrange.
        gslib_RestClient client = new gslib_RestClient(
            'https://test.endpoint',
            new TestSerializer1(),
            new TestClientConfigModule1()
        );

        // Act.
        gslib_RestClient.RestClientRequest request = client.createRequest();

        // Assert.
        System.assertEquals('https://test.endpoint', request.endpoint);
        System.assertEquals(1, request.configModules.size());
        System.assert(request.configModules.get(0) instanceof TestClientConfigModule1,
            'Should contain a TestClientConfigModule1 instance.');
        System.assert(request.serializer instanceof TestSerializer1, 'Should be a TestSerializer1 instance.');
    }

    @IsTest
    static void createRequest_AddConfigModule_ShouldAppendToConstructorConfigModules() {
        // Arrange.
        gslib_RestClient client = new gslib_RestClient(
            'https://test.endpoint',
            new TestSerializer1(),
            new TestClientConfigModule1()
        );

        // Act.
        gslib_RestClient.RestClientRequest request = client.createRequest()
            .addConfigModule(new TestClientConfigModule2());

        // Assert client.
        System.assertEquals(1, client.configModules.size());

        // Assert request.
        System.assertEquals(2, request.configModules.size());
        System.assert(request.configModules.get(0) instanceof TestClientConfigModule1,
            'Should contain a TestClientConfigModule1 instance.');
        System.assert(request.configModules.get(1) instanceof TestClientConfigModule2,
            'Should contain a TestClientConfigModule2 instance.');
        System.assert(request.serializer instanceof TestSerializer1, 'Should be a TestSerializer1 instance.');
    }

    @IsTest
    static void createRequest_AddConfigModules_ShouldAppendToConstructorConfigModules() {
        // Arrange.
        gslib_RestClient client = new gslib_RestClient(
            'https://test.endpoint',
            new TestSerializer1(),
            new TestClientConfigModule1()
        );

        // Act.
        gslib_RestClient.RestClientRequest request = client.createRequest()
            .addConfigModules(new List<gslib_IRestClientConfigModule> { new TestClientConfigModule2() });

        // Assert client.
        System.assertEquals(1, client.configModules.size());
        System.assert(client.configModules.get(0) instanceof TestClientConfigModule1,
            'Should contain a TestClientConfigModule1 instance.');

        // Assert request.
        System.assertEquals(2, request.configModules.size());
        System.assert(request.configModules.get(0) instanceof TestClientConfigModule1,
            'Should contain a TestClientConfigModule1 instance.');
        System.assert(request.configModules.get(1) instanceof TestClientConfigModule2,
            'Should contain a TestClientConfigModule2 instance.');
        System.assert(request.serializer instanceof TestSerializer1, 'Should be a TestSerializer1 instance.');
    }

    @IsTest
    static void createRequest_ClearConfigModules_ShouldClearConstructorConfigModules() {
        // Arrange.
        gslib_RestClient client = new gslib_RestClient(
            'https://test.endpoint',
            new TestSerializer1(),
            new TestClientConfigModule1()
        );

        // Act.
        gslib_RestClient.RestClientRequest request = client.createRequest()
            .clearConfigModules()
            .addConfigModules(new List<gslib_IRestClientConfigModule> { new TestClientConfigModule2() });

        // Assert client.
        System.assertEquals(1, client.configModules.size());
        System.assert(client.configModules.get(0) instanceof TestClientConfigModule1,
            'Should contain a TestClientConfigModule1 instance.');

        // Assert request.
        System.assertEquals(1, request.configModules.size());
        System.assert(request.configModules.get(0) instanceof TestClientConfigModule2,
            'Should contain a TestClientConfigModule2 instance.');
        System.assert(request.serializer instanceof TestSerializer1, 'Should be a TestSerializer1 instance.');
    }

    @IsTest
    static void createRequest_SetSerializer_ShouldReplaceConstructorSerializer() {
        // Arrange.
        gslib_RestClient client = new gslib_RestClient(
            'https://test.endpoint',
            new TestSerializer1(),
            new TestClientConfigModule1()
        );

        // Act.
        gslib_RestClient.RestClientRequest request = client.createRequest()
            .setSerializer(new TestSerializer2());

        // Assert client.
        System.assertEquals(1, client.configModules.size());
        System.assert(client.serializer instanceof TestSerializer1, 'Should be a TestSerializer1 instance.');

        // Assert request.
        System.assertEquals(1, request.configModules.size());
        System.assert(request.configModules.get(0) instanceof TestClientConfigModule1,
            'Should contain a TestClientConfigModule1 instance.');
        System.assert(request.serializer instanceof TestSerializer2, 'Should be a TestSerializer2 instance.');
    }

    @IsTest
    static void createRequest_AddHeader_ShouldAddHeaderValue() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        gslib_RestClient client = new gslib_RestClient(
            'https://test.endpoint',
            new TestClientConfigModule1()
        );

        // Act.
        client.createRequest()
            .addHeader('Header1', 'Value1')
            .addHeader('Header2', 'Value2')
            .call('DELETE', '');

        // Assert.
        System.assertEquals('Value1', calloutMock.request.getHeader('Header1'));
        System.assertEquals('Value2', calloutMock.request.getHeader('Header2'));
        System.assertEquals('Module1Configuration', calloutMock.request.getHeader('Module1'));
    }

    @IsTest
    static void createRequest_AddHeaders_ShouldAddHeaderValue() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        gslib_RestClient client = new gslib_RestClient(
            'https://test.endpoint',
            new TestClientConfigModule1()
        );

        // Act.
        client.createRequest()
            .addHeaders(new Map<String, String>{
                'Header1' => 'Value1', 'Header2' => 'Value2'
            })
            .call('DELETE', '');

        // Assert.
        System.assertEquals('Value1', calloutMock.request.getHeader('Header1'));
        System.assertEquals('Value2', calloutMock.request.getHeader('Header2'));
        System.assertEquals('Module1Configuration', calloutMock.request.getHeader('Module1'));
    }

    /*
     * Generic call tests.
     */

    @IsTest
    static void call_WithMethodAndPathTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');

        // Act.
        Object response = client.createRequest().call('GET', '/call/test');

        // Assert request.
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals('https://test.endpoint/api/call/test', calloutMock.request.getEndpoint());
        System.assertEquals('GET', calloutMock.request.getMethod());
        System.assertEquals('application/json', calloutMock.request.getHeader('Content-Type'));
        System.assertEquals('', calloutMock.request.getBody());

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof Map<String, Object>, 'It should be a Map<String, Object>');
        Map<String, Object> responseMap = (Map<String, Object>) response;
        System.assertEquals(true, responseMap.containsKey('response'));
        System.assertEquals('test mock', responseMap.get('response'));
    }

    @IsTest
    static void call_WithMethodPathAndArgumentsTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        Map<String, String> args = new Map<String, String> {
            'arg 1'=> 'value1',
            'arg2' => 'value 2'
        };

        // Act.
        Object response = client.createRequest().call('POST', '/call/test', args);

        // Assert request.
        String expectedEndpoint = 'https://test.endpoint/api/call/test?arg+1=value1&arg2=value+2';
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals(expectedEndpoint, calloutMock.request.getEndpoint());
        System.assertEquals('POST', calloutMock.request.getMethod());
        System.assertEquals('application/json', calloutMock.request.getHeader('Content-Type'));
        System.assertEquals('', calloutMock.request.getBody());

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof Map<String, Object>, 'It should be a Map<String, Object>');
        Map<String, Object> responseMap = (Map<String, Object>) response;
        System.assertEquals(true, responseMap.containsKey('response'));
        System.assertEquals('test mock', responseMap.get('response'));
    }

    @IsTest
    static void call_WithMethodPathAndPayloadTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        TestPayload payload = new TestPayload('test value', 12345);

        // Act.
        Object response = client.createRequest().call('POST', '/call/test', payload);

        // Assert request.
        String expectedPayload = '{"field2":12345,"field1":"test value"}';
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals('https://test.endpoint/api/call/test', calloutMock.request.getEndpoint());
        System.assertEquals('POST', calloutMock.request.getMethod());
        System.assertEquals('application/json', calloutMock.request.getHeader('Content-Type'));
        System.assertEquals(expectedPayload, calloutMock.request.getBody());

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof Map<String, Object>, 'It should be a Map<String, Object>');
        Map<String, Object> responseMap = (Map<String, Object>) response;
        System.assertEquals(true, responseMap.containsKey('response'));
        System.assertEquals('test mock', responseMap.get('response'));
    }

    @IsTest
    static void call_WithMethodPathArgumentsAndPayloadTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        Map<String, String> args = new Map<String, String> {
            'arg 1'=> 'value1',
            'arg2' => 'value 2'
        };
        TestPayload payload = new TestPayload('new value', 23456);

        // Act.
        Object response = client.createRequest().call('POST', '/call/test', args, payload);

        // Assert request.
        String expectedEndpoint = 'https://test.endpoint/api/call/test?arg+1=value1&arg2=value+2';
        String expectedPayload = '{"field2":23456,"field1":"new value"}';
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals(expectedEndpoint, calloutMock.request.getEndpoint());
        System.assertEquals('POST', calloutMock.request.getMethod());
        System.assertEquals('application/json', calloutMock.request.getHeader('Content-Type'));
        System.assertEquals(expectedPayload, calloutMock.request.getBody());

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof Map<String, Object>, 'It should be a Map<String, Object>');
        Map<String, Object> responseMap = (Map<String, Object>) response;
        System.assertEquals(true, responseMap.containsKey('response'));
        System.assertEquals('test mock', responseMap.get('response'));
    }

    @IsTest
    static void call_ShouldThrowExceptionWhenStatusCodeIsNot2NN() {
        Integer[] statusCodes = new Integer[] { 100, 199, 300, 301, 302, 400, 401, 404, 500, 600, 700, 800, 900 };
        for(Integer statusCode : statusCodes) {
            // Arrange.
            Test.setMock(HttpCalloutMock.class, new TestCalloutMockImpl(statusCode));
            gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');

            try {
                // Act.
                client.createRequest().call('GET', '/call/test');
                System.assert(false, 'Should throw exception');

            } catch(Exception e) {
                // Assert.
                System.assert(e instanceof gslib_RestClientException, 'Should be a gslib_RestClientException instance');
                gslib_RestClientException restException = (gslib_RestClientException) e;
                System.assertNotEquals(null, restException.payload);
                System.assertNotEquals(null, restException.response);
                System.assertEquals(statusCode, restException.response.getStatusCode());
            }
        }
    }

    @IsTest
    static void call_ShouldNotThrowExceptionWhenStatusIn2NNRange() {
        Integer[] statusCodes = new Integer[] { 200, 201, 202, 210, 250, 299 };
        for(Integer statusCode : statusCodes) {
            // Arrange.
            Test.setMock(HttpCalloutMock.class, new TestCalloutMockImpl(statusCode));
            gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');

            // Act.
            Object payload = client.createRequest().call('GET', '/call/test');
            System.assertNotEquals(null, payload);
        }
    }

    @IsTest
    static void call_SetSerializer_ShouldUseCustomSerializer() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        TestSerializer1 serializer = new TestSerializer1();
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        Map<String, String> args = new Map<String, String> {
            'arg 1'=> 'value1',
            'arg2' => 'value 2'
        };

        // Act.
        Object response = client.createRequest()
            .setSerializer(serializer)
            .call('GET', '/call/test');

        // Assert request.
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals('https://test.endpoint/api/call/test', calloutMock.request.getEndpoint());
        System.assertEquals('GET', calloutMock.request.getMethod());
        System.assertEquals('text/html', calloutMock.request.getHeader('Content-Type'));

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof String, 'It should be a String');
        String responseData = (String) response;
        System.assertEquals('<div>{"response":"test mock"}</div>', responseData);
    }

    /*
     * Generic async call tests.
     */

    @IsTest
    static void callAsync_WithMethodAndPathTest() {
        // Arrange.
        String testId = gslib_IdUtils.createUUID();
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        TestCallback callback = new TestCallback(testId);

        // Act.
        Test.startTest();
        client.createRequest().callAsync('GET', '/get/test', callback);
        Test.stopTest();

        // Assert request.
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals('https://test.endpoint/api/get/test', calloutMock.request.getEndpoint());
        System.assertEquals('GET', calloutMock.request.getMethod());
        System.assertEquals('application/json', calloutMock.request.getHeader('Content-Type'));
        System.assertEquals('', calloutMock.request.getBody());

        // Assert onError response callback.
        callback = callbackData.get(testId);
        String errorMessage = callback.responseException == null ? '' : callback.responseException.getMessage();
        System.assertEquals(null, callback.responseException, errorMessage);
        System.assertEquals(null, callback.onErrorResponse);

        // Assert onSuccess response callback.
        System.assertNotEquals(null, callback.onSuccessRequest);
        System.assertNotEquals(null, callback.onSuccessPayload);
        System.assert(callback.onSuccessPayload instanceof Map<String, Object>, 'It should be a Map<String, Object>');
        Map<String, Object> responseMap = (Map<String, Object>) callback.onSuccessPayload;
        System.assertEquals(true, responseMap.containsKey('response'));
        System.assertEquals('test mock', responseMap.get('response'));
    }

    @IsTest
    static void callAsync_WithMethodPathAndPayloadTest() {
        // Arrange.
        String testId = gslib_IdUtils.createUUID();
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        TestPayload payload = new TestPayload('test value', 12345);
        TestCallback callback = new TestCallback(testId);

        // Act.
        Test.startTest();
        client.createRequest().callAsync('POST', '/post/test', payload, callback);
        Test.stopTest();

        // Assert request.
        String expectedPayload = '{"field2":12345,"field1":"test value"}';
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals('https://test.endpoint/api/post/test', calloutMock.request.getEndpoint());
        System.assertEquals('POST', calloutMock.request.getMethod());
        System.assertEquals('application/json', calloutMock.request.getHeader('Content-Type'));
        System.assertEquals(expectedPayload, calloutMock.request.getBody());

        // Assert onError response callback.
        callback = callbackData.get(testId);
        String errorMessage = callback.responseException == null ? '' : callback.responseException.getMessage();
        System.assertEquals(null, callback.responseException, errorMessage);
        System.assertEquals(null, callback.onErrorResponse);

        // Assert onSuccess response callback.
        System.assertNotEquals(null, callback.onSuccessRequest);
        System.assertNotEquals(null, callback.onSuccessPayload);
        System.assert(callback.onSuccessPayload instanceof Map<String, Object>, 'It should be a Map<String, Object>');
        Map<String, Object> responseMap = (Map<String, Object>) callback.onSuccessPayload;
        System.assertEquals(true, responseMap.containsKey('response'));
        System.assertEquals('test mock', responseMap.get('response'));
    }

    @IsTest
    static void callAsync_WithMethodPathArgumentsAndPayloadTest() {
        // Arrange.
        String testId = gslib_IdUtils.createUUID();
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        Map<String, String> args = new Map<String, String> {
            'arg 1'=> 'value1',
            'arg2' => 'value 2'
        };
        TestPayload payload = new TestPayload('new value', 23456);
        TestCallback callback = new TestCallback(testId);

        // Act.
        Test.startTest();
        client.createRequest().callAsync('GET', '/get/test', args, payload, callback);
        Test.stopTest();

        // Assert request.
        String expectedEndpoint = 'https://test.endpoint/api/get/test?arg+1=value1&arg2=value+2';
        String expectedPayload = '{"field2":23456,"field1":"new value"}';
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals(expectedEndpoint, calloutMock.request.getEndpoint());
        System.assertEquals('GET', calloutMock.request.getMethod());
        System.assertEquals('application/json', calloutMock.request.getHeader('Content-Type'));
        System.assertEquals(expectedPayload, calloutMock.request.getBody());

        // Assert onError response callback.
        callback = callbackData.get(testId);
        String errorMessage = callback.responseException == null ? '' : callback.responseException.getMessage();
        System.assertEquals(null, callback.responseException, errorMessage);
        System.assertEquals(null, callback.onErrorResponse);

        // Assert onSuccess response callback.
        System.assertNotEquals(null, callback.onSuccessRequest);
        System.assertNotEquals(null, callback.onSuccessPayload);
        System.assert(callback.onSuccessPayload instanceof Map<String, Object>, 'It should be a Map<String, Object>');
        Map<String, Object> responseMap = (Map<String, Object>) callback.onSuccessPayload;
        System.assertEquals(true, responseMap.containsKey('response'));
        System.assertEquals('test mock', responseMap.get('response'));
    }

    @IsTest
    static void callAsync_SetSerializer_ShouldUseCustomSerializer() {
        // Arrange.
        String testId = gslib_IdUtils.createUUID();
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        TestSerializer1 serializer = new TestSerializer1();
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        Map<String, String> args = new Map<String, String> {
            'arg 1'=> 'value1',
            'arg2' => 'value 2'
        };
        TestCallback callback = new TestCallback(testId);

        // Act.
        Test.startTest();
        client.createRequest()
            .setSerializer(serializer)
            .callAsync('PUT', '/put/test', callback);
        Test.stopTest();

        // Assert request.
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals('https://test.endpoint/api/put/test', calloutMock.request.getEndpoint());
        System.assertEquals('PUT', calloutMock.request.getMethod());
        System.assertEquals('text/html', calloutMock.request.getHeader('Content-Type'));

        // Assert onError response callback.
        callback = callbackData.get(testId);
        String errorMessage = callback.responseException == null ? '' : callback.responseException.getMessage();
        System.assertEquals(null, callback.responseException, errorMessage);
        System.assertEquals(null, callback.onErrorResponse);

        // Assert onSuccess response callback.
        System.assertNotEquals(null, callback.onSuccessRequest);
        System.assertNotEquals(null, callback.onSuccessPayload);
        System.assert(callback.onSuccessPayload instanceof String, 'It should be a String');
        String responseData = (String) callback.onSuccessPayload;
        System.assertEquals('<div>{"response":"test mock"}</div>', responseData);
    }

    /*
     * GET call tests.
     */

    @IsTest
    static void get_WithMethodAndPathTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');

        // Act.
        Object response = client.createRequest().get('/get/test');

        // Assert request.
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals('https://test.endpoint/api/get/test', calloutMock.request.getEndpoint());
        System.assertEquals('GET', calloutMock.request.getMethod());
        System.assertEquals('application/json', calloutMock.request.getHeader('Content-Type'));
        System.assertEquals('', calloutMock.request.getBody());

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof Map<String, Object>, 'It should be a Map<String, Object>');
        Map<String, Object> responseMap = (Map<String, Object>) response;
        System.assertEquals(true, responseMap.containsKey('response'));
        System.assertEquals('test mock', responseMap.get('response'));
    }

    @IsTest
    static void get_WithMethodPathAndArgumentsTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        Map<String, String> args = new Map<String, String> {
            'arg 1'=> 'value1',
            'arg2' => 'value 2'
        };

        // Act.
        Object response = client.createRequest().get('/get/test', args);

        // Assert request.
        String expectedEndpoint = 'https://test.endpoint/api/get/test?arg+1=value1&arg2=value+2';
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals(expectedEndpoint, calloutMock.request.getEndpoint());
        System.assertEquals('GET', calloutMock.request.getMethod());
        System.assertEquals('application/json', calloutMock.request.getHeader('Content-Type'));
        System.assertEquals('', calloutMock.request.getBody());

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof Map<String, Object>, 'It should be a Map<String, Object>');
        Map<String, Object> responseMap = (Map<String, Object>) response;
        System.assertEquals(true, responseMap.containsKey('response'));
        System.assertEquals('test mock', responseMap.get('response'));
    }

    @IsTest
    static void get_WithMethodPathAndPayloadTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        TestPayload payload = new TestPayload('test value', 12345);

        // Act.
        Object response = client.createRequest().get('/get/test', payload);

        // Assert request.
        String expectedPayload = '{"field2":12345,"field1":"test value"}';
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals('https://test.endpoint/api/get/test', calloutMock.request.getEndpoint());
        System.assertEquals('GET', calloutMock.request.getMethod());
        System.assertEquals('application/json', calloutMock.request.getHeader('Content-Type'));
        System.assertEquals(expectedPayload, calloutMock.request.getBody());

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof Map<String, Object>, 'It should be a Map<String, Object>');
        Map<String, Object> responseMap = (Map<String, Object>) response;
        System.assertEquals(true, responseMap.containsKey('response'));
        System.assertEquals('test mock', responseMap.get('response'));
    }

    @IsTest
    static void get_WithMethodPathArgumentsAndPayloadTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        Map<String, String> args = new Map<String, String> {
            'arg 1'=> 'value1',
            'arg2' => 'value 2'
        };
        TestPayload payload = new TestPayload('new value', 23456);

        // Act.
        Object response = client.createRequest().get('/get/test', args, payload);

        // Assert request.
        String expectedEndpoint = 'https://test.endpoint/api/get/test?arg+1=value1&arg2=value+2';
        String expectedPayload = '{"field2":23456,"field1":"new value"}';
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals(expectedEndpoint, calloutMock.request.getEndpoint());
        System.assertEquals('GET', calloutMock.request.getMethod());
        System.assertEquals('application/json', calloutMock.request.getHeader('Content-Type'));
        System.assertEquals(expectedPayload, calloutMock.request.getBody());

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof Map<String, Object>, 'It should be a Map<String, Object>');
        Map<String, Object> responseMap = (Map<String, Object>) response;
        System.assertEquals(true, responseMap.containsKey('response'));
        System.assertEquals('test mock', responseMap.get('response'));
    }

    @IsTest
    static void get_WithSerializerMethodAndPathTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        TestSerializer1 serializer = new TestSerializer1();
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        Map<String, String> args = new Map<String, String> {
            'arg 1'=> 'value1',
            'arg2' => 'value 2'
        };

        // Act.
        Object response = client.createRequest()
            .setSerializer(serializer)
            .get('/get/test');

        // Assert request.
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals('https://test.endpoint/api/get/test', calloutMock.request.getEndpoint());
        System.assertEquals('GET', calloutMock.request.getMethod());
        System.assertEquals('text/html', calloutMock.request.getHeader('Content-Type'));

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof String, 'It should be a String');
        String responseData = (String) response;
        System.assertEquals('<div>{"response":"test mock"}</div>', responseData);
    }

    @IsTest
    static void get_WithSerializerMethodPathAndArgumentsTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        TestSerializer1 serializer = new TestSerializer1();
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        Map<String, String> args = new Map<String, String> {
            'arg 1'=> 'value1',
            'arg2' => 'value 2'
        };

        // Act.
        Object response = client.createRequest()
            .setSerializer(serializer)
            .get('/get/test', args);

        // Assert request.
        String expectedEndpoint = 'https://test.endpoint/api/get/test?arg+1=value1&arg2=value+2';
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals(expectedEndpoint, calloutMock.request.getEndpoint());
        System.assertEquals('GET', calloutMock.request.getMethod());
        System.assertEquals('text/html', calloutMock.request.getHeader('Content-Type'));

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof String, 'It should be a String');
        String responseData = (String) response;
        System.assertEquals('<div>{"response":"test mock"}</div>', responseData);
    }

    @IsTest
    static void get_WithSerializerMethodPathAndPayloadTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        TestSerializer1 serializer = new TestSerializer1();
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        TestPayload payload = new TestPayload('test value', 54321);

        // Act.
        Object response = client.createRequest()
            .setSerializer(serializer)
            .get('/get/test', payload);

        // Assert request.
        String expectedPayload = '<div>TestPayload:[field1=test value, field2=54321]</div>';
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals('https://test.endpoint/api/get/test', calloutMock.request.getEndpoint());
        System.assertEquals('GET', calloutMock.request.getMethod());
        System.assertEquals('text/html', calloutMock.request.getHeader('Content-Type'));
        System.assertEquals(expectedPayload, calloutMock.request.getBody());

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof String, 'It should be a String');
        String responseData = (String) response;
        System.assertEquals('<div>{"response":"test mock"}</div>', responseData);
    }

    @IsTest
    static void get_WithSerializerMethodPathArgumentsAndPayloadTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        TestSerializer1 serializer = new TestSerializer1();
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        Map<String, String> args = new Map<String, String> {
            'arg 1'=> 'value1',
            'arg2' => 'value 2'
        };
        TestPayload payload = new TestPayload('new value', 5746);

        // Act.
        Object response = client.createRequest()
            .setSerializer(serializer)
            .get('/get/test', args, payload);

        // Assert request.
        String expectedEndpoint = 'https://test.endpoint/api/get/test?arg+1=value1&arg2=value+2';
        String expectedPayload = '<div>TestPayload:[field1=new value, field2=5746]</div>';
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals(expectedEndpoint, calloutMock.request.getEndpoint());
        System.assertEquals('GET', calloutMock.request.getMethod());
        System.assertEquals('text/html', calloutMock.request.getHeader('Content-Type'));
        System.assertEquals(expectedPayload, calloutMock.request.getBody());

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof String, 'It should be a String');
        String responseData = (String) response;
        System.assertEquals('<div>{"response":"test mock"}</div>', responseData);
    }

    /*
     * POST call tests with default JSON serializer.
     */

    @IsTest
    static void post_WithMethodAndPathTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');

        // Act.
        Object response = client.createRequest().post('/post/test');

        // Assert request.
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals('https://test.endpoint/api/post/test', calloutMock.request.getEndpoint());
        System.assertEquals('POST', calloutMock.request.getMethod());
        System.assertEquals('application/json', calloutMock.request.getHeader('Content-Type'));
        System.assertEquals('', calloutMock.request.getBody());

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof Map<String, Object>, 'It should be a Map<String, Object>');
        Map<String, Object> responseMap = (Map<String, Object>) response;
        System.assertEquals(true, responseMap.containsKey('response'));
        System.assertEquals('test mock', responseMap.get('response'));
    }

    @IsTest
    static void post_WithMethodPathAndArgumentsTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        Map<String, String> args = new Map<String, String> {
            'arg 1'=> 'value1',
            'arg2' => 'value 2'
        };

        // Act.
        Object response = client.createRequest().post('/post/test', args);

        // Assert request.
        String expectedEndpoint = 'https://test.endpoint/api/post/test?arg+1=value1&arg2=value+2';
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals(expectedEndpoint, calloutMock.request.getEndpoint());
        System.assertEquals('POST', calloutMock.request.getMethod());
        System.assertEquals('application/json', calloutMock.request.getHeader('Content-Type'));
        System.assertEquals('', calloutMock.request.getBody());

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof Map<String, Object>, 'It should be a Map<String, Object>');
        Map<String, Object> responseMap = (Map<String, Object>) response;
        System.assertEquals(true, responseMap.containsKey('response'));
        System.assertEquals('test mock', responseMap.get('response'));
    }

    @IsTest
    static void post_WithMethodPathAndPayloadTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        TestPayload payload = new TestPayload('test value', 12345);

        // Act.
        Object response = client.createRequest().post('/post/test', payload);

        // Assert request.
        String expectedPayload = '{"field2":12345,"field1":"test value"}';
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals('https://test.endpoint/api/post/test', calloutMock.request.getEndpoint());
        System.assertEquals('POST', calloutMock.request.getMethod());
        System.assertEquals('application/json', calloutMock.request.getHeader('Content-Type'));
        System.assertEquals(expectedPayload, calloutMock.request.getBody());

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof Map<String, Object>, 'It should be a Map<String, Object>');
        Map<String, Object> responseMap = (Map<String, Object>) response;
        System.assertEquals(true, responseMap.containsKey('response'));
        System.assertEquals('test mock', responseMap.get('response'));
    }

    @IsTest
    static void post_WithMethodPathArgumentsAndPayloadTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        Map<String, String> args = new Map<String, String> {
            'arg 1'=> 'value1',
            'arg2' => 'value 2'
        };
        TestPayload payload = new TestPayload('new value', 23456);

        // Act.
        Object response = client.createRequest().post('/post/test', args, payload);

        // Assert request.
        String expectedEndpoint = 'https://test.endpoint/api/post/test?arg+1=value1&arg2=value+2';
        String expectedPayload = '{"field2":23456,"field1":"new value"}';
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals(expectedEndpoint, calloutMock.request.getEndpoint());
        System.assertEquals('POST', calloutMock.request.getMethod());
        System.assertEquals('application/json', calloutMock.request.getHeader('Content-Type'));
        System.assertEquals(expectedPayload, calloutMock.request.getBody());

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof Map<String, Object>, 'It should be a Map<String, Object>');
        Map<String, Object> responseMap = (Map<String, Object>) response;
        System.assertEquals(true, responseMap.containsKey('response'));
        System.assertEquals('test mock', responseMap.get('response'));
    }

    @IsTest
    static void post_WithSerializerMethodAndPathTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        TestSerializer1 serializer = new TestSerializer1();
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        Map<String, String> args = new Map<String, String> {
            'arg 1'=> 'value1',
            'arg2' => 'value 2'
        };

        // Act.
        Object response = client.createRequest()
            .setSerializer(serializer)
            .post('/post/test');

        // Assert request.
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals('https://test.endpoint/api/post/test', calloutMock.request.getEndpoint());
        System.assertEquals('POST', calloutMock.request.getMethod());
        System.assertEquals('text/html', calloutMock.request.getHeader('Content-Type'));

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof String, 'It should be a String');
        String responseData = (String) response;
        System.assertEquals('<div>{"response":"test mock"}</div>', responseData);
    }

    @IsTest
    static void post_WithSerializerMethodPathAndArgumentsTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        TestSerializer1 serializer = new TestSerializer1();
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        Map<String, String> args = new Map<String, String> {
            'arg 1'=> 'value1',
            'arg2' => 'value 2'
        };

        // Act.
        Object response = client.createRequest()
            .setSerializer(serializer)
            .post('/post/test', args);

        // Assert request.
        String expectedEndpoint = 'https://test.endpoint/api/post/test?arg+1=value1&arg2=value+2';
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals(expectedEndpoint, calloutMock.request.getEndpoint());
        System.assertEquals('POST', calloutMock.request.getMethod());
        System.assertEquals('text/html', calloutMock.request.getHeader('Content-Type'));

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof String, 'It should be a String');
        String responseData = (String) response;
        System.assertEquals('<div>{"response":"test mock"}</div>', responseData);
    }

    @IsTest
    static void post_WithSerializerMethodPathAndPayloadTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        TestSerializer1 serializer = new TestSerializer1();
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        TestPayload payload = new TestPayload('test value', 54321);

        // Act.
        Object response = client.createRequest()
            .setSerializer(serializer)
            .post('/post/test', payload);

        // Assert request.
        String expectedPayload = '<div>TestPayload:[field1=test value, field2=54321]</div>';
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals('https://test.endpoint/api/post/test', calloutMock.request.getEndpoint());
        System.assertEquals('POST', calloutMock.request.getMethod());
        System.assertEquals('text/html', calloutMock.request.getHeader('Content-Type'));
        System.assertEquals(expectedPayload, calloutMock.request.getBody());

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof String, 'It should be a String');
        String responseData = (String) response;
        System.assertEquals('<div>{"response":"test mock"}</div>', responseData);
    }

    @IsTest
    static void post_WithSerializerMethodPathArgumentsAndPayloadTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        TestSerializer1 serializer = new TestSerializer1();
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        Map<String, String> args = new Map<String, String> {
            'arg 1'=> 'value1',
            'arg2' => 'value 2'
        };
        TestPayload payload = new TestPayload('new value', 5746);

        // Act.
        Object response = client.createRequest()
            .setSerializer(serializer)
            .post('/post/test', args, payload);

        // Assert request.
        String expectedEndpoint = 'https://test.endpoint/api/post/test?arg+1=value1&arg2=value+2';
        String expectedPayload = '<div>TestPayload:[field1=new value, field2=5746]</div>';
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals(expectedEndpoint, calloutMock.request.getEndpoint());
        System.assertEquals('POST', calloutMock.request.getMethod());
        System.assertEquals('text/html', calloutMock.request.getHeader('Content-Type'));
        System.assertEquals(expectedPayload, calloutMock.request.getBody());

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof String, 'It should be a String');
        String responseData = (String) response;
        System.assertEquals('<div>{"response":"test mock"}</div>', responseData);
    }

    /*
     * PUT call tests with default JSON serializer.
     */

    @IsTest
    static void put_WithMethodAndPathTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');

        // Act.
        Object response = client.createRequest().put('/put/test');

        // Assert request.
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals('https://test.endpoint/api/put/test', calloutMock.request.getEndpoint());
        System.assertEquals('PUT', calloutMock.request.getMethod());
        System.assertEquals('application/json', calloutMock.request.getHeader('Content-Type'));
        System.assertEquals('', calloutMock.request.getBody());

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof Map<String, Object>, 'It should be a Map<String, Object>');
        Map<String, Object> responseMap = (Map<String, Object>) response;
        System.assertEquals(true, responseMap.containsKey('response'));
        System.assertEquals('test mock', responseMap.get('response'));
    }

    @IsTest
    static void put_WithMethodPathAndArgumentsTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        Map<String, String> args = new Map<String, String> {
            'arg 1'=> 'value1',
            'arg2' => 'value 2'
        };

        // Act.
        Object response = client.createRequest().put('/put/test', args);

        // Assert request.
        String expectedEndpoint = 'https://test.endpoint/api/put/test?arg+1=value1&arg2=value+2';
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals(expectedEndpoint, calloutMock.request.getEndpoint());
        System.assertEquals('PUT', calloutMock.request.getMethod());
        System.assertEquals('application/json', calloutMock.request.getHeader('Content-Type'));
        System.assertEquals('', calloutMock.request.getBody());

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof Map<String, Object>, 'It should be a Map<String, Object>');
        Map<String, Object> responseMap = (Map<String, Object>) response;
        System.assertEquals(true, responseMap.containsKey('response'));
        System.assertEquals('test mock', responseMap.get('response'));
    }

    @IsTest
    static void put_WithMethodPathAndPayloadTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        TestPayload payload = new TestPayload('test value', 12345);

        // Act.
        Object response = client.createRequest().put('/put/test', payload);

        // Assert request.
        String expectedPayload = '{"field2":12345,"field1":"test value"}';
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals('https://test.endpoint/api/put/test', calloutMock.request.getEndpoint());
        System.assertEquals('PUT', calloutMock.request.getMethod());
        System.assertEquals('application/json', calloutMock.request.getHeader('Content-Type'));
        System.assertEquals(expectedPayload, calloutMock.request.getBody());

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof Map<String, Object>, 'It should be a Map<String, Object>');
        Map<String, Object> responseMap = (Map<String, Object>) response;
        System.assertEquals(true, responseMap.containsKey('response'));
        System.assertEquals('test mock', responseMap.get('response'));
    }

    @IsTest
    static void put_WithMethodPathArgumentsAndPayloadTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        Map<String, String> args = new Map<String, String> {
            'arg 1'=> 'value1',
            'arg2' => 'value 2'
        };
        TestPayload payload = new TestPayload('new value', 23456);

        // Act.
        Object response = client.createRequest().put('/put/test', args, payload);

        // Assert request.
        String expectedEndpoint = 'https://test.endpoint/api/put/test?arg+1=value1&arg2=value+2';
        String expectedPayload = '{"field2":23456,"field1":"new value"}';
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals(expectedEndpoint, calloutMock.request.getEndpoint());
        System.assertEquals('PUT', calloutMock.request.getMethod());
        System.assertEquals('application/json', calloutMock.request.getHeader('Content-Type'));
        System.assertEquals(expectedPayload, calloutMock.request.getBody());

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof Map<String, Object>, 'It should be a Map<String, Object>');
        Map<String, Object> responseMap = (Map<String, Object>) response;
        System.assertEquals(true, responseMap.containsKey('response'));
        System.assertEquals('test mock', responseMap.get('response'));
    }

    @IsTest
    static void put_WithSerializerMethodAndPathTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        TestSerializer1 serializer = new TestSerializer1();
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        Map<String, String> args = new Map<String, String> {
            'arg 1'=> 'value1',
            'arg2' => 'value 2'
        };

        // Act.
        Object response = client.createRequest()
            .setSerializer(serializer)
            .put('/put/test');

        // Assert request.
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals('https://test.endpoint/api/put/test', calloutMock.request.getEndpoint());
        System.assertEquals('PUT', calloutMock.request.getMethod());
        System.assertEquals('text/html', calloutMock.request.getHeader('Content-Type'));

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof String, 'It should be a String');
        String responseData = (String) response;
        System.assertEquals('<div>{"response":"test mock"}</div>', responseData);
    }

    @IsTest
    static void put_WithSerializerMethodPathAndArgumentsTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        TestSerializer1 serializer = new TestSerializer1();
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        Map<String, String> args = new Map<String, String> {
            'arg 1'=> 'value1',
            'arg2' => 'value 2'
        };

        // Act.
        Object response = client.createRequest()
            .setSerializer(serializer)
            .put('/put/test', args);

        // Assert request.
        String expectedEndpoint = 'https://test.endpoint/api/put/test?arg+1=value1&arg2=value+2';
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals(expectedEndpoint, calloutMock.request.getEndpoint());
        System.assertEquals('PUT', calloutMock.request.getMethod());
        System.assertEquals('text/html', calloutMock.request.getHeader('Content-Type'));

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof String, 'It should be a String');
        String responseData = (String) response;
        System.assertEquals('<div>{"response":"test mock"}</div>', responseData);
    }

    @IsTest
    static void put_WithSerializerMethodPathAndPayloadTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        TestSerializer1 serializer = new TestSerializer1();
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        TestPayload payload = new TestPayload('test value', 54321);

        // Act.
        Object response = client.createRequest()
            .setSerializer(serializer)
            .put('/put/test', payload);

        // Assert request.
        String expectedPayload = '<div>TestPayload:[field1=test value, field2=54321]</div>';
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals('https://test.endpoint/api/put/test', calloutMock.request.getEndpoint());
        System.assertEquals('PUT', calloutMock.request.getMethod());
        System.assertEquals('text/html', calloutMock.request.getHeader('Content-Type'));
        System.assertEquals(expectedPayload, calloutMock.request.getBody());

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof String, 'It should be a String');
        String responseData = (String) response;
        System.assertEquals('<div>{"response":"test mock"}</div>', responseData);
    }

    @IsTest
    static void put_WithSerializerMethodPathArgumentsAndPayloadTest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        TestSerializer1 serializer = new TestSerializer1();
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');
        Map<String, String> args = new Map<String, String> {
            'arg 1'=> 'value1',
            'arg2' => 'value 2'
        };
        TestPayload payload = new TestPayload('new value', 5746);

        // Act.
        Object response = client.createRequest()
            .setSerializer(serializer)
            .put('/put/test', args, payload);

        // Assert request.
        String expectedEndpoint = 'https://test.endpoint/api/put/test?arg+1=value1&arg2=value+2';
        String expectedPayload = '<div>TestPayload:[field1=new value, field2=5746]</div>';
        System.assertNotEquals(null, calloutMock.request);
        System.assertEquals(expectedEndpoint, calloutMock.request.getEndpoint());
        System.assertEquals('PUT', calloutMock.request.getMethod());
        System.assertEquals('text/html', calloutMock.request.getHeader('Content-Type'));
        System.assertEquals(expectedPayload, calloutMock.request.getBody());

        // Assert response.
        System.assertNotEquals(null, response);
        System.assert(response instanceof String, 'It should be a String');
        String responseData = (String) response;
        System.assertEquals('<div>{"response":"test mock"}</div>', responseData);
    }

    /*
     * Configuration module tests.
     */

    @IsTest
    static void restClient_ShouldApplyConfigurationFromConstructorModules() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        gslib_RestClient client = new gslib_RestClient(
            'https://test.endpoint/api',
            new List<gslib_IRestClientConfigModule> {
                new TestClientConfigModule1(),
                new TestClientConfigModule2()
            }
        );

        // Act.
        client.createRequest().call('POST', '/post');

        // Assert.
        HttpRequest request = calloutMock.request;
        System.assertEquals('Module1Configuration', request.getHeader('Module1'));
        System.assertEquals('Module2Configuration', request.getHeader('Module2'));
    }

    @IsTest
    static void restClient_ShouldApplyConfigurationFromCreateRequest() {
        // Arrange.
        TestCalloutMockImpl calloutMock = new TestCalloutMockImpl();
        Test.setMock(HttpCalloutMock.class, calloutMock);
        gslib_RestClient client = new gslib_RestClient('https://test.endpoint/api');

        // Act.
        client.createRequest()
            .addConfigModules(new List<gslib_IRestClientConfigModule> {
                new TestClientConfigModule1(),
                new TestClientConfigModule2()
            })
            .call('POST', '/post');

        // Assert.
        HttpRequest request = calloutMock.request;
        System.assertEquals('Module1Configuration', request.getHeader('Module1'));
        System.assertEquals('Module2Configuration', request.getHeader('Module2'));
    }

    /*
     * Text fixtures
     */
    public static Map<String, TestCallback> callbackData = new Map<String, TestCallback>();

    public class TestSerializer1 implements gslib_IRestClientSerializer {

        public HttpRequest serializerRequest { get; set; }
        public Object payload { get; set; }

        public HttpRequest deserializerRequest { get; set; }
        public HttpResponse response { get; set; }

        public String contentType() {
            return 'text/html';
        }

        public Object serialize(HttpRequest request, Object payload) {
            this.serializerRequest = request;
            this.payload = payload;
            return '<div>' + payload.toString() + '</div>';
        }

        public Object deserialize(HttpRequest request, HttpResponse response) {
            this.deserializerRequest = request;
            this.response = response;
            return '<div>' + response.getBody() + '</div>';
        }

        public Object deserializeError(HttpRequest request, HttpResponse response) {
            return null;
        }
    }

    public class TestSerializer2 implements gslib_IRestClientSerializer {

        public String contentType() {
            return 'text/html';
        }

        public Object serialize(HttpRequest request, Object payload) {
            return '';
        }

        public Object deserialize(HttpRequest request, HttpResponse response) {
            return '';
        }

        public Object deserializeError(HttpRequest request, HttpResponse response) {
            return null;
        }
    }

    public class TestClientConfigModule1 implements gslib_IRestClientConfigModule {

        public void applyConfiguration(HttpRequest request) {
            request.setHeader('Module1', 'Module1Configuration');
        }
    }

    public class TestClientConfigModule2 implements gslib_IRestClientConfigModule {

        public void applyConfiguration(HttpRequest request) {
            request.setHeader('Module2', 'Module2Configuration');
        }
    }

    public class TestCalloutMockImpl implements HttpCalloutMock {

        private Integer statusCode;

        public HTTPRequest request { get; set; }

        public TestCalloutMockImpl() {
            this(200);
        }

        public TestCalloutMockImpl(Integer statusCode) {
            this.statusCode = statusCode;
        }

        public HTTPResponse respond(HTTPRequest request) {
            this.request = request;
            HTTPResponse response = new HTTPResponse();
            response.setStatusCode(statusCode);
            response.setBody('{"response":"test mock"}');
            return response;
        }
    }

    public class TestCallback implements gslib_IRestClientCallback {

        private String key;

        public HttpRequest onSuccessRequest { get; set; }
        public Object onSuccessPayload { get; set; }

        public HttpRequest onErrorRequest { get; set; }
        public HttpResponse onErrorResponse { get; set; }
        public Exception responseException { get; set; }

        public TestCallback(String key) {
            this.key = key;
        }

        public void onSuccess(HttpRequest request, Object payload) {
            callbackData.put(this.key, this);
            this.onSuccessRequest = request;
            this.onSuccessPayload = payload;
        }

        public void onError(HttpRequest request, HttpResponse response, Exception callException) {
            callbackData.put(this.key, this);
            this.onErrorRequest = request;
            this.onErrorResponse = response;
            this.responseException = callException;
        }
    }

    public class TestPayload {

        public String field1 { get; set; }
        public Integer field2 { get; set; }

        public TestPayload(String field1, Integer field2) {
            this.field1 = field1;
            this.field2 = field2;
        }
    }
}