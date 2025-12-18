public class OrderResponse {
    public String status;             // Response status: 'success' or 'error'
    public String message;            // Message describing the response
    public String transactionType;    // Optional transaction type info
    public Id requestTrackerId;       // Optional tracker record Id

    // Constructor: Basic response with status and message
    public OrderResponse(String status, String message) {
        this(status, message, null, null);
    }

    // Constructor: Full response with additional transaction data
    public OrderResponse(String status, String message, String transactionType, Id requestTrackerId) {
        this.status = status;
        this.message = message;
        this.transactionType = transactionType;
        this.requestTrackerId = requestTrackerId;
    }

    // Factory: Success response
    public static OrderResponse success(String message, String transactionType, Id requestTrackerId) {
        return new OrderResponse('success', message, transactionType, requestTrackerId);
    }

    // Factory: Error response with just message
    public static OrderResponse error(String message) {
        return new OrderResponse('error', message);
    }

    // Factory: Error with tracker ID (String type)
    public static OrderResponse error(String message, String requestTrackerId) {
        return new OrderResponse('error', message, null, Id.valueOf(requestTrackerId));
    }

    // Factory: Error with transaction and tracker ID
    public static OrderResponse error(String message, String transactionType, String requestTrackerId) {
        return new OrderResponse('error', message, transactionType, Id.valueOf(requestTrackerId));
    }
}