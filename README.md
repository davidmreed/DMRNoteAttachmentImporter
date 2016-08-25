# DMRNoteAttachmentImporter

This source-only package provides Apex support for easily adding notes and attachments (using the new 
content library objects) to Salesforce records, as well as bulk note importing. 100% test coverage is included.

The package is available under the MIT License.

## Note Content Preparation

The following steps are required to [prepare note content](https://help.salesforce.com/apex/HTViewSolution?id=000230867&language=en_US) for insertion into Salesforce:

 1. Replace all basic HTML characters (`<>"'&`) with their corresponding entities (`&amp;` and friends).
 2. Replace all line breaks with `<br>` (taking care with Windows CRLF/Linux LF/Mac CR)
 3. Replace `&apos;` with `&#39;`.
 4. Do *not* replace Unicode characters with entities. Other entities, including `&apos;`, result in an exception. Unicode should be left as the bare characters.
 5. Ensure that the source content is well-formed Unicode/UTF-8 and does not contain non-printable characters.
 6. The title must not be `null`, zero-length, or consist only of whitespace. The title need not be escaped.

All but (5) are handled by this package. You are responsible for ensuring that supplied text is well-formed.  

Errors that do occur with `ContentNote`s usually come in the form of `System.UnexpectedException`s, which *cannot be caught or handled*. Despite the best efforts of this package, it is still possible to trigger these exceptions by attempting to import notes whose text contains non-printable characters or mangled UTF-8. In a bulk note import process, this will cause the failure of the entire batch with no error message recorded on the note proxies. The error can be diagnosed by examining the Apex Jobs log, where the exception will be displayed. The only workaround is to use very small (or even 1) batch sizes to identify the offending note and manually correct its text.

Note that the [API reference on `ContentNote`](https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_objects_contentnote.htm) incorrectly specifies to use `String.escapeHTML4()` to prepare content. This does not work.

## Sharing and Visibility Settings

Both the Apex methods below and the Note Proxy object used for bulk note imports accept parameters for visibility and sharing settings. When linking notes and attachments to regular Salesforce records, like Contacts, visibility "AllUsers" and sharing type "I" (inferred) are appropriate. (Other visibility values will actually cause exceptions). More detail on acceptable values is found in the [`ContentDocumentLink` API reference](https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_objects_contentdocumentlink.htm). Values other than "AllUsers"/"I" may be useful when working with content libraries or communities.

## Notes and Attachments in Apex

The class `DMRNoteAttachmentImporter` provides Apex support. The following methods are available:

### `void addNote(String title, String content, Id linkedTo, String visibility, String shareType)`

Create a note linked to the record whose Id is supplied. `ContentNote` titles may not be null, empty, or composed only of whitespace; if such is provided, it will be replaced by the string "Untitled Note". `DMRNoteAttachmentImporter` will escape the text provided as required (see below). See the section above for more on `visibility` and `shareType`.

### `void addAttachment(String title, String path, Blob contents, Id linkedTo, String visibility, String shareType)`

Create an attachment linked to the record whose Id is supplied. For a plain-text attachment, you can provide `Blob.valueOf(aString)` for `contents` without going through the preparation steps required for notes.

### `Boolean insertRecords()`

Insert all of the accumulated notes, attachments, and links. Update the `results` list accordingly. Return `true` if all inserts succeeded, and `false` if any errors occurred. If errors resulted from invalid links, the corresponding notes or attachments aren't retained and the link error appears at the corresponding index in the `results` list.

### `static Boolean addSingleNote(String title, String content, Id linkedTo, String visibility, String shareType)`
### `static Boolean addSingleAttachment(String title, String path, Blob contents, Id linkedTo, String visibility, String shareType)`

These static convenience methods simply create the records as specified and immediately insert them into the database. `true` or `false` is returned for success or failure, but errors aren't available - create an instance if error reporting is needed.

## Bulk Note Imports

Notes may be added in bulk by importing data to the `DMRNoteProxy__c` object using any data loader. If working with very large notes, bear in mind that some data loaders and spreadsheet applications are not able to handle more than 32KB of text within a CSV cell.

List views on the Note Proxies tab provide access to proxies and can initiate a batch Apex process (`DMRNoteBulkImporter`) to perform imports. Be aware that, using the Note Proxy object, you can only import notes of lengths up to the limit of a Long Text Area, 131,072 characters (128KB, assuming 1-byte characters). In my testing, it's fine to process 32KB notes in batches of 200. Stepping up to 64KB notes required a reduction in batch size.

## Permissions

A DMRNoteImporter permission set is provided. It enables full access to all of the package's functionality.
