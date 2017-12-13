// DMRNoteAttachmentImporterTEST.cls
// (c) 2016-2017 David Reed
// Available under the terms of the MIT License.

@isTest
private class DMRNoteAttachmentImporterTEST {
    // Test content contains HTML entities, line breaks (of all types), and Unicode.
    private static String content = 'This is some example text. \'"&<>\n\n\rκατέβην χθὲς εἰς Πειραιᾶ μετὰ Γλαύκωνος τοῦ Ἀρίστωνος\r\nπροσευξόμενός τε τῇ θεῷ καὶ ἅμα τὴν ἑορτὴν βουλόμενος\nθεάσασθαι τίνα τρόπον ποιήσουσιν ἅτε νῦν πρῶτον ἄγοντες.\nHwæt, wē Gār-Dena      in gēardagum,\nþēodcyninga      þrym gefrūnon,\nhū ðā æþelingas      ellen fremedon !';
    
    @isTest
    private static void testAddingAttachments() {
        Contact linkedContact = new Contact(LastName='Testify');
        DMRNoteAttachmentImporter im = new DMRNoteAttachmentImporter();

        insert linkedContact;
        
        // Add 50 attachments linked to the same contact in a batch, plus one inserted in a one-off.
        // Verify that there are 51 attachments linked.

        for (Integer i = 0; i < 50; i++) {
            im.addAttachment('Test Attachment', 'Test.txt', Blob.valueOf(content), linkedContact.Id, 'AllUsers', 'I');
        }
        
        System.assertEquals(true, im.insertRecords());        
        System.assertEquals(true, DMRNoteAttachmentImporter.addSingleAttachment('Test Attachment', 'Test.txt', Blob.valueOf(content), linkedContact.Id, 'AllUsers', 'I'));
        System.assertEquals(51, [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId = :linkedContact.Id]);
    }
    
    @isTest 
    private static void testAddingNotes() {
        Contact linkedContact = new Contact(LastName='Testify');
        DMRNoteAttachmentImporter im = new DMRNoteAttachmentImporter();

        insert linkedContact;
        
        // Add 50 notes linked to the same contact in a batch, plus one inserted in a one-off.
        // Verify that there are 51 notes linked.

        for (Integer i = 0; i < 50; i++) {
            im.addNote('Test Note', content, linkedContact.Id, 'AllUsers', 'I');
        }

        System.assertEquals(true, im.insertRecords());
        
        // The empty title will be replaced to avoid triggering an exception.
        System.assertEquals(true, DMRNoteAttachmentImporter.addSingleNote('', content, linkedContact.Id, 'AllUsers', 'I'));

        // We are going to check that all notes inserted correctly.
        // We are not going to verify that the note text is exactly equal to
        // our original text (HTML conversion obviates that).
        System.assertEquals(51, [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId = :linkedContact.Id]);
    }
    
    @isTest
    private static void testErrorHandling() {
        // To test error handling, we will attempt to import notes and attachments that succeed and fail.
        // We should get a result of false, errors listed in DMRNoteBulkImporter.results, and only the valid notes/attachments remaining.
        // Note that all of the errors we are triggering are due to the ContentDocumentLink.
        // Most errors relating to the note itself are uncatchable System.UnexpectedExceptions.
        Contact n = new Contact(LastName='N');
        Contact m = new Contact(LastName='M');
        DMRNoteAttachmentImporter a = new DMRNoteAttachmentImporter();
        
        insert n;
        insert m;
      
        // Succeed
        a.addNote('Successful Note 1', content, n.Id, 'AllUsers', 'I');
        a.addAttachment('Successful Attachment 1', 'Test.txt', Blob.valueOf(content), n.Id, 'AllUsers', 'I');
      
        // Fail due to a too-long Title field (note: this is the only route I'm aware of to produce a DMLException, rather than an UnexpectedException)
        // Our Content string is 307 characters; the limit is 255.
        a.addNote(content, content, n.Id, 'AllUsers', 'I');
        
        // Fail due to invalid ContentDocumentLinks
        a.addAttachment('Test Attachment', 'Test.txt', Blob.valueOf(content), n.Id, 'AllUsers', 'Q');
        a.addNote('Test Note', content, m.Id, 'AllUsers', 'Q');
              
        // Succeed
        a.addNote('Successful Note 2', content, m.Id, 'AllUsers', 'I');
        a.addAttachment('Successful Attachment 2', 'Test.txt', Blob.valueOf(content), m.Id, 'AllUsers', 'I');
        
        System.assertEquals(false, a.insertRecords());
        System.assertEquals(a.results.size(), 7);
        System.assertEquals(true, a.results[0].isSuccess());        
        System.assertEquals(true, a.results[1].isSuccess());
        System.assertEquals(false, a.results[2].isSuccess());
        System.assertEquals(false, a.results[3].isSuccess());
        System.assertEquals(false, a.results[4].isSuccess());
        System.assertEquals(true, a.results[5].isSuccess());
        System.assertEquals(true, a.results[6].isSuccess());
        
        // Confirm the right number of notes/attachments is associated with each Contact, and that bad records were deleted.
        System.assertEquals(2, [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId = :n.Id]);        
        System.assertEquals(2, [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId = :m.Id]);        
        System.assertEquals(2, [SELECT count() FROM ContentNote]);
        // ContentNotes have ContentVersions/ContentDocuments behind the scenes.
        System.assertEquals(4, [SELECT count() FROM ContentVersion]);
        System.assertEquals(4, [SELECT count() FROM ContentDocument]);
        
        // Make sure Note and Attachment 1 went to n, and 2 went to m.
        System.assertEquals(1, [SELECT count() FROM ContentDocumentLink WHERE ContentDocument.Title = 'Successful Note 1' AND LinkedEntityId = :n.Id]);
        System.assertEquals(1, [SELECT count() FROM ContentDocumentLink WHERE ContentDocument.Title = 'Successful Attachment 1' AND LinkedEntityId = :n.Id]);
        System.assertEquals(1, [SELECT count() FROM ContentDocumentLink WHERE ContentDocument.Title = 'Successful Note 2' AND LinkedEntityId = :m.Id]);
        System.assertEquals(1, [SELECT count() FROM ContentDocumentLink WHERE ContentDocument.Title = 'Successful Attachment 2' AND LinkedEntityId = :m.Id]);
    }
}