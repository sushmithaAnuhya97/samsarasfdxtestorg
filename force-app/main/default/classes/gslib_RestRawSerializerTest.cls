@IsTest
public class gslib_RestRawSerializerTest {

    @IsTest
    static void serialize_ShouldReturnTheRawPayload() {
        // Arrange.
        gslib_RestRawSerializer serializer = new gslib_RestRawSerializer();
        String payload = 'Test payload';

        // Act.
        Object serializedPayload = serializer.serialize(null, payload);

        // Assert.
        System.assertEquals(payload, serializedPayload);
    }

    @IsTest
    static void deserialize_ShouldReturnTheRawPayload() {
        // Arrange.
        gslib_RestRawSerializer serializer = new gslib_RestRawSerializer();
        HttpRequest httpRequest = new HttpRequest();
        HttpResponse httpResponse = new HttpResponse();
        httpResponse.setBody('Test payload');

        // Act.
        Object deserializedPayload = serializer.deserialize(httpRequest, httpResponse);

        // Assert.
        System.assertEquals('Test payload', deserializedPayload);
    }

    @IsTest
    static void deserializeError_ShouldReturnTheRawPayload() {
        // Arrange.
        gslib_RestRawSerializer serializer = new gslib_RestRawSerializer();
        HttpRequest httpRequest = new HttpRequest();
        HttpResponse httpResponse = new HttpResponse();
        httpResponse.setBody('Error payload');

        // Act.
        Object deserializedPayload = serializer.deserializeError(httpRequest, httpResponse);

        // Assert.
        System.assertEquals('Error payload', deserializedPayload);
    }
}