/**
 * Created by vikasmishra on 2021-09-26.
 */

@IsTest
private class GS_EmailTemplateMetaDataSelectorTest {
    @IsTest
    static void shouldReturnEmailTemplateNull() {
        GS_EmailTemplateMetaDataSelector thisSelector = new GS_EmailTemplateMetaDataSelector(true);
        thisSelector.checkFatalError();
        System.assert(thisSelector.getEmailTemplatesMdtByType('').size()==0, 'Should return no template');
    }

}