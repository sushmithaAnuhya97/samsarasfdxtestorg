@isTest
public class FlexTestMocks {
    private static Map<String, Map<String, Object>> mocks = new Map<String, Map<String, Object>>();
    
    public static void setMock(Type classType, String methodName, Object returnValue) {
        String key = classType.getName();
        if (!mocks.containsKey(key)) {
            mocks.put(key, new Map<String, Object>());
        }
        mocks.get(key).put(methodName, returnValue);
    }
    
    public static Object getMock(Type classType, String methodName) {
        String key = classType.getName();
        if (mocks.containsKey(key) && mocks.get(key).containsKey(methodName)) {
            return mocks.get(key).get(methodName);
        }
        return null;
    }
}