// DMRNoteAttachmentImporterTEST.cls
// (c) 2016 David Reed
// Available under the terms of the MIT License.

@istest
private class DMRNoteAttachmentImporterTEST {
    // Test content contains HTML entities, line breaks (of all types), and Unicode.
    private static String content = 'This is some example text. \'"&<>\n\n\rκατέβην χθὲς εἰς Πειραιᾶ μετὰ Γλαύκωνος τοῦ Ἀρίστωνος\r\nπροσευξόμενός τε τῇ θεῷ καὶ ἅμα τὴν ἑορτὴν βουλόμενος\nθεάσασθαι τίνα τρόπον ποιήσουσιν ἅτε νῦν πρῶτον ἄγοντες.\nHwæt, wē Gār-Dena      in gēardagum,\nþēodcyninga      þrym gefrūnon,\nhū ðā æþelingas      ellen fremedon !';
    
    @istest
    private static void testAddingAttachments() {
        Contact linkedContact = new Contact(LastName='Testify');
        DMRNoteAttachmentImporter im = new DMRNoteAttachmentImporter();

        insert linkedContact;

        for (Integer i = 0; i < 50; i++) {
            im.addAttachment('Test Attachment', 'Test.txt', Blob.valueOf(content), linkedContact.Id, 'AllUsers', 'I');
        }
        
        System.assertEquals(true, im.insertRecords());        
        System.assertEquals(true, DMRNoteAttachmentImporter.addSingleAttachment('Test Attachment', 'Test.txt', Blob.valueOf(content), linkedContact.Id, 'AllUsers', 'I'));
        System.assertEquals(51, [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId = :linkedContact.Id]);
    }
    
    @istest 
    private static void testAddingNotes() {
        Contact linkedContact = new Contact(LastName='Testify');
        DMRNoteAttachmentImporter im = new DMRNoteAttachmentImporter();

        insert linkedContact;

        for (Integer i = 0; i < 50; i++) {
            im.addNote('Test Note', content, linkedContact.Id, 'AllUsers', 'I');
        }

        System.assertEquals(true, im.insertRecords());
        
        System.assertEquals(true, DMRNoteAttachmentImporter.addSingleNote('Test Note', content, linkedContact.Id, 'AllUsers', 'I'));

        // We are going to check that all notes/attachments inserted correctly.
        // We are not going to verify that the note text is exactly equal to
        // our original text (HTML conversion obviates that).
        System.assertEquals(51, [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId = :linkedContact.Id]);
    }

    @istest
    private static void testBulkImporter() {
        List<DMRNoteProxy__c> proxies = new List<DMRNoteProxy__c>();
        Contact linkedContact = new Contact(LastName='Testify');
        
        insert linkedContact;

        for (Integer i = 0; i < 200; i++) {
            proxies.add(new DMRNoteProxy__c(Title__c = 'Test', Content__c = content, LinkedTo__c = linkedContact.Id, Visibility__c = 'AllUsers', ShareType__c = 'I', Imported__c = False));
        }

        insert proxies;

        DMRNoteBulkImporter b = new DMRNoteBulkImporter(new List<Id>(new Map<Id, sObject>(proxies).keySet()));

        Test.startTest();
        Database.executeBatch(b);
        Test.stopTest();
        System.assertEquals(200, [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId = :linkedContact.Id]);
        System.assertEquals(0, [SELECT count() FROM DMRNoteProxy__c WHERE Imported__c = false]);        
    }
    
    @istest
    private static void testErrorHandling() {
        // To test error handling, we will attempt to import notes and attachments that fail both for themselves and in their ContentDocumentLinks.
        // We should get a result of false, errors listed in DMRNoteBulkImporter.results, and only the valid notes/attachments remaining.
        DMRNoteProxy__c n = new DMRNoteProxy__c();
        DMRNoteAttachmentImporter a = new DMRNoteAttachmentImporter();
        
        insert n;
        
        // Fail due to invalid ContentDocumentLinks
        a.addAttachment('Test Attachment', 'Test.txt', Blob.valueOf(content), n.Id, 'AllUsers', 'Q');
        a.addNote('Test Note', content, n.Id, 'AllUsers', 'Q');
              
        // Succeed
        a.addNote('Successful Note', content, n.Id, 'AllUsers', 'I');
        a.addAttachment('Successful Attachment', 'Test.txt', Blob.valueOf(content), n.Id, 'AllUsers', 'I');
        
        System.assertEquals(false, a.insertRecords());
        System.assertEquals(a.results.size(), 4);
        System.assertEquals(false, a.results[0].isSuccess());        
        System.assertEquals(false, a.results[1].isSuccess());
        System.assertEquals(true, a.results[2].isSuccess());
        System.assertEquals(true, a.results[3].isSuccess());
        System.assertEquals(2, [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId = :n.Id]);        
        System.assertEquals(1, [SELECT count() FROM ContentNote]);
        // ContentNotes have hidden ContentVersions/ContentDocuments somewhere or other.
        System.assertEquals(2, [SELECT count() FROM ContentVersion]);
        System.assertEquals(2, [SELECT count() FROM ContentDocument]);
    }
}