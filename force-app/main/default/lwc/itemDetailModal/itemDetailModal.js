import { LightningElement, api } from "lwc";

export default class ItemDetailModal extends LightningElement {
  @api item;

  get hasImage() {
    return !!this.item && !!this.item.imageUrl;
  }

  handleClose() {
    this.dispatchEvent(new CustomEvent("close"));
  }

  handleAdd() {
    this.dispatchEvent(new CustomEvent("addtocart", { detail: this.item }));
    this.handleClose();
  }
}
