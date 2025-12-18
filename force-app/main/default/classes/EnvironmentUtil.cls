//GTMS-27138
public class EnvironmentUtil {
    public static Boolean isSandbox() {
        // Get the org's domain URL and check if it contains sandbox indicators
        String domain = System.Url.getOrgDomainUrl().getHost();
        return domain.contains('.sandbox.') || domain.contains('.cs');
    }

    public static String getNamedCredential() {
        // Return appropriate named credential based on environment
        return isSandbox() ? 'WorkatoIntegration_Sandbox' : 'WorkatoIntegration_Prod';
    }
}