import { LightningElement, api } from 'lwc';

export default class FlexIneligibleProductScreen extends LightningElement {
    @api ineligibleProductList;
    // @api name; // Not used

    get processedIneligibleProductList() {
        if (!this.ineligibleProductList) return [];
        return this.ineligibleProductList.map(product => ({
            ...product,
            productLink: product.pnpOneProductDetails?.selectedProductUrl || product.productLink
        }));
    }
}