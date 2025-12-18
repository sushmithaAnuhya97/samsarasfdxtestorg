public class GS_TaskCacheService {

    Map<Id, Contact> relatedContactsMap;

    public void loadContacts(Set<Id> idSet, Boolean forceReload){
        if ((this.relatedContactsMap == null || this.relatedContactsMap.size() <= 0) || forceReload){
            this.relatedContactsMap = new Map<Id, Contact>(
                (new GS_ContactSelector(false)).getRelatedTaskContactsById(idSet)
            );
        }
    }

    public Map<Id, Contact> getRelatedContactsMap(){
        return this.relatedContactsMap;
    }
}