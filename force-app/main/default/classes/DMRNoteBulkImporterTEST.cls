@isTest
private class DMRNoteBulkImporterTEST {
    // Test content contains HTML entities, line breaks (of all types), and Unicode.
    private static String content = 'This is some example text. \'"&<>\n\n\rκατέβην χθὲς εἰς Πειραιᾶ μετὰ Γλαύκωνος τοῦ Ἀρίστωνος\r\nπροσευξόμενός τε τῇ θεῷ καὶ ἅμα τὴν ἑορτὴν βουλόμενος\nθεάσασθαι τίνα τρόπον ποιήσουσιν ἅτε νῦν πρῶτον ἄγοντες.\nHwæt, wē Gār-Dena      in gēardagum,\nþēodcyninga      þrym gefrūnon,\nhū ðā æþelingas      ellen fremedon !';

    @isTest
    private static void testBulkImporter() {
        List<DMRNoteProxy__c> proxies = new List<DMRNoteProxy__c>();
        Contact linkedContact = new Contact(LastName='Testify');
        
        insert linkedContact;
        
        // Insert 200 note proxy records. Run a batch import process.
        // Confirm that 200 notes were created and all proxies were updated to mark them as imported.

        for (Integer i = 0; i < 199; i++) {
            proxies.add(new DMRNoteProxy__c(Title__c = 'Test', Content__c = content, LinkedTo__c = linkedContact.Id, Visibility__c = 'AllUsers', ShareType__c = 'I', Imported__c = False));
        }
        
        // Add one note record that will fail.
        proxies.add(new DMRNoteProxy__c(Title__c = 'Test', Content__c = content, LinkedTo__c = linkedContact.Id, Visibility__c = 'AllUsers', ShareType__c = 'Q', Imported__c = False));

        insert proxies;

        DMRNoteBulkImporter b = new DMRNoteBulkImporter(new List<Id>(new Map<Id, sObject>(proxies).keySet()));

        Test.startTest();
        Database.executeBatch(b);
        Test.stopTest();
        System.assertEquals(199, [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId = :linkedContact.Id]);
        System.assertEquals(1, [SELECT count() FROM DMRNoteProxy__c WHERE Imported__c = false]);
        System.assertEquals(1, [SELECT count() FROM DMRNoteProxy__c WHERE Error__c <> '']);       
    }
}