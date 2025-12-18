@isTest
public class DiagnosticsInstrumentation_Test {

	@isTest private static void diagnosticTests() {
		DiagnosticsInstrumentation.push('Test');
		DiagnosticsInstrumentation.debug('Test');
		try{
			Contact c = new Contact(Id = 'abcdefg');
			insert c;
		} catch(Exception e) {
			DiagnosticsInstrumentation.debugException(e);
		}
		DiagnosticsInstrumentation.pop();
		DiagnosticsInstrumentation.popAll();
		DiagnosticsInstrumentation.pop();
		DiagnosticsInstrumentation.pop();
		DiagnosticsInstrumentation.currentLog();
	}
}