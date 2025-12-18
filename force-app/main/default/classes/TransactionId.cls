public inherited sharing class TransactionId {
    private static String id;

    /**
     * @description Generates the transactionId
     * @return Id of the transaction
     */
    public static String get() {
        if (id == null) {
            id = generateTransactionId();
        }
        return id;
    }

    private static String generateTransactionId() {
        Request reqInfo = Request.getCurrent();
        return (reqInfo != null) ? reqInfo.getRequestId() : generateRandomId();
    }

    @TestVisible
    public static String generateRandomId() {
        Blob randomBlob = Crypto.generateAESKey(128);
        String hexString = EncodingUtil.convertToHex(randomBlob);
        return hexString.substring(0, 8) +
          '-' +
          hexString.substring(8, 12) +
          '-' +
          hexString.substring(12, 16) +
          '-' +
          hexString.substring(16, 20) +
          '-' +
          hexString.substring(20);
      }
  }