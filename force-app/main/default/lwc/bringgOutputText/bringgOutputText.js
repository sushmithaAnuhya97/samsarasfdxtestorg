import { LightningElement, api } from 'lwc';

export default class BringgOutputText extends LightningElement {
	value;

	@api record;
	@api dynamicField;

	connectedCallback() {
		this.value = this.record[this.dynamicField];
	}
}