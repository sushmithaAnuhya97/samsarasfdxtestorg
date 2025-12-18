// Define a class to hold information about the contracts to renew
public with sharing class CreateRenewalContext {
    public Id masterContractId;
    public Contract[] renewedContracts;
  public Boolean returnOnlyQuoteId;
}