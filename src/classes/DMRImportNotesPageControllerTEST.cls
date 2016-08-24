// DMRImportNotesPageControllerTEST.cls
// (c) 2016 David Reed
// Available under the terms of the MIT License.

@isTest
private class DMRImportNotesPageControllerTEST {
    // Test content contains HTML entities, line breaks (of all types), and Unicode.
    private static String content = 'This is some example text. \'"&<>\n\n\rκατέβην χθὲς εἰς Πειραιᾶ μετὰ Γλαύκωνος τοῦ Ἀρίστωνος\r\nπροσευξόμενός τε τῇ θεῷ καὶ ἅμα τὴν ἑορτὴν βουλόμενος\nθεάσασθαι τίνα τρόπον ποιήσουσιν ἅτε νῦν πρῶτον ἄγοντες.\nHwæt, wē Gār-Dena      in gēardagum,\nþēodcyninga      þrym gefrūnon,\nhū ðā æþelingas      ellen fremedon !';
    
    @isTest
    private static void testController() {
        Contact linkedContact = new Contact(LastName='Testify');
        List<DMRNoteProxy__c> proxies = new List<DMRNoteProxy__c>();
        
        insert linkedContact;

        for (Integer i = 0; i < 200; i++) {
            proxies.add(new DMRNoteProxy__c(Title__c = 'Test', Content__c = content, LinkedTo__c = linkedContact.Id, Visibility__c = 'AllUsers', ShareType__c = 'I', Imported__c = False));
        }
        
        insert proxies;
        
        // Use both constructors
        DMRImportNotesPageController c = new DMRImportNotesPageController(new ApexPages.StandardSetController(proxies));
                
        c = new DMRImportNotesPageController();
        
        // Without a set controller, it will pull all un-imported note proxies.
        System.assertEquals(200, c.noteCount);
        
        // It'll adjust itself back down.
        c.batchSize = 5000;
        
        // Make sure the import runs cleanly.
        Test.startTest();
        c.importNotes();
        Test.stopTest();
        
        System.assertEquals(200, [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId = :linkedContact.Id]);
        System.assertEquals(0, [SELECT count() FROM DMRNoteProxy__c WHERE Imported__c = false]);        
        
    }
}