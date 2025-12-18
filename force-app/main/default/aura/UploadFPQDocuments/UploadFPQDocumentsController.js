({
    doInit: function(component, event, helper) { 
        console.log('****',component.get('v.recordId'));
        component.set("v.isLoading",true);
        var action = component.get("c.checkAlreadyUploaded");
        action.setParams({
            parentId: component.get("v.recordId") 
        });
        // set call back 
        action.setCallback(this, function(response) {
            // store the response / Attachment Id   
            console.log('***',response.getReturnValue());
            var state = response.getState();
            if (state === "SUCCESS") {
                if(response.getReturnValue() == true)  {
                    component.set("v.alreadyUploaded",true);
                    component.set("v.isLoading",false);
                    component.set("v.currentStep", "complete");
                }  
                else{
                    component.set("v.alreadyUploaded",false);
                    component.set("v.isLoading",false);
                }
                // handel the response errors        
            } else if (state === "INCOMPLETE") {
                alert("From server: " + response.getReturnValue());
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        // enqueue the action
        $A.enqueueAction(action);
    },
    onPageReferenceChanged: function(cmp, event, helper) {
        $A.get('e.force:refreshView').fire();
    },
    moveNext: function(component, event, helper) {
        component.set("v.currentStep", "complete");
    },
    handleSave: function(component, event, helper) {
        console.log('####',component.find("fuploader").get("v.files").length);
        if (component.find("fuploader").get("v.files").length > 0) {
            component.set("v.isLoading",true);
            helper.uploadHelper(component, event);
        } else {
            alert('Please Select a Valid File');
        }
    }, 
    
   /* handleFilesChange: function(component, event, helper) {
        var fileName = 'No File Selected..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.fileName", fileName);
    },
    handleUploadFinished: function (cmp, event) {
        // Get the list of uploaded files
        var uploadedFiles = event.getParam("files");
        // alert("Files uploaded : " + uploadedFiles.length);
        
        // Get the file name
        uploadedFiles.forEach(file => console.log(file.name));
    }*/
    handleFilesChange: function(component, event, helper) {
        var fileName = "No File Selected..";
        var fileCount=component.find("fileId").get("v.files").length;
        var files='';
        if (fileCount > 0) {
            for (var i = 0; i < fileCount; i++) 
            {
                fileName = component.find("fileId").get("v.files")[i]["name"];
                files=files+'<br/>'+fileName;
            }
        }
        else
        {
            files=fileName;
        }
        component.set("v.fileName", files);
    },
    uploadFiles: function(component, event, helper) {
        if(component.find("fileId").get("v.files")==undefined)
        {
            helper.showMessage('Please select atleast one file to proceed',false);
            return;
        }
        if (component.find("fileId").get("v.files").length > 0) {
            var s = component.get("v.FilesUploaded");
            var fileName = "";
            var fileType = "";
            var fileCount=component.find("fileId").get("v.files").length;
            if (fileCount > 0) {
                for (var i = 0; i < fileCount; i++) 
                { 
                   component.set("v.isLoading",true);
                   helper.uploadHelper(component, event,component.find("fileId").get("v.files")[i]);
                }
            }
        } else {
            helper.showMessage("Please Select a Valid File",false);
        }
    }
})