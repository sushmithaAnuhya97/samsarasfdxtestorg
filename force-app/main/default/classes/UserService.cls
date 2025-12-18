/**
 * Created by henryzhao on 2020-01-20.
 */

public class UserService {

    public static final String SOBJECT_NAME = SObjectType.User.name;
    public static final String BASE_QUERY = 'SELECT {0} FROM {1} WHERE {2}';
    public static final List<String> REQUIRED_EMAIL_FIELDS = new List<String>{
            String.valueOf(User.Id),
            String.valueOf(User.Name),
            String.valueOf(User.Email)
    };

    public static Map<Id, User> selectUserForEmail(Set<Id> userIds) {
        String condition = 'Id IN :userIds';
        String query = String.format(BASE_QUERY, new List<String>{
                String.join(REQUIRED_EMAIL_FIELDS, ', '),
                SOBJECT_NAME,
                condition
        });
        return new Map<Id, User>((List<User>) System.Database.query(query));
    }
}