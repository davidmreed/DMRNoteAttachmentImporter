public class DMRImportNotesPageController {
    public Integer batchSize {get; set;}
    public String importType {get; set;}
    public Boolean removeImported {get; set;}
    private ApexPages.StandardSetController controller {get; set;}
    public Boolean hasSelection {
    	get {
    		return controller.getSelected().size() != 0;
    	}
    }
    public Boolean hasRecords {
    	get {
    		return controller.getRecords().size() != 0;
    	}
    }
    public Integer countForAll {
        get {
      		return notesForImportType('all').size();
        }
    }
    public Integer countForSelected {
        get {
      		return notesForImportType('selected').size();
        }
    }
    public Integer countForSet {
        get {
      		return notesForImportType('set').size();
        }
    }

        
    public DMRImportNotesPageController(ApexPages.StandardSetController standardController) { 
    	// This initializer may be invoked whether we're in a tab or called from a list view.
    	// Attempt to intelligently determine the type of import based on the user's selection
    	// and the contents of our controller.
    	
        controller = standardController; 
        removeImported = true;
        batchSize = 200;
        
        if (!hasRecords) {
            importType = 'all';
        } else {
            if (hasSelection) {
                importType = 'selected';
            } else {
                importType = 'set';
            }
        }
    } 
    
    public List<DMRNoteProxy__c> notesForImportType(String aType) {
        if (aType == 'selected') {
        	return controller.getSelected();
        } else if (aType == 'set') {
            return controller.getRecords();
        } else {
        	return [SELECT Id FROM DMRNoteProxy__c WHERE Imported__c = false];
        }
    }
    
    public PageReference importNotes() {
        DMRNoteBulkImporter i;
        List<DMRNoteProxy__c> notes;
        
        // Pull out the appropriate note set
        notes = notesForImportType(importType);

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