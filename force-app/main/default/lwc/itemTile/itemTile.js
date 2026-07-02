import { LightningElement, api } from "lwc";

export default class ItemTile extends LightningElement {
  @api item;

  handleDetails() {
    this.dispatchEvent(
      new CustomEvent("showdetails", { detail: this.item.itemId })
    );
  }

  handleAdd() {
    this.dispatchEvent(new CustomEvent("addtocart", { detail: this.item }));
  }

  get hasImage() {
    return !!this.item.imageUrl;
  }
}
