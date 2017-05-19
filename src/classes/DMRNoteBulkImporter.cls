// DMRNoteBulkImporter.cls
// (c) 2016-2017 David Reed
// Available under the terms of the MIT License.

public class DMRNoteBulkImporter implements Database.Batchable<sObject> {
    private List<Id> noteProxyIDs;
    public Boolean removeImported { get; set; }

    public DMRNoteBulkImporter(List<Id> proxies) {
        noteProxyIDs = new List<Id>(proxies);
        removeImported = false;
    }

    // Limits usage: 1 SOQL query; 0 DML operations
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Title__c, Content__c, LinkedTo__c, Visibility__c, ShareType__c
                                         FROM DMRNoteProxy__c
                                         WHERE Id in :noteProxyIDs]);
    }

    // Limits usage: 0-2 SOQL queries (from DMRNoteAttachmentImporter.insertRecords()), 3-4 DML operations (2 inherited + 1)
    public void execute(Database.BatchableContext bc, List<sObject> noteProxies) {
        DMRNoteAttachmentImporter im = new DMRNoteAttachmentImporter();
        
        // Add a note record for each DMRNoteProxy object.
        for (sObject np : noteProxies) {
            DMRNoteProxy__c proxy = (DMRNoteProxy__c)np;
            
            im.addNote(proxy.Title__c, proxy.Content__c, proxy.LinkedTo__c, proxy.Visibility__c, proxy.ShareType__c);
        }

        im.insertRecords();
        
        // Update the original proxy objects to reflect a successful import or an error.
        // Note that most errors that will be thrown during the import process are System.UnexpectedExceptions,
        // which can't be caught and will abort the entire operation.
        for (Integer i = 0; i < im.results.size(); i++) {
            DMRNoteProxy__c proxy = (DMRNoteProxy__c)noteProxies[i];

            if (im.results[i].isSuccess()) {
                proxy.Imported__c = true;
                proxy.Error__c = '';
                proxy.Note_ID__c = im.results[i].getId();
            } else {
                Database.Error err = im.results[i].getErrors()[0];
                proxy.Imported__c = false;
                proxy.Error__c = err.getStatusCode() + ': ' + err.getMessage();
            }
        }
        
        update noteProxies;
    }

	// Limits usage: 1-2 SOQL query, 0-2 DML operations.
    public void finish(Database.BatchableContext bc) {
        // If we've been asked to remove successfully imported proxies, query and remove them.
    	
    	if (removeImported) {
    		delete [SELECT Id FROM DMRNoteProxy__c WHERE Imported__c = true AND Id in :noteProxyIDs];
    	}    	
    }
}