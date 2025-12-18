/**
 * Created by vikasmishra on 2020-10-20.
 */

trigger ContractTrigger on Contract (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new ContractTriggerHandler().run();
}