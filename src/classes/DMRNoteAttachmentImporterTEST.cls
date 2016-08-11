// DMRNoteAttachmentImporterTEST.cls
// (c) 2016 David Reed
// Available under the terms of the BSD License.

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
            im.addAttachment('Test Attachment', 'Test.txt', Blob.valueOf(content), linkedContact.Id, 'InternalUsers', 'I');
        }
        
        System.assertEquals(true, im.insertRecords());
        
        System.assertEquals(true, DMRNoteAttachmentImporter.addSingleAttachment('Test Attachment', 'Test.txt', Blob.valueOf(content), linkedContact.Id, 'InternalUsers', 'I'));
        
        System.assertEquals(51, [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId = :linkedContact.Id]);
    }
    
    @istest 
    private static void testAddingNotes() {
        Contact linkedContact = new Contact(LastName='Testify');
        DMRNoteAttachmentImporter im = new DMRNoteAttachmentImporter();

        insert linkedContact;

        for (Integer i = 0; i < 50; i++) {
            im.addNote('Test Note', content, linkedContact.Id, 'InternalUsers', 'I');
        }

        System.assertEquals(true, im.insertRecords());
        
        System.assertEquals(true, DMRNoteAttachmentImporter.addSingleNote('Test Note', content, linkedContact.Id, 'InternalUsers', 'I'));

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
            proxies.add(new DMRNoteProxy__c(Title__c = 'Test', Content__c = content, LinkedTo__c = linkedContact.Id, Visibility__c = 'InternalUsers', ShareType__c = 'I', Imported__c = False));
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
        // To test error handling, we will attempt to import a note and an attachment to a record that supports neither (our own DMRNoteProxy object).
        // We should get a result of false, errors listed in DMRNoteBulkImporter.results, and zero notes/attachments remaining.
        DMRNoteProxy__c n = new DMRNoteProxy__c();
        DMRNoteAttachmentImporter a = new DMRNoteAttachmentImporter();
        
        insert n;
        
        a.addAttachment('Test Attachment', 'Test.txt', Blob.valueOf(content), n.Id, 'InternalUsers', 'I');
        a.addNote('Test Note', content, n.Id, 'InternalUsers', 'I');
        
        System.assertEquals(false, a.insertRecords());
        System.assertEquals(a.results.size(), 2);
        System.assertEquals(false, a.results[0].isSuccess());        
        System.assertEquals(false, a.results[1].isSuccess());
        System.assertEquals(0, [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId = :n.Id]);        
        System.assertEquals(0, [SELECT count() FROM ContentNote]);
        System.assertEquals(0, [SELECT count() FROM ContentVersion]);
    }
}