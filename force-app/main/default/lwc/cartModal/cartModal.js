import { LightningElement, api } from "lwc";

const COLUMNS = [
  { label: "Item Name", fieldName: "name" },
  { label: "Price", fieldName: "unitCost", type: "currency" },
  { label: "Quantity", fieldName: "amount", type: "number", editable: true },
  {
    type: "button-icon",
    typeAttributes: {
      iconName: "utility:delete",
      name: "remove",
      title: "Remove",
      variant: "bare",
      alternativeText: "Remove"
    }
  }
];

export default class CartModal extends LightningElement {
  @api cartItems = [];
  @api isCheckingOut = false;

  columns = COLUMNS;
  draftValues = [];

  get isEmpty() {
    return !this.cartItems || this.cartItems.length === 0;
  }

  get grandTotal() {
    if (!this.cartItems) return 0;
    return this.cartItems.reduce(
      (sum, item) => sum + item.amount * item.unitCost,
      0
    );
  }

  handleClose() {
    this.dispatchEvent(new CustomEvent("close"));
  }

  handleRowAction(event) {
    const { action, row } = event.detail;
    if (action.name === "remove") {
      this.dispatchEvent(new CustomEvent("removeitem", { detail: row.itemId }));
    }
  }

  handleCellChange(event) {
    const draftValues = event.detail.draftValues;
    this.dispatchEvent(
      new CustomEvent("updatequantity", { detail: draftValues })
    );
  }

  handleCheckout() {
    this.dispatchEvent(new CustomEvent("checkout"));
  }
}
