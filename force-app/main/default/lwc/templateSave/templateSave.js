import { LightningElement,api,wire,track } from 'lwc';
import getAllObjects from '@salesforce/apex/TemplateListController.getAllObjects'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFiles from '@salesforce/apex/TemplateListController.getFiles';
import saveFiles from '@salesforce/apex/TemplateListController.saveFile';

const columns = [{
    label: 'Title',
    fieldName: 'FileName',
    type: 'url',
    typeAttributes: {
        label: {
            fieldName: 'Title'
        },
        target: '_blank'
    }
}];

export default class TemplateSave extends LightningElement {
    @api main = false;
    @api abutton = false; 

    @track objects = [];
    @track error;

    table = true;
    Next(event){
    this.main = true;
    this.abutton = true;
    }

    @api recordId;

    fileName = '';
    filesUploaded = [];
    isLoading = false;
    fileSize;

    nameChange(event) {
        this.inputValue= event.target.value;
        console.log('data'+ event.target.value);
    }

    connectedCallback(){
        getAllObjects()
        .then(result => {
        //this.objects = result;
        alert(' Result ==> ' + result);
        for(let key in result) {
            // Preventing unexcepted data
            if (result.hasOwnProperty(key)) { // Filtering the data in the loop
                this.objects.push({value:result[key], key:key});
                // alert(' Results ==> ' + this.objects);

            }
        }
    })
    .catch(error => {
        this.error = error;
    });

}
showLoadingSpinner = false;
@track fileNames = '';
@track filesUploaded = [];
@track data;
@track columns = columns;

handleFileChanges(event) {
    let files = event.target.files;

    if (files.length > 0) {
        let filesName = '';

        for (let i = 0; i < files.length; i++) {
            let file = files[i];

            filesName = filesName + file.name + ',';

            let freader = new FileReader();
            freader.onload = f => {
                let base64 = 'base64,';
                let content = freader.result.indexOf(base64) + base64.length;
                let fileContents = freader.result.substring(content);
                this.filesUploaded.push({
                    Title: file.name,
                    VersionData: fileContents
                });
            };
            freader.readAsDataURL(file);
        }

        this.fileNames = filesName.slice(0, -1);
    }
}

handleSaveFiles() {
    this.showLoadingSpinner = true;
    saveFiles({filesToInsert: this.filesUploaded})
    .then(data => {
        this.showLoadingSpinner = false;
        const showSuccess = new ShowToastEvent({
            title: 'Success!!',
            message: this.fileNames + ' files uploaded successfully.',
            variant: 'Success',
        });
        this.dispatchEvent(showSuccess);
        this.getFilesData(data);
        this.fileNames = undefined;
    })
    .catch(error => {
        const showError = new ShowToastEvent({
            title: 'Error!!',
            message: 'An Error occur while uploading the file.',
            variant: 'error',
        });
        this.dispatchEvent(showError);
    });
}

getFilesData(lstIds) {
    getFiles({lstFileIds: lstIds})
    .then(data => {
        data.forEach((record) => {
            record.FileName = '/' + record.Id;
        });

        this.data = data;
    })
    .catch(error => {
        window.console.log('error ====> ' + error);
    })
}

}