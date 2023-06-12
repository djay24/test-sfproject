import { LightningElement, api } from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import getGolfers from '@salesforce/apex/golfApiController.getGolfers';

export default class GolferInfo extends LightningElement {
    @api golferList = [];
    @api errors;
    @api showSpinner;

    connectedCallback(){
        this.showSpinner = true;
        getGolfers()
        .then(data => {
            // window.console.log(data);
            for(var i = 0; i < 10; i++) {
                this.golferList.push(data[i]);
            }
            this.golferList = this.formatGolfers(this.golferList);
            this.showSpinner = false;
            window.console.log(JSON.stringify(this.golferList));
        })
        .catch(error => {
            this.showSpinner = false;
            window.console.log(error);
        })
    }

    formatGolfers(arr) {
        var tempList = [];
        for(var i = 0; i < arr.length; i++) {
            var tempObj = Object.assign({}, arr[i]);
            tempObj.expand = false;
            tempList.push(tempObj);
        }
        if(tempList.length > 0) {
            window.console.log('formatted');
            return tempList;
        } else {
            return null;
        }
    }
    expandCard(e) {

    }
}