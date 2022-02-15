public class TemplateListController {

    @AuraEnabled(cacheable=true)
    public static map<string, string> getAllObjects(){
        map<string, string> objectList = new map<string, string>();
        for ( Schema.SObjectType o : Schema.getGlobalDescribe().values() )
        {
            Schema.DescribeSObjectResult objResult = o.getDescribe();
            objectList.put(objResult.getName(), objResult.getLabel());
        }
        return objectList;
    } 
    
    @AuraEnabled
    public static void Savefun(String inputValue,String picklist,String richData){
        template__c template = new template__c();
        template.Name = inputValue;
        template.sObject__c = picklist;
        template.Template_Data__c = richData;
        upsert template;
    }    

    @AuraEnabled
    public static List<String> getObjectFields(String objName) {
        SObjectType objtype = Schema.getGlobalDescribe().get(objName);
        Schema.DescribeSObjectResult Reslt = objtype.getDescribe();
        List<String> apiNames =  new list<String>();
        for(string apiName : Reslt.fields.getMap().keySet()){
            apiNames.add(apiName);
        }
        System.debug(apiNames);
        return apiNames;
    } 
    
   @AuraEnabled(cacheable=true)
    public static Id saveFile(Id parentId, String fileName, String base64Data, String contentType, String fileId) {
        system.debug(fileId);
        if (fileId == '') {
            fileId = saveTheFile(parentId, fileName, base64Data);
        } else {
            system.debug('hi');
            appendToFile(fileId, base64Data);
        }
        return Id.valueOf(fileId);
    }
    
    public static Id saveTheFile(Id recordId, String fileName, String base64Data) {
       system.debug('hiii');
       ContentVersion contentToInsert =new ContentVersion(); 
       contentToInsert.Title =fileName; 
       contentToInsert.VersionData=EncodingUtil.base64Decode(base64Data);
       contentToInsert.PathOnClient='/' + fileName ;
       contentToInsert.IsMajorVersion = false;
       insert contentToInsert; 
       
       contentToInsert = [select id, ContentDocumentId from ContentVersion WHERE Id =: contentToInsert.Id];
       ContentDocumentLink cl = new ContentDocumentLink();
       cl.ContentDocumentId = contentToInsert.ContentDocumentId;
       cl.LinkedEntityId = recordId; 
       cl.ShareType = 'V';
       cl.Visibility = 'AllUsers';
       insert cl;
       
       return contentToInsert.id;
    }
    
    private static void appendToFile(Id fileId, String base64Data) {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');        
        Attachment a = [SELECT Id, Body FROM Attachment WHERE Id = : fileId];
        String existingBody = EncodingUtil.base64Encode(a.Body);        
        a.Body = EncodingUtil.base64Decode(existingBody + base64Data); 
        system.debug(a.Body);
        update a;
    }
    
    @AuraEnabled  
    public static attachmentWrapper getFiles(String recordId){
        Attachment attachment = [SELECT Id,Name,Body FROM Attachment WHERE parentId =: recordId ORDER By CreatedDate desc Limit 1]; 
        /* CSV
Blob csvBlob = attachment.Body;
String csvBody = EncodingUtil.base64Encode(csvBlob);
Blob afterblob = EncodingUtil.base64Decode(csvBody); */
        
        //Notepad
        Blob b = attachment.body;  
        HttpRequest tmp = new HttpRequest();
        tmp.setBodyAsBlob(b);
        String value = tmp.getBody(); 
        
        /*Blob bodyBlob = attachment.body;
Zippex myZip = new Zippex(bodyBlob);
String docXml = myZip.getFile('word/document.xml').toString();
String plainText = EncodingUtil.base64Encode(bodyBlob);
Blob plainText1 = EncodingUtil.base64Decode(plainText);
System.debug(plainText1.toString());*/
        
        attachmentWrapper attach = new attachmentWrapper(attachment.Id,attachment.Name,value);
        return attach;        
    } 
    
    public class attachmentWrapper{
        @AuraEnabled public Id Id;
        @AuraEnabled public string Name;
        @AuraEnabled public string Body;
        public attachmentWrapper(Id Id,string Name, String Body){
            this.Id = Id;
            this.Name = Name;
            this.Body = Body;
        }
    }
    
    @AuraEnabled  
    public static attachmentWrapper getNullFiles(){
        attachmentWrapper attch = new attachmentWrapper(Null,'','');
        return attch;
    }
    
    @AuraEnabled  
    public static void deleteFile(String AttachmentId){ 
        system.debug(AttachmentId);
        delete [SELECT Id from Attachment WHERE Id = :AttachmentId];       
    }
    @AuraEnabled    
    public static List<Template__c> getTemplate()  
    { 
        return [SELECT Id, Name,sObject__c FROM Template__c];
    }
    
    @AuraEnabled
    public static List<Template__c> getByName(String searchKey) {
        String name = '%' + searchKey + '%';
        return [SELECT Id, Name,sObject__c FROM Template__c WHERE name LIKE :name];
    }
    
    @AuraEnabled
    public static void deleteTemplate(string id){
        system.debug(id);
        delete [SELECT Id from Template__c WHERE Id = :id];  
    }
    
    @AuraEnabled
    public static void deleteTemplates(List<Id> id){
        delete [SELECT Id from Template__c WHERE Id IN :id];  
    }
    
    @AuraEnabled
    public static Template__c updateTemplate(string id){
        system.debug(id);
        Template__c tem = [SELECT Id,Name,sObject__c,Template_Data__c FROM Template__c WHERE Id =: id];
        system.debug(tem);
        return tem;
    }

    @AuraEnabled
    public static list<ContentVersion> returnFiles(list<String> lstFileIds){
        return [SELECT Id, Title FROM ContentVersion WHERE Id IN :lstFileIds];
    }

    @AuraEnabled
    public static list<Id> saveFiles(list<Object> filesToInsert){
        
        list<Id> lstCntVerIds = new list<Id>();
        List<ContentVersion> lstVersionsToInsert = new List<ContentVersion>();
        for (Object file : filesToInsert) {
            FileInfo fileData = (FileInfo)JSON.deserialize(JSON.serialize(file), FileInfo.class);
            ContentVersion objCntVersion = new ContentVersion();
            objCntVersion.PathOnClient = fileData.Title;
            objCntVersion.Title = fileData.Title;
            objCntVersion.VersionData = fileData.VersionData;
            lstVersionsToInsert.add(objCntVersion);
        }

        list<Database.saveResult> res = Database.insert(lstVersionsToInsert);
        for (Database.SaveResult saveResult : res) {
            if(saveResult.isSuccess()) {
                lstCntVerIds.add(saveResult.getId());
            }
        }
        return lstCntVerIds;
    }


    public class FileInfo {
        public String Title;
        public Blob VersionData;
    }

}