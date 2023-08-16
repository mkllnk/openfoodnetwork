import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  static targets = ["loading"];

  connect() {
    super.connect();
    // Fetch the products on page load
    this.stimulate("Products#fetch");
  }

  beforeReflex() {
    this.showLoading();
    this.scrollToElement();
  }

  afterReflex() {
    this.hideLoading();
  }

  showLoading = () => {
    if (this.getLoadingController()) {
      this.getLoadingController().showLoading();
    }
  };

  hideLoading = () => {
    if (this.getLoadingController()) {
      this.getLoadingController().hideLoading();
    }
  };

  scrollToElement = () => {
    this.element.scrollIntoView();
  };

  getLoadingController = () => {
    return (this.loadingController ||= this.application.getControllerForElementAndIdentifier(
      this.loadingTarget,
      "loading"
    ));
  };
}
