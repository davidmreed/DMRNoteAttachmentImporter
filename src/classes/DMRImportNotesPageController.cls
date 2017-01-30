public class DMRImportNotesPageController {
    public Integer batchSize {get; set;}
    public String importType {get; set;}
    public Boolean removeImported {get; set;}
    private ApexPages.StandardSetController controller {get; set;}
    public Boolean hasSelection {
    	get {
    		return controller != null;
    	}
    }
    
    public DMRImportNotesPageController() {
    	// We're the controller for a this component as used in a standalone tab
    	// (i.e., not invoked from a list view)
        List<sObject> notes = [SELECT Id FROM DMRNoteProxy__c WHERE Imported__c = false];
        
        controller = null;
        importType = 'all';
        removeImported = true;
        batchSize = 200;
    }
    
    public DMRImportNotesPageController(ApexPages.StandardSetController standardController) { 
    	// We're being invoked from a list view, so there's a user-selected note set.
        controller = standardController; 
        importType = 'selected';
        removeImported = true;
        batchSize = 200;
    } 
    
    public PageReference importNotes() {
        DMRNoteBulkImporter i;
        List<DMRNoteProxy__c> notes;
        
        // Pull out the appropriate note set
        if (controller != null && importType == 'selected') {
        	notes = controller.getSelected();
        } else {
        	notes = [SELECT Id FROM DMRNoteProxy__c WHERE Imported__c = false];
        }

        i = new DMRNoteBulkImporter(new List<Id>(new Map<Id, sObject>(notes).keySet()));
        i.removeImported = removeImported;
        
        // Clamp the batch size reasonably. This operation can use a fair amount of memory.
        // Testing shows batch reduction below 200 required for 32KB+ notes.
        if (batchSize < 1 || batchSize > 200)
            batchSize = 200;
        
        Database.executeBatch(i, batchSize);
        
        PageReference pageReference = new PageReference('/' + DMRNoteProxy__c.SObjectType.getDescribe().getKeyPrefix() + '/o');
        pageReference.setRedirect(true);
        
        return pageReference;
    }
}