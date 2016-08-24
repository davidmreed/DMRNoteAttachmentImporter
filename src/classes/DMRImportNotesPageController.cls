public class DMRImportNotesPageController {
    public Integer batchSize {get; set;}
    private ApexPages.StandardSetController controller {get; set;}
    public Integer noteCount { 
        get {
            return controller.getSelected().size();
        }
    }
    
    public DMRImportNotesPageController() {
        List<sObject> notes = [SELECT Id FROM DMRNoteProxy__c WHERE Imported__c = false];
        
        controller = new ApexPages.StandardSetController(notes);
        controller.setSelected(notes);
        batchSize = 200;
    }
    
    public DMRImportNotesPageController(ApexPages.StandardSetController standardController) { 
        controller = standardController; 
        batchSize = 200;
    } 
    
    public PageReference importNotes() {
        DMRNoteBulkImporter i = new DMRNoteBulkImporter(new List<Id>(new Map<Id, sObject>(controller.getSelected()).keySet()));
        
        if (batchSize < 1 || batchSize > 200)
            batchSize = 200;
        
        Database.executeBatch(i, batchSize);
        
        PageReference pageReference = new PageReference('/' + DMRNoteProxy__c.SObjectType.getDescribe().getKeyPrefix() + '/o');
        pageReference.setRedirect(true);
        return pageReference;
    }
}