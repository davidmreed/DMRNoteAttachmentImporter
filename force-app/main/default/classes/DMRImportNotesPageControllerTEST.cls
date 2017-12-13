// DMRImportNotesPageControllerTEST.cls
// (c) 2016-2017 David Reed
// Available under the terms of the MIT License.

@isTest
private class DMRImportNotesPageControllerTEST {
    // Test content contains HTML entities, line breaks (of all types), and Unicode.
    private static String content = 'This is some example text. \'"&<>\n\n\rκατέβην χθὲς εἰς Πειραιᾶ μετὰ Γλαύκωνος τοῦ Ἀρίστωνος\r\nπροσευξόμενός τε τῇ θεῷ καὶ ἅμα τὴν ἑορτὴν βουλόμενος\nθεάσασθαι τίνα τρόπον ποιήσουσιν ἅτε νῦν πρῶτον ἄγοντες.\nHwæt, wē Gār-Dena      in gēardagum,\nþēodcyninga      þrym gefrūnon,\nhū ðā æþelingas      ellen fremedon !';
    
    @testSetup
    private static void setup() {
        Contact linkedContact = new Contact(LastName='Testify');
        List<DMRNoteProxy__c> proxies = new List<DMRNoteProxy__c>();
        
        insert linkedContact;

        for (Integer i = 0; i < 200; i++) {
            proxies.add(new DMRNoteProxy__c(Title__c = 'Test', Content__c = content, LinkedTo__c = linkedContact.Id, Visibility__c = 'AllUsers', ShareType__c = 'I', Imported__c = False));
        }
        
        insert proxies;
    }
    
    @isTest
    private static void testInitializers() {
        List<DMRNoteProxy__c> proxies = [SELECT Id FROM DMRNoteProxy__c];
        ApexPages.StandardSetController ctl = new ApexPages.StandardSetController(proxies);
        DMRImportNotesPageController c = new DMRImportNotesPageController(ctl);
        System.assertEquals('set', c.importType);
        System.assertEquals(false, c.hasSelection);
        System.assertEquals(true, c.hasRecords);

        c = new DMRImportNotesPageController(new ApexPages.StandardSetController(new List<DMRNoteProxy__c>()));
        System.assertEquals('all', c.importType);
        System.assertEquals(false, c.hasSelection);
        System.assertEquals(false, c.hasRecords);
        
        ctl.setSelected(new List<DMRNoteProxy__c>{proxies[0]});
        c = new DMRImportNotesPageController(ctl);
        System.assertEquals('selected', c.importType);
        System.assertEquals(true, c.hasSelection);
        System.assertEquals(true, c.hasRecords);
    }
    
    @isTest
    private static void testCounts() {
        List<DMRNoteProxy__c> proxies = [SELECT Id FROM DMRNoteProxy__c LIMIT 50];
        ApexPages.StandardSetController ctl = new ApexPages.StandardSetController(proxies);
        DMRImportNotesPageController c = new DMRImportNotesPageController(ctl);
        
        System.assertEquals(proxies.size(), c.countForSet);
        System.assertEquals(proxies.size(), c.notesForImportType('set').size());
        System.assertEquals([SELECT count() FROM DMRNoteProxy__c], c.countForAll);
        
        ctl.setSelected(new List<DMRNoteProxy__c>{proxies[0]});
        System.assertEquals(1, c.countForSelected);
    }
    
    @isTest
    private static void testBatchSize() {
        List<DMRNoteProxy__c> proxies = [SELECT Id FROM DMRNoteProxy__c LIMIT 50];
        ApexPages.StandardSetController ctl = new ApexPages.StandardSetController(proxies);
        DMRImportNotesPageController c = new DMRImportNotesPageController(ctl);

        // Ensure the batch size is appropriately clamped..
        c.batchSize = 5000;
        System.assertEquals(200, c.batchSize);
        c.batchSize = 0;
        System.assertEquals(200, c.batchSize);
    }
    
    @isTest
    private static void testImportOperation() {
        List<DMRNoteProxy__c> proxies = [SELECT Id FROM DMRNoteProxy__c LIMIT 200];
        ApexPages.StandardSetController ctl = new ApexPages.StandardSetController(proxies);
        DMRImportNotesPageController c = new DMRImportNotesPageController(ctl);
        Contact ct = [SELECT Id FROM Contact LIMIT 1];
        
        // Make sure the import runs cleanly.
        Test.startTest();
        c.importNotes();
        Test.stopTest();
        
        System.assertEquals(200, [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId = :ct.Id]);
        System.assertEquals(0, [SELECT count() FROM DMRNoteProxy__c WHERE Imported__c = false]);        
        
    }
}