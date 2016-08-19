// DMRNoteAttachmentImporter.cls
// (c) 2016 David Reed
// Available under the terms of the BSD License.

public class DMRNoteAttachmentImporter {
    private List<sObject> objs;
    private List<ContentDocumentLink> links;
    public List<Database.SaveResult> results {get; private set;}

    public DMRNoteAttachmentImporter() {
        objs = new List<sObject>();
        links = new List<ContentDocumentLink>();
    }

    public static Boolean addSingleNote(String title, String content, Id linkedTo, String visibility, String shareType) {
        DMRNoteAttachmentImporter im = new DMRNoteAttachmentImporter();

        im.addNote(title, content, linkedTo, visibility, shareType);
        
        return im.insertRecords();
    }

    public static Boolean addSingleAttachment(String title, String path, Blob contents, Id linkedTo, String visibility, String shareType) {
        DMRNoteAttachmentImporter im = new DMRNoteAttachmentImporter();

        im.addAttachment(title, path, contents, linkedTo, visibility, shareType);
        
        return im.insertRecords();
    }

    public void addNote(String title, String content, Id linkedTo, String visibility, String shareType) {
        // Inserting ContentNotes requires that the text be prepared carefully. We must:
        // 1. Replace all basic HTML characters (<>"'&) with their corresponding entities (&amp; etc.)
        // 2. Replace all line breaks with <br>
        // 3. Replace &apos; with &#39; per Salesforce documentation.
        // Note that all other Unicode characters should *not* be replaced with entities.
        // Other entities, including &apos;, result in an exception. Unicode is supported just fine, however.
        // This is why we do not use String.escapeHTML4(), which does replace Unicode. String.escapeXML() is closest to what we need.
        // Documentation is incorrect about this in various locations.
        // See:
        //  - https://help.salesforce.com/apex/HTViewSolution?id=000230867&language=en_US
        //  - https://help.salesforce.com/apex/HTViewSolution?urlname=ContentNote-insert-error-Note-Can-t-Be-Saved-Because-It-Contains-HTML-Tags-Or-Unescaped-Characters-That-Are-Not-Allowed-In-A-Note&language=en_US
        //  - https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_methods_system_string.htm?search_text=escapexml

        ContentNote cn = new ContentNote();

        cn.Title = title;
        cn.Content = Blob.valueOf(content.escapeXML().replace('\r\n', '<br>').replace('\r', '<br>').replace('\n', '<br>').replace('&apos;', '&#39;'));

        objs.add(cn);

        ContentDocumentLink cdl = new ContentDocumentLink();

        cdl.ContentDocumentId = cn.Id;
        cdl.LinkedEntityId = linkedTo;
        cdl.Visibility = visibility;
        cdl.ShareType = shareType;

        links.add(cdl);
    }

    public void addAttachment(String title, String path, Blob contents, Id linkedTo, String visibility, String shareType) {
        ContentVersion v = new ContentVersion();

        v.VersionData = contents;
        v.PathOnClient = path;
        v.Title = title;

        objs.add(v);

        ContentDocumentLink cdl = new ContentDocumentLink();

        // We'll populate the ContentDocumentId in insertRecords() after the version is inserted.
        cdl.LinkedEntityId = linkedTo;
        cdl.ShareType = shareType;
        cdl.Visibility = visibility;
        
        links.add(cdl);
    }

    // Insert all of the accumulated note and attachment records and their associated links.
    // Return true if all succeeded; false if any errors occured. this.results contains the errors, if any.
    // If the content inserts correctly and the link does not, removes the content.
    // Limits usage: 0-3 SOQL queries; 2-4 DML operations
    public Boolean insertRecords() {
        List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
        List<ContentDocumentLink> linksToAttachments = new List<ContentDocumentLink>();
        List<Id> attachmentIds = new List<Id>();
        Boolean retval = true;
        
        results = Database.insert(objs, false);
       
        for (Integer i = 0; i < results.size(); i++) {
            Database.SaveResult sr = results[i]; 
            
            if (sr.isSuccess()) {
                ContentDocumentLink cdl = links[i];
                
                // We have to set the ContentDocumentId field for each ContentDocumentLink
                // For ContentNotes, this is the Id of the ContentNote itself.
                // For ContentVersions, it's the ContentDocumentId for the ContentVersion, which isn't updated on insert.
                // Pull out the latter and update with one query.
                if (objs[i] instanceof ContentNote) {
                    cdl.ContentDocumentId = objs[i].Id;
                } else {
                    linksToAttachments.add(cdl);
                    attachmentIds.add(objs[i].Id);
                }
                
                linksToInsert.add(cdl);
            } else {
                retval = false;
            }
        }
        
        // For the attachments, if any, pull out the ContentDocumentIds to update our links.
        Set<Id> contentDocumentIds = new Set<Id>();
                
        if (attachmentIds.size() > 0) {
            Map<Id, ContentVersion> m = new Map<Id, ContentVersion>([SELECT ContentDocumentId FROM ContentVersion WHERE Id IN :attachmentIds]);
        
            for (Integer i = 0; i < linksToAttachments.size(); i++) {
                linksToAttachments[i].ContentDocumentId = m.get(attachmentIds[i]).ContentDocumentId;
                contentDocumentIds.add(linksToAttachments[i].ContentDocumentId);
            }
        }
        
        List<Database.SaveResult> linksSRs = Database.insert(linksToInsert, false);
        
        // If any link object failed to insert, remove the corresponding note or attachment and report the error.
        // ContentVersion cannot be deleted directly; query for the associated ContentDocument and remove that.
        List<Id> attachmentsToDelete = new List<Id>();
        List<Id> notesToDelete = new List<Id>();
        
        for (Integer i = 0; i < linksSRs.size(); i++) {
            
            if (!linksSRs[i].isSuccess()) {
                if (contentDocumentIds.contains(linksToInsert[i].ContentDocumentId)) {
                    // This is a link to a ContentDocument
                    attachmentsToDelete.add(linksToInsert[i].ContentDocumentId);
                } else {
                    notesToDelete.add(linksToInsert[i].ContentDocumentId);
                }
                
                // Replace the successful result from the associated note or attachment with this error record.
                results.set(i, linksSRs[i]);
            }
        }
        
        if (attachmentsToDelete.size() > 0) {
            List<ContentDocument> documents = [SELECT Id FROM ContentDocument WHERE Id IN :attachmentsToDelete];
            delete documents;
            retval = false;
        }
        
        if (notesToDelete.size() > 0) {
            List<ContentNote> notes = [SELECT Id FROM ContentNote WHERE Id IN :notesToDelete];
            
            delete notes;
            retval = false;
        }
        
        return retval;
    }
    
}