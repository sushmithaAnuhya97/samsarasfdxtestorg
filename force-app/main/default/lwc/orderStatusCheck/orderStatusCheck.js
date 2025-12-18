import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import processOrder from '@salesforce/apex/OrderTriggerHandler.handleOrderUpdate';

export default class OrderStatusCheck extends LightningElement {
    @api recordId;
    errorMessage;
    isProcessing = false;
    orderStatus;
    orderData;

    @wire(getRecord, { 
        recordId: '$recordId', 
        fields: [
            'Order.Id',
            'Order.Status', 
            'Order.OpportunityId',
            'Order.RecordTypeId',
            'Order.Type'
        ] 
    })
    wiredOrder({ error, data }) {
        if (data) {
            console.log('Wire Service Data:', data);
            this.orderStatus = data.fields.Status.value;
            this.orderData = {
                Id: data.fields.Id.value,
                Status: data.fields.Status.value,
                OpportunityId: data.fields.OpportunityId.value,
                RecordTypeId: data.fields.RecordTypeId.value,
                Type: data.fields.Type.value
            };
            console.log('Order Data prepared:', this.orderData);
            this.processOrderStatus();
        } else if (error) {
            console.error('Wire Service Error:', error);
            this.errorMessage = 'Error loading order status: ' + error.body.message;
        }
    }

    processOrderStatus() {
        if (this.orderStatus !== 'Fulfilled') {
            this.errorMessage = 'Order Is Not Fulfilled to perform operation';
            return;
        }

        if (!this.orderData.Id) {
            this.errorMessage = 'Invalid Order Id';
            return;
        }

        this.isProcessing = true;
        console.log('Order Data being sent:', this.orderData);
        processOrder({ order: this.orderData })
            .then(result => {
                console.log('result:',result);
                if(result == 'Success') {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Order processed successfully',
                            variant: 'success'
                        })
                    );
                } else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: result,
                            variant: 'error'
                        })
                    );     
                }
                this.closeQuickAction();   
            })
            .catch(error => {
                console.error('Error details:', error);
                this.errorMessage = 'Error processing order: ' + error.body.message;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: this.errorMessage,
                        variant: 'error'
                    })
                );
                this.closeQuickAction();
            })
            .finally(() => {
                this.isProcessing = false;
            });
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}