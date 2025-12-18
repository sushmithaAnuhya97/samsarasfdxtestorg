/**
 * Created by vikasmishra on 2021-09-26.
 */

@IsTest
private class GS_OpportunityLineItemSelectorTest {
    @IsTest
    static void shouldReturnOpportunityLineItemByOpportunityIds() {
        System.assert(
                new GS_OpportunityLineItemSelector(true)
                        .checkFatalError()
                        .getOpportunityLineItemByOpportunityIds(null).isEmpty(),
                'Should return Empty List Of OLI'
        );
    }
}