trigger NewProductAdditionTrigger on New_Product_Addition__c (
  before insert, after insert, 
  before update, after update, 
  before delete, after delete) {

  if (Trigger.isBefore) {
    if (Trigger.isInsert) {
      // Call class logic here!
    } 
    if (Trigger.isUpdate) {
      NewProductAdditionHelper.ProductCreator(Trigger.oldMap, Trigger.newMap);
    }
    if (Trigger.isDelete) {
      // Call class logic here!
    }
  }

  if (Trigger.isAfter) {
    if (Trigger.isInsert) {
      // Call class logic here!
    } 
    if (Trigger.isUpdate) {
      // Call class logic here!
     NewProductAdditionHelper.updateStage(Trigger.oldMap, Trigger.newMap);

    }
    if (Trigger.isDelete) {
      // Call class logic here!
    }
  }
}