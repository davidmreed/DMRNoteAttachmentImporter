# DMRNoteAttachmentImporter

This unmanaged package provides Apex support for easily adding notes and attachments (using the new 
content library objects) to Salesforce records, as well as bulk note importing.

The class `DMRNoteAttachmentImporter` provides Apex support. Notes may be added in bulk by importing data
to the `DMRNoteProxy__c` object. List views provide access to proxies and can initiate a batch Apex process
to perform imports. Note that added information is limited to 131,072 characters (the maximum length of 
a Long Text Area); long notes may require a lowered batch size.

The package is available under the MIT License.
