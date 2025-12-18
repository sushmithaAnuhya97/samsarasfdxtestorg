/**
 * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
 * @date 2020-08-20
 * @lastModified 2020-08-24
 */
public class DMLWrapper
{
    public static UnitOfWork uow ;
    
    public static void intializeUnitOfWork (List<Schema.SObjectType> SOBJECTS_Sequence)
    {
        
        uow = new UnitOfWork(SOBJECTS_Sequence);
    }

    public static void doInsert(SObject thisRecord)
    {
			uow.registerNew(thisRecord);
    }

    public static void doInsert(List<Sobject> Records)
    {
        for(Sobject thisRecord :  Records)
		{
			uow.registerNew(thisRecord);
		}
    }

    public static void doInsert(SObject thisRecord, Schema.sObjectField relatedToParentField, SObject relatedToParentRecord)
    {
        uow.registerNew(thisRecord, relatedToParentField, relatedToParentRecord);
    }

    public static void doUpdate (SObject thisRecord)
    {
        uow.registerDirty(thisRecord);
    }

    public static void doUpdate(List<Sobject> Records) {
        for (Sobject thisRecord : Records) {
            uow.registerDirty(thisRecord);
        }
    }

    public static void doUpdate(SObject thisRecord, List<SObjectField> dirtyFields) {
        uow.registerDirty(thisRecord, dirtyFields);
    }

    public static void doUpdate(SObject thisRecord, Schema.sObjectField relatedToParentField, SObject relatedToParentRecord) {
        uow.registerDirty(thisRecord, relatedToParentField, relatedToParentRecord);
    }

    public static void doUpsert(SObject thisRecord) {
        uow.registerUpsert(thisRecord);
    }

    public static void doUpsert(List<SObject> records)
    {
        for (SObject thisRecord : records)
        {
            uow.registerUpsert(thisRecord);
        }
        
    }

    public static void doDelete(SObject thisRecord)
    {
			uow.registerDeleted(thisRecord);
    }

    public static void doDelete(List<Sobject> Records)
    {
        for(Sobject thisRecord :  Records)
		{
			uow.registerDeleted(thisRecord);
		}
    }

    public static void doRegisterRelationship(SObject thisrecord, Schema.sObjectField relatedToField, SObject relatedTo) {
        uow.registerRelationship(thisrecord, relatedToField, relatedTo);
    }

    public static void publishDML() {
        uow.commitWork();
    }
    //This method been used to remove the static reference of Unit work.
    //This method resolves the problem of overwriting the uow in case of nested
    // calls. Maintain the stack of UOw to perform all DMLs.
    public static Void publishDML(UnitOfWork thisUow) {
        thisUow.commitWork();
    }


}