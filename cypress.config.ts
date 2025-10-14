import { defineConfig } from "cypress";

export default defineConfig({
  e2e: {
    redirectionLimit: 50,
    setupNodeEvents(on, config) {
        on("task", {
            log(message) {
                console.log(message);
                return null;
            },
        });
        return config;
    },
  },
});

