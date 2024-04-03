import { defineConfig } from "cypress";

export default defineConfig({
  e2e: {
    redirectionLimit: 50,
    setupNodeEvents(on, config) {
      // implement node event listeners here
    },
  },
});
