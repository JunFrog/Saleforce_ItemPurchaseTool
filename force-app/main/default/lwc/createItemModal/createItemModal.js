import { LightningElement, api, track, wire } from "lwc";
import getPicklistOptions from "@salesforce/apex/ItemPurchaseController.getPicklistOptions";

export default class CreateItemModal extends LightningElement {
  @api isLoading = false;

  @track name = "";
  @track description = "";
  @track selectedType = "";
  @track selectedFamily = "";
  @track price = null;

  @wire(getPicklistOptions)
  picklistOptions;

  get typeOptions() {
    if (!this.picklistOptions.data) return [];
    return this.picklistOptions.data.typeValues.map((v) => ({
      label: v,
      value: v
    }));
  }

  get familyOptions() {
    if (!this.picklistOptions.data) return [];
    return this.picklistOptions.data.familyValues.map((v) => ({
      label: v,
      value: v
    }));
  }

  handleClose() {
    this.dispatchEvent(new CustomEvent("close"));
  }

  handleNameChange(event) {
    this.name = event.target.value;
  }
  handleDescriptionChange(event) {
    this.description = event.target.value;
  }
  handleTypeChange(event) {
    this.selectedType = event.detail.value;
  }
  handleFamilyChange(event) {
    this.selectedFamily = event.detail.value;
  }
  handlePriceChange(event) {
    this.price = parseFloat(event.target.value);
  }

  handleSave() {
    if (
      !this.name ||
      !this.selectedType ||
      !this.selectedFamily ||
      !this.price
    ) {
      return;
    }
    this.dispatchEvent(
      new CustomEvent("saveitem", {
        detail: {
          name: this.name,
          description: this.description,
          typeValue: this.selectedType,
          familyValue: this.selectedFamily,
          price: this.price
        }
      })
    );
  }

  get isSaveDisabled() {
    return (
      this.isLoading ||
      !this.name ||
      !this.selectedType ||
      !this.selectedFamily ||
      !this.price
    );
  }
}
