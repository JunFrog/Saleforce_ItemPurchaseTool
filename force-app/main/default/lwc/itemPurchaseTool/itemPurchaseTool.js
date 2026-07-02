import { LightningElement, api, track, wire } from "lwc";
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getAccountHeader from "@salesforce/apex/ItemPurchaseController.getAccountHeader";
import getItems from "@salesforce/apex/ItemPurchaseController.getItems";
import getPicklistOptions from "@salesforce/apex/ItemPurchaseController.getPicklistOptions";
import isCurrentUserManager from "@salesforce/apex/ItemPurchaseController.isCurrentUserManager";
import checkout from "@salesforce/apex/ItemPurchaseController.checkout";
import createItem from "@salesforce/apex/ItemPurchaseController.createItem";

export default class ItemPurchaseTool extends NavigationMixin(
  LightningElement
) {
  effectiveRecordId;

  @api
  get recordId() {
    return this.effectiveRecordId;
  }

  set recordId(value) {
    this.effectiveRecordId = value;
  }

  @track accountHeader = {};
  @track items = [];
  @track cartItems = [];
  @track searchTerm = "";
  @track selectedType = "";
  @track selectedFamily = "";
  @track typeOptions = [];
  @track familyOptions = [];
  @track isManager = false;

  @track showDetailModal = false;
  @track selectedItem = null;
  @track showCartModal = false;
  @track showCreateModal = false;
  @track isCreatingItem = false;
  @track isCheckingOut = false;

  connectedCallback() {
    this.loadPicklistOptions();
    this.checkManagerStatus();
    this.loadItems();
  }

  @wire(CurrentPageReference)
  wiredPageReference(pageReference) {
    const urlRecordId = pageReference?.state?.c__recordId;
    if (urlRecordId && urlRecordId !== this.effectiveRecordId) {
      this.effectiveRecordId = urlRecordId;
    }
  }

  @wire(getAccountHeader, { accountId: "$effectiveRecordId" })
  wiredAccount({ data, error }) {
    if (data) {
      this.accountHeader = data;
    } else if (error) {
      this.accountHeader = {};
    }
  }

  loadPicklistOptions() {
    getPicklistOptions()
      .then((data) => {
        this.typeOptions = [
          { label: "All", value: "" },
          ...data.typeValues.map((v) => ({ label: v, value: v }))
        ];
        this.familyOptions = [
          { label: "All", value: "" },
          ...data.familyValues.map((v) => ({ label: v, value: v }))
        ];
      })
      .catch(() => {});
  }

  checkManagerStatus() {
    isCurrentUserManager()
      .then((result) => {
        this.isManager = result;
      })
      .catch(() => {
        this.isManager = false;
      });
  }

  loadItems() {
    getItems({
      searchTerm: this.searchTerm,
      typeFilter: this.selectedType,
      familyFilter: this.selectedFamily
    })
      .then((data) => {
        this.items = data;
      })
      .catch((error) => {
        this.showToast(
          "Error",
          error.body ? error.body.message : "Failed to load items.",
          "error"
        );
      });
  }

  get itemCount() {
    return this.items ? this.items.length : 0;
  }

  get cartCount() {
    return this.cartItems ? this.cartItems.length : 0;
  }

  get cartLabel() {
    return `Cart (${this.cartCount})`;
  }

  handleSearchChange(event) {
    this.searchTerm = event.target.value;
    this.loadItems();
  }

  handleTypeFilter(event) {
    this.selectedType = event.currentTarget.dataset.value;
    this.loadItems();
  }

  handleFamilyFilter(event) {
    this.selectedFamily = event.currentTarget.dataset.value;
    this.loadItems();
  }

  handleShowDetails(event) {
    const itemId = event.detail;
    this.selectedItem = this.items.find((i) => i.itemId === itemId);
    this.showDetailModal = true;
  }

  handleAddToCart(event) {
    const item = event.detail;
    const existing = this.cartItems.find((c) => c.itemId === item.itemId);
    if (existing) {
      this.cartItems = this.cartItems.map((c) => {
        return c.itemId === item.itemId ? { ...c, amount: c.amount + 1 } : c;
      });
    } else {
      this.cartItems = [
        ...this.cartItems,
        { ...item, amount: 1, unitCost: item.price }
      ];
    }
    this.showToast("Success", `"${item.name}" added to cart.`, "success");
  }

  handleCloseDetail() {
    this.showDetailModal = false;
    this.selectedItem = null;
  }

  handleOpenCart() {
    this.showCartModal = true;
  }

  handleCloseCart() {
    this.showCartModal = false;
  }

  handleRemoveFromCart(event) {
    const itemId = event.detail;
    this.cartItems = this.cartItems.filter((c) => c.itemId !== itemId);
  }

  handleUpdateQuantity(event) {
    const draftValues = event.detail;
    draftValues.forEach((draft) => {
      this.cartItems = this.cartItems.map((c) => {
        return c.itemId === draft.itemId
          ? { ...c, amount: parseInt(draft.amount, 10) }
          : c;
      });
    });
  }

  handleCheckout() {
    this.isCheckingOut = true;
    const cartPayload = this.cartItems.map((c) => ({
      itemId: c.itemId,
      amount: c.amount,
      unitCost: c.unitCost
    }));

    checkout({ accountId: this.effectiveRecordId, cartItems: cartPayload })
      .then((purchaseId) => {
        this.cartItems = [];
        this.showCartModal = false;
        this.showToast("Success", "Purchase created successfully!", "success");
        this[NavigationMixin.Navigate]({
          type: "standard__recordPage",
          attributes: {
            recordId: purchaseId,
            actionName: "view"
          }
        });
      })
      .catch((error) => {
        this.showToast(
          "Error",
          error.body ? error.body.message : "Checkout failed.",
          "error"
        );
      })
      .finally(() => {
        this.isCheckingOut = false;
      });
  }

  handleOpenCreateItem() {
    this.showCreateModal = true;
  }

  handleCloseCreateItem() {
    this.showCreateModal = false;
  }

  handleSaveItem(event) {
    const { name, description, typeValue, familyValue, price } = event.detail;
    this.isCreatingItem = true;

    createItem({ itemName: name, description, typeValue, familyValue, price })
      .then(() => {
        this.showCreateModal = false;
        this.showToast(
          "Success",
          `Item "${name}" created successfully.`,
          "success"
        );
        this.loadItems();
      })
      .catch((error) => {
        this.showToast(
          "Error",
          error.body ? error.body.message : "Failed to create item.",
          "error"
        );
      })
      .finally(() => {
        this.isCreatingItem = false;
      });
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}
