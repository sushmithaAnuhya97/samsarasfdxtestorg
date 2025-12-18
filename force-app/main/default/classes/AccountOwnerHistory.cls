public class AccountOwnerHistory {

    public class Request {
        @InvocableVariable(required=true)
        public Id accountId;

        @InvocableVariable(required=true)
        public Datetime checkDate;
    }

    public class Response {
        @InvocableVariable
        public Boolean isOwnerADRIB;

        public Response(Boolean flag){
            this.isOwnerADRIB = flag;
        }
    }

    @InvocableMethod(label='Check Account Owner Role ADR IB'
                     description='Returns true if any owner has role containing ADR IB before given date')
    public static List<Response> checkOwner(List<Request> requests) {
        List<Response> results = new List<Response>();
        String oldUserId;

        Request req = requests[0];

        List<AccountHistory> hist = [
            SELECT Id, NewValue
            FROM AccountHistory
            WHERE Field = 'Owner'
                AND CreatedDate < :req.checkDate
                AND AccountId = :req.accountId
            ORDER BY CreatedDate DESC
            LIMIT 2
        ];
        Set<Id> uIds = new Set<Id>();
        for (AccountHistory h : hist) {
            String newValue = String.valueOf(h.NewValue);
            if (h.NewValue != null && newValue.startsWith('005')) {
                oldUserId = newValue;
            }
        }

        List<User> oldUserList = new List<User>();
        oldUserList = [SELECT Id
             FROM User
             WHERE Id = :oldUserId
             AND UserRole.Name LIKE '%ADR IB%'];

        results.add(new Response(!oldUserList.isEmpty()));

        return results;
    }
}