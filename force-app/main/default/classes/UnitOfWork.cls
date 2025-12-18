/**
 * Created by henryzhao on 2020-01-30.
 */

public class UnitOfWork extends fflib_SObjectUnitOfWork {
    public class UnitOfWorkException extends Exception {
    }

    public UnitOfWork(List<Schema.SObjectType> sObjectTypes) {
        super(sObjectTypes);
    }

    /**
    * @author Groundswell - Henry Zhao - henry@gscloudsolutions.com
    * @date 2020-01-30
    *
    * @description Retrieves either the existing dirty object, or returns a cloned updatable version
    *
    * Not currently being used.
    */
//    public SObject getUpdateableDirty(final SObject obj) {
//        final String sObjectName = obj.getSObjectType().getDescribe().getName();
//        if (obj.Id == null) {
//            throw new UnitOfWorkException('SObject has no ID');
//        }
//        SObject found = super.m_dirtyMapByType.get(sObjectName).get(obj.Id);
//        if (found != null) {
//            return found;
//        } else {
//            return obj.clone(true, true, true, true);
//        }
//    }
}