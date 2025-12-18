/**
 * Created by vikasmishra on 2021-09-26.
 */

@IsTest
private class GS_QuotaOpportunitySelectorTest {
    @IsTest
    static void shouldReturnEmptyList() {
        System.assert(
                new GS_QuotaOpportunitySelector(true)
                        .checkFatalError()
                        .getQuotaOpportunitiesFromOpportunityIds(null).isEmpty(),
                'Should return Empty List Of QuotaOpportunity'
        );
    }
}