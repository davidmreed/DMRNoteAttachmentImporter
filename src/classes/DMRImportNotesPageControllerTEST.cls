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
        
        ApexPages.StandardSetController ctl = new ApexPages.StandardSetController(proxies);
        DMRImportNotesPageController c = new DMRImportNotesPageController(ctl);
        System.assertEquals('set', c.importType);
        System.assertEquals(false, c.hasSelection);
        System.assertEquals(true, c.hasRecords);

        c = new DMRImportNotesPageController(new ApexPages.StandardSetController(null));
        System.assertEquals('all', c.importType);
        System.assertEquals(false, c.hasSelection);
        System.assertEquals(false, c.hasRecords);
        
        ctl.setSelected(new Set<DMRNoteProxy__c>(proxies[0]));
        c = new DMRImportNotesPageController(ctl);
        System.assertEquals('selected', c.importType);
        System.assertEquals(true, c.hasSelection);
        System.assertEquals(true, c.hasRecords);
        
        System.assertEquals(1, c.countForSelected);
        System.assertEquals(200, c.countForSet);
        System.assertEquals(200, c.countForAll);
                
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