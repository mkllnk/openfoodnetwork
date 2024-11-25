import { Controller } from "stimulus";

export default class extends Controller {
  static values = { primaryProducer: String };
  static targets = ["spinner"];

  primaryProducerChanged(event) {
    this.primaryProducerValue = event.currentTarget.checked;
    this.makeRequest();
  }

  makeRequest() {
    fetch(
      `?stimulus=true&is_primary_producer=${this.primaryProducerValue}`,
      {
        method: "GET",
        headers: { "Content-type": "application/json; charset=UTF-8" },
      }
    )
      .then((data) => data.json())
      .then((operation) => {
        CableReady.perform(operation);
        this.spinnerTarget.classList.add("hidden");
      });
  }
}
